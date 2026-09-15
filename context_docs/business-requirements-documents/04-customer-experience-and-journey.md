# 04 — Customer Mobile App Journey Specification

This document defines the functional screen flow, UI states, and interactions for the **Customer Mobile App** (Flutter).

---

## 1. Screen Flow Diagram

```
[Onboarding / Language] ──► [Home / Discovery] ──► [Store Details & Menu] ──► [Item Customizer]
                                                           │                        │
                                                           ▼                        ▼
[Order History & Re-order] ◄── [Live Map Tracking] ◄── [Checkout & Payment] ◄── [Cart Review]
```

---

## 2. Screen Specifications

### Screen 1: Splash & Authentication
- **Language Picker**: Selection of `English`, `العربية` (RTL), or `বাংলা`. Auto-persisted in local storage.
- **Guest Browsing**: Users can browse stores without login. Login requested only at checkout or when saving an address.
- **Phone OTP**: Input mobile number → SMS OTP (4–6 digits) → Token issuance.

### Screen 2: Delivery Address Selection
- Interactive Google Map with pin drop.
- Reverse geocoded address string with manual overrides: `Address Line`, `Building/Floor`, `Delivery Note`.
- Quick label chips: `Home`, `Work`, `Other`.

### Screen 3: Home & Store Discovery
- **Vertical Switcher**: Horizontal tabs: `Restaurants`, `Groceries`, `Super Shops`.
- **Geofenced Store Cards**: Fetches stores within delivery radius (`GET /vendors/nearby?lat=&lng=`).
- **Store Card Elements**: Thumbnail, Name, Rating, Estimated Delivery Time, Delivery Fee, Open/Closed badge.
- **Search & Filters**: Search by dish/product name, category chips, and cuisine tags.

### Screen 4: Store Catalog & Item Details
- Sticky category navigation bar.
- Product cards showing title, thumbnail, price, unit type (e.g. `piece`, `kg`), and `ADD` button.
- Items marked `is_in_stock == FALSE` displayed with disabled grayed-out state and "Sold Out" badge.

### Screen 5: Item Customization Modal
- Dynamic option groups:
  - **Radio selection** for Variants (e.g., Small, Medium, Large).
  - **Checkbox selection** for Add-on Groups (e.g., Extra Cheese, Extra Sauce).
  - **Numeric counter** for quantities / weights.
  - Special preparation instructions text input.

### Screen 6: Cart & Single-Vendor Guard
- Enforces single-vendor rule. If user adds item from Store B while Store A items are in cart:
  - Shows modal: *"Replace cart items? Your cart contains items from [Store A]."*
- Displays items, subtotal, delivery fee, and `PROCEED TO CHECKOUT` CTA.

### Screen 7: Checkout
- **Delivery Mode**: Toggle `Home Delivery` or `Self-Pickup`.
- **Delivery Fee**: Displays active calculated fee (Flat or Distance).
- **Payment Method**: Select `Cash on Delivery (COD)` or `Online Payment Gateway`.
- **Place Order CTA**: Submits order payload (`POST /orders/checkout`).

### Screen 8: Live Order Tracking & Direct Call
- **Progress Stepper**: `Placed` → `Confirmed by Store` → `Preparing` → `Rider Picked Up` → `Delivered`.
- **Live Google Map**: Shows Store pin, Customer pin, and moving Rider marker streamed via WebSockets.
- **Direct Call Shortcut**: Tap-to-call button triggering device native dialer (`tel:<phone_number>`) to contact rider or store. *No in-app VoIP or chat.*

### Screen 9: Smart Re-Order (Past Orders)
- "Past Orders" screen with list of previous completed orders.
- Tapping **"Re-order"** calls `POST /orders/validate-reorder`:
  - If store is closed or items are out of stock, displays specific alert detailing unavailable items.
  - If valid, populates cart with current prices and opens cart review screen.
