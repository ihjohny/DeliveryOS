# 03 — Core Business Rules & Commercial Logic

This document defines the mathematical equations, financial ledgers, order state rules, permission models, and multi-region configurations for DeliveryOS.

---

## 1. Catalog, Cart & Address Guard Rules

1. **Single-Vendor Checkout**: A cart contains items from exactly **one vendor outlet**. Adding an item from another vendor requires customer confirmation to clear the active cart.
2. **Item Pricing**:
   - `Item Total = (Base Price + Selected Variant Modifier + Sum of Selected Add-ons) * Quantity`
3. **Cart Address Geofence Guard (Strict Coverage Enforcement)**:
   - When browsing, the customer's selected location filters available outlets.
   - When reviewing the cart, the customer can add or edit their delivery address.
   - **Boundary Invariant**: The system strictly prohibits moving or selecting a delivery address outside the active outlet's delivery coverage radius.
   - **Validation**:
     ```sql
     ST_DWithin(customer_address.coordinates, vendor.coordinates, vendor.delivery_radius_km * 1000) == TRUE
     ```
   - If the delivery coordinates fall outside the radius, checkout is blocked with an immediate prompt: *"Selected address is outside this outlet's delivery coverage area. Please choose an address within coverage or select a closer outlet."*
4. **Coupon Code & Promotional Discounts**:
   - Customers can apply one valid coupon code per order.
   - **Percentage Discount**:
     `Discount = MIN(Gross Subtotal * (coupon.discount_value / 100), coupon.max_discount_amount)`
   - **Flat Discount**:
     `Discount = MIN(coupon.discount_value, Gross Subtotal)`
   - **Validation Invariants**:
     - `order.gross_subtotal >= coupon.min_order_amount`
     - `CURRENT_TIMESTAMP BETWEEN coupon.valid_from AND coupon.valid_to`
     - `coupon.current_uses < coupon.usage_limit`
5. **Smart Re-Order Validation**:
   - Before repopulating a previous order into the cart, the backend validates:
     - `vendor.is_active == TRUE` and within operating hours.
     - `customer_address` is still within `vendor.delivery_radius_km`.
     - `product.is_in_stock == TRUE` for all items and variants.
     - Updates cart items to current active prices.
6. **Deterministic Order Numbering**:
   - Sequence Format: `ORD-YYYYMMDD-XXXX` (e.g. `ORD-20260924-0001`).
   - Generated via atomic Redis daily counter (`INCR order:seq:YYYYMMDD` with 48h TTL).
   - Backed by an automated 3-attempt database unique constraint collision retry loop.

---

## 2. Order Lifecycle & Configurable Dispatch Sequences

The platform supports a **dynamically configurable order flow sequence** (`order_flow_mode` in settings) to prevent food waste and adapt to operational requirements.

### Sequence Mode 1: `RIDER_FIRST` (Recommended — Zero Food Waste & Loss Prevention)
Designed for food delivery where kitchen preparation must only begin after a delivery rider is secured:
```
1. Customer submits checkout
2. System checks store status & address coverage BEFORE creating DB order
3. System broadcasts order immediately to available online riders within radius
4. Available rider claims order ──► Rider Assigned (RIDER_ASSIGNED)
5. System sends order to Vendor console (kitchen chime rings with rider-guaranteed badge)
6. Vendor reviews items, selects custom prep time OR default prep time, and taps ACCEPT
7. Vendor prepares food while rider travels to store ──► [READY_FOR_PICKUP]
8. Rider arrives, picks up order ──► [DISPATCHED] ──► [DELIVERED]
```
> **Key Benefit**: Eliminates uncollectible food waste and financial loss if no rider is available, while preserving the vendor's explicit manual control over order acceptance and prep timing.

### Sequence Mode 2: `VENDOR_FIRST` (Traditional Retail / Grocery Flow)
```
1. Customer submits checkout ──► [PLACED]
2. Vendor accepts & sets prep timer (or uses default) ──► [ACCEPTED] ──► [PREPARING]
3. When items are packed, store marks [READY_FOR_PICKUP]
4. System broadcasts to riders ──► Rider claims ──► [DISPATCHED] ──► [DELIVERED]
```

### Universal State Transitions:

