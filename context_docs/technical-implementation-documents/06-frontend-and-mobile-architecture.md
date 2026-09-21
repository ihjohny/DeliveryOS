# 06 — Frontend & Mobile Architecture

This document specifies the client-side architectural standards for the **Flutter Mobile Applications** (Customer & Rider Apps) and the **React.js Single Page Application Web Portal** (Admin & Vendor Dashboards).

---

## 1. Flutter Mobile Architecture (Customer & Rider Apps)

Both the Customer and Rider apps are built with **Flutter 3.19+** using a **Feature-First Clean Architecture** with **Riverpod 2.x** for state management.

```
apps/customer_app/lib/
├── core/
│   ├── constants/           # Colors, assets, typography, API URLs
│   ├── network/             # Dio client, JWT auth interceptor, retry interceptor
│   ├── localization/        # en.json, ar.json, bn.json, l10n delegate
│   └── utils/               # Native dialer launcher, currency formatters
└── features/
    ├── auth/                # presentation (screens/widgets), domain, data
    ├── discovery/           # nearby vendors, category filter, search
    ├── store/               # product list, variant customizer
    ├── cart/                # single-vendor cart provider, validation
    ├── checkout/            # payment picker, delivery fee logic
    └── tracking/            # live map with Google Maps controller, call button
```

### 1.1 Internationalization & RTL Support
- Handled via `flutter_localizations` and standard JSON translation catalogs (`en.json`, `ar.json`, `bn.json`).
- When the active locale is Arabic (`ar`), Flutter automatically mirrors the entire layout hierarchy to **Right-to-Left (RTL)**.

### 1.2 Device Native Handoff Implementation
To maintain zero-latency and low licensing overhead, native device capabilities are triggered via the `url_launcher` package:

```dart
// Direct Phone Calling Shortcut (No in-app WebRTC)
Future<void> makeDirectPhoneCall(String phoneNumber) async {
  final Uri launchUri = Uri(
    scheme: 'tel',
    path: phoneNumber,
  );
  if (await canLaunchUrl(launchUri)) {
    await launchUrl(launchUri);
  }
}

// Native Google Maps Turn-by-Turn Navigation Handoff (Rider App)
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

---

## 2. Dedicated React.js SPA Architecture (Admin & Vendor Portals)

The web tier is split into two single-responsibility Single Page Applications (SPAs) built with **Vite**, **React 18**, **Tailwind CSS**, and **TanStack Query**:

1. **Super Admin Master Console (`apps/admin_portal`)** — Port `3000`:
   - **Theme**: Enterprise Indigo & Slate palette (`primary-600: #4f46e5`) providing an authoritative, data-dense governance center.
   - **Scope**: Platform KPIs, multi-outlet governance, Live Fleet Radar, unassigned order dispatch override, banners scheduler, coupon engine, and settlement CSV exports.
   - **Role Guard**: Exclusively restricted to `SUPER_ADMIN`.

2. **Vendor Store & Kitchen Order Console (`apps/vendor_portal`)** — Port `3001`:
   - **Theme**: Warm Amber & Flame Orange culinary palette (`primary-500: #f59e0b`, `culinary-600: #ea580c`) optimized for high-contrast kitchen tablets.
   - **Scope**: 3-lane KDS order Kanban (`New`, `Preparing`, `Ready`), persistent looped chime, custom prep timers (`15m`, `25m`, `35m`), catalog stock toggle, rush pause, and outlet sales ledger.
   - **Role Guard**: Restricted to `VENDOR_ADMIN` (with `SUPER_ADMIN` store inspection capability).

```
apps/
├── admin_portal/src/
│   ├── components/ui/       # Enterprise UI components (Button, Modal, Table, Input)
│   ├── contexts/            # AuthContext
│   ├── pages/admin/         # Dashboard, Vendors, Dispatch, Orders, Promotions, Settings
│   ├── routes/              # Super Admin RoleGuard & routes
│   ├── layouts/             # AdminLayout & AuthLayout
│   └── main.tsx
│
└── vendor_portal/src/
    ├── components/kds/      # KDSOrderCard, CountdownTimer
    ├── components/vendor/   # OutletSwitcher (ALL_OUTLETS_MASTER vs PARTICULAR_OUTLET)
    ├── contexts/            # AuthContext, VendorOutletContext
    ├── hooks/               # useKDSOrders with Socket.IO chime triggers
    ├── pages/vendor/        # KDS Kitchen Console, Catalog Stock, Settings, Orders Ledger
    ├── routes/              # Vendor RoleGuard & routes
    ├── layouts/             # VendorLayout & AuthLayout
    └── main.tsx
```

### 2.1 Role-Based Access Control (RBAC) Route Guards

```tsx
// In admin_portal/src/routes/AppRoutes.tsx:
<Route
  element={
    <RoleGuard allowedRoles={[UserRole.SUPER_ADMIN]}>
      <AdminLayout />
    </RoleGuard>
  }
>
  <Route path="/" element={<AdminDashboardPage />} />
  <Route path="/vendors" element={<AdminVendorsPage />} />
  <Route path="/dispatch" element={<AdminDispatchPage />} />
  <Route path="/orders" element={<AdminOrdersPage />} />
  <Route path="/promotions" element={<AdminPromotionsPage />} />
  <Route path="/settings" element={<AdminSettingsPage />} />
</Route>

// In vendor_portal/src/routes/AppRoutes.tsx:
<Route
  element={
    <RoleGuard allowedRoles={[UserRole.VENDOR_ADMIN, UserRole.SUPER_ADMIN]}>
      <VendorLayout />
    </RoleGuard>
  }
>
  <Route path="/" element={<VendorDashboardPage />} />
  <Route path="/catalog" element={<VendorCatalogPage />} />
  <Route path="/orders" element={<VendorOrdersPage />} />
  <Route path="/settings" element={<VendorSettingsPage />} />
</Route>
```

### 2.2 Kitchen Audio Alert Engine (Persistent Chime)

Browsers restrict audio autoplay until user interaction. The portal initializes audio context on first user click and triggers a persistent chime when a new order arrives via WebSocket:

```tsx
// hooks/useKitchenSoundAlert.ts
import { useEffect, useRef } from 'react';
import { socket } from '../api/socket';

export const useKitchenSoundAlert = (vendorId: string) => {
  const audioRef = useRef<HTMLAudioElement | null>(null);

  useEffect(() => {
    audioRef.current = new Audio('/sounds/order-alarm.mp3');
    audioRef.current.loop = true;

    socket.on('order:new', (payload) => {
      // Play continuous alert sound
      audioRef.current?.play().catch((err) => console.warn('Audio unlock needed:', err));
    });

    socket.on('order:status:changed', () => {
      // Stop ringing once acknowledged or accepted
      audioRef.current?.pause();
      if (audioRef.current) audioRef.current.currentTime = 0;
    });

    return () => {
      audioRef.current?.pause();
    };
  }, [vendorId]);
};
```
