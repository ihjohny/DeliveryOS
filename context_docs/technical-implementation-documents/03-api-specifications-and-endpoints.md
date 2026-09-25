# 03 — API Specifications & Endpoints

This document specifies the authoritative RESTful API contracts for the **DeliveryOS** backend (`/api/v1`). All endpoints follow standardized JSON envelopes, HTTP status codes, and strict TypeScript DTO definitions.

---

## 1. Global API Standards

- **Base URL**: `https://api.domain.com/api/v1` (locally `http://localhost:8080/api/v1`)
- **Content-Type**: `application/json`
- **Authentication**: Bearer Token in `Authorization: Bearer <jwt_access_token>`

### Standard Success Response Envelope:
```json
{
  "success": true,
  "statusCode": 200,
  "message": "Operation successful",
  "data": {}
}
```

### Standard Error Response Envelope:
```json
{
  "success": false,
  "statusCode": 400,
  "error": "BAD_REQUEST",
  "message": "Detailed human-readable error description",
  "timestamp": "2026-10-01T12:00:00.000Z"
}
```

---

## 2. Authentication & User Profile Module (`/auth`)

### 2.1 Request Phone OTP
- **Endpoint**: `POST /auth/phone-login`
- **Access**: Public (Rate-limited: 5 requests / 15 min per IP/phone)
- **Request Body**:
```json
{
  "phone": "+8801700000000",
  "role": "CUSTOMER" // "CUSTOMER" | "RIDER" | "VENDOR_ADMIN"
}
```
- **Response**: `{ "success": true, "message": "OTP sent successfully", "data": { "referenceId": "otp-uuid" } }`

### 2.2 Verify Phone OTP & Issue JWT
- **Endpoint**: `POST /auth/verify-otp`
- **Access**: Public
- **Request Body**:
```json
{
  "phone": "+8801700000000",
  "otp": "123456"
}
```
- **Response**: Returns `{ "accessToken": "jwt...", "user": { "id": "...", "phone": "...", "role": "..." } }`

### 2.3 Get Current User Session
- **Endpoint**: `GET /auth/me`
- **Access**: Authenticated (`JwtAuthGuard`)
- **Response**: Returns current authenticated user record with permissions and profile metadata.

### 2.4 Register FCM Device Token
- **Endpoint**: `POST /auth/device-token`
- **Access**: Authenticated (`JwtAuthGuard`)
- **Request Body**:
```json
{
  "fcmToken": "fcm-registration-token-string",
  "devicePlatform": "ANDROID" // "ANDROID" | "IOS" | "WEB"
}
```

---

## 3. Customer Discovery, Cart & Checkout Module (`/vendors`, `/orders`, `/coupons`, `/banners`)

### 3.1 Get Active Promotional Banners
- **Endpoint**: `GET /banners/active`
- **Access**: Public
- **Response**: Returns sorted list of active banners with `imageUrl`, `title`, and deep-link target metadata.

### 3.2 Get Nearby Outlets by Location
- **Endpoint**: `GET /vendors/nearby`
- **Access**: Public / Authenticated
- **Query Params**: `lat` (required), `lng` (required), `vertical` (optional: `FOOD` | `GROCERY` | `SUPER_SHOP` | `PHARMACY`)
- **Action**: Queries PostGIS using `ST_DWithin` returning active outlets within their `delivery_radius_km`.

### 3.3 Search Outlets & Menu Items
- **Endpoint**: `GET /vendors/search`
- **Access**: Public / Authenticated
- **Query Params**: `q` (keyword query), `lat` (optional), `lng` (optional)
- **Response**: Matches outlet names and individual dish/item names available within range.

### 3.4 Get Public Storefront Catalog
- **Endpoint**: `GET /vendors/:id/catalog`
- **Access**: Public / Authenticated
- **Response**: Returns categories and products marked `isInStock = true`.

