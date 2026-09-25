# 04 — Customer Mobile App Journey Specification

This document defines the functional screen flow, UI states, and interactions for the **Customer Mobile App** (Flutter 3.19+, Riverpod 3.3.2).

---

## 1. Screen Flow Diagram

```
[Splash & Auth] ──► [Location & Address Book] ──► [Home & Discovery] ──► [Storefront & Menu]
                                                                                │
                                                                                ▼
[Smart Re-Order] ◄── [Live Map Tracking] ◄── [Payment & Switch-to-COD] ◄── [Guarded Cart & Checkout]
```

---

## 2. Screen Specifications

### Screen 1: Splash & Smooth Authentication
- **Language Picker**: Quick switch between `English`, `العربية` (RTL layout mirroring), or `বাংলা`.
- **Guest Browsing**: Customers explore merchants and menus freely. Authentication is requested only upon checkout or saving an address.
- **Phone OTP Verification**: Enter phone number (`+880` / `+966`) ➔ receive 6-digit SMS OTP ➔ automatic token verification and session persistence.

### Screen 2: Location Picker & Saved Address Book CRUD
- **Interactive Map Pinning**: Draggable pin picker on Google Maps with automatic reverse geocoding.
- **Address Book Management Screen (`AddressBookScreen`)**:
  - Full CRUD capabilities: create, update, delete, and set default delivery address (`/addresses`).
  - Form inputs: Label chips (`Home`, `Work`, `Other`), Street Address, Building/Floor/Apartment, and Custom Delivery Notes (gate code, landmark).
  - Geofence coordinate extraction directly from map marker or device GPS.

### Screen 3: Home Feed, Categorized Discovery & Instant Search
- **Top Promotional Banner Carousel**: Dynamic banners highlighting active platform campaigns with deep links to merchants or promo codes.
- **Vertical Category Selector**: Filter pills (`All`, `FOOD`, `GROCERY`, `PHARMACY`) dynamically filtering nearby stores.
- **Available Outlets Feed**: Live cards showing store logo, vertical, distance, ETA, delivery fee, and live operational status badges (`OPEN`, `CLOSED`, `BUSY`).
- **Smart Search with Direct Add-to-Cart (`SearchScreen`)**:
  - Debounced search querying merchant names and product titles simultaneously (`GET /vendors/search?q=...`).
  - **Direct `ADD +` Action**: Product cards in search results allow tapping `ADD +` to launch the `ItemCustomizerSheet` directly from search without opening the store page.
  - **Single-Vendor Cart Conflict Resolution**: If an item from a different store is selected, displays confirmation dialog: *"Replace Cart Items? Your cart already contains items from [Store A]. Clear cart and add from [Store B]?"* with `"Clear & Add"` action.
  - **Shortcut SnackBar**: Visual confirmation upon adding items featuring a `"VIEW CART"` action button for immediate checkout.

### Screen 4: Outlet Details & Menu Navigation
- **Collapsing Sticky Category Header**: Store banner collapses into a pinned category tab bar (`OutletDetailScreen`) allowing smooth jumping between dish sections.
- **Menu Dish Cards**: High-resolution dish photos, prices, unit descriptors, and `ADD` button. Sold-out items display a grayed-out "Out of Stock" badge and disable customization.

### Screen 5: Item Customizer Modal (Bottom Sheet)
- **Single-Choice Variants**: Mutually exclusive radio buttons (e.g. Size: *Small, Medium, Large* or Weight: *500g, 1kg*) with real-time price delta recalculation.
- **Optional Toppings & Add-ons**: Checkbox groups with selection limits.
- **Special Cooking Notes**: Textarea capturing custom preparation requests passed directly to kitchen staff.

### Screen 6: Cart Page & Operational Guards
- **Store Status Protection Banners**:
  - **Red Alert Banner**: Displayed if store is closed (`isVendorActive === false`), warning that the store is currently not taking orders.
  - **Amber Alert Banner**: Displayed if merchant toggled Rush Hour Pause (`isVendorBusy === true`), informing the customer that orders are temporarily paused.
  - **Checkout Button Guard**: Primary CTA button is disabled (`canCheckout === false`), dynamically displaying `"Store Currently Closed"` or `"Store Paused (Rush Hour)"`.
- **Address Coverage Guard**: Validates customer coordinates against store radius (`ST_DWithin`). Blocks checkout with high-contrast warning if out of bounds.
- **Promo Coupon Engine**: Input validating promo codes (`POST /coupons/validate`) with minimum order spend check and line item discount deduction.
- **Payment Method Toggle**: Choose between **Cash on Delivery (COD)** and **Online Gateway** (bKash, Moyasar, Stripe).

### Screen 7: Order Placement & Payment Gateway
- **Checkout Submission**: Submits payload to `POST /orders/checkout`.
- **Payment Webview / Gateway**: Online payments launch gateway session. Unpaid orders remain in `PLACED` state until cryptographic webhook confirms `PAID` ([ADR-011](context_docs/architecture-decision-records/ADR-011-multi-gateway-online-payment-and-webhook-idempotency.md)).

### Screen 8: Live Order Tracking, Failure Recovery & Hotline
- **6-Stage Fulfillment Stepper**: Visual timeline: `Placed` ➔ `Assigned` ➔ `Preparing` ➔ `Ready` ➔ `Delivering` ➔ `Delivered`.
- **Live Moving Map**: Store pin, customer drop-off pin, and animated courier motorcycle icon streamed via WebSockets.
- **Switch-to-COD Failure Recovery Card**:
  - Displays when an online payment gateway transaction is pending or failed.
  - Features an amber recovery card with a one-tap `"Switch to Cash (COD)"` action calling `POST /orders/:id/switch-cod`, converting the order to cash and instantly releasing it to the kitchen and dispatch queue.
- **24/7 Support Hotline Launcher**: AppBar action icon and Profile tile dialing customer support (`+8801700000000`) via native OS phone handoff (`phone_call_launcher.dart`).
- **Direct Voice Call Shortcuts**: One-tap phone buttons to call the assigned courier or merchant directly.
- **Self-Service Order Cancellation**: Allowed during `PLACED` and `RIDER_ASSIGNED` stages via `POST /orders/:id/cancel` with automatic ledger reversal.

### Screen 9: Smart Re-Order from Order History
- History screen itemizing past completed receipts.
- Tapping **"Re-order"** invokes backend validation (`POST /orders/validate-reorder`):
  - Validates current store opening hours and rush pause status.
  - Identifies out-of-stock items, displays an alert dialog itemizing omitted dishes, and repopulates the cart with remaining items at updated prices.
