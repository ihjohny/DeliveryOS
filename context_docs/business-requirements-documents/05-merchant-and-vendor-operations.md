# 05 — Merchant & Vendor Portal Specification

This document defines the onboarding workflows, permission levels, interface layout, and operational rules for the **Vendor Store Portal** (`/vendor`), a responsive React.js SPA running on tablets, desktops, and mobile browsers.

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
   - Merchant visits `/vendor/register`, inputs store name, vertical (`Food`, `Grocery`, `Super Shop`), trade license info, owner name, phone, and proposed outlet address.
   - Account is created in `PENDING_APPROVAL` status.
2. **Direct Super Admin Creation**:
   - Platform Super Admin can directly create a new vendor outlet, set up store credentials, and assign staff directly from `/admin/vendors`.
3. **Super Admin Approval Requirement**:
   - An outlet cannot accept orders or appear in customer search until the Super Admin formally reviews and changes status to `ACTIVE`.

---

## 2. Two-Level Vendor Permission Hierarchy

The portal dynamically adapts its navigation and data access based on the logged-in user's assigned permission tier:

```
┌──────────────────────────────────────────────────────────┐
│             Master Vendor Account (All Outlets)          │
│       Oversees Brand-wide Performance, Multi-Branch Menus│
└─────────────┬──────────────────────────────┬─────────────┘
              ▼                              ▼
┌───────────────────────────┐  ┌───────────────────────────┐
│   Branch 1 Manager Portal │  │   Branch 2 Manager Portal │
│ (Particular Outlet Perm.) │  │ (Particular Outlet Perm.) │
└───────────────────────────┘  └───────────────────────────┘
```

### Level 1: Particular Outlet Permission (Branch Store Manager)
- **Scope**: Strictly bound to a single physical outlet ID (`vendor_id`).
- **Access**:
  - Live kitchen order console for that outlet only.
  - Stock availability toggle for items at that specific location.
  - Opening/closing operating hours and rush hour pause for that outlet.
  - Daily sales ledger and settlement records for that specific outlet.
- **Restriction**: Cannot view or modify sister branches, pricing across other outlets, or brand-level financials.

### Level 2: All Outlets Permission (Master Vendor / Franchise Owner)
- **Scope**: Multi-outlet brand access across all branches under the parent brand.
- **Access**:
  - Outlet selector switcher in the top navigation bar to toggle between individual branches or view consolidated data.
  - Brand-wide menu catalog manager (bulk push category and item changes to all outlets or override specific branches).
  - Consolidated sales analytics and aggregated payout statements.
  - Creation and management of branch-level staff accounts.

---

## 3. Interface Layout & Routes

```
/vendor
├── /live-orders      # Kitchen / Store Order Console (KDS)
├── /catalog          # Category, Product, Variant & Topping Management
├── /timings          # Operating Hours, Default Prep Time & Emergency Pause
└── /financials       # Sales Ledger & Settlement History
```

---

## 4. Module 1: Live Kitchen Order Console (`/live-orders`)

### Audio Alert Engine & Screen Behavior:
- **Continuous Audio Alarm**: Plays a persistent ringing chime (`/sounds/order-alarm.mp3`) upon receiving an incoming order via WebSocket. The audio context unlocks on first touch/interaction.
- **Visual Alert**: Flashing green border on incoming order cards.
- **Acknowledgement**: The chime rings continuously until kitchen staff acknowledges the order by tapping **Accept** or **Reject**.

### Order Lanes (Kanban Workflow):
1. **New Orders Lane**:
   - Displays Order Number, itemized dish list, variants, selected toppings, customer cooking notes, total amount, payment method (COD vs Online), and a badge verifying the assigned delivery rider.
   - **Acceptance Option A (Default Prep Time)**: One-tap button **"Accept with Default [X] mins"** for rapid kitchen throughput during rush hours.
   - **Acceptance Option B (Custom Prep Time)**: Tap **"Accept (Custom)"** and select from prep time dropdown (`15m`, `25m`, `35m`, `45m`).
   - **Rejection**: Tap **"Reject"** with mandatory reason dropdown (`Kitchen Overloaded`, `Item Out of Stock`, `Closing Early`).
2. **In Preparation Lane**:
   - Active countdown timer reflecting the accepted preparation duration.
   - Action: **"Ready for Pickup"** button. (Notifies the waiting rider that food is packaged and ready at the counter).
3. **Ready for Pickup Lane**:
   - Displays assigned rider name, phone shortcut, and rider ETA.
   - Action: **"Handed to Rider"** button. (Confirms parcel transfer and moves order to Dispatched state).

---

## 5. Module 2: Catalog & Item Customizer (`/catalog`)

### Outlet Data & Item Customization:
- **Category Management**: Create, rename, re-order, and delete categories within the outlet.
- **Product Information**: Name, description, base price, unit type (`piece`, `kg`, `500g`), and photo upload.
- **Single Variant Configuration**: Add mutually exclusive options (e.g. Size: *Regular, Medium, Large* or Weight: *500g, 1kg*) with respective price deltas (`+/- X`).
- **Toppings & Add-on Groups**: Configure optional extras (e.g. *Extra Cheese +50 ৳, Sauce +20 ৳*) with min/max selection bounds.
- **Instant Stock Toggle**: Every item and variant features an active **`In Stock / Out of Stock`** switch that updates the database and customer apps immediately via `PATCH /vendor/products/:id/stock`.

---

## 6. Module 3: Store Customization & Operations (`/timings`)

- **Default Preparation Time**: Store manager configures the outlet's standard prep duration (e.g. `15 mins`, `20 mins`, `30 mins`). Used for one-tap order acceptance.
- **Weekly Schedule**: Configure `open_time` and `close_time` for each day of the week (Sunday through Saturday), with individual closed-day checkboxes.
- **Emergency Store Pause**: Quick button to pause incoming orders temporarily for `30 minutes`, `1 hour`, or `Rest of Day` during extreme kitchen rushes or prayer times.

---

## 7. Module 4: Sales & Ledgers (`/financials`)

- **Daily Performance Summary**: Total orders completed, gross sales revenue, platform commission deducted, and net balance pending payout.
- **Settlement Statements**: Historical statements generated by the Super Admin indicating settlement statuses (`PENDING`, `SETTLED`) and bank transfer references.
