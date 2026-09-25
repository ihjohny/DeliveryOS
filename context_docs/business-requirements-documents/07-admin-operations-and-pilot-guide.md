# 07 — Super Admin Operations & 10-Vendor Pilot Guide

This document defines the controls of the **Super Admin Master Console** (`/admin`) and provides the operational playbook for platform administrators and dispatchers.

---

## 1. Master Console Modules & Route Architecture

The Super Admin Console is structured into 6 consolidated SPA operational modules ([ADR-005](context_docs/architecture-decision-records/ADR-005-micro-frontends-and-subpath-routing.md)):

```
/admin
├── / & /dashboard    # Operational Overview, Real-time KPIs & Order Feed
├── /dispatch         # Leaflet Live Fleet Radar & Applicant Couriers Queue
├── /orders           # Order Lifecycle Monitor, ?orderNumber Deep Linking & Overrides
├── /promotions       # Hero Carousel Banners & Discount Coupon Engine
├── /vendors          # Outlet Onboarding, Commission Rates & Staff Scopes
└── /settings         # Order Flow FSM, Delivery Fee Economics & CSV Settlements
```

---

## 2. Key Administrative Controls & Workflows

### 2.1. Live Fleet Radar & Dispatch Command (`/dispatch`)
- **Interactive Leaflet OSM Radar**: Zero-API-cost mapping engine tracking active couriers and unassigned delivery orders (`LiveFleetMap`).
- **Color-Coded Courier Pins**:
  - Emerald `#10b981`: Online & idle, ready for dispatch.
  - Sky `#0284c7`: In-flight active delivery.
  - Amber `#ea580c`: Approaching COD cash collection limit.
  - Slate `#64748b`: Offline.
- **Unassigned Orders Radar**: Bouncing amber target markers displaying order number, store name, and gross total.
- **SPA Deep Linking Navigation**: Clicking `"Open Order →"` inside a map popup navigates directly to `/orders?orderNumber=...` via React Router without page reload or dropping WebSocket connections.

### 2.2. Courier Fleet Governance & Applicant Queue (`/dispatch`)
- **Dedicated Applicant Couriers Queue**: Filter tab displaying all pending self-registered couriers awaiting verification.
- **Applicant Badge Metric Card**: Real-time counter of couriers awaiting verification.
- **1-Click Approval & Suspension**: Instant toggle approving applicant credentials (`adminApi.setRiderApproval(id, true)`) or suspending problematic couriers.
- **Cash Safety Limit Adjustment**: Modal allowing operations staff to adjust a courier's maximum COD limit (e.g. ৳3,000 to ৳10,000) based on trust and tenure.

### 2.3. Live Order Monitor & Administrative Overrides (`/orders`)
- **URL Query Param Deep Linking**: Navigating to `/orders?orderNumber=ORD-XXXX` automatically filters the table, displays an active filter banner, and opens the assignment or details modal.
- **Itemized Order Details Modal**:
  - Store outlet and customer details.
  - Courier assignment status with 1-click assign shortcut.
  - Cooking and delivery notes.
  - Complete line items list with unit prices and subtotals.
  - Financial summary.
- **Force-Assign Courier Modal**:
  - Line items summary with quantities and dish names.
  - Customer notes display.
  - Courier selection radio list displaying online status, active delivery state, and current cash balance.
  - Bypasses automated dispatch algorithm via `adminApi.forceAssignRider(orderId, riderId)`.
- **Force-Cancel Order Modal**:
  - Reversal warning alert: audit trail logging, courier release, and ledger reversal.
  - Itemized list of dishes to be cancelled.
  - Mandatory audit reason textarea (minimum 5 characters).
  - Reverses commission ledger and broadcasts cancellation to all parties (`adminApi.cancelOrder(orderId, reason)`).

### 2.4. Promotional Campaigns & Coupons (`/promotions`)
- **Hero Carousel Banner Management**: Tab to schedule, activate, prioritize, and delete homepage promotion banners with image previews.
- **Discount Coupon Engine**:
  - Alphanumeric promo codes with flat or percentage discount modes.
  - Configurable minimum order spend, maximum discount ceiling, and total usage limits.
  - 1-click active/inactive toggle and deletion.

### 2.5. Restaurant & Outlet Management (`/vendors`)
- **Outlet Onboarding & Approval**: Approve pending merchant registration requests or directly create new outlets and staff logins.
- **Permission Assignment**: Grant either `PARTICULAR_OUTLET` (binds staff strictly to one branch) or `ALL_OUTLETS_MASTER` (brand owner access).
- **Store Configuration**: Commission rate (e.g. 15%), delivery radius (km), operational hours, and default prep time.

### 2.6. System Settings & Settlement Statements (`/settings`)
- **Order Flow FSM Selector**: 1-click toggle between `RIDER_FIRST` (Zero Food Waste Mode) and `VENDOR_FIRST` (Traditional Retail Mode).
- **Delivery Fee Pricing Engine**: Toggle between `FIXED_FLAT` (uniform flat rate) and `DISTANCE_TIERED` (base fee + per-km fee).
- **RFC 4180 CSV Settlement Export**: Download formatted `vendor-settlements-YYYY-MM-DD.csv` for enterprise accounting systems (ERP / QuickBooks) ([ADR-009](context_docs/architecture-decision-records/ADR-009-deterministic-financial-accounting-ledger.md)).
- **Settlement Batch Audit Trail & Trigger**: Payout batch list and modal to execute settlement cycles via `POST /admin/finance/settlement-cycle`.

---

## 3. 10-Vendor Pilot Launch Checklist (1-Month Run)

### Week 0: Pre-Launch Setup
- [ ] **Zone Definition**: Establish a concentrated 3–5 km radius pilot geofence.
- [ ] **Store Onboarding**: Onboard 10 initial stores (7 restaurants/cafes, 3 grocery/super shops).
- [ ] **Permission Assignment**: Set up store managers with Particular Outlet permissions and brand owners with Master permissions.
- [ ] **Catalog Digitalization**: Populate complete menus, prices, variants, toppings, and product images.
- [ ] **Promotional Campaign**: Configure 2–3 welcome promotional banners and a pilot coupon code (`PILOT50`).
- [ ] **Store Hardware**: Ensure each store has a tablet or smartphone with active internet at the counter.
- [ ] **Rider Fleet**: Onboard and pre-approve 5–8 active riders with motorcycles or bicycles.
- [ ] **System Settings**: Set delivery fee mode to `FIXED_FLAT` (e.g., 50 BDT / 12 SAR) for transparent pilot pricing.

### Week 1: Soft Launch & Controlled Testing
- [ ] Operate during limited hours (e.g. 12:00 PM – 9:00 PM).
- [ ] Execute test orders across all 10 vendors to verify tablet audio chimes, native map routing, and COD collection.
- [ ] Validate that the Cart Address Geofence Guard strictly prevents orders outside the 3–5 km zone.

### Week 2: Public Launch
- [ ] Open ordering to public within pilot zone.
- [ ] Deploy marketing table tents with QR codes at the 10 pilot partner locations.
- [ ] Monitor order acceptance times, kitchen prep timers, and rider dispatch response.

### Week 3: Performance Tuning
- [ ] Audit delivery times (target: under 35 minutes).
- [ ] Optimize vendor prep times and address any recurring stock-out issues.

### Week 4: Pilot Audit & Expansion Sign-Off
- [ ] Export 30-day financial, commission, and rider remuneration statements via CSV export.
- [ ] Review customer feedback, vendor satisfaction, and rider delivery metrics.
- [ ] Plan Phase 2 expansion to 50+ stores and additional delivery zones.
