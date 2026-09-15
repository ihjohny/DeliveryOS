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

## 2. React.js SPA Architecture (Web Portal)

The unified Web Portal is a responsive Single Page Application (SPA) built with **Vite**, **React 18**, **Tailwind CSS**, and **TanStack Query**.

```
apps/web_portal/src/
├── api/                     # Axios instance & TanStack Query hooks
├── components/              # Shared UI components (Button, Modal, Table, Input)
├── contexts/                # AuthContext, AudioAlertContext
├── modules/
│   ├── admin/               # /admin/* routes (Fleet map, Master catalog, Ledgers)
│   └── vendor/              # /vendor/* routes (Live KDS, Stock toggle, Settings)
├── routes/                  # ProtectedRoute, RoleGuard, Router config
├── App.tsx
└── main.tsx
```

### 2.1 Role-Based Access Control (RBAC) Route Guards

```tsx
// routes/RoleGuard.tsx
export const RoleGuard = ({ allowedRoles, children }: { allowedRoles: string[]; children: JSX.Element }) => {
  const { user, isAuthenticated, isLoading } = useAuth();

  if (isLoading) return <LoadingSpinner />;
  if (!isAuthenticated) return <Navigate to="/login" replace />;
  if (!allowedRoles.includes(user.role)) return <Navigate to="/unauthorized" replace />;

  return children;
};

// In AppRouter:
<Route path="/admin/*" element={
  <RoleGuard allowedRoles={['SUPER_ADMIN']}>
    <AdminLayout />
  </RoleGuard>
} />

<Route path="/vendor/*" element={
  <RoleGuard allowedRoles={['VENDOR_ADMIN', 'SUPER_ADMIN']}>
    <VendorLayout />
  </RoleGuard>
} />
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
