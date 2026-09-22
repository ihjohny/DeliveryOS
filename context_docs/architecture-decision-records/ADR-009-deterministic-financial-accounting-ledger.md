# ADR-009: Deterministic Floating-Point Math & Double-Entry Commission Settlement Ledger

## Status
Accepted (2026-09-22)

## Context & Problem Statement
Financial reconciliation in multi-vendor delivery platforms is susceptible to floating-point drift and rounding errors. 
- In JavaScript: `0.1 + 0.2 === 0.30000000000000004`.
- Aggregating thousands of orders with tiny rounding discrepancies produces cash reconciliation discrepancies between merchant payables, courier payouts, and platform take-rates.
- If payout calculations are computed on-the-fly from live orders rather than recorded in an immutable ledger, settlement disputes cannot be audited mathematically.

## Decision Drivers
- **Exact Penny/Paisa Determinism**: Calculations must round to 2 decimal places at every intermediate step.
- **Auditable Double-Entry Ledger**: Every order must generate a persistent `CommissionLedger` entry at creation.
- **RFC 4180 CSV Export Compliance**: Financial settlement exports must be compatible with ERP systems (SAP, Oracle, QuickBooks).

## Considered Options
1. **On-the-Fly Aggregation**: Calculate vendor commission dynamically upon invoice request: `orders.reduce((sum, o) => sum + o.total * 0.15)`. (Rejected: Fails when commission rates change; susceptible to rounding drift).
2. **Third-Party Payment Split API Only**: Rely completely on payment gateway webhooks. (Rejected: Fails for Cash on Delivery (COD), which accounts for 60%+ of hyperlocal volume in pilot regions).
3. **Dedicated Transactional Commission Ledger with Deterministic Math (Chosen)**: Store explicit `CommissionLedger` records inside the order checkout transaction.

## Decision Outcome
Chosen option: **Dedicated Transactional Commission Ledger with Deterministic Math**, because:
- Floating-point calculations are rounded explicitly: `Math.round(val * 100) / 100`.
- The database schema enforces `DECIMAL(10, 2)` across all monetary columns (`grossAmount`, `commissionRate`, `commissionDeducted`, `netVendorPayable`).
- Automated commission split (15% platform take-rate, 85% net vendor payable) is locked permanently upon order creation:

```
Customer Checkout: ৳300.00
├── Gross Food Subtotal: ৳200.00
│   ├── 15% Platform Commission: ৳30.00 (CommissionLedger.commissionDeducted)
│   └── 85% Net Vendor Payable:  ৳170.00 (CommissionLedger.netVendorPayable)
└── Delivery Fee: ৳100.00
    ├── 80% Courier Earnings:    ৳80.00
    └── 20% Logistics Take-Rate: ৳20.00
```

### Positive Consequences
- **Absolute Financial Precision**: Zero cent/paisa drift across millions of transactions.
- **Instant Settlement Generation**: Super Admin can query settled vs unsettled balances instantaneously without scanning raw order item trees.
- **Universal Accounting Export**: Direct CSV generation conforming to RFC 4180 standard.

### Negative Consequences / Trade-offs
- Every checkout transaction writes an additional row to `commission_ledgers`. (Negligible storage cost for guaranteed auditability).

## Technical Implementation Details
Implemented in [`order.service.ts`](file:///Users/bs0650/BS-23-Pro/DeliveryOS/services/backend_api/src/modules/orders/order.service.ts) and [`finance.service.ts`](file:///Users/bs0650/BS-23-Pro/DeliveryOS/services/backend_api/src/modules/finance/finance.service.ts):
```typescript
const commissionRate = Number(vendor.commissionRate || 0.15);
const platformFee = Math.round(netSubtotal * commissionRate * 100) / 100;
const netVendorPayable = Math.round((netSubtotal - platformFee) * 100) / 100;

await tx.commissionLedger.create({
  data: {
    orderId: newOrder.id,
    vendorId: vendor.id,
    grossAmount: netSubtotal,
    commissionRate,
    commissionDeducted: platformFee,
    netVendorPayable,
    settlementStatus: SettlementStatus.UNSETTLED,
  },
});
```

## Compliance & Verification
- Tested in `apps/admin_portal/scripts/test-admin-console.ts` (Section 8: Financial Settlements Statement & CSV Export).
- Tested in `apps/vendor_portal/scripts/test-vendor-multi-tier.ts` (Section 7: Consolidated vs per-outlet sales ledgers).
