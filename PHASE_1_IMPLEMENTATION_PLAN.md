# Phase 1 Implementation Plan — Trust & Correctness

> **Parent**: [`PROJECT_REVIEW_AND_PLAN.md`](./PROJECT_REVIEW_AND_PLAN.md) §5 Phase 1
> **Goal**: Eliminate silent fakes, financial inconsistencies, informal state transitions, and scaling hazards so the platform behaves the same in demo and in production.
> **Duration estimate**: ~1.5 weeks solo. **Dependency**: Phase 0 security items (especially rider self-assignment fix A3, which touches the same files as Task 1.1/1.2) should land first or in the same working session to avoid merge conflicts.
> **Precondition**: Commit or stash the 4 currently modified test scripts (`git status`) before starting.

---

## Task Summary & Order

| # | Task | Size | Files touched (primary) |
| :--- | :--- | :--- | :--- |
| 1.1 | Central Order FSM guard | M | `src/modules/orders/order-state.machine.ts` (new), `order-flow`, `vendor-staff`, `riders` services |
| 1.2 | Single source of truth for money & ETA | M | `order-flow.service.ts`, `rider.service.ts`, `vendor.service.ts`, `tracking.gateway.ts`, `order.service.ts`, `delivery-fee.service.ts`, `seed.ts` |
| 1.3 | Deterministic order numbers | S | `order.service.ts`, `schema.prisma` |
| 1.4 | DB indexes + PostGIS GiST (expression) | M | `prisma/migrations/*` (new), `vendor.service.ts`, `order.service.ts` |
| 1.5 | Flutter de-mocking + rider cash-deposit backend | L | 4 Flutter providers, new backend `CashDeposit` model + endpoint |
| 1.6 | Real GPS (rider beacon + customer locate) | M | `duty_provider.dart`, `location_provider.dart`, `map_location_picker_screen.dart`, pubspecs, manifests |
| 1.7 | Restore `rider_app` Android/iOS platform | S | `apps/rider_app/android`, `ios`, manifests, pubspec |
| 1.8 | Portal defect fixes | S–M | `AdminDispatchPage.tsx`, `AdminSettingsPage.tsx`, `AdminPromotionsPage.tsx`, `AdminDashboardPage.tsx` |
| 1.9 | Docs sync (invariant §8.4) | S | `TID-02`, `TID-03`, `BRD-03`, `ADR-002` |

Execute 1.1 → 1.2 → 1.3 → 1.4 on the backend first (one coherent backend pass), then 1.5–1.7 Flutter, then 1.8 portals, 1.9 last.

---

## Task 1.1 — Central Order FSM Guard

**Problem**: Every transition hand-rolls its own status check with gaps. `claimOrder` accepts *any* non-terminal status (`order-flow.service.ts:275-279`), `ACCEPTED` is never written, `CANCELLED` is unreachable. Checks are scattered across 4 services and already disagree with each other.

**Implementation**:
1. Create `services/backend_api/src/modules/orders/order-state.machine.ts`:
   ```ts
   import { OrderStatus } from '@prisma/client';
   import { BadRequestException } from '@nestjs/common';

   export const ORDER_TRANSITIONS: Record<OrderStatus, OrderStatus[]> = {
     PLACED:            [OrderStatus.RIDER_ASSIGNED, OrderStatus.PREPARING, OrderStatus.CANCELLED],
     RIDER_ASSIGNED:    [OrderStatus.PREPARING, OrderStatus.CANCELLED],
     PREPARING:         [OrderStatus.READY_FOR_PICKUP, OrderStatus.CANCELLED],
     READY_FOR_PICKUP:  [OrderStatus.DISPATCHED],
     DISPATCHED:        [OrderStatus.DELIVERED],
     DELIVERED:         [],
     CANCELLED:         [],
   };

   export function assertTransition(from: OrderStatus, to: OrderStatus): void {
     if (!ORDER_TRANSITIONS[from]?.includes(to)) {
       throw new BadRequestException(`Illegal order transition ${from} → ${to}`);
     }
   }
   ```
