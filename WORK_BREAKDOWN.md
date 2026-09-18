# DeliveryOS — Master Work Breakdown Structure (WBS)
### End-to-End Engineering Roadmap for AI-Assisted Implementation
> **Protocol for Human Pilot & AI Agent**:
> - Implement **one stage/task at a time**.
> - Every task must be verified with automated or manual tests before marking complete.
> - Code must strictly adhere to the technical contracts in `context_docs/`.
> - If requirements or schema evolve during development, the corresponding `context_docs/` files must be updated in sync.
> - **Git Commit Rule**: Commits are never automated; the agent only commits when the user gives an explicit command.

---

## 🗺️ High-Level Engineering Roadmap

```mermaid
graph TD
    P1[Phase 1: Project Foundation & Database] ──► P2[Phase 2: Core Backend Domain Modules]
    P2 ──► P3[Phase 3: Realtime Engine & Dispatch FSM]
    P3 ──► P4[Phase 4: Unified Web Portal - React SPA]
    P3 ──► P5[Phase 5: Customer Mobile App - Flutter]
    P3 ──► P6[Phase 6: Rider Mobile App - Flutter]
    P4 & P5 & P6 ──► P7[Phase 7: End-to-End Testing & Pilot Deployment]
```

---

## 📌 Phase 1: Foundation, Monorepo Scaffolding & Database Engine

### Task 1.1: Project Scaffolding & Multi-App Monorepo Setup
- **Objective**: Establish the workspace structure for backend, web portal, and shared configurations.
- **Deliverables**:
  - Root directory organization (`/services`, `/apps`, shared configurations, and modular monorepo structure).
  - Docker Compose setup (`docker-compose.yml`) spinning up PostgreSQL 16 (with PostGIS extension) and Redis 7.
  - Environment variables blueprint (`.env.example`) with multi-region presets (`BD` / `KSA`).
- **Context Docs**:
  - [`TID-07: Deployment & Environment Setup`](./context_docs/technical-implementation-documents/07-deployment-devops-and-environment-setup.md)
  - [`TID-01: System Architecture & Tech Stack`](./context_docs/technical-implementation-documents/01-system-architecture-and-tech-stack.md)
- **Validation Checklist**:
  - [x] `docker compose up -d` boots Postgres with PostGIS and Redis without errors.
  - [x] Database connection test script confirms PostGIS extensions (`uuid-ossp`, `postgis`) are active.
  - [x] Redis responds to `PING` with `PONG`.

---

### Task 1.2: Database Migrations & Data Models
- **Objective**: Generate and execute the complete PostgreSQL/PostGIS database schema via Prisma / TypeORM.
- **Deliverables**:
  - Prisma schema / migration files reflecting all 19 relational entities: `users`, `customer_addresses`, `vendor_brands`, `vendors`, `vendor_staff`, `vendor_operating_hours`, `categories`, `products`, `product_variants`, `product_addon_groups`, `product_addons`, `banners`, `coupons`, `riders`, `system_settings`, `orders`, `order_items`, `commission_ledgers`, `rider_trip_ledgers`.
  - Spatial GIST indexes on coordinates (`customer_addresses`, `vendors`, `riders`).
- **Context Docs**:
  - [`TID-02: Database Schema & Data Models`](./context_docs/technical-implementation-documents/02-database-schema-and-data-models.md)
- **Validation Checklist**:
  - [x] All database migrations run cleanly (`npx prisma migrate dev`).
  - [x] PostGIS spatial distance query executes successfully against sample coordinates.
  - [x] Generated TypeScript client types match all domain entities.

---

### Task 1.3: Database Seeder & Default System Settings
- **Objective**: Populate the database with essential initial data for rapid development and testing.
- **Deliverables**:
  - Seed script (`seed.ts`) populating:
    - Super Admin user (`admin@deliveryos.local`).
    - 2 Sample Vendor Brands (1 Restaurant chain with 2 outlets, 1 Grocery super shop).
    - Menus with variants and toppings.
    - 2 Sample promotional banners and 1 test coupon (`WELCOME50`).
    - Core system settings (`order_flow_config`, `delivery_fee_config`, `region_config`).
