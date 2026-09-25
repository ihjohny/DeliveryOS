# 05 — Merchant & Vendor Portal Specification

This document defines the onboarding workflows, permission levels, interface layout, and operational rules for the **Vendor Store Portal** (`/vendor`), a responsive React 18 SPA optimized for kitchen tablets and merchant desktop browsers.

---

## 1. Onboarding & Account Lifecycle

Vendors join the platform through two supported pathways:

```
Pathway A: Self-Registration Form
  [Vendor Submits Application] ──► [Pending Review in Admin] ──► [Admin Approves & Grants Permissions] ──► [Store Goes Live]

Pathway B: Direct Admin Registration
  [Super Admin Creates Store & Staff Account] ──► [Assigns Outlet / Master Scope] ──► [Credentials Sent to Vendor]
```

1. **Vendor Self-Registration Application**:
   - Merchant visits `/vendor/register`, inputs store name, vertical (`FOOD`, `GROCERY`, `SUPER_SHOP`, `PHARMACY`), contact details, and branch coordinates.
   - Account is created in `PENDING_APPROVAL` status.
2. **Direct Super Admin Creation**:
   - Platform Super Admin can create outlets and staff accounts directly from `/admin/vendors`.
3. **Super Admin Approval Requirement**:
   - Outlets cannot accept orders or appear in customer discovery until approved as `ACTIVE`.

---

## 2. Two-Level Vendor Permission Hierarchy

The portal dynamically adapts based on the user's permission scope ([ADR-005](context_docs/architecture-decision-records/ADR-005-micro-frontends-and-subpath-routing.md)):

```
┌──────────────────────────────────────────────────────────┐
│             Master Vendor Account (ALL_OUTLETS_MASTER)   │
│       Oversees Brand-wide Performance, Multi-Branch Menus│
└─────────────┬──────────────────────────────┬─────────────┘
              ▼                              ▼
┌───────────────────────────┐  ┌───────────────────────────┐
│   Branch 1 Manager Portal │  │   Branch 2 Manager Portal │
│ (PARTICULAR_OUTLET Perm.) │  │ (PARTICULAR_OUTLET Perm.) │
└───────────────────────────┘  └───────────────────────────┘
```

### Level 1: Particular Outlet Permission (`PARTICULAR_OUTLET`)
- **Scope**: Bound strictly to a single physical outlet ID.
- **Access**:
  - Live KDS board for that outlet only.
  - Stock availability toggle for items at that location.
  - Operating hours and rush hour pause for that outlet.
  - Sales ledger and receipts for that specific location.
- **Lock Indicator**: The top navbar displays a locked store pill (`Store` icon + `Lock` icon) showing access is fixed to that branch.

### Level 2: All Outlets Permission (`ALL_OUTLETS_MASTER`)
- **Scope**: Multi-branch brand owner account.
- **Access**:
  - Interactive `OutletSwitcher` dropdown in the top header to toggle between individual branches or aggregate across all outlets (`ALL`).
  - View consolidated sales volume and payout statements across the entire brand.

---

## 3. Interface Layout & Active Routes

```
/vendor
├── / & /kds           # 3-Lane Kitchen Display System (KDS)
├── /catalog           # Merchant Menu Catalog, Sold-Out Retention & Stock Toggles
├── /orders            # Itemized Sales Ledger, Today vs All Time, Payout Statements
└── /settings          # Outlet Operating Hours, Default Prep Duration & Rush Pause
```

---

## 4. Module 1: Live Kitchen Order Console (`/kds`)

### 4.1. Web Audio API Oscillator Alert Engine (ADR-007)
- **In-Memory Synthesized Chime**: Eliminates external `.mp3` files; synthesizes a dual-tone bell chime in-memory (D5 587 Hz + A5 880 Hz).
- **Persistent Alarm Loop**: Chime repeats every 3 seconds upon incoming orders via WebSocket `order:new`.
- **Guaranteed Silence Invariant**: Audio loop automatically stops **only when all unaccepted orders in Lane 1 are accepted or rejected**.
- **User Gesture Unlock**: Unlocks browser audio context on the first user interaction anywhere on the page.

