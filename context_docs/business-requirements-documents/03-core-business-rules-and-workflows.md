# 03 — Core Business Rules & Commercial Logic

This document defines the mathematical equations, financial ledgers, order state rules, and multi-region configurations for DeliveryOS.

---

## 1. Catalog & Cart Rules

1. **Single-Vendor Checkout**: A cart contains items from exactly **one vendor**. Adding an item from another vendor requires customer confirmation to clear the active cart.
2. **Item Pricing**:
   - `Item Total = (Base Price + Selected Variant Modifier + Sum of Selected Add-ons) * Quantity`
3. **Smart Re-Order Validation**:
   - Before repopulating a previous order into the cart, the backend validates:
     - `vendor.is_active == TRUE` and within operating hours.
     - `product.is_in_stock == TRUE` for all items.
     - Updates cart items to current active prices.

---

## 2. Order Lifecycle State Machine

```
[PLACED] ──► [ACCEPTED] ──► [PREPARING] ──► [READY_FOR_PICKUP] ──► [DISPATCHED] ──► [DELIVERED]
   │             │               │
   ▼             ▼               ▼
[CANCELLED]   [CANCELLED]   [CANCELLED] (Admin Only)
```

| Transition | Allowed Roles | Trigger Condition / Validation |
| :--- | :--- | :--- |
| `PLACED` → `ACCEPTED` | `VENDOR_ADMIN`, `SUPER_ADMIN` | Requires estimated `prep_time_minutes` (e.g., 15, 25, 40). |
| `PLACED` → `CANCELLED` | `VENDOR_ADMIN`, `SUPER_ADMIN`, `CUSTOMER` | Customer can cancel only while status is `PLACED`. |
| `ACCEPTED` → `PREPARING` | `VENDOR_ADMIN`, `SUPER_ADMIN` | Kitchen starts preparation. |
| `PREPARING` → `READY_FOR_PICKUP` | `VENDOR_ADMIN`, `SUPER_ADMIN` | Triggers radius broadcast dispatch to nearby online riders. |
| `READY_FOR_PICKUP` → `DISPATCHED` | `RIDER`, `SUPER_ADMIN` | Rider confirms order pickup at store. Activates live GPS streaming. |
| `DISPATCHED` → `DELIVERED` | `RIDER`, `SUPER_ADMIN` | Rider confirms delivery at customer doorstep + marks COD cash collected. |

---

## 3. Delivery Fee Calculation Engine

Super Admin configures delivery fee calculation via `system_settings`:

### Mode A: `FIXED_FLAT` (Pilot Default)
- `Delivery Fee = flat_rate` (e.g., 50.00 BDT or 12.00 SAR).

### Mode B: `DISTANCE_TIERED`
- If `distance_km <= base_km`:
  - `Delivery Fee = base_fee`
- If `distance_km > base_km`:
  - `Delivery Fee = base_fee + ((distance_km - base_km) * per_km_rate)`

---

## 4. Financial Equations & Commission Ledger

For every completed order:

| Metric | Formula | Example (BDT) |
| :--- | :--- | :--- |
| **Gross Subtotal** | Sum of items & add-ons | 500.00 |
| **Delivery Fee** | Based on active fee model | 50.00 |
| **Tax / VAT** | `Gross Subtotal * (tax_rate / 100)` | 0.00 |
| **Total Customer Paid** | `Gross Subtotal + Delivery Fee + Tax` | **550.00** |
| **Platform Commission** | `Gross Subtotal * (commission_rate / 100)` | 75.00 (15%) |
| **Net Vendor Payable** | `Gross Subtotal - Platform Commission` | **425.00** |
| **Rider Delivery Earnings**| Configured trip payout | **40.00** |
| **Platform Net Margin** | `Platform Commission + (Delivery Fee - Rider Earnings)` | **85.00** |

---

## 5. Cash on Delivery (COD) & Settlement

1. **Rider Cash Collection**:
   - For COD orders, the rider collects `total_amount` in physical cash.
   - `rider.cash_in_hand += total_amount`.
   - `rider.earnings_balance += rider_delivery_earnings`.
   - If `rider.cash_in_hand >= rider.max_cash_limit`, block new COD orders.
2. **Vendor Batch Settlement**:
   - Super Admin generates weekly CSV settlement report: `Net Vendor Payable`.
   - Admin disburses funds via offline bank transfer and marks the batch `SETTLED`.

---

## 6. Multi-Region Parameters

| Parameter | Region Mode: `BD` | Region Mode: `KSA` |
| :--- | :--- | :--- |
| **Currency Code / Symbol** | `BDT` / `৳` | `SAR` / `﷼` |
| **Supported Locales** | English (`en`), Bengali (`bn`) | Arabic RTL (`ar`), English (`en`) |
| **Phone Prefix** | `+880` (10-digit national number) | `+966` (9-digit national number) |
| **Default Flat Delivery Fee** | 50.00 BDT | 12.00 SAR |