### 3.5 Validate Address Delivery Coverage
- **Endpoint**: `POST /vendors/validate-address-coverage`
- **Access**: Authenticated (`CUSTOMER`)
- **Request Body**:
```json
{
  "vendorId": "vendor-uuid",
  "addressId": "address-uuid"
}
```
- **Response**: `{ "isWithinCoverage": true, "distanceKm": 2.4, "deliveryFee": 50.0 }`

### 3.6 Validate Promotional Coupon
- **Endpoint**: `POST /coupons/validate`
- **Access**: Authenticated (`CUSTOMER`)
- **Request Body**:
```json
{
  "code": "WELCOME50",
  "cartSubtotal": 500.0,
  "vendorId": "vendor-uuid"
}
```

### 3.7 Place Order Checkout
- **Endpoint**: `POST /orders/checkout`
- **Access**: Authenticated (`CUSTOMER`)
- **Request Body**:
```json
{
  "vendorId": "vendor-uuid",
  "deliveryAddressId": "address-uuid",
  "deliveryMethod": "HOME_DELIVERY",
  "paymentMethod": "CASH_ON_DELIVERY", // or "ONLINE_GATEWAY"
  "couponCode": "WELCOME50",
  "customerNotes": "Please do not ring bell",
  "items": [
    {
      "productId": "product-uuid",
      "quantity": 2,
      "variantId": "variant-uuid",
      "addonIds": ["addon-uuid-1"]
    }
  ]
}
```

### 3.8 Validate Past Order for Re-Order
- **Endpoint**: `POST /orders/validate-reorder`
- **Access**: Authenticated (`CUSTOMER`)
- **Request Body**: `{ "previousOrderId": "order-uuid" }`
- **Response**: Returns store open status, unavailable item list, and price changes.

### 3.9 Customer Order History & Tracking
- **List Orders**: `GET /orders/history` (sorted with newest orders first)
- **Order Details**: `GET /orders/:id`
- **Live Tracking**: `GET /orders/:id/live-tracking` (returns stage, assigned courier coordinates, and ETA)
- **Switch to Cash on Delivery (COD)**: `POST /orders/:id/switch-cod` (converts failed or pending online payments to cash)
- **Cancel Order**: `POST /orders/:id/cancel` (permitted in `PLACED` or `RIDER_ASSIGNED` stages)

---

## 4. Vendor Store & Kitchen Console Module (`/vendor`)

> **Access Control**: Authenticated `VENDOR_ADMIN` or `SUPER_ADMIN`. Multi-branch operations enforce `PARTICULAR_OUTLET` vs `ALL_OUTLETS_MASTER` scopes ([ADR-005](context_docs/architecture-decision-records/ADR-005-micro-frontends-and-subpath-routing.md)).

### 4.1 Merchant Profile & Outlets
- **Get Staff Profile**: `GET /vendor/me` (returns assigned outlet ID and scope)
- **List Accessible Outlets**: `GET /vendor/outlets` (returns outlet list for brand switcher)

### 4.2 KDS Live Queue & Progression
- **Get Live KDS Orders**: `GET /vendor/orders/live?vendorId=...`
- **Accept Incoming Order**: `PATCH /vendor/orders/:id/accept`
  - Request Body: `{ "prepTimeMinutes": 25 }` (transitions directly to `PREPARING` per ADR-002)
- **Reject Incoming Order**: `POST /vendor/orders/:id/reject`
  - Request Body: `{ "reasonCode": "OUT_OF_STOCK", "reasonNotes": "Ran out of ingredients" }`
- **Mark Order Ready**: `PATCH /vendor/orders/:id/ready` (transitions to `READY_FOR_PICKUP`)
- **Confirm Handover**: `PATCH /vendor/orders/:id/handover` (transitions to `DISPATCHED`)

### 4.3 Merchant Menu Catalog & Instant Stock Toggles
- **Get Full Merchant Catalog**: `GET /vendor/catalog?vendorId=...`
  - *Invariant*: Retains all items including out-of-stock items, returning `totalInStock` vs `totalOutOfStock`.
