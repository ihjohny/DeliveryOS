# 04 — Customer Mobile App Journey Specification

This document defines the functional screen flow, UI states, and interactions for the **Customer Mobile App** (Flutter).

---

## 1. Screen Flow Diagram

```
[Splash & Smooth Auth] ──► [Hassle-Free Map Location] ──► [Home & Banners] ──► [Outlet Menu & Categories]
                                                                                      │
                                                                                      ▼
[Smart Re-Order (History)] ◄── [Live Map Tracking] ◄── [Order Placement] ◄── [Cart Page & Address Guard]
                                                                         (Item Count, Coupon, Coverage)
```

---

## 2. Screen Specifications

### Screen 1: Splash & Smooth Authentication
- **Language Picker**: Selection of `English`, `العربية` (RTL), or `বাংলা`. Auto-persisted in local storage.
- **Guest Browsing**: Customers can immediately explore outlets and menus without logging in. Authentication is required only at checkout or when saving an address.
- **Smooth Phone OTP**: Input phone number with auto-selected country code (+966 / +880) → receive 4–6 digit SMS OTP → automatic token verification.

### Screen 2: Hassle-Free Location Choice from Map
- Interactive Google Map with draggable pin and "Use Current Location" GPS shortcut.
- Setting location dynamically updates the platform context: queries the backend for active outlets whose delivery coverage encompasses that coordinate (`GET /vendors/nearby?lat=&lng=`).
- Quick saved address chips: `Home`, `Work`, `Other` with custom notes (flat/gate/landmark).

### Screen 3: Home, Promotional Banners & Discovery
- **Top Promotional / Offer Banner Carousel**: Auto-sliding visual banners configured by Super Admin highlighting active discounts, festive campaigns, or spotlight outlets. Tapping navigates directly to the target outlet or category.
- **Outlet & Item Search Bar**: Universal instant search with debounced querying:
  - Search by outlet/restaurant name.
  - Search by dish or grocery item name across all open outlets.
- **Vertical Switcher**: Horizontal category filter pills (`Restaurants`, `Groceries`, `Super Shops`).
- **Available Outlets Feed**: Cards display outlet logo, name, distance, estimated prep/delivery time, flat/tiered delivery fee, and open/closed status.

### Screen 4: Outlet Details & Categorized Menu
- Outlet header with cover photo, name, contact phone, delivery radius, and current operational status.
- **Sticky Category Navigation**: Horizontal scrollable tabs (e.g. *Burgers, Appetizers, Drinks, Desserts* or *Dairy, Bakery, Fresh Produce*).
- **Product Cards**: Display title, image, price, unit type (`piece`, `kg`), and prominent `ADD` button. Sold-out items display a grayed-out badge and disabled tap.

### Screen 5: Single-Outlet Item Customizer (Modal / Bottom Sheet)
- **Single Variant Choice**: Radio selection for the core size or weight option (e.g. *Small, Medium, Large* or *500g, 1kg*).
- **Toppings & Add-ons**: Checkbox groups for optional extras (e.g. *Extra Cheese +50 ৳, Special Sauce +20 ৳*).
- **Special Cooking Notes**: Optional free-text instructions for the kitchen.
- **Quantity Selector**: Default 1 with `+` / `-` increment buttons.
- **Add to Cart CTA**: Recalculates total price in real time and adds to cart.

### Screen 6: Cart Page & Smart Address Coverage Guard
- **Single-Outlet Invariant Guard**: If adding items from Outlet B while Outlet A is in cart, triggers confirmation modal: *"Replace cart items? Your cart already contains items from [Outlet A]."*
- **Item Count Adjustment**: Increment/decrement quantities or swipe to remove items with immediate subtotal updates.
- **Delivery Method Toggle**: Select between `Home Delivery` or `Self-Pickup (Takeaway)`.
- **Address Management & Smart Coverage Guard**:
  - Displays selected delivery address.
  - Customer can tap **Edit Address** or add a new address directly within the cart.
  - **Coverage Boundary Enforcement**: The system strictly validates the address against the active outlet's coverage radius (`ST_DWithin`).
  - **Smart Feedback**: If the customer selects or moves their pin outside the outlet's coverage, the cart displays a clear warning: *"⚠️ This address is outside [Outlet Name]'s delivery area."* The checkout CTA is disabled until an address within coverage is selected.
- **Coupon Code Input**:
  - Text input for promotional coupon codes.
  - Tapping **Apply** validates the code against order subtotal and displays the exact discount deduction line item.
- **Payment Method Selection**: Choose between **Cash on Delivery (COD)** and **Online Card / Mobile Wallet**.
- **Order Summary**: Breakdown showing Gross Subtotal, Coupon Discount, Delivery Fee, Tax/VAT, and Total Payable.

### Screen 7: Order Placement
- Prominent **"Place Order"** button.
- Submits checkout payload (`POST /orders/checkout`).
- If online payment, launches seamless payment webview/SDK; if COD, proceeds directly to order tracking.

### Screen 8: Live Order Tracking & Direct Call
- **Real-Time Stepper**: `Placed` → `Rider Assigned` → `Store Preparing` → `Ready for Pickup` → `Rider Delivering` → `Delivered`.
- **Live Interactive Map**: Displays Store pin, Customer pin, and live moving Rider icon streamed via WebSockets.
- **Direct Native Call**: Dedicated **Call Rider** and **Call Store** buttons trigger the phone's native dialer (`tel:<phone_number>`) for instant voice communication without text chat friction.

### Screen 9: Smart Re-Order from Order History
- History page showing past delivered orders with item summaries, date, and total paid.
- Tapping **"Re-order"** invokes backend validation (`POST /orders/validate-reorder`):
  - Checks if the outlet is currently open and within operating hours.
  - Checks if the customer's delivery address remains within coverage.
  - Verifies that all items, variants, and toppings are currently in stock.
  - If any item is unavailable, displays an explicit alert itemizing what is out of stock.
  - If valid, populates the cart with current prices and opens the cart page for review.
