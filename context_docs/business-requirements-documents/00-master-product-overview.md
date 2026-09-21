# DeliveryOS — Master Product Overview & Feature Guide
### The Complete Plain-English Guide for Business Owners, Clients & Non-Technical Partners

---

## 1. What is DeliveryOS?

**DeliveryOS** is an all-in-one on-demand multi-vendor delivery platform. It connects local businesses—such as restaurants, cafes, grocery shops, and pharmacies—with nearby customers through a dedicated delivery fleet.

The platform provides everything needed to launch and scale a delivery business:
1. 📱 **Customer Mobile App** (iPhone & Android)
2. 🛵 **Delivery Rider Mobile App** (iPhone & Android)
3. 🏪 **Store & Kitchen Web Portal** (Tablet, Laptop & Mobile friendly)
4. 👑 **Super Admin Master Console** (Complete business governance)

---

## 2. Platform Highlights & Key Business Advantages

- 🛡️ **Zero Food Waste Order Flow**: A delivery rider is secured **before** the kitchen starts cooking. The restaurant never wastes food on an unassigned order.
- 🎯 **Smart Geofenced Address Guard**: Customers can freely adjust their delivery address on the map, but the system intelligently prevents selecting any address outside the chosen outlet's delivery coverage radius.
- 🏢 **2-Level Vendor Hierarchy**: Support both single-branch shop managers (*Particular Outlet Permission*) and multi-branch chain owners (*Master Vendor Permission for All Outlets*).
- 🏷️ **Promotions & Coupon Engine**: Engage customers with dynamic home-screen promotional banners and flexible discount coupons (percentage or flat discounts).
- 💵 **Flexible Delivery Fee**: Toggle between a simple **Fixed Flat Delivery Fee** (e.g. 50 ৳ or 12 ﷼) or a distance-based fee with one click in your admin panel.
- 👑 **100% Master Control**: As the platform owner, you have full authority to create, edit, price-override, or disable any store's menu items centrally.
- 🔄 **Smart Re-Order**: Customers can repeat past orders in one tap. The system automatically verifies that the store is open and items are in stock before checkout.
- 📞 **Instant Phone Connection**: Customers, riders, and stores can call each other directly with one tap using their phone's native dialer—avoiding text chat confusion.
- 🛒 **Multi-Vertical Flexibility**: Sell restaurant meals (with cheese/sauce add-ons), groceries by weight (kg/grams), or pharmacy items in the same platform.
- 🌍 **Dual-Region Ready**: Built-in support for **Saudi Arabia** (SAR currency, Arabic Right-to-Left layout, +966 phone numbers) and **South Asia** (BDT currency, Bengali/English, +880 phone numbers).

---

## 3. The 4 Platform Stakeholders & Applications

DeliveryOS is designed to deliver a smooth, balanced experience across all four essential stakeholders:

```
                  ┌─────────────────────────────────────────┐
                  │      👑 Super Admin Master Console      │
                  │  (Banners, Coupons, Fleet, Catalog, Ops)│
                  └───────┬─────────────────────────┬───────┘
                          │                         │
            ┌─────────────┴───────────┐ ┌───────────┴─────────────┐
            │ 🏪 Store Kitchen Portal │ │ 🛵 Delivery Rider App   │
            │ (Audio Alerts, 2-Tier   │ │ (Duty Switch, Broadcast,│
            │  Permissions, Prep Time)│ │  Turn-by-Turn, Handover)│
            └─────────────┬───────────┘ └───────────┬─────────────┘
                          │                         │
                          └───────────┬─────────────┘
                                      │
                        ┌─────────────▼─────────────┐
                        │   📱 Customer Mobile App  │
                        │ (Map Pick, Banners, Guard,│
                        │  Coupons, Tracking, Re-Do)│
                        └───────────────────────────┘
```

---

### 3.1 📱 Customer Mobile App (iOS & Android)

Designed for fast browsing, effortless ordering, and live visibility:

