# ADR-008: Immutable Historical Order Snapshots using JSONB for Audit Integrity

## Status
Accepted (2026-09-22)

## Context & Problem Statement
In multi-vendor e-commerce, catalogs and customer addresses are mutable:
- A restaurant frequently changes prices, alters item names, or deletes old dishes.
- Customers edit their saved addresses or delete old apartment numbers.

If order history records only store foreign keys (`product_id`, `address_id`) and join against mutable tables:
1. Past receipts and financial reports retroactively reflect new prices or altered descriptions.
2. Deleted items or addresses break past order views with `Foreign Key Constraint Violation` or `null` exceptions.
3. Legal invoice audit trails and VAT tax declarations are corrupted.

## Decision Drivers
- **Audit & Invoicing Immutability**: A receipt generated today must be identical 5 years from now.
- **Resilience to Catalog Deletions**: Merchants must be able to delete obsolete products without cascading failures into order history.
- **Extensible Snapshot Schemas**: Snapshots must capture variant names, price modifiers, and dynamic addons cleanly.

## Considered Options
1. **Live Relational Joins on Mutable Tables**: Only store `product_id` and `customer_address_id`. (Rejected: Severe audit trail corruption).
2. **Duplicated Relational Snapshot Tables**: Create `order_address_snapshots`, `order_product_snapshots`, `order_addon_snapshots`. (Rejected: Schema bloat; requires dozens of joining tables for simple receipt lookups).
3. **Immutable JSONB Snapshots on Order & OrderItem Tables (Chosen)**: Store frozen JSON snapshots in `deliveryAddressSnapshot`, `variantSnapshot`, and `addonsSnapshot` at checkout.

## Decision Outcome
Chosen option: **Immutable JSONB Snapshots**, because:
- PostgreSQL `JSONB` stores structured binary JSON with zero join overhead.
- When an order is placed in [`order.service.ts`](file:///Users/bs0650/BS-23-Pro/DeliveryOS/services/backend_api/src/modules/orders/order.service.ts), the exact address text, product title, chosen variant, and addons are frozen in time.
- Strongly typed TypeScript interfaces (`OrderAddressSnapshot`, `OrderVariantSnapshot`, `OrderAddonSnapshot`) ensure compile-time safety and eliminate untyped `any` data.

### Positive Consequences
- **Permanent Legal Auditability**: Past invoices and tax reports can never be altered by future menu updates.
- **Fast Historical Retrieval**: Viewing an old order does not require complex 6-table joins.
- **Resilient Cascade Rules**: Products and customer addresses can be safely deactivated without breaking historical orders.

### Negative Consequences / Trade-offs
- Schema changes in snapshots over time must handle optional fields for backwards compatibility. (Mitigated with TypeScript optional fields `?`).

## Technical Implementation Details
In Prisma schema and [`order.service.ts`](file:///Users/bs0650/BS-23-Pro/DeliveryOS/services/backend_api/src/modules/orders/order.service.ts):
```typescript
export interface OrderAddressSnapshot {
  type: string;
  vendorAddress?: string;
  addressId?: string;
  addressLine?: string;
  buildingFloor?: string | null;
  label?: string;
  latitude?: number;
  longitude?: number;
  deliveryNote?: string | null;
  [key: string]: Prisma.InputJsonValue | undefined;
}

export interface OrderVariantSnapshot {
  id: string;
  name: string;
  priceModifier: number;
  [key: string]: Prisma.InputJsonValue | undefined;
}

export interface OrderAddonSnapshot {
  id: string;
  name: string;
  price: number;
  [key: string]: Prisma.InputJsonValue | undefined;
}
```

## Compliance & Verification
- Validated by Prisma compilation and backend tests.
- Re-order validation logic in [`ValidateReorderDto`](file:///Users/bs0650/BS-23-Pro/DeliveryOS/services/backend_api/src/modules/orders/dto/validate-reorder.dto.ts) explicitly compares snapshot data against current live catalog prices.