| Transition | Allowed Roles | Trigger Condition / Validation |
| :--- | :--- | :--- |
| `PLACED` → `RIDER_ASSIGNED` | `RIDER`, `SUPER_ADMIN` | In `RIDER_FIRST` mode: Rider claims broadcast before kitchen prep begins. |
| `PLACED` or `RIDER_ASSIGNED` → `ACCEPTED` | `VENDOR_ADMIN`, `SUPER_ADMIN` | Store confirms receipt with custom or default prep time and starts prep. |
| `PLACED` → `CANCELLED` | `VENDOR_ADMIN`, `SUPER_ADMIN`, `CUSTOMER` | Customer or store cancels before prep / rider lock. |
| `ACCEPTED` → `PREPARING` | `VENDOR_ADMIN`, `SUPER_ADMIN` | Kitchen / packing in progress. |
| `PREPARING` → `READY_FOR_PICKUP` | `VENDOR_ADMIN`, `SUPER_ADMIN` | Items packed and waiting on store counter. |
| `READY_FOR_PICKUP` → `DISPATCHED` | `RIDER`, `SUPER_ADMIN` | Rider confirms physical pickup at store. Activates live GPS streaming. |
| `DISPATCHED` → `DELIVERED` | `RIDER`, `SUPER_ADMIN` | Rider confirms delivery at customer doorstep + marks COD cash collected. |

---

## 3. Vendor Permission Hierarchy & Scope Rules

DeliveryOS enforces a two-tier vendor management hierarchy to accommodate both standalone single stores and large multi-outlet chains:

| Permission Tier | Scope | Allowed Actions & Visibility |
| :--- | :--- | :--- |
| **Particular Outlet Permission** *(Branch Manager)* | Single assigned physical outlet (`vendor_id`) | - Live kitchen order console for that outlet only.<br/>- Instant stock availability toggle for that outlet.<br/>- Operating hours and emergency pause for that outlet.<br/>- Sales ledger for that outlet only.<br/>*Cannot access or modify any sister branch.* |
| **All Outlets Permission (Master Vendor)** *(Brand Owner / Franchisee)* | All outlets under merchant brand | - Consolidated brand overview and multi-outlet sales aggregation.<br/>- Switch seamlessly between branch views with one click.<br/>- Brand-wide menu and master catalog updates across all outlets.<br/>- Combined financial statements and settlement records. |

---

## 4. Delivery Fee Calculation Engine

Super Admin configures delivery fee calculation via `system_settings`:

### Mode A: `FIXED_FLAT` (Pilot Default)
- `Delivery Fee = flat_rate` (e.g., 50.00 BDT or 12.00 SAR).

### Mode B: `DISTANCE_TIERED`
- If `distance_km <= base_km`:
  - `Delivery Fee = base_fee`
- If `distance_km > base_km`:
  - `Delivery Fee = base_fee + ((distance_km - base_km) * per_km_rate)`

---

## 5. Financial Equations & Commission Ledger

For every completed order:

| Metric | Formula | Example (BDT) |
| :--- | :--- | :--- |
| **Gross Subtotal** | Sum of items & add-ons | 500.00 |
| **Coupon Discount** | Applied coupon value | - 50.00 |
| **Net Subtotal** | `Gross Subtotal - Coupon Discount` | 450.00 |
| **Delivery Fee** | Based on active fee model | 50.00 |
| **Tax / VAT** | `Net Subtotal * (tax_rate / 100)` | 0.00 |
| **Total Customer Paid** | `Net Subtotal + Delivery Fee + Tax` | **500.00** |
| **Platform Commission** | `Net Subtotal * (commission_rate / 100)` | 67.50 (15%) |
| **Net Vendor Payable** | `Net Subtotal - Platform Commission` | **382.50** |
| **Rider Delivery Earnings**| Configured trip payout | **40.00** |
| **Platform Net Margin** | `Platform Commission + (Delivery Fee - Rider Earnings)` | **77.50** |

---

## 6. Cash on Delivery (COD) & Settlement

1. **Rider Cash Collection**:
   - For COD orders, the rider collects `Total Customer Paid` in physical cash.
   - `rider.cash_in_hand += Total Customer Paid`.
   - `rider.earnings_balance += rider_delivery_earnings`.
   - If `rider.cash_in_hand >= rider.max_cash_limit`, block new COD orders.
2. **Vendor Batch Settlement**:
   - Super Admin generates weekly CSV settlement report: `Net Vendor Payable`.
   - Admin disburses funds via offline bank transfer and marks the batch `SETTLED`.

---

## 7. Multi-Region Parameters

| Parameter | Region Mode: `BD` | Region Mode: `KSA` |
| :--- | :--- | :--- |
| **Currency Code / Symbol** | `BDT` / `৳` | `SAR` / `﷼` |
| **Supported Locales** | English (`en`), Bengali (`bn`) | Arabic RTL (`ar`), English (`en`) |
| **Phone Prefix** | `+880` (10-digit national number) | `+966` (9-digit national number) |
| **Default Flat Delivery Fee** | 50.00 BDT | 12.00 SAR |