2. Replace the ad-hoc checks at: `order-flow.service.ts:271-279` (claim), `vendor-staff.service.ts:170-177` (accept), `:220-227` (ready), `:264-268` (handover), `rider.service.ts:85-103` (pickup), `:137-141` (deliver). Each call site keeps its *role/ownership* checks and delegates only the status logic to `assertTransition`.
3. **Tighten claim rules per dispatch mode** (currently claimable in any non-terminal state):
   - `RIDER_FIRST`: claimable from `PLACED` only → transitions to `RIDER_ASSIGNED`.
   - `VENDOR_FIRST`: claimable from `READY_FOR_PICKUP` only → status stays, `riderId` set.
   - Model this as a `CLAIMABLE_FROM: Record<OrderFlowMode, OrderStatus[]>` map in the same file.
4. **Retire `ACCEPTED`**: no code path writes it. Remove it from all transition checks (the machine above already omits it). Keep the enum value in `schema.prisma` for now (Postgres enum removal needs its own migration); add a one-line comment marking it deprecated, drop it in a later cleanup migration.
5. **Cancel comes from Phase 0 (0.8)** — the machine above already reserves `CANCELLED` edges so Phase 0's cancel endpoints plug in without touching the table again.

**Acceptance**:
- Claiming a `PREPARING` or `DISPATCHED` order returns 400.
- Existing lifecycle scripts pass: `npm run vendor-rider:test`, `npm run dispatch:test`, `npm run order:test`, `npm run e2e:test`.
- Exactly one file in the codebase defines legal transitions (grep `OrderStatus.` in service transition checks returns only the machine + role checks).

---

## Task 1.2 — Single Source of Truth for Money & ETA

**Problem**: Four hardcoded constants contradict the configurable engine, and one is an outright **financial bug**: the dispatch broadcast promises riders `deliveryFee × 0.8` (`order-flow.service.ts:153, 210`) while `rider.service.ts:171` records `deliveryEarnings: order.deliveryFee` (**100%**) in `rider_trip_ledgers`. BRD-03 §5 defines rider earnings as **80% of delivery fee** — the ledger is wrong.

**Implementation**:
1. **New system setting `delivery_economics`** (add to `seed.ts` alongside `delivery_fee_config`):
   ```json
   { "rider_share_percent": 80, "eta_avg_speed_kmh": 25, "eta_fallback_minutes": 10 }
   ```
   Read it through one `DeliveryEconomicsService` (or extend `DeliveryFeeService`) with a 60s in-memory cache — same pattern as `getConfig()` in `delivery-fee.service.ts:27-40`.
2. **Fix the ledger**: `rider.service.ts:171,181` → `deliveryEarnings: round(order.deliveryFee * riderShare)`. The rider screen already displays values from this ledger, so UI picks it up automatically.
3. **Use the share in broadcasts**: replace the two `* 0.8` literals (`order-flow.service.ts:153, 210`) with the configured share — one service call per broadcast, not per rider.
4. **Discovery fee truth**: `vendor.service.ts:108` (`deliveryFee: 50.0` in nearby list) and `:284` (`estimatedDeliveryFee: 50.0` in coverage check) must call the fee engine. Inject `DeliveryFeeService` (module is `@Global()`), fetch config **once per request**, and compute per-vendor fees via a new pure helper `computeFee(config, distanceKm)` extracted from `calculateFee` — avoids N config reads for the nearby list (page can return 20+ vendors).
5. **ETA truth**: `tracking.gateway.ts:253` (`/ 25` km/h) and `order.service.ts:~548` (fallback `10` min) read `eta_avg_speed_kmh` / `eta_fallback_minutes` from the setting.
6. **Guard the invoice chain**: after changes, assert in checkout that `totalAmount === subtotal − couponDiscount + deliveryFee` (already true at `order.service.ts:272`) and add a comment tying rider earnings + commission to ADR-09 rounding rules (round at each step, `Math.round(x*100)/100`).

**Decision (recorded, not open)**: rider share = 80% per BRD-03 §5 — the ledger changes from 100% → 80%. If the business later wants 100%, change the setting, not the code.

