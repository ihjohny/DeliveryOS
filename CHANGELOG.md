# Changelog

All notable changes to the **DeliveryOS** platform will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.4.1] - 2026-09-26

### Fixed
- **Customer Mobile App Layout & Responsiveness**:
  - Constrained `OrderStepperWidget` stages and clamped label text scaling to prevent horizontal blowout on 320px screens.
  - Converted `OrderHistoryScreen` and `PaymentRecoveryBanner` action rows to flexible `Wrap` layout to eliminate RenderFlex overflows under dynamic font scaling (1.5x).
  - Enforced text truncation and ellipsis on outlet cards, search results, and store detail metadata.
  - Hardened pin code input, phone input, and bottom sheets against keyboard-induced viewport clipping.
- **Rider Fleet Mobile App Layout & Responsiveness**:
  - Wrapped duty switch card, top bar metrics, active trip banner, and GPS telemetry card in flexible containers with ellipsis to prevent 320px–360px screen overflows.
  - Constrained COD cash-in-hand metrics in `CodCashLimitCard` and `EarningsSummaryCard`, eliminating a 47px overflow.
  - Wrapped 45-second dispatch broadcast modal, 3-step fulfillment action cards, and doorstep SOP sheets in `SingleChildScrollView` to prevent vertical clipping on compact devices.
- **Backend Test Script Resilience**:
  - Added operating hours upsert in `test-order-cancellation.ts` to ensure test vendor is open regardless of server execution time and timezone.

### Changed
- Standardized code-level comments across all Customer and Rider mobile app components per AGENT_RULES.md § 3.6, stripping trivial boilerplate while preserving core state machine and safety invariants.

---

## [1.4.0] - 2026-09-25

### Added
- **Admin Portal Governance & Queue**:
  - Dedicated Applicant Couriers queue with real-time pending applicant badge counter and 1-click approval/suspension actions (`adminApi.setRiderApproval`).
  - Cash safety limit adjustment modal allowing platform operators to update courier maximum cash-in-hand thresholds (`adminApi.updateRiderCashLimit`).
- **Interactive Leaflet Live Fleet Radar**:
  - Replaced external mapping dependency with free OpenStreetMap tile layers via Leaflet (`LiveFleetMap.tsx`).
  - Added courier color-coded markers (Emerald for idle, Sky for on-trip, Amber for near-limit, Slate for offline).
  - Integrated React Router SPA navigation (`/orders?orderNumber=...`) inside popup modals without page reload or dropping WebSocket connections.
- **Deep Linking & Administrative Overrides**:
  - URL query parameter deep linking (`?orderNumber=...`) with direct-link filter banner and auto-assignment modal launch.
  - Itemized order details modal featuring customer cooking instructions, delivery address, and complete dish breakdown.
  - Force-Assign modal with live courier status, cash-in-hand figures, and itemized dishes summary.
  - Force-Cancel modal with mandatory audit reason (minimum 5 characters), reversal warning, and itemized dishes to be cancelled.
- **Financial Settlements & Statement Exports**:
  - RFC 4180 CSV settlement export (`GET /admin/finance/settlement-export?format=csv`) and JSON query for ERP accounting integration.
  - Payout batch audit trail and settlement cycle trigger modal (`POST /admin/finance/settlement-cycle`).

### Changed
- Standardized Admin Portal routing into 6 consolidated views (`/dashboard`, `/dispatch`, `/orders`, `/promotions`, `/vendors`, `/settings`).
- Hardened Rider App duty switch to strictly handle HTTP 400 when attempting to go offline with an active in-flight delivery.

---

## [1.3.0] - 2026-09-25

### Added
- **Vendor Kitchen Display System (KDS)**:
  - 3-Lane Kanban progression (`New Orders`, `Preparing`, `Ready for Pickup`) with dynamic badge counters and prep time selection (`[15, 20, 25, 35, 45]` minutes).
  - Structured order rejection modal with predefined reason codes (`OUT_OF_STOCK`, `KITCHEN_OVERLOAD`, `STORE_CLOSING_SOON`, `OTHER`) and custom notes.
  - Overdue preparation countdown timer shifting from amber to flashing red upon SLA breach.
- **Synthesized In-Memory Audio Alerts (ADR-007)**:
  - Persistent Web Audio API dual-tone chime loop (D5 587 Hz + A5 880 Hz) sounding every 3 seconds upon incoming orders.
  - Guaranteed silence invariant: chime automatically stops only when zero unaccepted orders remain in Lane 1.