- **Context Docs**:
  - [`TID-02: Section 2 (DDL & Inserts)`](./context_docs/technical-implementation-documents/02-database-schema-and-data-models.md)
  - [`BRD-03: Multi-Region Parameters`](./context_docs/business-requirements-documents/03-core-business-rules-and-workflows.md)
- **Validation Checklist**:
  - [x] `npx prisma db seed` executes idempotently without duplicate key errors.
  - [x] Querying `system_settings` returns active JSON configs.

---

## 📌 Phase 2: Core Backend Domain Modules (NestJS Enterprise REST API)

### Task 2.1: Authentication & RBAC Module (`AuthModule`)
- **Objective**: Implement international phone OTP authentication, JWT token issuance, and role-based guards.
- **Deliverables**:
  - `POST /auth/otp/request` with rate-limiting.
  - `POST /auth/otp/verify` returning user profile, JWT access token, and refresh token.
  - Role Guards (`@Roles('SUPER_ADMIN', 'VENDOR_ADMIN', 'RIDER', 'CUSTOMER')`).
  - SMS gateway interface (`ISmsService`) with a console/mock adapter for local testing and Twilio/local SMS provider adapter.
- **Context Docs**:
  - [`TID-03: Section 2 (Auth Endpoints)`](./context_docs/technical-implementation-documents/03-api-specifications-and-endpoints.md)
- **Validation Checklist**:
  - [x] Unit/E2E test: Request OTP -> Verify with mock OTP -> Receive valid JWT token.
  - [x] Protected route test: Accessing admin endpoint with customer token returns 403 Forbidden.

---