**Acceptance**:
- Admin changes `rider_share_percent` → next broadcast payload, trip ledger, and rider earnings screen all agree.
- Admin switches fee mode to `DISTANCE_TIERED` with `base_fee 30 / base_km 2 / per_km 10` → nearby vendors and coverage check return distance-based estimates identical to checkout's charged fee for the same coordinates.
- `npm run promotions:test && npm run vendor-rider:test` pass.

---

## Task 1.3 — Deterministic Order Numbers

**Problem**: `ORD-YYYYMMDD-XXXX` with a random 4-digit suffix (`order.service.ts:277-280`) collides under load; ~10k orders/day gives ~1.3% birthday-collision probability at the 5,000th order.

**Implementation**:
1. Verify `orderNumber` has a unique constraint in `schema.prisma` (add `@unique` + migration if missing — check the `Order` model around line 370).
2. Replace random suffix with a Redis counter: `INCR order:seq:YYYYMMDD` (set 48h TTL on first increment), format `ORD-YYYYMMDD-0001` (zero-padded 4+ digits).
3. Belt-and-braces: wrap order creation in a 3-attempt retry on unique-violation (regenerate seq) so a Redis flush can't fail checkout.
4. Keep the order-number generation in one private method `generateOrderNumber()` — Phase 0's cancel flow and settlement exports reference the format.

**Acceptance**: unit-style loop creating 1,000 orders produces 1,000 distinct sequential numbers; `npm run order:test` passes.

---

## Task 1.4 — DB Indexes + PostGIS Spatial Indexing

**Problem**: `VendorStaff.userId` is probed on **every authenticated request** (JWT guard rehydration) with no index; order kitchen queues scan; and — worst — lat/lng are plain `Float`, so every `ST_DWithin` (`vendor.service.ts:73-102, 120-170, 252-263`, `order.service.ts:121-132`) is a **sequential scan** that will not scale past a few thousand vendors.

**Implementation**:
1. **Prisma-managed indexes** — new migration adding to `schema.prisma`:
   - `VendorStaff @@index([userId])`
   - `Category @@index([vendorId])`
   - `Order @@index([vendorId, status])` and `Order @@index([placedAt])`
   - `Banner @@index([isActive])`, `Rider @@index([isOnline])`, `OrderItem @@index([productId])`
   (`CustomerAddress.userId`, `Product.vendorId/categoryId`, `Order.customerId/vendorId/riderId/status` already exist — verified.)
2. **PostGIS GiST without schema drift**: use **expression indexes** so `schema.prisma` stays untouched (Prisma doesn't manage indexes it doesn't know, so no drift complaints):
   ```sql
   CREATE INDEX vendors_location_gix ON vendors
     USING GIST (ST_SetSRID(ST_MakePoint("longitude", "latitude"), 4326));
   -- same for customer_addresses, riders
   ```
   Hand-write this in a `--create-only` migration after the Prisma index block.
3. **Rewrite the spatial SQL** to match the index expression *exactly* (planner requirement), e.g.:
   ```sql
   WHERE ST_DWithin(
     ST_SetSRID(ST_MakePoint(v."longitude", v."latitude"), 4326),
     ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)::geography,
     ${radiusMeters}
   )
   ```
   Update all 4 query sites. Verify with `EXPLAIN ANALYZE` that `vendors_location_gix` is used.
4. Regression-check `npm run vendor:test` (nearby, search, coverage).

**Acceptance**: `EXPLAIN ANALYZE` shows Bitmap Index Scan on the GiST indexes (not Seq Scan); `vendor:test` passes; `prisma migrate dev` reports no drift afterwards.

---

## Task 1.5 — Flutter De-Mocking + Rider Cash-Deposit Backend

**Problem**: Silent `catch (_) {}` blocks fabricate success: customer checkout returns `mock-order-uuid` on API failure **after already clearing the cart** (`cart_provider.dart:307-318`), customer OTP `123456` logs in offline (`auth_provider.dart:104-124`), reorder auto-succeeds offline (`order_history_provider.dart:~100-113`), coupons are computed locally (`cart_provider.dart:200-264`). Worst: the **rider app never authenticates at all** — `verifyOtp` ignores the API response and always writes `mock-jwt-token-rider` with a hardcoded pilot profile (`rider_auth_provider.dart:205-225`), and OTP request returns `true` even when the call throws (`:114-121`). The cash-deposit feature has **no backend endpoint** to call.