- **Operational Controls & Stock Management**:
  - 1-click Rush Hour Pause toggle on top navigation bar with full-width amber banner and quick-resume action.
  - Dedicated merchant catalog endpoint `GET /vendor/catalog` retaining all sold-out items with total in-stock vs out-of-stock metrics.
  - Instant 1-click stock switches for products and product variants.
- **Sales Ledgers & Statements**:
  - Date filter toggle (`Today` vs `All Time`) with dynamic gross volume, commission (15%), and net payable calculation.
  - Itemized order details modal with cooking instructions, variant breakdown, and settlement statuses.

---

## [1.2.0] - 2026-09-24

### Added
- **Rider Fleet Telemetry & Background Services**:
  - Android `FOREGROUND_SERVICE_LOCATION` and iOS background location updates with 10-meter distance filtering.
  - Dual WebSocket (`rider:location:update`) and HTTP (`PATCH /riders/duty`) location synchronization.
- **Dispatch Alerting & Claim Mutex (ADR-004)**:
  - 45-second dispatch broadcast modal with animated progress bar shifting color in final 10 seconds.
  - Dual audio chime alert and repeating heavy haptic vibration pulsing every 3 seconds.
  - Atomic Redis `SET NX EX` mutex lock preventing duplicate courier assignments.
- **3-Step Sequential Fulfillment Workflow**:
  - Visual 3-stage stepper: `Pick Up Food` ➔ `Deliver to Customer` ➔ `Handover & Cash Verification`.
  - One-tap external turn-by-turn navigation handoff to Google Maps / Apple Maps.
  - Mandatory confirmation checkbox for Cash on Delivery orders before delivery completion.
- **Doorstep Exceptions & Safety**:
  - 5-minute unresponsive customer SOP countdown modal with direct customer call launcher and failure reporting (`POST /orders/:id/issue`).
  - Remote cancellation listener and banner displaying server-provided cancellation reason.
  - Daily earnings history (`Today` vs `This Week`) and hub cash deposit settlement flow.

---

## [1.1.0] - 2026-09-24

### Added
- **Customer Mobile Experience**:
  - Debounced instant search querying restaurants and items (`GET /vendors/search?q=...`).
  - Direct `ADD +` from search results launching item customizer sheet with single-vendor conflict dialog.
  - Category filter grid (`All`, `FOOD`, `GROCERY`, `PHARMACY`) on home screen and sticky category navigation on store menus.
  - High-contrast Red Store Closed and Amber Rush Hour Paused warning banners with disabled checkout CTAs.
  - Switch-to-COD payment failure recovery card (`POST /orders/:id/switch-cod`) allowing instant transition to cash upon gateway delays.
  - 24/7 Support Hotline dialer (+8801700000000) accessible from AppBar and Profile screens.
  - 6-stage order tracking stepper with live motorcycle GPS tracking.
  - Smart re-order flow (`POST /orders/validate-reorder`) checking current menu stock and repopulating valid items.
  - Saved address book CRUD management with coordinate extraction and delivery instructions.

---

## [1.0.0] - 2026-09-24

### Added
- **Platform Foundation & Architecture**:
  - Production-grade monorepo containing NestJS backend, 2 Flutter mobile apps, and 2 React/Vite web portals.
  - Docker Compose orchestration with PostgreSQL 16 + PostGIS 3.4, Redis 7.2, and Nginx edge proxy on port 8080.
  - Modular Monorepo and Nginx Subpath Routing ([ADR-001](context_docs/architecture-decision-records/ADR-001-modular-monorepo-and-ingress-topology.md), [ADR-005](context_docs/architecture-decision-records/ADR-005-micro-frontends-and-subpath-routing.md)).
  - Dynamic Dual Order Flow State Machine (`RIDER_FIRST` vs `VENDOR_FIRST`) ([ADR-002](context_docs/architecture-decision-records/ADR-002-dynamic-dual-order-flow-fsm.md)).
  - PostGIS spatial indexing (`ST_DWithin`) and Redis geospatial clustering ([ADR-003](context_docs/architecture-decision-records/ADR-003-postgis-spatial-engine-and-redis-geohash.md)).
  - Deterministic double-entry commission accounting ledger with 2-decimal rounding ([ADR-009](context_docs/architecture-decision-records/ADR-009-deterministic-financial-accounting-ledger.md)).
  - Multi-gateway payment infrastructure (bKash, Moyasar, Stripe, Cash on Delivery) with idempotent webhooks ([ADR-011](context_docs/architecture-decision-records/ADR-011-multi-gateway-online-payment-and-webhook-idempotency.md)).
  - AI engineering governance and commit authority rules ([ADR-010](context_docs/architecture-decision-records/ADR-010-ai-driven-engineering-governance-and-no-auto-commits.md)).