### Task 2.2: Geofencing & Customer Discovery Module (`VendorModule` & `GeoModule`)
- **Objective**: Implement geospatial store discovery, instant search, and cart coverage guard.
- **Deliverables**:
  - `GET /vendors/nearby?lat=&lng=&vertical=` (queries PostGIS `ST_DWithin`).
  - `GET /vendors/search?q=&lat=&lng=` (searches both outlets and menu items).
  - `GET /vendors/:id/catalog` (returns categorized menu, variants, toppings, and stock status).
  - `POST /cart/validate-address-coverage` (validates whether customer address coordinates fall within vendor's `delivery_radius_km`).
- **Context Docs**:
  - [`TID-03: Section 3 (Discovery & Cart)`](./context_docs/technical-implementation-documents/03-api-specifications-and-endpoints.md)
  - [`TID-02: Section 3 (Spatial Queries)`](./context_docs/technical-implementation-documents/02-database-schema-and-data-models.md)
- **Validation Checklist**:
  - [x] Nearby vendor query only returns stores whose radius encompasses test coordinates.
  - [x] Out-of-coverage coordinates submitted to `/cart/validate-address-coverage` return HTTP 422 error.

---

### Task 2.3: Promotions & Pricing Engine (`BannerModule` & `CouponModule`)
- **Objective**: Implement promotional banner retrieval and coupon code validation.
- **Deliverables**:
  - `GET /banners/active` (returns sorted active promotional banners).
  - `POST /coupons/validate` (validates min spend, active dates, calculates percentage with cap or flat discount).
  - Dynamic delivery fee calculator utility (supporting `FIXED_FLAT` and `DISTANCE_TIERED` modes).
- **Context Docs**:
  - [`BRD-03: Section 1.4 & 4 (Coupon & Delivery Fee Logic)`](./context_docs/business-requirements-documents/03-core-business-rules-and-workflows.md)
  - [`TID-03: Endpoints 3.1 & 3.5`](./context_docs/technical-implementation-documents/03-api-specifications-and-endpoints.md)
- **Validation Checklist**:
  - [x] Coupon validation correctly applies percentage discount and enforces `max_discount_amount`.
  - [x] Flat delivery fee correctly computes based on active system settings.

---

### Task 2.4: Order Management & Ledger Module (`OrderModule`)
- **Objective**: Implement atomic order checkout, single-vendor enforcement, and commission ledger calculations.
- **Deliverables**:
  - `POST /orders/checkout` wrapped in ACID transaction (`prisma.$transaction`):
    - Validates vendor status and item stock.
    - Validates delivery address within outlet coverage.
    - Applies coupon discount if provided.
    - Computes platform commission and creates `orders`, `order_items`, and `commission_ledgers`.
  - `POST /orders/validate-reorder` (verifies current menu availability before populating cart).
  - `GET /orders/:id` and `GET /orders/history` for customer tracking.
- **Context Docs**:
  - [`BRD-03: Section 1 & 5 (Financial Equations & Ledgers)`](./context_docs/business-requirements-documents/03-core-business-rules-and-workflows.md)
  - [`TID-03: Section 3.6 & 3.7`](./context_docs/technical-implementation-documents/03-api-specifications-and-endpoints.md)
- **Validation Checklist**:
  - [x] Submitting multi-vendor items in a single order payload is rejected.
  - [x] Completed order generates mathematically balanced entries in `commission_ledgers`.

---

### Task 2.5: Vendor & Rider Management APIs (`VendorStaffModule` & `RiderModule`)
- **Objective**: Support vendor multi-tier permissions, stock toggling, prep time acceptance, and rider duty states.
- **Deliverables**:
  - Vendor staff permission checks: `PARTICULAR_OUTLET` (scoped to outlet) vs `ALL_OUTLETS_MASTER` (brand-wide).
  - `PATCH /vendor/products/:id/stock` (instant stock toggle).
  - `PATCH /vendor/orders/:id/accept` (accept with custom minutes or default prep time).
  - `PATCH /vendor/orders/:id/ready` and `PATCH /vendor/orders/:id/handover`.
  - `PATCH /rider/duty` (toggle online/offline).
  - `PATCH /rider/orders/:id/deliver` (records COD cash collected and closes trip).
- **Context Docs**:
  - [`BRD-05: Merchant & Vendor Operations`](./context_docs/business-requirements-documents/05-merchant-and-vendor-operations.md)
  - [`TID-03: Sections 4 & 5`](./context_docs/technical-implementation-documents/03-api-specifications-and-endpoints.md)
- **Validation Checklist**:
  - [x] Particular outlet manager cannot access or accept orders from a different outlet.
  - [x] Acceptance without `prepTimeMinutes` correctly applies the vendor's `default_prep_time_minutes`.

---

## 📌 Phase 3: Realtime Engine, Geofence & Configurable Order Dispatch FSM

### Task 3.1: Socket.IO WebSocket Gateway (`TrackingGateway`)
- **Objective**: Establish real-time communication rooms for orders, store chimes, and live tracking.
- **Deliverables**:
  - WebSocket gateway authenticating JWT connections.
  - Room architecture: `order:{orderId}`, `vendor:{vendorId}`, `rider:{riderId}`.
  - Event triggers for incoming order chime (`order:new`) and status updates (`order:status_changed`).
- **Context Docs**:
  - [`TID-04: Realtime Events & WebSocket Protocol`](./context_docs/technical-implementation-documents/04-realtime-events-and-websocket-protocol.md)
- **Validation Checklist**:
  - [x] Test client connects to WebSocket gateway with JWT and joins vendor room.
  - [x] Triggering a test order emits `order:new` to the vendor room within 200ms.

---

### Task 3.2: Configurable Dispatch Pipeline (`OrderFlowService`)
- **Objective**: Implement configurable order dispatch flow supporting `RIDER_FIRST` (Zero Food Waste) and `VENDOR_FIRST`.
- **Deliverables**:
  - Dynamic sequence controller driven by `system_settings.order_flow_config`:
    - **`RIDER_FIRST`**: Broadcast to riders -> secure rider (`RIDER_ASSIGNED`) -> alert store console with guaranteed rider badge -> store accepts with prep timer.
    - **`VENDOR_FIRST`**: Store accepts & preps -> broadcast to riders when `READY_FOR_PICKUP`.
  - Redis Geospatial broadcast engine (`GEORADIUS` / `GEOSEARCH` within 3–5 km).
  - Redis distributed lock (`SET NX EX`) preventing race conditions during rider claims.
- **Context Docs**:
  - [`TID-05: Order State Machine & Dispatch Engine`](./context_docs/technical-implementation-documents/05-order-state-machine-and-dispatch-engine.md)
  - [`BRD-03: Section 2 (Dispatch Sequences)`](./context_docs/business-requirements-documents/03-core-business-rules-and-workflows.md)
- **Validation Checklist**:
  - [x] In `RIDER_FIRST` mode, order transitions to `RIDER_ASSIGNED` before store accepts.
  - [x] Concurrent rider claim test: Two simultaneous claims on the same order result in exactly one 200 OK and one 409 Conflict.

---

### Task 3.3: Live Rider Location Streaming & Customer Tracking
- **Objective**: Stream live GPS coordinates from the rider to customer map room via Redis cache.
- **Deliverables**:
  - `rider:location_update` incoming event caching location in Redis (`GEOADD riders:active:geo`).
  - Throttled broadcasting of rider position to `order:{orderId}` room every 3–5 seconds.
  - Fallback polling endpoint `GET /orders/:id/live-tracking`.
- **Context Docs**:
  - [`TID-04: Section 3.2 (Live Rider Coordinate Streaming)`](./context_docs/technical-implementation-documents/04-realtime-events-and-websocket-protocol.md)
- **Validation Checklist**:
  - [x] Location update sent from simulated rider updates customer tracking subscriber in real time.

---

## 📌 Phase 4: Unified Web Portal (React.js SPA - Admin & Vendor)

### Task 4.1: Web Portal Scaffolding & Responsive Layout
- **Objective**: Set up the React.js Single Page Application with TailwindCSS and role-based routing.
- **Deliverables**:
  - Vite + React + TypeScript setup in `apps/web_portal`.
  - Role-based route protection (`/admin/*` vs `/vendor/*`).
  - Shared design system: alerts, modals, tables, badges, and sound trigger utility.
  - i18n support with RTL mirroring for Arabic (`en.json`, `ar.json`, `bn.json`).
- **Context Docs**:
  - [`TID-06: Frontend & Mobile Architecture (Section 2)`](./context_docs/technical-implementation-documents/06-frontend-and-mobile-architecture.md)
- **Validation Checklist**:
  - [x] App compiles and runs with Vite dev server.
  - [x] Non-authenticated visits to `/admin` redirect to login.

---

### Task 4.2: Store Kitchen Order Console (KDS) & Audio Alert
- **Objective**: Build the tablet/desktop friendly kitchen order board for store staff.
- **Deliverables**:
  - Three-lane Kanban view (`New Orders`, `In Preparation`, `Ready for Pickup`).
  - Persistent looped audio alarm (`/sounds/order-alarm.mp3`) on new orders until accepted.
  - One-tap accept with default prep time OR custom prep time dropdown (`15m`, `25m`, `35m`).
  - "Ready for Pickup" button and "Handed to Rider" action.
  - Outlet stock toggle board (`/vendor/catalog`) for instant availability switching.
- **Context Docs**:
  - [`BRD-05: Module 1 & 2 (Kitchen Console & Stock)`](./context_docs/business-requirements-documents/05-merchant-and-vendor-operations.md)
- **Validation Checklist**:
  - [x] Incoming WebSocket event plays chime and renders order card in `New Orders`.
  - [x] Tapping accept silences chime and moves card to `In Preparation` with active countdown timer.

---

### Task 4.3: Vendor Multi-Tier Management & Brand Switching
- **Objective**: Support store managers (Particular Outlet) and brand owners (All Outlets).
- **Deliverables**:
  - Brand header outlet switcher for users with `ALL_OUTLETS_MASTER` scope.
  - Outlet operating schedule configuration and emergency rush pause (`30m`, `1h`, rest of day).
  - Daily sales ledger with platform commission breakdown.
- **Context Docs**:
  - [`BRD-05: Sections 2, 6 & 7`](./context_docs/business-requirements-documents/05-merchant-and-vendor-operations.md)
- **Validation Checklist**:
  - [x] Brand owner can switch between outlets and view aggregated sales reports.
  - [x] Branch manager view is locked to their assigned physical outlet.

---

### Task 4.4: Super Admin Master Console
- **Objective**: Build the master control center for business governance.
- **Deliverables**:
  - **Live Fleet Radar**: Google Map showing active riders, assigned trips, and idle riders.
  - **Live Order Lifecycle Monitor**: Real-time table with manual dispatch force-assign modal.
  - **Promotional Banners Manager**: Create, schedule, and reorder home banners.
  - **Coupon Engine Manager**: Create and toggle discount promo codes.
  - **Master Catalog Authority**: Global categories, item editing, and store price overrides.
  - **Settings Console**: Switch order flow mode (`RIDER_FIRST` vs `VENDOR_FIRST`) and delivery fee mode.
  - **Financial Settlements**: Export weekly vendor payout statements (CSV).
- **Context Docs**:
  - [`BRD-07: Admin Operations Guide`](./context_docs/business-requirements-documents/07-admin-operations-and-pilot-guide.md)
  - [`TID-03: Section 6 (Admin Endpoints)`](./context_docs/technical-implementation-documents/03-api-specifications-and-endpoints.md)
- **Validation Checklist**:
  - [x] Admin can manually override rider assignment on an unassigned order.
  - [x] CSV export generates accurate net payable calculations matching ledger records.

---

## 📌 Phase 5: Customer Mobile App (Flutter - iOS & Android)

### Task 5.1: App Scaffolding, Auth & Map Location Selection
- **Objective**: Initialize the Flutter project and build onboarding and location selection.
- **Deliverables**:
  - Flutter 3.x project setup with Riverpod state management and dio networking.
  - Splash screen, language picker (`English`, `Arabic RTL`, `Bengali`), and phone OTP auth with guest mode.
  - Interactive Google Map pin picker with reverse geocoding and saved addresses (`Home`, `Work`, `Other`).
- **Context Docs**:
  - [`BRD-04: Screens 1 & 2`](./context_docs/business-requirements-documents/04-customer-experience-and-journey.md)
  - [`TID-06: Section 1 (Flutter Architecture)`](./context_docs/technical-implementation-documents/06-frontend-and-mobile-architecture.md)
- **Validation Checklist**:
  - [x] App launches smoothly on simulator/device.
  - [x] Dropping pin on map sets delivery coordinates and updates available outlet listings.

---

### Task 5.2: Discovery, Banners & Outlet Menu
- **Objective**: Build home screen promotional carousel, search, and categorized outlet menus.
- **Deliverables**:
  - Auto-sliding promotional banner carousel linking to outlets or categories.
  - Universal search bar (search by outlet or dish/item name).
  - Outlet menu view with sticky category bar, dish cards, and sold-out badges.
  - Item customizer bottom sheet: single variant choice (radio) + toppings (checkboxes) + special notes.
- **Context Docs**:
  - [`BRD-04: Screens 3, 4 & 5`](./context_docs/business-requirements-documents/04-customer-experience-and-journey.md)
- **Validation Checklist**:
  - [x] Customizer dynamically recalculates total price when selecting variant and toppings.
  - [x] Sold-out items cannot be added to cart.

---

### Task 5.3: Cart Page, Geofence Guard & Checkout
- **Objective**: Build the cart page with strict address coverage enforcement and coupon discounts.
- **Deliverables**:
  - Item count adjustments (+/-) and single-outlet cart guard.
  - Delivery mode selector (`Home Delivery` vs `Takeaway`).
  - **Cart Address Geofence Guard**: Real-time validation checking if the selected address is within outlet coverage. Disables checkout and shows warning banner if out of coverage.
  - Coupon code input field with immediate discount deduction.
  - Payment method choice (`Cash on Delivery` vs `Online Payment`).
- **Context Docs**:
  - [`BRD-04: Screens 6 & 7`](./context_docs/business-requirements-documents/04-customer-experience-and-journey.md)
  - [`BRD-03: Section 1.3 (Geofence Invariant)`](./context_docs/business-requirements-documents/03-core-business-rules-and-workflows.md)
- **Validation Checklist**:
  - [x] Moving address outside outlet coverage disables "Place Order" CTA and displays warning.
  - [x] Applying coupon `WELCOME50` reduces cart total by exact discount amount.

---

### Task 5.4: Live Tracking, Direct Calling & Smart Re-Order
- **Objective**: Implement order tracking, one-tap direct calling, and history re-ordering.
- **Deliverables**:
  - Order status progress stepper driven by WebSocket updates.
  - Live interactive map with Store marker, Customer marker, and moving Rider marker.
  - One-tap direct call buttons (`tel:<phone_number>`) for rider and store.
  - Order history screen with 1-tap "Re-order" calling validation API before populating cart.
- **Context Docs**:
  - [`BRD-04: Screens 8 & 9`](./context_docs/business-requirements-documents/04-customer-experience-and-journey.md)
- **Validation Checklist**:
  - [x] Order status updates smoothly in real time as store and rider advance states.
  - [x] Re-order alerts user if an item from past order is currently sold out.

---

## 📌 Phase 6: Rider Mobile App (Flutter - iOS & Android)

### Task 6.1: Rider Onboarding & Duty Switch
- **Objective**: Minimal rider registration, approved authentication, and duty management.
- **Deliverables**:
  - Registration screen (name, phone, vehicle type) with `Pending Approval` state until admin approves.
  - Secure login with approved credentials.
  - Sunlight-readable dashboard with prominent `Online` / `Offline` duty switch.
  - Background GPS location beaconing when online.
- **Context Docs**:
  - [`BRD-06: Rider Fleet Handbook`](./context_docs/business-requirements-documents/06-rider-fleet-and-dispatch-handbook.md)
  - [`TID-03: Section 5.1`](./context_docs/technical-implementation-documents/03-api-specifications-and-endpoints.md)
- **Validation Checklist**:
  - [x] Unapproved rider account is prevented from toggling online.
  - [x] Toggling online registers rider coordinates in Redis geo-index.

---

### Task 6.2: Trip Alerts & 3-Step Fulfillment Flow
- **Objective**: Audio broadcast alert and streamlined 3-step delivery execution.
- **Deliverables**:
  - Incoming order alert modal with loud chime, showing pickup store, drop-off area, distance, and payout.
  - Single-tap **Accept Order** (claims lock).
  - Step 1: **Pick Up Food** (one-tap "Navigate to Store" via native Google/Apple Maps + "Order Picked Up" button).
  - Step 2: **Deliver Food** (one-tap "Navigate to Customer" + one-tap "Call Customer").
  - Step 3: **Complete Delivery** (with COD cash collected verification checkbox).
- **Context Docs**:
  - [`BRD-06: Section 2 (3-Step Journey)`](./context_docs/business-requirements-documents/06-rider-fleet-and-dispatch-handbook.md)
  - [`TID-03: Sections 5.2 to 5.4`](./context_docs/technical-implementation-documents/03-api-specifications-and-endpoints.md)
- **Validation Checklist**:
  - [x] Tapping "Navigate" opens device native Google Maps / Apple Maps app with pre-filled destination coordinates.
  - [x] Marking delivered closes the trip and updates order status to `DELIVERED`.

---

### Task 6.3: Rider Earnings, COD Cash & Safety Limit
- **Objective**: Real-time wallet tracking and safety limit enforcement.
- **Deliverables**:
  - Daily/weekly completed trips and delivery earnings view.
  - Accumulated COD cash-in-hand monitor.
  - Safety limit guard: Blocks accepting new COD trips if `cash_in_hand >= max_cash_limit`.
- **Context Docs**:
  - [`BRD-03: Section 5 (COD & Settlement)`](./context_docs/business-requirements-documents/03-core-business-rules-and-workflows.md)
- **Validation Checklist**:
  - [x] Rider cash balance increments by exact collected amount upon COD completion.
  - [x] Reaching cash limit alerts rider to deposit funds before taking more cash orders.

---

## 📌 Phase 7: End-to-End Integration, Stress Testing & Pilot Deployment

### Task 7.1: Full Lifecycle E2E Simulation & Testing
- **Objective**: Execute end-to-end multi-role test journeys across all 4 stakeholders.
- **Deliverables**:
  - Automated integration test suite covering:
    - Customer places order with coupon & geofence validation.
    - `RIDER_FIRST` dispatch: Rider claims broadcast -> Vendor gets audio alert -> Vendor accepts with prep time -> Food ready -> Rider picks up -> Rider delivers & collects cash.
    - Ledger validation: Customer bill = Vendor payout + Rider earnings + Platform margin.
- **Context Docs**:
  - [`BRD-00: Section 4 & 5`](./context_docs/business-requirements-documents/00-master-product-overview.md)
- **Validation Checklist**:
  - [x] Complete order journey executes with 0 state machine errors or orphaned records.
  - [x] Financial double-entry ledgers balance to the penny.

---

### Task 7.2: Production Docker & Cloud Server Provisioning
- **Objective**: Deploy backend services, database, cache, and web portal to cloud infrastructure.
- **Deliverables**:
  - Production `docker-compose.prod.yml` with Nginx reverse proxy and Let's Encrypt SSL.
  - Automated daily PostgreSQL backup cron script.
  - Web portal build deployed to Nginx / Cloudflare Pages.
  - Environment variables configured for production domains and payment/SMS gateways.
- **Context Docs**:
  - [`TID-07: Deployment, DevOps & Setup`](./context_docs/technical-implementation-documents/07-deployment-devops-and-environment-setup.md)
- **Validation Checklist**:
  - [ ] SSL rating A on production domain.
  - [ ] Health check endpoint `GET /api/v1/health` returns `200 OK` with database and Redis status healthy.

---

### Task 7.3: 10-Vendor Pilot Launch Execution
- **Objective**: Execute the 1-month pilot test run in a single 3–5 km radius zone.
- **Deliverables**:
  - Onboard 10 initial stores (7 restaurants, 3 grocery shops) with digital catalogs and default prep times.
  - Configure tablets at store counters with web portal audio chime enabled.
  - Onboard and approve 5–8 active riders.
  - Launch customer promotional campaign (`PILOT50` coupon and home banners).
  - Pilot monitoring and weekly payout export execution.
- **Context Docs**:
  - [`BRD-07: Section 3 (10-Vendor Pilot Checklist)`](./context_docs/business-requirements-documents/07-admin-operations-and-pilot-guide.md)
  - [`BRD-00: Section 6 (Pilot Plan)`](./context_docs/business-requirements-documents/00-master-product-overview.md)
- **Validation Checklist**:
  - [ ] All 10 pilot stores successfully process and fulfill live test orders.
  - [ ] Zero food waste incidents reported during pilot test run.
