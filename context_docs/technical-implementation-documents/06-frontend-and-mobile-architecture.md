# 06 — Frontend & Mobile Architecture

This document specifies the client-side architectural standards for the **Flutter Mobile Applications** (Customer & Rider Apps) and the **React.js Single Page Application Web Portals** (Admin & Vendor Dashboards).

---

## 1. Flutter Mobile Architecture (Customer & Rider Apps)

Both the Customer and Rider apps are built with **Flutter 3.19+** using a **Feature-First Clean Architecture** with **Riverpod 3.3.2** for reactive state management.

### 1.1 Customer App Architecture (`apps/customer_app`)

```
apps/customer_app/lib/
├── core/
│   ├── constants/           # Colors, assets, typography, API endpoints
│   ├── network/             # Dio client, JWT auth interceptor, retry interceptor
│   ├── localization/        # In-code localized string lookups & LanguageNotifier
│   ├── storage/             # SharedPreferences local storage wrapper
│   └── utils/               # Native dialer launcher, currency formatters
└── features/
    ├── addresses/           # AddressBookScreen, AddressNotifier, CustomerAddressModel
    ├── auth/                # PhoneInputScreen, OtpVerificationScreen, AuthProvider
    ├── banners/             # BannerCarousel, PromoBannerModel
    ├── cart/                # Single-vendor CartScreen, CartNotifier, Guarded Checkout
    ├── discovery/           # SearchScreen, SearchNotifier, CategoryChips
    ├── home/                # HomeScreen, NearbyVendorsFeed, Sticky Category Bar
    ├── location/            # MapLocationPickerScreen, LocationNotifier
    ├── orders/              # OrderHistoryScreen, SmartReorderNotifier
    ├── profile/             # ProfileScreen, CustomerProfileNotifier
    ├── store/               # OutletDetailScreen, ItemCustomizerSheet, ProductCatalogModel
    └── tracking/            # OrderTrackingScreen, OrderStepperWidget, LiveMap
```

### 1.2 Rider App Architecture (`apps/rider_app`)

```
apps/rider_app/lib/
├── core/
│   ├── constants/           # AppColors, ApiConstants, Typography
│   ├── network/             # Dio client with JWT interceptor & refresh handling
│   ├── services/            # RiderSocketService (Socket.IO client for dispatch & telemetry)
│   ├── storage/             # Secure SharedPreferences storage provider
│   └── utils/               # Native turn-by-turn navigation & phone dialer handoffs
└── features/
    ├── auth/                # PhoneLoginScreen, OtpVerificationScreen, PendingApprovalScreen
    ├── dashboard/           # RiderDashboardScreen, RiderDutyNotifier, TelemetryBeacon
    ├── earnings/            # RiderEarningsScreen, TimeframeToggle, CashDepositModal
    └── trips/               # ActiveTripScreen (3-Step Stepper), IncomingTripModal (45s Chime),
                             # Doorstep Unresponsive SOP Modal (5-min Timer)
```

### 1.3 Device Native Handoff & Background Capabilities

To ensure battery efficiency, low network latency, and zero external licensing overhead, native capabilities are integrated directly:

```dart
// 1. Direct Native Phone Calling
Future<void> makeDirectPhoneCall(String phoneNumber) async {
  final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
  if (await canLaunchUrl(launchUri)) {
    await launchUrl(launchUri);
  }
}

// 2. Native Turn-by-Turn Navigation Handoff (Google Maps / Apple Maps)
Future<void> openNativeTurnByTurnNavigation(double lat, double lng) async {
  final Uri googleMapsUri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
  final Uri appleMapsUri = Uri.parse('https://maps.apple.com/?daddr=$lat,$lng');

  if (Platform.isAndroid && await canLaunchUrl(googleMapsUri)) {
    await launchUrl(googleMapsUri);
  } else if (await canLaunchUrl(appleMapsUri)) {
    await launchUrl(appleMapsUri);
  }
}
```

- **Android Foreground Location Service**: Configured in `AndroidManifest.xml` via `FOREGROUND_SERVICE_LOCATION` permission, enabling persistent 10-meter GPS beaconing even when the app is in the background.

---

## 2. Dedicated React.js SPA Architecture (Admin & Vendor Portals)

The web tier consists of two independent Single Page Applications (SPAs) built with **Vite**, **React 18**, **Tailwind CSS**, and **TanStack Query** behind Nginx subpath routing ([ADR-005](context_docs/architecture-decision-records/ADR-005-micro-frontends-and-subpath-routing.md)):

