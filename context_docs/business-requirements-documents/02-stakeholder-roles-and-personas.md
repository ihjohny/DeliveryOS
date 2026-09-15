# 02 — Stakeholder Roles & Access Specifications

This document defines the roles, permissions, operational constraints, and critical UX requirements for all platform actors.

---

## 1. Role Matrix

| Role | Role Enum | Interface | Core Responsibilities & Scope |
| :--- | :--- | :--- | :--- |
| **Customer** | `CUSTOMER` | Mobile App (Flutter) | Browse stores, customize cart, checkout, live track delivery, direct phone call, re-order. |
| **Vendor Staff** | `VENDOR_ADMIN` | Web Portal (`/vendor`) | Acknowledge incoming orders with audio alarm, update prep times, manage catalog & stock toggles. |
| **Delivery Rider**| `RIDER` | Mobile App (Flutter) | Online/offline duty toggle, claim broadcasted orders, 3-step delivery execution, COD collection. |
| **Super Admin** | `SUPER_ADMIN` | Web Portal (`/admin`) | 100% master authority: catalog edits, price overrides, vendor settings, live fleet map, manual dispatch, ledger exports. |
| **Support Agent** | `SUPPORT` | Web Portal (`/admin`) | Read-only inspection of orders, customer/rider details, and delivery event timelines. |

---

## 2. Detailed Role Specifications

### 2.1 Customer (`CUSTOMER`)
- **Primary Actions**:
  - Authenticate via Phone OTP (or browse as Guest until checkout).
  - Pin delivery location on Google Maps; save labeled addresses (`Home`, `Work`, `Other`).
  - Add items to cart from **single vendor**; configure variants and add-ons.
  - Checkout via Cash on Delivery (COD) or Online Payment Gateway.
  - Track order progress via stepper and live moving rider map marker.
  - One-tap **Direct Call** shortcut (`tel:` link) to reach rider or vendor.
  - One-tap **Smart Re-Order** with real-time stock and store operational status check.
- **Constraints**: Cannot order from multiple stores in a single checkout. Cannot cancel once vendor begins preparation without contacting support.

---

### 2.2 Vendor Staff (`VENDOR_ADMIN`)
- **Primary Actions**:
  - Receive real-time orders via WebSockets with continuous audio alarm until acknowledged.
  - Accept order with prep timer (`15m`, `25m`, `40m`) or reject with reason code.
  - Tap "Ready for Pickup" to notify waiting riders.
  - Instant stock availability toggle (In Stock / Out of Stock switch) per item/variant.
  - Configure daily business hours and emergency store pause.
  - View daily sales summary and net payout ledger balance.
- **Constraints**: Scoped strictly to own store data (`WHERE vendor_id = user.vendorId`).

---

### 2.3 Delivery Rider (`RIDER`)
- **Primary Actions**:
  - Sign up with phone OTP, name, and vehicle type (minimal onboarding).
  - Toggle duty status (`Online` / `Offline`).
  - Receive radius broadcast alerts; tap to claim order within 45 seconds.
  - **Fulfillment Step 1**: Accept broadcasted order.
  - **Fulfillment Step 2**: Tap "Directions to Store" (launches native Google/Apple Maps); arrive and tap "Order Picked Up".
  - **Fulfillment Step 3**: Tap "Directions to Customer"; deliver parcel; check COD collection box if cash order; tap "Order Delivered".
  - Track daily completed trips and collected cash balance.
- **Constraints**: Blocked from accepting new COD orders if collected cash exceeds `max_cash_limit` (e.g., 5,000 BDT / 500 SAR) until cash is deposited.

---

### 2.4 Super Admin (`SUPER_ADMIN`)
- **Primary Actions**:
  - **Master Catalog Authority**: Centrally create, edit, reprice, or delete any dish, SKU, or category across all vendors.
  - **Live Fleet Radar**: View all online riders on an interactive map with trip statuses.
  - **Manual Dispatch Override**: Force-assign or reassign unaccepted orders to any online rider.
  - **Configurable Fees**: Toggle platform delivery fee mode (`FIXED_FLAT` vs `DISTANCE_TIERED`).
  - **Financial Settlements**: Export weekly vendor payout and rider commission reports (CSV).
- **Constraints**: None. Super Admin bypasses all multi-tenant filters.
