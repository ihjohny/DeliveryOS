# 07 — Super Admin Operations & 10-Vendor Pilot Guide

This document defines the controls of the **Super Admin Master Console** (`/admin`) and provides the execution checklist for the **1-Month 10-Vendor Pilot Test Run**.

---

## 1. Master Console Modules (`/admin`)

```
/admin
├── /fleet-radar      # Interactive Live Map of Active Riders & Orders
├── /vendors          # Master Vendor Directory, Creation & Onboarding
├── /master-catalog   # Global Categories, Price Overrides, Dish Management
├── /dispatch         # Unassigned Orders Queue & Manual Override
├── /settings         # Delivery Fee Mode, Currency, Tax Rates
└── /finance          # Vendor Settlements & Rider Cash Audits
```

### Key Administrative Controls:
- **Master Vendor & Catalog Authority**: Super Admin has unrestricted create, edit, price-override, and delete rights across all vendors, categories, and products.
- **Manual Dispatch Override**: Real-time list of unassigned orders. Dispatcher can one-click assign any order to any active online rider.
- **Delivery Fee Switch**: Toggle between `FIXED_FLAT` (flat rate) and `DISTANCE_TIERED` (base + per km rate).
- **Financial Export**: Export weekly vendor payout statements (Gross Sales, Commission, Net Balance) to CSV for offline bank transfers.

---

## 2. 10-Vendor Pilot Launch Checklist (1-Month Run)

### Week 0: Pre-Launch Setup
- [ ] **Zone Definition**: Set a 3–5 km radius pilot geofence.
- [ ] **Store Onboarding**: Onboard 10 initial stores (7 restaurants/cafes, 3 grocery/super shops).
- [ ] **Catalog Digitalization**: Populate complete menus, prices, variants, and product images.
- [ ] **Store Hardware**: Ensure each store has a tablet or smartphone with active internet at the counter.
- [ ] **Rider Recruitment**: Onboard and pre-approve 5–8 active riders with motorcycles or bicycles.
- [ ] **System Settings**: Set delivery fee mode to `FIXED_FLAT` (e.g., 50 BDT / 12 SAR) for simple pilot pricing.

### Week 1: Soft Launch & Controlled Testing
- [ ] Operate during limited hours (e.g. 12:00 PM – 9:00 PM).
- [ ] Execute test orders across all 10 vendors to verify tablet audio chimes, native map routing, and COD collection.

### Week 2: Public Launch
- [ ] Open ordering to public within pilot zone.
- [ ] Deploy marketing table tents at the 10 pilot partner locations.
- [ ] Monitor order acceptance times and rider dispatch response.

### Week 3: Performance Tuning
- [ ] Audit delivery times (target: under 35 minutes).
- [ ] Optimize vendor prep times and address any recurring stock-out issues.

### Week 4: Pilot Audit & Expansion Sign-Off
- [ ] Export 30-day financial and commission statements.
- [ ] Review customer feedback and rider delivery metrics.
- [ ] Plan Phase 2 expansion to 50+ stores and additional delivery zones.
