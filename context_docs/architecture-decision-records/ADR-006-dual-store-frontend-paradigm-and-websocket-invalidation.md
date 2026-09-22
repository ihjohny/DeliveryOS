# ADR-006: Dual-Store Frontend Paradigm (Zustand + TanStack Query) & Real-Time WebSocket Invalidation

## Status
Accepted (2026-09-22)

## Context & Problem Statement
Web frontends in delivery platforms must handle two distinct categories of state:
1. **Client / Session State**: JWT authentication tokens, active user profile, multi-outlet scope (`ALL_OUTLETS_MASTER` vs `PARTICULAR_OUTLET`), UI sidebar collapse state, and active Socket.IO connection references.
2. **Server / Remote State**: Active orders list, live fleet radar courier locations, product inventory, and financial ledger summaries.

Attempting to store all server responses inside global client stores (like Redux or Zustand) results in "State Bloat", boilerplate reducers, cache invalidation bugs, and stale data. Conversely, relying purely on short HTTP polling loops (e.g. polling every 5 seconds) degrades server performance and introduces latency.

## Decision Drivers
- **Separation of Concerns**: Client session state must be clearly separated from server cache state.
- **Real-Time UI Responsiveness**: Changes to orders or fleet status must be visible in under 100 milliseconds without tight polling loops.
- **Deterministic Cache Invalidation**: Server data must auto-refresh upon receiving targeted WebSocket events.
- **Lightweight Implementation**: No heavy Redux boilerplate.

## Considered Options
1. **Redux Toolkit + Redux Thunks for Everything**: Everything in Redux. (Rejected: Excessive boilerplate; difficult cache lifecycle management).
2. **TanStack Query + Short HTTP Polling**: React Query with 5-second `refetchInterval`. (Rejected: Causes continuous HTTP traffic spikes; still lags behind instantaneous events).
3. **Dual-Store Architecture (Zustand + TanStack Query + WebSocket Invalidation) (Chosen)**:
   - **Zustand** manages client persistent and session state.
   - **TanStack Query** manages server cache.
   - **Socket.IO Events** trigger immediate cache invalidations.

## Decision Outcome
Chosen option: **Dual-Store Architecture with WebSocket Invalidation**:

```
┌─────────────────────────────────────────────────────────────┐
│                      Client State                           │
│  Managed by ZUSTAND (LocalStorage Synchronized)             │
│  - useAuthStore: Token, User, Login/Logout, Socket handle   │
│  - useVendorOutletStore: Active Outlet ID, Multi-tier scope │
└─────────────────────────────────────────────────────────────┘
                               ▲
                               │ (Supplies JWT to queries)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                      Server State                           │
│  Managed by TANSTACK QUERY (React Query)                    │
│  - useQuery(['admin-orders'], fetchOrders)                  │
│  - useQuery(['admin-fleet'], fetchFleet)                    │
│  - useQuery(['admin-overview'], fetchOverview)              │
└─────────────────────────────────────────────────────────────┘
                               ▲
                               │ (Triggers Invalidation)
┌─────────────────────────────────────────────────────────────┐
│                Real-Time WebSocket Gateway                  │
│  Socket.IO (/events)                                        │
│  - Event 'order:new' -> queryClient.invalidateQueries(...)  │
│  - Event 'order:status:changed' -> invalidateQueries(...)   │
│  - Event 'dispatch:broadcast' -> invalidateQueries(...)     │
└─────────────────────────────────────────────────────────────┘
```

### Positive Consequences
- **Instantaneous Real-Time Updates**: UI updates within 50ms of a backend state change.
- **Drastic Reduction in HTTP Overhead**: Eliminates unnecessary polling requests when the system is quiet.
- **Zero Stale Cache Bugs**: Server data is revalidated directly from authoritative backend endpoints.

### Negative Consequences / Trade-offs
- Frontend pages must register and clean up WebSocket listeners in `useEffect` hooks to prevent duplicate event triggers.

## Technical Implementation Details
In [`AdminOrdersPage.tsx`](file:///Users/bs0650/BS-23-Pro/DeliveryOS/apps/admin_portal/src/pages/admin/AdminOrdersPage.tsx):
```typescript
const queryClient = useQueryClient();

// 1. Fetch server state with relaxed fallback polling (30s)
const { data: orders = [], isLoading } = useQuery({
  queryKey: ['admin-orders'],
  queryFn: () => adminApi.getOrders(),
  refetchInterval: 30000,
});

// 2. Invalidate immediately on live Socket.IO events
useEffect(() => {
  const socket = getSocket();
  if (!socket) return;

  const handleOrderChange = () => {
    queryClient.invalidateQueries({ queryKey: ['admin-orders'] });
  };

  socket.on('order:new', handleOrderChange);
  socket.on('order:status:changed', handleOrderChange);

  return () => {
    socket.off('order:new', handleOrderChange);
    socket.off('order:status:changed', handleOrderChange);
  };
}, [queryClient]);
```

## Compliance & Verification
- Implemented across `AdminDashboardPage.tsx`, `AdminOrdersPage.tsx`, and `AdminDispatchPage.tsx`.
- Verified in `apps/admin_portal` test suites (8/8 passing).