- **Toggle Product Stock**: `PATCH /vendor/products/:id/stock`
  - Request Body: `{ "isInStock": false }`
- **Toggle Variant Stock**: `PATCH /vendor/products/variants/:id/stock`
  - Request Body: `{ "isInStock": false }`

### 4.4 Operational Timings & Rush Hour Controls
- **Get Store Operations Settings**: `GET /vendor/settings?vendorId=...`
- **Update Store Operations**: `PATCH /vendor/settings`
  - Request Body: `{ "vendorId": "...", "isBusy": true, "defaultPrepTimeMinutes": 25 }`
- **Save Weekly Operating Schedule**: `PUT /vendor/operating-hours`
  - Request Body: Array of 7 day schedules with `dayOfWeek`, `openTime`, `closeTime`, `isClosed`.

### 4.5 Sales Ledgers & Performance
- **Get Sales Ledger**: `GET /vendor/sales?vendorId=...&dateFilter=TODAY` (or `ALL_TIME`)
  - Response: Completed orders count, gross volume, commission deducted, net payable, and itemized receipts.

---

## 5. Rider Operations Module (`/riders`, `/orders`)

### 5.1 Courier Duty & Profile
- **Get Rider Profile**: `GET /riders/profile` (returns active status, vehicle, cash in hand, safety limit)
- **Toggle Shift Duty**: `PATCH /riders/duty`
  - Request Body: `{ "isOnline": true, "latitude": 23.7925, "longitude": 90.4078 }`
  - *Invariant*: Returns `400 Bad Request` if attempting to go offline while carrying an active delivery (`RIDER_ASSIGNED` or `DISPATCHED`).

### 5.2 Dispatch Claim Mutex
- **Claim Broadcasted Order**: `POST /riders/orders/:id/claim`
  - Backed by atomic Redis `SET resource_lock token NX EX 45` ([ADR-004](context_docs/architecture-decision-records/ADR-004-atomic-dispatch-claim-mutex.md)).

### 5.3 3-Step Sequential Fulfillment
- **Step 1 — Confirm Pickup**: `POST /orders/:id/pickup` (transitions to `DISPATCHED`)
- **Step 2 — Doorstep Arrival**: Handled via mobile UI progression to handover step.
- **Step 3 — Confirm Delivery & COD**: `POST /orders/:id/deliver`
  - Request Body: `{ "codCashCollected": true, "amountCollected": 500.0 }` (transitions to `DELIVERED`)

### 5.4 Doorstep Failure Reporting (5-Minute SOP)
- **Report Delivery Issue**: `POST /orders/:id/issue`
  - Request Body: `{ "reason": "Customer unreachable at doorstep after 5 min wait" }`
  - Action: Unlocks courier, returns order to Dispatch HQ, and logs failure audit trail.

### 5.5 Shift Earnings & COD Cash Settlement
- **Get Daily Trips & Earnings**: `GET /riders/trips?timeframe=TODAY` (or `THIS_WEEK`)
- **Submit Cash Deposit at Hub**: `POST /riders/deposit-cash`
  - Request Body: `{ "amount": 2500.0, "referenceNo": "HUB-DEP-9821", "note": "Cash deposit at Banani Hub" }`

---

## 6. Super Admin Master Governance Module (`/admin`)

### 6.1 Platform Operational Overview
- **Get Operational Overview**: `GET /admin/overview` (active orders, revenue, active couriers, pending applicants)
- **List All Orders**: `GET /admin/orders` (filterable by `status`, `dateRange`, `search`)
- **Force-Assign Courier**: `POST /admin/orders/:id/force-assign`
  - Request Body: `{ "riderId": "rider-uuid" }`
- **Force-Cancel Order**: `POST /admin/orders/:id/cancel`
  - Request Body: `{ "reason": "Fraudulent address reported by customer support" }` (min 5 chars)

### 6.2 Courier Fleet Governance
- **List Fleet & Radar**: `GET /admin/riders?approvalStatus=ALL` (or `PENDING`, `APPROVED`)
- **Toggle Courier Approval**: `PATCH /admin/riders/:id/approval`
  - Request Body: `{ "isApproved": true }`
