# 06 — Rider Fleet & Dispatch Specification

This document specifies the delivery workflow, dispatch algorithms, and the **Rider Mobile App** (Flutter).

---

## 1. Frictionless Rider Onboarding

- **Registration**: Phone number input → SMS OTP verification.
- **Minimal Profile**: Full Name, Vehicle Type (`motorcycle`, `bicycle`, `car`), Contact Number.
- **Approval Gate**: Account created with status `PENDING_APPROVAL`. Super Admin activates rider with one click from `/admin/riders`. *Complex document uploads are omitted for the pilot.*

---

## 2. Rider App Interface & Duty State

- **Duty Toggle**: Prominent switch at top of app: `Online` / `Offline`.
- **Location Streaming**: When `Online`, streams GPS coordinates every 5–8 seconds to the backend via WebSocket (`rider:location:update`).
- **Performance Summary**: Displays completed trips today, delivery earnings, and accumulated COD cash in hand.

---

## 3. Order Dispatch & Broadcast Logic

```
[ Store Marks Order READY_FOR_PICKUP ]
                 │
                 ▼
[ Redis searches online idle riders within radius (e.g. 3-5 km) ]
                 │
                 ▼
[ Socket.IO sends dispatch:broadcast alert to matched riders ]
                 │
                 ▼
[ First rider to tap ACCEPT claims order via atomic Redis lock ]
                 │
                 ▼
(Fallback: If unaccepted after 90s, escalates to Super Admin manual assign)
```

---

## 4. The 3-Step Delivery Fulfillment Journey

Fulfillment is intentionally simple: zero verification PINs, zero barcode scans, zero touchscreen signatures.

```
[ STEP 1: ACCEPT ] ──► [ STEP 2: PICK UP ] ──► [ STEP 3: DELIVER ]
```

### Step 1: Accept Order
- Audio chime alert with modal displaying: Store Name, Distance to Store, Customer Area, Delivery Payout.
- Rider taps **"ACCEPT"** within 45-second window.

### Step 2: Pick Up Order
- **Navigate**: Tap "Directions to Store" → Opens native Google Maps or Apple Maps with turn-by-turn routing.
- **Arrive**: Collect packaged order labeled with `#OrderNumber`.
- **Confirm**: Tap **"Order Picked Up"** → Server transitions order to `DISPATCHED` and activates live customer tracking.

### Step 3: Deliver Order
- **Navigate**: Tap "Directions to Customer" → Opens native Google Maps to customer doorstep pin.
- **Contact**: Tap **"Call Customer"** shortcut (`tel:<phone_number>`) if directions are needed.
- **Complete Handover**:
  - If **Prepaid**: Tap **"Order Delivered"**.
  - If **Cash on Delivery (COD)**: Collect cash amount displayed on screen, check **"Cash Collected"** checkbox, then tap **"Order Delivered"**.
- Order transitions to `DELIVERED`, wallet balances update, and rider returns to idle pool.

---

## 5. Cash on Delivery (COD) Rules

- Every COD order adds the collected order value to `rider.cash_in_hand`.
- Every completed trip credits `rider.earnings_balance` with the trip payout.
- If `cash_in_hand >= max_cash_limit` (e.g., 5,000 BDT / 500 SAR), the system blocks the rider from receiving new COD broadcasts until cash is submitted at the central office.