```
apps/
├── admin_portal/src/
│   ├── components/
│   │   ├── dispatch/LiveFleetMap.tsx # Leaflet OpenStreetMap interactive radar
│   │   └── ui/                       # Button, Modal, Table, Badge, Alert, Input
│   ├── pages/admin/
│   │   ├── AdminDashboardPage.tsx    # Live operational KPIs & recent orders feed
│   │   ├── AdminDispatchPage.tsx     # Fleet Radar, Applicant Couriers queue, Cash Limits
│   │   ├── AdminOrdersPage.tsx       # Order monitor, ?orderNumber deep link, override modals
│   │   ├── AdminPromotionsPage.tsx   # Hero banner scheduler & promo coupon engine
│   │   ├── AdminSettingsPage.tsx     # Order flow FSM, delivery fee mode, CSV/JSON settlements
│   │   └── AdminVendorsPage.tsx      # Vendor onboarding, commission rates, staff assignment
│   ├── routes/AppRoutes.tsx          # RBAC RouteGuard enforcing SUPER_ADMIN
│   ├── stores/useAuthStore.ts        # Zustand auth session store
│   └── services/adminApi.ts          # Axios client for /api/v1/admin/*
│
└── vendor_portal/src/
    ├── components/
    │   ├── kds/                      # KDSOrderCard, CountdownTimer (amber->red overdue)
    │   ├── vendor/OutletSwitcher.tsx # Multi-branch Brand Owner vs Single-Store staff switch
    │   └── ui/                       # High-contrast culinary UI components
    ├── pages/vendor/
    │   ├── VendorDashboardPage.tsx   # 3-lane KDS Kanban board with audio chime
    │   ├── VendorCatalogPage.tsx     # Merchant catalog retaining sold-out items with stock toggles
    │   ├── VendorOrdersPage.tsx      # Itemized sales ledger, Today vs All Time, details modal
    │   └── VendorSettingsPage.tsx    # Emergency pause (30m, 1h, Day), prep time, 7-day schedule
    ├── hooks/useKDSOrders.ts         # TanStack Query + Socket.IO invalidation + persistent chime
    ├── utils/sound.ts                # Web Audio API in-memory oscillator chime (ADR-007)
    ├── routes/AppRoutes.tsx          # RBAC RouteGuard enforcing VENDOR_ADMIN
    └── services/kdsApi.ts            # Axios client for /api/v1/vendor/*
```

### 2.1 Role-Based Access Control (RBAC) Route Registries

```tsx
// In admin_portal/src/routes/AppRoutes.tsx:
<Route element={<RoleGuard allowedRoles={[UserRole.SUPER_ADMIN]}><AdminLayout /></RoleGuard>}>
  <Route path="/" element={<AdminDashboardPage />} />
  <Route path="/dispatch" element={<AdminDispatchPage />} />
  <Route path="/orders" element={<AdminOrdersPage />} />
  <Route path="/promotions" element={<AdminPromotionsPage />} />
  <Route path="/vendors" element={<AdminVendorsPage />} />
  <Route path="/settings" element={<AdminSettingsPage />} />
</Route>

// In vendor_portal/src/routes/AppRoutes.tsx:
<Route element={<RoleGuard allowedRoles={[UserRole.VENDOR_ADMIN]}><VendorLayout /></RoleGuard>}>
  <Route path="/" element={<VendorDashboardPage />} />
  <Route path="/kds" element={<VendorDashboardPage />} />
  <Route path="/catalog" element={<VendorCatalogPage />} />
  <Route path="/orders" element={<VendorOrdersPage />} />
  <Route path="/settings" element={<VendorSettingsPage />} />
</Route>
```

### 2.2 Synthesized Kitchen Audio Alert Engine (ADR-007)

External audio files (`.mp3`) are prone to network latency and 404 path mismatches under subpath reverse proxies. The Vendor KDS synthesizes dual-tone bell alarms directly in browser memory using the Web Audio API:

```typescript
// apps/vendor_portal/src/utils/sound.ts
export function playOrderAlarmChime(): void {
  try {
    const AudioCtx = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
    if (!AudioCtx) return;
    const ctx = new AudioCtx();

    // Dual-tone harmonic bells (D5 587.33 Hz + A5 880 Hz)
    const osc1 = ctx.createOscillator();
    const osc2 = ctx.createOscillator();
    const gain = ctx.createGain();

    osc1.type = 'sine';
    osc1.frequency.setValueAtTime(587.33, ctx.currentTime);
    osc2.type = 'triangle';
    osc2.frequency.setValueAtTime(880, ctx.currentTime);

    gain.gain.setValueAtTime(0.001, ctx.currentTime);
    gain.gain.linearRampToValueAtTime(0.4, ctx.currentTime + 0.05);
    gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + 1.2);

    osc1.connect(gain);
    osc2.connect(gain);
    gain.connect(ctx.destination);

    osc1.start();
    osc2.start();
    osc1.stop(ctx.currentTime + 1.25);
    osc2.stop(ctx.currentTime + 1.25);
  } catch (err) {
    console.warn('Audio synthesis warning:', err);
  }
}
```

- **Loop Invariant**: In `useKDSOrders.ts`, when an incoming order arrives, `startOrderAlarm()` repeats this chime every 3 seconds. The loop is cleared **only when zero unaccepted orders remain in Lane 1**.

### 2.3 Live Fleet Radar Engine (Leaflet + OpenStreetMap)

Implemented in `apps/admin_portal/src/components/dispatch/LiveFleetMap.tsx`:
- Zero external Google Maps API key requirements or per-tile billing costs.
- Custom Leaflet `DivIcon` markers colored dynamically: Emerald (Idle), Sky (On Trip), Amber (Approaching Cash Limit), Slate (Offline).
- Marker popups provide direct SPA links (`navigate('/orders?orderNumber=...')`), preserving the active WebSocket connection without reloading the page.