| Feature Area | What It Does for the Customer |
| :--- | :--- |
| **Smooth Authentication** | Fast login with mobile number via SMS OTP, plus guest browsing so customers can explore stores before signing up. |
| **Hassle-Free Map Location** | Drop a pin on an interactive map to automatically filter and display only the outlets actively serving that exact location. |
| **Promotional Offer Banners** | Eye-catching top carousel on the home screen highlighting deals, seasonal campaigns, or featured outlets. |
| **Vendor & Item Discovery** | Browse by store or use the instant search bar to find specific dishes, groceries, or stores by name. |
| **Categorized Outlet Menus** | View outlet menus neatly arranged into sticky categories (e.g. Burgers, Drinks, Desserts, Fresh Produce). |
| **Item Customization** | Pick a single variant (e.g. Regular, Large, 1 kg) and add optional toppings or extras (e.g. extra cheese, sauce). |
| **Item Count & Cart Review** | Adjust item quantities (+/-), review order subtotal, and maintain single-store cart simplicity. |
| **Smart Address Coverage Guard** | Add or edit delivery address directly in the cart, but the system **intelligently blocks any address outside the store's delivery coverage radius**, preventing failed deliveries. |
| **Delivery & Payment Choice** | Choose between **Home Delivery** or **Takeaway (Self-Pickup)**, and pay via **Cash on Delivery (COD)** or **Online Payment**. |
| **Coupon Code Discount** | Enter a promo coupon code at checkout to receive an instant flat or percentage discount on eligible orders. |
| **Live Map Order Tracking** | Watch the order progress through every step with live rider movement tracked on an interactive map. |
| **1-Tap Direct Call** | Prominent one-tap buttons connect directly to the rider or store via phone dialer for quick voice updates. |
| **Smart 1-Tap Re-Order** | Repeat any past order from history; the app automatically checks item availability and store hours before checkout. |

---

### 3.2 🛵 Delivery Rider Mobile App (iOS & Android)

Designed to be simple, sunlight-readable, and usable with gloves on:

| Feature Area | What It Does for the Rider |
| :--- | :--- |
| **Admin-Approved Registration** | Register with phone number, name, and vehicle type; account activates immediately once Super Admin approves. |
| **Secure Login** | Quick login using approved credentials to access assigned trips and daily earnings. |
| **Work Mode Toggle** | Prominent duty switch to go **Online** (ready to receive trip requests) or **Offline** (taking a break). |
| **Detailed Order Broadcasts** | Loud incoming chime with a clear order preview: pickup outlet, customer delivery area, distance, and rider payout. |
| **Instant Order Acceptance** | Single tap to claim the trip and secure the delivery assignment. |
| **Turn-by-Turn Voice Navigation**| One tap launches device-native Google Maps or Apple Maps for voice-guided navigation to store and customer. |
| **Step-by-Step Fulfillment** | Three simple milestones: **Pick Up Food** at counter ➔ **Navigate to Customer** ➔ **Mark Delivered**. |
| **Doorstep Cash Collection** | For COD orders, collect cash at the door and verify collection with a simple checkbox. |
| **Direct Customer Dial** | One-tap phone button to contact the customer directly upon arriving at the building gate. |
| **Daily Earnings & Cash Limit** | Real-time wallet tracking total deliveries, earnings, and cash collected with an automatic safety limit. |

---

### 3.3 🏪 Store & Kitchen Web Portal (Dedicated React App — Port 3001)

Runs as an independent React application (`apps/vendor_portal`) with a warm Amber & Flame Orange culinary theme optimized for kitchen tablets, cashier PCs, and counter displays:

| Feature Area | What It Does for Store Owners & Kitchen Staff |
| :--- | :--- |
| **Flexible Onboarding** | Apply online via a registration form, OR have the platform Super Admin create and configure the account directly. |
| **Admin Approval Workflow** | All self-registered vendor applications are reviewed and approved by the Super Admin before going live. |
| **2-Level Permission Hierarchy** | **1. Particular Outlet Permission**: Branch manager access to run a single physical location.<br/>**2. All Outlets Permission (Master Vendor)**: Multi-outlet chain owner access to oversee all brand branches. |
| **Menu & Catalog Customizer** | Create and edit categories, items, variants (sizes, weights), and toppings/add-on groups with photos and prices. |
| **Instant Stock Toggle** | 2-tap switch to mark any item or variant **In Stock** or **Out of Stock** immediately. |
| **Continuous Audio Chime** | Plays a persistent ringing chime when a new order arrives until kitchen staff acknowledges it. |
| **Full Order Details & Rider Badge**| Clear display of items, toppings, customer notes, and badge confirming the assigned delivery rider. |
| **Flexible Prep Time Selection** | Accept with a custom prep timer (`15m`, `25m`, `40m`) OR tap one-click accept with the store's **Default Prep Time**. |
| **Food Ready Notification** | Tap **"Ready for Pickup"** once packaged, alerting the waiting rider to collect the order at the counter. |
| **Rider Handover Confirmation** | Mark order handed over to the rider as they depart the store. |
| **Operating Hours & Rush Pause** | Configure weekly opening/closing times; tap **"Pause Orders"** during unexpected kitchen rushes. |
| **Financial Ledger & Reports** | Transparent view of daily sales, platform commissions deducted, and net payout balances. |