- **Update Cash Safety Limit**: `PATCH /admin/riders/:id/cash-limit`
  - Request Body: `{ "maxCashLimit": 8000.0 }`

### 6.3 Vendor Management & Onboarding
- **List Vendors**: `GET /admin/vendors`
- **Create Vendor Directly**: `POST /admin/vendors`
- **Update Vendor Details**: `PATCH /admin/vendors/:id`
- **Update Vendor Status**: `PATCH /admin/vendors/:id/status` (`ACTIVE`, `SUSPENDED`, `PENDING_APPROVAL`)
- **Assign Vendor Staff**: `POST /admin/vendors/:id/staff`

### 6.4 Promotions & Master Catalog
- **Banner CRUD**: `GET /admin/banners`, `POST /admin/banners`, `PATCH /admin/banners/:id`, `DELETE /admin/banners/:id`
- **Coupon CRUD**: `GET /admin/coupons`, `POST /admin/coupons`, `PATCH /admin/coupons/:id`, `DELETE /admin/coupons/:id`
- **Central Categories**: `GET /admin/catalog/categories`, `POST /admin/catalog/categories`

### 6.5 System Settings & Engine Configuration
- **Get System Settings**: `GET /admin/settings`
- **Update Order Flow FSM**: `PATCH /admin/settings/order-flow` (`RIDER_FIRST` vs `VENDOR_FIRST`)
- **Update Delivery Fee Mode**: `PATCH /admin/settings/delivery-fee` (`FIXED_FLAT` vs `DISTANCE_TIERED`)

### 6.6 Financial Accounting & Settlements
- **Export Settlements (CSV / JSON)**: `GET /admin/finance/settlement-export?format=csv` (or `format=json`)
- **List Historical Settlement Batches**: `GET /admin/finance/settlement-batches`
- **Execute Settlement Cycle**: `POST /admin/finance/settlement-cycle`
  - Request Body: `{ "notes": "Weekly settlement payout cycle" }`
- **List Cash Deposits**: `GET /admin/finance/cash-deposits`
- **Verify Cash Deposit**: `PATCH /admin/finance/cash-deposits/:id/verify`
  - Request Body: `{ "status": "APPROVED" }`

---

## 7. Online Payment Gateways Module (`/payments`)

### 7.1 Initiate Payment Session
- **Endpoint**: `POST /payments/initiate`
- **Guards**: `JwtAuthGuard`
- **Request Body**: `{ "orderId": "order-uuid", "gateway": "BKASH" }` (or `MOYASAR`, `STRIPE`)
- **Response**: `{ "paymentUrl": "https://gateway.com/pay/...", "transactionId": "TXN-...", "amount": 450.0 }`

### 7.2 Webhook Ingress (Cryptographic IPN)
- **Endpoint**: `POST /payments/webhook/:gateway`
- **Guards**: HMAC signature validation (`x-webhook-signature`)
- **Action**: Idempotent database transaction lock; updates `payments.status = PAID` and triggers order progression.

### 7.3 Payment Status Check
- **Endpoint**: `GET /payments/status/:transactionId`
- **Guards**: `JwtAuthGuard`
- **Response**: `{ "status": "PAID", "paidAt": "2026-09-25T12:00:00Z" }`

---

## 8. Customer Saved Addresses Module (`/addresses`)

- **List Addresses**: `GET /addresses`
- **Create Address**: `POST /addresses`
- **Update Address**: `PUT /addresses/:id`
- **Delete Address**: `DELETE /addresses/:id`
- **Set Default Address**: `PATCH /addresses/:id/default`

---

## 9. Infrastructure & Health Module (`/health`, `/geo`)

- **Health Probe**: `GET /health` (returns database connection status and Redis ping)
- **Reverse Geocoding**: `GET /geo/reverse-geocode?lat=23.7925&lng=90.4078` (backed by OSM Nominatim with 24-hour Redis caching)
