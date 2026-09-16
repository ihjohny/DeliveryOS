# 07 — Super Admin Operations & 10-Vendor Pilot Guide

This document defines the controls of the **Super Admin Master Console** (`/admin`) and provides the execution checklist for the **1-Month 10-Vendor Pilot Test Run**.

---

## 1. Master Console Modules (`/admin`)

```
/admin
├── /fleet-radar      # Interactive Live Map of Active Riders & Orders
├── /orders           # Live Order Lifecycle Monitor & Manual Dispatch Override
├── /banners          # Home Screen Promotional / Offer Banner Management
├── /coupons          # Promo Code Engine & Discount Rules
├── /vendors          # Vendor Applications, Direct Creation & Permission Scopes
├── /master-catalog   # Central Categories, Global SKUs & Store Price Overrides
├── /riders           # Rider Registrations, Account Approvals & Cash Limits
├── /settings         # Delivery Fee Mode, Currency, Tax Rates & Flow Pipelines
└── /finance          # Vendor Batch Settlements & Rider Cash Audits
```

---

## 2. Key Administrative Controls & Workflows

### 2.1 Promotional Banner Management (`/admin/banners`)
- **Banner Creation & Scheduling**: Upload desktop/mobile banner creative, define display title, and assign sort sequence order.
- **Deep-Linking**: Direct clicks to:
  - Specific Vendor Outlet (`vendor_id`).
  - Catalog Category (`category_id`).
  - External promotional URL.
- **Active State Toggle**: Instantly activate or pause promotional banners without app redeployment.

### 2.2 Coupon Code Management (`/admin/coupons`)
- **Promo Code Definition**: Specify alphanumeric code (e.g. `WELCOME50`, `EATFREE`).
- **Discount Computation**:
  - `PERCENTAGE`: Discount rate (e.g. 20%) with strict `max_discount_amount` cap.
  - `FLAT`: Fixed deduction (e.g. 50 ৳ / 15 ﷼).
- **Enforcement Rules**: Minimum gross subtotal spend, date validity range (`valid_from` to `valid_to`), and total system-wide usage limit.

### 2.3 Rider Fleet Administration (`/admin/riders`)
- **Registration Approval**: Review incoming rider applications, verify vehicle information and contact phone, and activate accounts (`PENDING_APPROVAL` → `ACTIVE`).
- **Live Fleet Radar**: View all active riders on an interactive Google Map (color-coded: Green = Idle/Online, Orange = En Route to Store, Blue = En Route to Customer).
- **Cash Safety Controls**: Monitor rider `cash_in_hand` and adjust maximum cash collection thresholds before blocking further COD assignments.

### 2.4 Restaurant & Outlet Management (`/admin/vendors`)
- **Application Approvals & Direct Creation**: Approve pending merchant registration requests or directly create new outlets and staff logins.
- **Permission Assignment**: Grant either:
  - **Particular Outlet Permission**: Binds a staff user strictly to a single physical outlet.
  - **All Outlets Permission (Master Vendor)**: Empowers franchise owners to manage all branches under their brand.
- **Store Configuration**: Commission rate (e.g. 15%), delivery radius (km), operational hours, and default prep time.

### 2.5 Master Catalog Authority (`/admin/master-catalog`)
- **Central Category Management**: Create and standardize global cuisine and product categories across the platform.
- **Central Product Control**: 100% authority to create, edit, price-override, or disable any store's menu items centrally to guarantee catalog data quality.

### 2.6 Order Lifecycle Monitor & Manual Dispatch Override (`/admin/orders`)
- **Real-Time Order Table**: Inspect all active orders across every stage: `PLACED`, `RIDER_ASSIGNED`, `ACCEPTED`, `PREPARING`, `READY_FOR_PICKUP`, `DISPATCHED`, `DELIVERED`.
- **Manual Assignment Override**: If an order remains unassigned or delayed, platform operators can one-click assign the delivery to any active online rider.

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
- [ ] Export 30-day financial, commission, and rider remuneration statements.
- [ ] Review customer feedback, vendor satisfaction, and rider delivery metrics.
- [ ] Plan Phase 2 expansion to 50+ stores and additional delivery zones.
