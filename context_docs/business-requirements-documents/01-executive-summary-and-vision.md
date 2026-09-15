# 01 — Executive Summary & Platform Scope

## 1. System Overview
**DeliveryOS** is an on-demand hyperlocal delivery platform supporting multiple merchant verticals (Restaurants, Groceries, Super Shops, Retail).

### Core Components:
- **Customer Mobile App**: Cross-platform Flutter app (iOS & Android) for store discovery, cart customization, and live order tracking.
- **Rider Mobile App**: Cross-platform Flutter app (iOS & Android) with a streamlined 3-step fulfillment workflow.
- **Unified Web Portal**: React.js SPA (Vite + TailwindCSS) for Super Admin operations (`/admin`) and Merchant store management (`/vendor`).
- **Backend API & Real-time Engine**: NestJS REST API, PostgreSQL 16 + PostGIS spatial database, Redis 7 cache/pub-sub, and Socket.IO.

---

## 2. Platform Scope & Multi-Vertical Strategy

| Vertical | Catalog Requirements | Operational Characteristics |
| :--- | :--- | :--- |
| **Restaurants & Food** | Variants (sizes), add-on groups, special cooking notes | High urgency, 25–40 min delivery, hot meals |
| **Groceries & Super Shops** | Weight options (kg, grams), unit counts, packaged goods | Bulk items, packed bags, scheduled or express delivery |
| **Pharmacies & Essentials** | Over-the-counter wellness, personal care products | Standard unit packaging, rapid fulfillment |

---

## 3. Rollout Milestones

```
[ Phase 1: 10-Vendor Pilot ] ──► [ Phase 2: Hyperlocal Scale ] ──► [ Phase 3: Enterprise OS ]
  • 10 Handpicked Stores           • 50–100+ Merchants               • Multi-branch franchises
  • 3–5 km Delivery Radius         • Multi-zone operation            • Algorithmic batch dispatch
  • Food & Grocery Focus           • Loyalty & wallet engine         • Dedicated vendor mobile app
  • 1-Month Operational Test
```

### Pilot Success Criteria:
- **Order Cycle**: Under 35 minutes end-to-end (Placement → Prep → Delivery).
- **Vendor Acceptance**: Under 2 minutes via kitchen audio alert console.
- **Rider Broadcast Acceptance**: Under 90 seconds.
- **Completion Rate**: > 95% of placed orders fulfilled without cancellation.
