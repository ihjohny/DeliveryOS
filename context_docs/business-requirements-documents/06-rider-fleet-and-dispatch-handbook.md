# 06 — Rider Fleet & Dispatch Handbook

This document specifies the courier onboarding workflow, shift management, dispatch algorithms, and fulfillment lifecycle for the **Rider Mobile App** (Flutter 3.19+, Riverpod 3.3.2).

---

## 1. Courier Onboarding & Approval Gate

- **Registration & Authentication**: Courier enters phone number (`+880` / `+966`) and verifies via 6-digit SMS OTP (`PhoneLoginScreen`).
- **Administrative Verification Gate (`PendingApprovalScreen`)**:
  - Newly registered couriers default to `is_approved = false` (`PENDING_APPROVAL`).
  - The app locks access to a clear verification screen explaining document review until activated by a Super Admin from `/admin/dispatch`.
  - When approved, courier is granted access to the shift dashboard.

---

## 2. Shift Management & Telemetry

- **High-Contrast Duty Switch (`RiderDashboardScreen`)**:
  - One-tap switch toggling between `Online (Start Shift)` and `Offline (End Shift)`.
  - **In-Flight Duty Lock**: Couriers are strictly blocked from going offline while assigned an active in-flight delivery (`RIDER_ASSIGNED` or `DISPATCHED`). The app prevents toggle action and surfaces a clear alert: *"Cannot go offline while you have an active in-flight delivery. Please complete or release the order first."*
- **Background GPS Foreground Service**:
  - Android `FOREGROUND_SERVICE_LOCATION` and iOS background location updates.
  - Telemetry streams location every 10 meters via WebSocket `rider:location:update` for live customer tracking and Redis GEO index persistence, with HTTP fallback (`PATCH /riders/duty`).

---

## 3. Order Dispatch & Broadcast Algorithm

The dispatch engine operates dynamically according to `order_flow_mode` ([ADR-002](context_docs/architecture-decision-records/ADR-002-dynamic-dual-order-flow-fsm.md)):

### In `RIDER_FIRST` Mode (Default — Zero Food Waste):
```
[ Customer Places Order & Payment Confirmed ]
                 │
                 ▼
[ Redis Proximity Search for online idle riders within radius (3–5 km) ]
                 │
                 ▼
[ Socket.IO sends dispatch:broadcast alert to matched couriers ]
                 │
                 ▼
[ First courier to claim claims order via atomic Redis lock ]
                 │
                 ▼
[ Vendor KDS receives order:new and sounds persistent kitchen chime ]
```

### In `VENDOR_FIRST` Mode:
- Courier broadcast is held until the kitchen marks the order `READY_FOR_PICKUP`.

---

## 4. The 3-Step Delivery Fulfillment Journey

```
[ STEP 1: PICK UP FOOD ] ──► [ STEP 2: DELIVER TO CUSTOMER ] ──► [ STEP 3: HANDOVER & CASH ]
```

### Step 1: Claim & Pick Up Food (`_buildStep1PickUp` in `ActiveTripScreen`)
- **Broadcast Alert Modal (`IncomingTripModal`)**:
  - Modal pops up upon receiving `dispatch:broadcast` with store name, distance, delivery area, and trip remuneration.
  - **Audio & Haptic Alerts**: Plays `SystemSound.alert` and vibrates `HapticFeedback.heavyImpact()` pulsing every 3 seconds until claimed or dismissed.
  - **45-Second Countdown Progress Bar**: Animated linear bar changing from green to urgent red in the final 10 seconds.
  - **Atomic Claim Action**: First courier to tap claims the order via Redis `SET NX EX` mutex lock (`POST /riders/orders/:id/claim`).
- **Store Pickup Workflow**:
  - One-tap directions handoff to Google Maps / Apple Maps.
  - Direct store phone dialer button.
  - Prominent visual package label: `LOOK FOR PACKAGE BAG - Order #...`.
  - Primary Button: `"ORDER PICKED UP ➔ START DELIVERY"` calls `POST /orders/:id/pickup` and advances stepper to Step 2.

### Step 2: Deliver to Customer (`_buildStep2Deliver`)
- One-tap navigation to customer doorstep coordinates.
- Displays customer address and custom delivery notes (flat number, gate code).
- Direct customer phone dialer button.
- Primary Button: `"ARRIVED AT DOORSTEP ➔ HANDOVER"` advances to Step 3.

### Step 3: Complete Handover & Cash Verification (`_buildStep3Handover`)
- **Prepaid Online Orders**: Green confirmation banner indicating zero cash collection.
- **Cash on Delivery (COD) Orders**: Amber banner displaying exact amount in BDT with mandatory verification checkbox: *"I have collected ৳[Amount] in cash from customer"*. Button remains disabled until checked.
- Primary Button: `"COMPLETE DELIVERY"` calls `POST /orders/:id/deliver` with `codCashCollected` and `amountCollected`.

---

## 5. Doorstep Exceptions & Safety Protocols

### 5.1. Unresponsive Customer 5-Minute SOP Modal
- Accessible from Step 2 and Step 3 via `"Customer Unreachable at Doorstep?"` button (`_showUnreachableBottomSheet`).
- **Standard Operating Procedure (SOP)**:
  1. Call customer at least twice.
  2. Ring doorbell / knock at door.
  3. Wait minimum 5 minutes before reporting failure.
- **Digital 5-Minute Countdown Timer**: 300-second timer formatting as monospace `$minutes:$seconds`. Tapping "Call Customer" starts the countdown automatically.
- **Failure Escalation**: Button `"Report Unresponsive & Release Order"` invokes `POST /orders/:id/issue`, releases the order to Dispatch HQ, and returns courier to the dashboard.

### 5.2. Real-Time Remote Cancellation Handling
- Listens to WebSocket event `order:cancelled` if customer, store, or admin cancels the delivery.
- Leaves socket order room and displays a full-screen cancellation layout with server-provided cancellation reason and `"Return to Dashboard"` button.

---

## 6. Daily Earnings & COD Cash Settlement

- **Timeframe Earnings Toggle (`RiderEarningsScreen`)**: Switch between `Today` and `This Week`.
- **Summary Metrics**: Total earnings in BDT, completed trips count, and average payout per trip.
- **COD Cash in Hand & Safety Limits**:
  - Displays collected cash balance against configured safety limit (default ৳5,000).
  - Progress meter shifts green ➔ amber (80%) ➔ red (100%).
  - If limit is reached, further COD broadcasts are restricted until cash is deposited.
- **Hub Cash Deposit Flow**: Courier records physical cash handover to central hub (`POST /riders/deposit-cash`) with reference number and deposit amount for administrative audit.
- **Completed Trips Feed**: Renders past trip receipts showing order number, merchant name, drop-off address, trip payout, and COD collected badges.