---

### 3.4 👑 Super Admin Master Console (Dedicated React App — Port 3000)

The central command headquarters running as an independent React application (`apps/admin_portal`) with an authoritative Enterprise Indigo & Slate theme:

| Feature Area | What It Does for the Platform Owner |
| :--- | :--- |
| **Complete Business Governance** | 100% centralized authority to oversee and control all stores, riders, customers, and transactions. |
| **Promotional Banner Management** | Create, schedule, and reorder home-screen banners linking to specific outlets, categories, or campaigns. |
| **Coupon Code Management** | Create promo codes with percentage or flat discounts, minimum spend limits, expiry dates, and usage caps. |
| **Rider Fleet Administration** | Review and approve rider registrations, monitor active online fleet on a live radar map, and enforce cash limits. |
| **Restaurant & Outlet Management** | Approve vendor applications, create new stores directly, and assign Particular Outlet or Master Vendor permissions. |
| **Master Catalog Authority** | Centrally create global categories, edit any store's menu, apply price overrides, or disable items across the platform. |
| **Live Order Monitor & Dispatch Override**| Real-time dashboard of all active orders with one-click ability to manually reassign orders to any online rider. |
| **Delivery Fee Control** | Toggle between **Fixed Flat Delivery Fee** (e.g. 50 BDT / 12 SAR) and dynamic road-distance pricing. |
| **Automated Financial Settlements** | Generate weekly payout statements for stores and riders ready for bank transfers (CSV/Excel export). |
| **Multi-Region & Localization** | Instant toggle between Saudi Arabia (SAR, Arabic RTL, +966) and South Asia (BDT, Bengali, +880). |

---

## 4. How the "Zero Food Waste" Order Workflow Works

```
1. CUSTOMER PLACES ORDER
   ├── App verifies outlet is open and selected items are in stock.
   └── Smart Address Guard ensures delivery pin is strictly within outlet coverage.

2. SYSTEM SECURES A RIDER FIRST
   ├── Broadcasts trip alert to available online riders within 3–5 km.
   └── Rider accepts trip ──► Delivery is now GUARANTEED.

3. KITCHEN CHIME RINGS AT THE STORE
   ├── Store manager hears continuous audio alert showing order items and assigned rider.
   └── Store manager approves order using custom prep time OR default prep time.

4. RIDER TRAVELS TO STORE WHILE FOOD IS COOKING
   └── Kitchen prepares food; food finishes cooking right as the rider arrives.

5. FOOD READY & HANDOVER
   ├── Store taps "Ready for Pickup" when packaged.
   └── Rider arrives at counter, collects parcel, and confirms pickup.

6. RIDER DELIVERS TO CUSTOMER
   ├── Rider navigates to customer doorstep using native turn-by-turn navigation.
   └── If Cash on Delivery, rider collects payment, checks "Cash Collected", and completes trip.
```

---

## 5. How Money & Accounting Flows

Dispute-free financial balance managed automatically:

```
Customer Pays Total:          550.00 BDT
  • Food Subtotal:            500.00 BDT
  • Delivery Fee:              50.00 BDT
  • Coupon Discount:         -  0.00 BDT (Applied if coupon is valid)
─────────────────────────────────────────────
Platform Deductions:
  • Vendor Commission (15%): - 75.00 BDT
─────────────────────────────────────────────
Net Vendor Payout:            425.00 BDT (Transferred weekly via Bank)
Rider Trip Earnings:           40.00 BDT (Credited to rider wallet)
Platform Net Profit:           85.00 BDT (75 commission + 10 delivery fee margin)
```

---

## 6. Recommended 1-Month Pilot Plan (10 Partner Stores)

- **Target Area**: A single 3 to 5 km radius neighborhood with high density.
- **Partner Mix**: 7 popular food restaurants + 3 neighbourhood grocery/super shops.
- **Rider Team**: 5 to 8 active riders for prompt, reliable 30-minute delivery.
- **Goal**: Perfect operations, zero food waste, and complete merchant satisfaction before onboarding the next 50+ stores.