**Implementation**:
1. **Backend first — rider cash deposit** (currently faked at `duty_provider.dart:214-240`):
   - New model in `schema.prisma`: `CashDeposit { id, riderId, amount, depositedAt, receivedByUserId?, note? }` + `@@index([riderId])`; migration.
   - `POST /rider/cash/deposit` (role RIDER): validates `amount ≤ cashInHand`, decrements `cashInHand`, creates ledger row, emits socket `rider:cash:updated` to `admin_hq`. Emitting to admin is optional-but-cheap; the ledger row is the requirement.
2. **Rider auth**: rewrite `verifyOtp` (`rider_auth_provider.dart:205-225`) to call `POST /auth/otp/verify` with role RIDER; map HTTP responses to the three real states — authenticated / `PENDING_APPROVAL` (403 with status payload → `pending_approval_screen`) / error. Delete `mock-jwt-token-rider`, `RiderProfileData.pilotApproved` fallback, and the always-true OTP-request catch (`:114-121`).
3. **Customer auth**: delete the `otp == '123456'` offline branch (`auth_provider.dart:104-124`). Dev convenience stays available *through the real API* (backend static OTP in non-prod), not around it.
4. **Checkout**: on failure, set `state.error`, do **not** `clearCart()`, return `{'success': false, 'error': …}`; cart screen shows a retry dialog (`cart_provider.dart:295-318`). Move `clearCart()` to after a verified 200/201.
5. **Reorder**: remove the dev fallback (`order_history_provider.dart:100-113`) — on API failure show a snackbar "Could not validate re-order, check connection" and don't touch the cart.
6. **Coupons**: delete local `WELCOME50`/`BURGER20` offline computation (`cart_provider.dart:200-264`); coupon UI shows the API's error message on failure.
7. **Dev simulate-trip button** (`rider_dashboard_screen.dart:692`) and `triggerBroadcastAlert` (`trip_provider.dart:67-82`): gate behind `kDebugMode && appFlavor == dev` (bool from `String.fromEnvironment('DEV_TOOLS')`) so release builds have no fabrication path. Cash-deposit screen calls the new real endpoint.
8. **Backend empty catches**: `order.service.ts:567, 585` — replace `catch {}` with `Logger.warn` and a null telemetry response (graceful, but visible).

**Acceptance**:
- Airplane-mode test: checkout, login, reorder, and coupon each show explicit errors; cart survives a failed checkout; nothing fabricates success.
- Real rider with pending approval sees the pending screen; approved rider gets a real JWT.
- `flutter test` (existing 1,860 lines) updated where they asserted mock behavior; all green.
- `flutter analyze` clean.

---

## Task 1.6 — Real GPS

**Problem**: No `geolocator` dependency anywhere. Rider "beaconing" jitters hardcoded Banani coordinates every 5s (`duty_provider.dart:150-174`); customer "Use Current Location" selects a preset chip (`map_location_picker_screen.dart:213`); reverse geocoding is a bounding-box guess (`location_provider.dart:117-127`).

**Implementation**:
1. Add `geolocator` (+ `permission_handler` if finer control wanted) to both pubspecs; add `ACCESS_FINE_LOCATION`/`ACCESS_COARSE_LOCATION` to both Android manifests (Task 1.7 adds rider's manifests; customer's main manifest needs them too — `INTERNET` is currently **debug-only**, so also add `INTERNET` to `customer_app/android/app/src/main/AndroidManifest.xml`).
2. **Rider**: replace `_startGpsBeaconing` with `Geolocator.getPositionStream(distanceFilter: 25)` subscribed while `state.isOnline`; on stream error, degrade to a visible "GPS unavailable" banner, not silence. Keep the existing REST dispatch (`PATCH /rider/duty` with coords, `duty_provider.dart:176-192`) for Phase 1 — the socket channel (`rider:location_update`) replaces it in Phase 2. Add a permission pre-flight: `Geolocator.requestPermission()` on first Online toggle; `LocationPermission.deniedForever` → deep-link to app settings.
3. **Customer locate-me**: wire the "Use Current Location" control to `Geolocator.getCurrentPosition()` with loading state, feeding the existing pin-picker flow (`map_location_picker_screen.dart:213`).
4. **Reverse geocoding**: add a small backend proxy `GET /geo/reverse-geocode?lat=&lng=` calling OpenStreetMap Nominatim (no API key, `User-Agent` header required, 1 req/s) with a Redis 24h cache keyed by rounded coords; customer app calls it instead of the bounding-box hack. (Google Geocoding arrives with the Maps key in Phase 2; this keeps Phase 1 key-free but real.)
   - Files: new `src/modules/geo/` module (controller + service) or a method in `vendors` module; register in `app.module.ts`.