### 4.2. 3-Lane Kanban Progression
1. **Lane 1: New Orders (`PLACED` / `RIDER_ASSIGNED`)**:
   - Displays pulsing rose ping badge with elapsed arrival timer.
   - Shows customer notes, dish options, quantities, and courier assignment status.
   - **One-Tap Accept**: Defaults to store prep duration (e.g. 20 min). Order transitions directly to `PREPARING` ([ADR-002](context_docs/architecture-decision-records/ADR-002-dynamic-dual-order-flow-fsm.md)).
   - **Custom Prep Time Selector**: Quick pills for `[15, 20, 25, 35, 45]` minutes.
   - **Structured Reject Modal**: Requires selecting from reason codes (`OUT_OF_STOCK`, `KITCHEN_OVERLOAD`, `STORE_CLOSING_SOON`, `OTHER`) with an optional notes field.
2. **Lane 2: In Preparation (`PREPARING`)**:
   - **Digital Countdown Timer (`CountdownTimer`)**: Computes remaining time from `acceptedAt + prepTimeMinutes`.
   - **SLA Breach Visuals**: Shifts from amber to flashing pulse-red when overdue.
   - Action: **"Ready for Pickup"** button transitions order to `READY_FOR_PICKUP`.
3. **Lane 3: Ready for Pickup (`READY_FOR_PICKUP`)**:
   - Displays assigned courier name, phone number snapshot, and arrival status.
   - Action: **"Hand to Rider"** button confirms physical package handover and moves order to `DISPATCHED`.

### 4.3. 1-Click Rush Hour Pause & Emergency Controls
- **Top Header Quick Toggle**: Directly accessible on the navbar with flame icon: `"Rush Pause"` ➔ `"Rush Paused (Resume)"`.
- **Global Alert Banner**: Amber banner notifying staff that customer checkouts are blocked, featuring an instant `"Resume Orders Now"` button.

---

## 5. Module 2: Merchant Catalog & Stockout Management (`/catalog`)

### 5.1. Dedicated Merchant Endpoint (`GET /vendor/catalog`)
- Unlike consumer storefronts that hide sold-out dishes, this endpoint retains all catalog items.
- Displays summary KPI cards: Total Dishes, In-Stock Count, and Out-of-Stock Count.

### 5.2. Instant 1-Click Stock Switches
- **Dish-Level Toggle**: 1-click toggle calling `PATCH /api/v1/vendor/products/:id/stock`.
- **Variant-Level Toggle**: 1-click toggle calling `PATCH /api/v1/vendor/products/variants/:id/stock`.
- Optimistic updates via TanStack Query provide instant visual feedback (sold-out items display red borders and "Sold Out" badges).

---

## 6. Module 3: Store Operations & Operating Schedule (`/settings`)

- **Default Preparation Duration**: Dropdown selector (`15`, `20`, `25`, `30`, `45` min) used for one-tap order acceptance.
- **Weekly 7-Day Schedule**: Form configuring opening and closing times for Sunday through Saturday, with individual closed-day checkboxes (`PUT /vendor/operating-hours`).
- **Emergency Timed Pause**: Preset pause durations (`30 minutes`, `1 hour`, `Rest of Day`).

---

## 7. Module 4: Sales Ledger & Financial Statements (`/orders`)

- **Date Range Filters**: Segmented control switching between `Today` (default) and `All Time`.
- **Dynamic KPI Summary**: Recalculates Completed Orders, Gross Revenue, Commission Deducted (15%), and Net Vendor Payable based on active date filter.
- **Itemized Order Details Modal**:
  - Customer contact snapshot and delivery address.
  - Special cooking instructions note.
  - Itemized breakdown of quantities, variants, add-ons, unit prices, and line item subtotals.
  - Financial breakdown: Gross amount, platform commission (15%), net payable, payment method, and settlement status (`SETTLED` vs `PENDING`).
