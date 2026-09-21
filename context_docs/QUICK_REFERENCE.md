# DeliveryOS — Quick Reference & AI Context Router
> **AI AGENT USAGE**: Read this file first to locate the **exact file** you need. Do NOT load the entire documentation directory into context.

---

## 1. Task-to-File Context Router (Read Only What You Need)

| If Your Task Involves... | Load ONLY These Documents |
| :--- | :--- |
| **Engineering Roadmap & Step-by-Step WBS** | `WORK_BREAKDOWN.md` |
| **Non-Technical Master Product Overview** | `BRD-00` (`00-master-product-overview.md`) |
| **Authentication, OTP, JWT, Role Guards** | `TID-03` (API Specs: Section 2) + `TID-02` (Users table) |
| **Customer App UI, Cart, Banners, Coupons** | `BRD-04` (Customer Journey) + `TID-03` (API Specs: Section 3) |
| **Cart Address Geofence Guard & Radius Check**| `BRD-03` (Sec 1.3) + `BRD-04` (Screen 6) + `TID-02` (Sec 3.2) + `TID-03` (Sec 3.4) |
| **Re-Order Validation Logic** | `BRD-04` (Screen 9) + `TID-03` (Endpoint 3.7) + `BRD-03` |
| **Vendor Kitchen Console, Audio Alert & Prep Time**| `apps/vendor_portal` + `BRD-05` + `TID-04` + `TID-06` |
| **Vendor 2-Tier Permissions (Outlet vs Master)**| `BRD-03` (Sec 3) + `BRD-05` (Sec 2) + `TID-02` (Sec 7) + `TID-03` (Sec 6.4) |
| **Vendor Catalog, Menu, Variants & Stock Toggle**| `BRD-05` + `TID-02` (Products/Variants tables) + `TID-03` (Sec 4.5) |
| **Rider App UI & 3-Step Delivery Fulfillment** | `BRD-06` (Rider Ops) + `TID-03` (API Specs: Section 5) |
| **Rider Dispatch, Radius Search, Redis Mutex** | `TID-05` (State Machine & Dispatch) + `TID-04` (Events: 3.2) |
| **Super Admin Console, Banners, Coupons, Orders**| `apps/admin_portal` + `BRD-07` (Admin Guide) + `TID-03` (Sec 6) + `TID-06` |
| **Delivery Fees (Flat vs Distance) & Ledgers** | `BRD-03` (Business Rules: Sec 4 & 5) + `TID-02` (Ledger tables) |
| **Database Schema, PostGIS Queries, Migrations** | `TID-02` (Database Schema & DDL) |
| **WebSockets, Realtime Rooms & Payloads** | `TID-04` (WebSocket Protocol) |
| **Docker, Nginx, Environment Variables, Setup** | `TID-07` (DevOps & Environment Setup) |

---

## 2. Core Enums & Invariant Values

```typescript
// Roles & Permissions
enum UserRole { SUPER_ADMIN = 'SUPER_ADMIN', VENDOR_ADMIN = 'VENDOR_ADMIN', RIDER = 'RIDER', CUSTOMER = 'CUSTOMER' }
enum PermissionScope { PARTICULAR_OUTLET = 'PARTICULAR_OUTLET', ALL_OUTLETS_MASTER = 'ALL_OUTLETS_MASTER' }

// Order Lifecycle FSM
enum OrderStatus { 
  PLACED = 'PLACED', 
  RIDER_ASSIGNED = 'RIDER_ASSIGNED',
  ACCEPTED = 'ACCEPTED', 
  PREPARING = 'PREPARING', 
  READY_FOR_PICKUP = 'READY_FOR_PICKUP', 
  DISPATCHED = 'DISPATCHED', 
  DELIVERED = 'DELIVERED', 
  CANCELLED = 'CANCELLED' 
}

// Payment & Fees
enum PaymentMethod { CASH_ON_DELIVERY = 'CASH_ON_DELIVERY', ONLINE_GATEWAY = 'ONLINE_GATEWAY' }
enum DeliveryFeeMode { FIXED_FLAT = 'FIXED_FLAT', DISTANCE_TIERED = 'DISTANCE_TIERED' }
enum DiscountType { PERCENTAGE = 'PERCENTAGE', FLAT = 'FLAT' }

// Configurable Order Dispatch Flow Sequence
enum OrderFlowMode { 
  RIDER_FIRST = 'RIDER_FIRST',     // Rider claimed first -> Sent to Vendor for manual acceptance -> Zero food waste
  VENDOR_FIRST = 'VENDOR_FIRST',   // Vendor accepts & preps first -> Rider broadcasted when ready
  PARALLEL = 'PARALLEL'           // Simultaneous broadcast to riders and vendor alert
}
```

---

## 3. Production Code Patterns (Copy-Paste Ready)

### A. Atomic Order Status / Financial Transaction (NestJS + Prisma)
```typescript
await prisma.$transaction(async (tx) => {
  const order = await tx.orders.update({
    where: { id: orderId },
    data: { status: OrderStatus.DELIVERED, delivered_at: new Date() }
  });
  await tx.rider_trip_ledgers.create({
    data: { order_id: orderId, rider_id: riderId, delivery_earnings: earnings, cod_collected: codAmount }
  });
});
```

### B. Redis Atomic Lock for Order Claims (Prevents Race Conditions)
```typescript
const acquired = await redis.set(`lock:order_claim:${orderId}`, riderId, 'NX', 'EX', 10);
if (!acquired) throw new ConflictException('Order already accepted by another rider');
```

### C. Standard API Response Envelope
```typescript
return { success: true, statusCode: HttpStatus.OK, message: 'Success', data: payload };
```