5. Delete the hardcoded Dhaka coordinate constants scattered across 5+ Flutter files — single `AppDefaults.pilotCenter` constant in `core/constants/`.

**Acceptance**: online rider's coordinates in Redis (`riders:locations:active` via `GEOADD`, check with `redis-cli GEOPOS`) move when the device moves; customer locate-me drops the pin at real GPS; reverse geocode returns a real address label for Dhaka coords; GPS-denied permission shows actionable UI.

---

## Task 1.7 — Restore `rider_app` Android/iOS Platforms

**Problem**: `apps/rider_app/` has only `macos/` and `web/` — it cannot be built for a phone. It also carries a dead `google_maps_flutter` dependency and no dialer `queries` declaration.

**Implementation**:
1. From `apps/rider_app/`: `flutter create --platforms=android,ios --org com.deliveryos --project-name rider_app .` (regenerates `android/`, `ios/` without touching `lib/`, `test/`).
2. Android: set `applicationId com.deliveryos.rider_app`, app label "DeliveryOS Rider"; manifest permissions: `INTERNET`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `ACCESS_BACKGROUND_LOCATION` (placeholder for Phase 2 background service — declare now to avoid a later store submission diff), and a `<queries>` block for `ACTION_DIAL`/`tel:` so `url_launcher` works on Android 11+.
3. Remove `google_maps_flutter` from `rider_app/pubspec.yaml` (unused; re-add in Phase 2 with an API key).
4. iOS: display name "DeliveryOS Rider", `NSLocationWhenInUseUsageDescription` (+ `Always` for Phase 2), `LSApplicationQueriesSchemes` for `tel` and `googlemaps`/`maps` (matches `native_launcher.dart:25-45`).
5. Smoke-build: `flutter build apk --debug` succeeds.

**Acceptance**: rider app installs and launches on an Android emulator; login → duty toggle → GPS stream (Task 1.6) works end-to-end against the local stack.

---

## Task 1.8 — Portal Defect Fixes

**Problem list (all verified)**:
- Broken link: dispatch card links to `/admin/orders?orderNumber=…` which 404s (`AdminDispatchPage.tsx:317`) — admin basename is `/`, real route is `/orders`.
- Fake "Pilot Geofence Status" card with hardcoded telemetry "Gulshan-Banani 5.0 km / < 3.2 mins" (`AdminDispatchPage.tsx:328-348`).
- Hardcoded "Dispatch: RIDER_FIRST" badge on the dashboard (`AdminDashboardPage.tsx:160-163`) that can contradict actual settings.
- Delivery-fee settings UI missing entirely — mutation and `currentFeeMode` exist but render nothing (`AdminSettingsPage.tsx:46, 75`; API: `adminApi.ts:271-279`, backend `admin.controller.ts:367-381`).
- Coupon `usageLimit` state unbound — always submits 1000 (`AdminPromotionsPage.tsx:40, 480`).
- Dead code: admin `utils/sound.ts`, `types/kds.ts`, `PlaceholderPage.tsx` (both portals), admin auth store's vendor-only `/vendor/me` branch (`useAuthStore.ts:69-89`).

**Implementation**:
1. Fix the link to `/orders?orderNumber=${…}` **and** make `AdminOrdersPage` read the `orderNumber` search param into its filter state on mount (otherwise the query param is still ignored).
2. Replace the geofence card with a real one computed from data already on the page: count of unassigned orders by age bucket (`< 2 min / 2–10 min / > 10 min`) from the `PLACED` orders query — this is genuinely useful to a dispatcher.
3. Dashboard badge reads `useQuery(['admin-settings'])` → `settings.orderFlow.mode` (endpoint already exists).
4. Add a "Delivery Fee" settings card: mode toggle + conditional inputs (`flatFee` | `baseFee`, `baseKm`, `perKmRate`) wired to the existing mutation; show the currently-active config from `settings.deliveryFee`. Add a proper `DeliveryFeeDto` on the backend while here (it's an inline `@Body()` — see Phase 0.7 overlap; at minimum add `@IsIn`, `@IsNumber`, `@Min(0)`).
5. Add the missing `usageLimit` input field next to max-discount in the coupon form.
6. Delete the dead files listed above; simplify the admin auth store to its own role.

**Acceptance**: `npm run build` passes in both portals; `npm test` (scaffolding script) passes; dispatcher link lands on a pre-filtered orders table; fee-mode change from the UI is reflected in checkout pricing (ties to Task 1.2 acceptance).

---

## Task 1.9 — Documentation Sync (Invariant §8.4)

1. **TID-02** §3: document the new indexes + GiST expression-index strategy and the *expression-must-match* rule for future query authors.
2. **TID-03**: add `POST /rider/cash/deposit` and `GET /geo/reverse-geocode` contracts.
3. **BRD-03** §5: note rider earnings are enforced via `delivery_economics.rider_share_percent` (80% default) and that trip ledgers were corrected from 100% → 80%.
4. **ADR-002** (dispatch FSM): append the central `ORDER_TRANSITIONS` table as the authoritative machine, the per-mode claimable states, and the `ACCEPTED` deprecation note — the invariant requires an ADR touch for state-machine changes.
5. **WORK_BREAKDOWN.md**: annotate Tasks 3.x/5.x/6.x validation items that were verified only by manual ts-node scripts (not automated suites) so the checklist stops overclaiming.

---

## Definition of Done (Phase 1) — ✅ COMPLETED & VERIFIED

- [x] All 11 backend integration scripts pass (`db`, `auth`, `vendor`, `promotions`, `order`, `vendor-rider`, `ws`, `dispatch`, `tracking`, `health`, `e2e`).
- [x] `flutter analyze` + `flutter test` green in both apps (customer: 32/32, rider: 28/28); rider platform files created for Android/iOS.
- [x] `npm run build` green in both portals (admin + vendor); portal tests pass.
- [x] Airplane-mode / bad-input sweeps produce visible errors everywhere — zero silent fabricated successes in `lib/` (all offline catch fallbacks and hardcoded mock tokens removed).
- [x] `EXPLAIN ANALYZE` proves GiST index usage for nearby/coverage queries (`Index Scan using idx_vendors_geo`).
- [x] Broadcast rider earnings == trip ledger earnings == rider earnings screen, for a full order lifecycle run (verified against dynamic 80% config).
- [x] Sequential order numbers (`ORD-YYYYMMDD-0001`) via atomic Redis counter with collision retry.
- [x] Docs synced (ADR-002, TID-02, TID-03, BRD-03) and changes organized for user-authorized commit sequence.

**Suggested commit sequence** (each independently revertable; commits executed only on your explicit command per §6.1):
1. `feat(orders): centralize order FSM with per-mode claim rules` (1.1)
2. `fix(ledger): rider earnings share from delivery_economics config` (1.2)
3. `feat(orders): deterministic sequential order numbers` (1.3)
4. `perf(db): hot-path indexes and PostGIS GiST expression indexes` (1.4)
5. `feat(riders): cash deposit ledger endpoint` (1.5 backend part)
6. `fix(customer_app): remove offline mock fallbacks across auth/checkout/reorder` (1.5)
7. `fix(rider_app): real OTP authentication and GPS beaconing` (1.5 + 1.6)
8. `chore(rider_app): restore android/ios platform targets` (1.7)
9. `fix(admin_portal): dispatch link, settings fee UI, real dispatch stats` (1.8)
10. `docs: sync TID/BRD/ADR with phase 1 changes` (1.9)
