# 03 — API Specifications & Endpoints

This document specifies the RESTful API endpoints for the **DeliveryOS** backend (`/api/v1`). All endpoints follow standardized JSON envelopes and status codes.

---

## 1. Global API Standards

- **Base URL**: `https://api.domain.com/api/v1`
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

## 2. Authentication & Profile Module

### 2.1 Request Phone OTP
- **Endpoint**: `POST /auth/otp/request`
- **Access**: Public (Rate-limited: 3 requests/5 min per IP/phone)
- **Request Body**:
```json
{
  "phone": "+8801700000000",
  "role": "CUSTOMER" // "CUSTOMER" | "RIDER"
}
```

### 2.2 Verify Phone OTP & Issue Tokens
- **Endpoint**: `POST /auth/otp/verify`
- **Access**: Public
- **Request Body**:
```json
{
  "phone": "+8801700000000",
  "otp": "123456"
}
```

---

## 3. Customer Discovery, Cart & Ordering Module

### 3.1 Get Active Promotional Banners
- **Endpoint**: `GET /banners/active`
- **Access**: Public
- **Response**: Returns sorted list of active home screen banners with deep-link metadata (outlet, category, or web campaign).

### 3.2 Get Nearby Outlets by Location
- **Endpoint**: `GET /vendors/nearby`
- **Access**: Public / Authenticated
- **Query Params**: `lat` (required), `lng` (required), `vertical` (optional: `FOOD` | `GROCERY` | `SUPER_SHOP`)
- **Action**: Queries PostGIS using `ST_DWithin` to return only outlets whose delivery coverage encompasses the coordinates.

### 3.3 Search Outlets & Menu Items
- **Endpoint**: `GET /vendors/search`
- **Access**: Public / Authenticated
- **Query Params**: `q` (keyword), `lat`, `lng`
- **Response**: Grouped results matching outlet names and individual dish/item names available within delivery radius.

### 3.4 Cart Address Coverage Check (Geofence Guard)
- **Endpoint**: `POST /cart/validate-address-coverage`
- **Access**: Authenticated (`CUSTOMER`)
- **Request Body**:
```json
{
  "vendorId": "v-101-...",
  "addressId": "addr-uuid-..."
}
```
- **Response (Valid)**:
```json
{
  "success": true,
  "data": {
    "isWithinCoverage": true,
    "distanceKm": 2.3,
    "deliveryFee": 50.0
  }
}
```
- **Response (Out of Coverage)**:
```json
{
  "success": false,
  "statusCode": 422,
  "error": "ADDRESS_OUT_OF_COVERAGE",
  "message": "Selected address is outside this outlet's delivery coverage radius."
}
```

### 3.5 Validate Coupon Code
- **Endpoint**: `POST /coupons/validate`
- **Access**: Authenticated (`CUSTOMER`)
- **Request Body**:
```json
{
  "code": "WELCOME50",
  "cartSubtotal": 500.0,
  "vendorId": "v-101-..."
}
```
- **Response**:
```json
{
  "success": true,
  "data": {
    "isValid": true,
    "couponId": "c-901-...",
    "discountAmount": 50.0,
    "finalSubtotal": 450.0
  }
}
```

### 3.6 Create Order Checkout
- **Endpoint**: `POST /orders/checkout`
- **Access**: Authenticated (`CUSTOMER`)
- **Request Body**:
```json
{
  "vendorId": "v-101-...",
  "deliveryAddressId": "addr-uuid-...",
  "deliveryMethod": "HOME_DELIVERY", // or "TAKEAWAY"
  "paymentMethod": "CASH_ON_DELIVERY", // or "ONLINE_GATEWAY"
  "couponCode": "WELCOME50",
  "customerNotes": "Please ring door bell",
  "items": [
    {
      "productId": "p-201-...",
      "quantity": 2,
      "variantId": "var-301-...",
      "addonIds": ["add-401-..."]
    }
  ]
}
```

### 3.7 Validate Re-Order
- **Endpoint**: `POST /orders/validate-reorder`
- **Access**: Authenticated (`CUSTOMER`)
- **Request Body**: `{ "previousOrderId": "ord-uuid-..." }`
- **Action**: Validates outlet operating hours, address geofence coverage, and active stock availability for all items/variants.

---

## 4. Vendor Store Console Module (`/vendor`)

> **Role Access & Portal Isolation Note**:
> - The standalone **Vendor Portal** (`/vendor`) is exclusively accessed by authenticated `VENDOR_ADMIN` users.
> - The underlying `/api/v1/vendor/*` endpoints permit both `VENDOR_ADMIN` (for store staff/managers) and `SUPER_ADMIN` (when platform administrators inspect, govern, or perform overrides on vendor data directly through the Super Admin Console).

### 4.1 Get Live Store Orders (Kitchen Display)
- **Endpoint**: `GET /vendor/orders/live`
- **Access**: Authenticated (`VENDOR_ADMIN`, `SUPER_ADMIN`)
- **Scope Enforced**: Restricted to user's assigned outlet (`vendor_id`) if `PARTICULAR_OUTLET` scope. When accessed by `SUPER_ADMIN`, outlet scope is not restricted.

### 4.2 Accept Incoming Order
- **Endpoint**: `PATCH /vendor/orders/:id/accept`
- **Access**: Authenticated (`VENDOR_ADMIN`, `SUPER_ADMIN`)
- **Request Body**:
```json
{
  "prepTimeMinutes": 25 // Optional: if omitted/null, backend defaults to outlet's default_prep_time_minutes
}
```

### 4.3 Mark Order Ready for Pickup
- **Endpoint**: `PATCH /vendor/orders/:id/ready`
- **Action**: Transitions status to `READY_FOR_PICKUP` and notifies the waiting rider.

### 4.4 Confirm Handover to Rider
- **Endpoint**: `PATCH /vendor/orders/:id/handover`
- **Action**: Confirms physical food transfer at the counter and transitions status to `DISPATCHED`.

### 4.5 Toggle Product & Variant Stock Availability
- **Endpoint**: `PATCH /vendor/products/:id/stock`
- **Request Body**: `{ "isInStock": false }`

---

## 5. Rider Operations Module

### 5.1 Toggle Duty Status
- **Endpoint**: `PATCH /rider/duty`
- **Access**: Authenticated (`RIDER`)
- **Request Body**: `{ "isOnline": true }`

### 5.2 Claim Broadcasted Order
- **Endpoint**: `POST /rider/orders/:id/claim`
- **Action**: Atomically locks and claims the incoming delivery trip via Redis mutex.

### 5.3 Confirm Pickup at Store (Step 2)
- **Endpoint**: `PATCH /rider/orders/:id/pickup`
- **Action**: Transitions status to `DISPATCHED` and activates live GPS location streaming.

### 5.4 Confirm Delivery & COD Collection (Step 3)
- **Endpoint**: `PATCH /rider/orders/:id/deliver`
- **Request Body**:
```json
{
  "codCashCollected": true,
  "amountCollected": 500.0
}
```

### 5.5 Deposit COD Cash at Hub / Settlement
- **Endpoint**: `POST /rider/cash/deposit`
- **Access**: Authenticated (`RIDER`)
- **Request Body**:
```json
{
  "amount": 2500.0,
  "reference": "BANK-TXN-1234",
  "notes": "End of shift cash deposit at Banani hub"
}
```
- **Response**: Returns updated `cashInHand` and records `cash_deposits` transaction.

---

## 5.1 Geospatial Engine Module (`/geo`)

### Reverse Geocode Coordinates
- **Endpoint**: `GET /geo/reverse-geocode`
- **Access**: Public / Authenticated
- **Query Params**: `lat` (required), `lng` (required)
- **Response**: Returns structured address object with `addressLine` and `displayName`, backed by OpenStreetMap Nominatim and 24-hour Redis caching.

---

## 6. Super Admin Master Governance Module (`/admin`)

### 6.1 Promotional Banner Management
- **List Banners**: `GET /admin/banners`
- **Create Banner**: `POST /admin/banners`
- **Update/Toggle Banner**: `PATCH /admin/banners/:id`
- **Delete Banner**: `DELETE /admin/banners/:id`

### 6.2 Coupon Code Management
- **List Coupons**: `GET /admin/coupons`
- **Create Coupon**: `POST /admin/coupons`
- **Update Coupon**: `PATCH /admin/coupons/:id`
- **Delete Coupon**: `DELETE /admin/coupons/:id`

### 6.3 Rider Fleet & Approval Management
- **List Fleet / Live Radar**: `GET /admin/fleet`
- **Approve Rider Account**: `PATCH /admin/riders/:id/approve`
- **Update Cash Safety Limit**: `PATCH /admin/riders/:id/cash-limit`

### 6.4 Vendor Onboarding & Staff Permission Management
- **Approve Vendor Application**: `PATCH /admin/vendors/:id/approve`
- **Create Vendor Directly**: `POST /admin/vendors`
- **Assign Vendor Staff & Permission Scope**: `POST /admin/vendors/:id/staff`
```json
{
  "userId": "user-uuid-...",
  "scope": "PARTICULAR_OUTLET", // or "ALL_OUTLETS_MASTER"
  "role": "BRANCH_MANAGER"
}
```

### 6.5 Master Catalog Authority
- **Create Central Category**: `POST /admin/catalog/categories`
- **Global Item Override**: `PUT /admin/catalog/products/:id/override`
- **Disable Product Across Stores**: `PATCH /admin/catalog/products/:id/disable`

### 6.6 Manual Dispatch Override
- **Endpoint**: `POST /admin/orders/:id/force-assign`
- **Request Body**: `{ "riderId": "rider-uuid-..." }`

### 6.7 Order Flow & Delivery Fee Settings
- **Update Order Flow**: `PATCH /admin/settings/order-flow` (`RIDER_FIRST` vs `VENDOR_FIRST`)
- **Update Delivery Fee Mode**: `PATCH /admin/settings/delivery-fee` (`FIXED_FLAT` vs `DISTANCE_TIERED`)
- **Export Settlements**: `GET /admin/finance/settlement-export`

### 6.8 Automated Settlement Cycles & Batches
- **Execute Batch Settlement**: `POST /admin/finance/settle-cycle`
- **List Historical Settlement Batches**: `GET /admin/finance/settlement-batches`

---

## 7. Online Payment Gateway Module (`/payments`)

### 7.1 Initiate Payment Session
- **Endpoint**: `POST /payments/initiate`
- **Guards**: `JwtAuthGuard`
- **Payload**:
```json
{
  "orderId": "order-uuid",
  "gateway": "BKASH" // "BKASH" | "SSLCOMMERZ" | "SANDBOX"
}
```
- **Response**: `{ "paymentUrl": "...", "transactionId": "...", "amount": 450 }`

### 7.2 Webhook Ingress (Cryptographic IPN)
- **Endpoint**: `POST /payments/webhook/:gateway`
- **Guards**: Public IPN with HMAC signature verification (`x-webhook-signature`)
- **Payload**: Gateway specific payload with transaction status and reference
- **Invariants**: Idempotent replay, triggers `handleOrderPaid(orderId)` upon verification confirming `PAID`.

### 7.3 Payment Status Check
- **Endpoint**: `GET /payments/status/:orderId`
- **Guards**: `JwtAuthGuard`

---

## 8. Customer Address Book & Profile Management (`/customers`)

### 8.1 Address Book CRUD
- **List Addresses**: `GET /customers/addresses` (sorted with default address first)
- **Create Address**: `POST /customers/addresses`
```json
{
  "label": "Home",
  "addressLine": "House 12, Road 4, Block B, Banani, Dhaka",
  "buildingFloor": "Flat 4A, 4th Floor",
  "deliveryNote": "Ring bell twice",
  "latitude": 23.7925,
  "longitude": 90.4078,
  "isDefault": true
}
```
- **Update Address**: `PUT /customers/addresses/:id`
- **Delete Address**: `DELETE /customers/addresses/:id`
- **Promote Default**: `PATCH /customers/addresses/:id/default` (Atomic default reassignment)

### 8.2 Customer Profile
- **Get Profile**: `GET /customers/profile` (returns name, email, phone, order count, address count)
- **Update Profile**: `PATCH /customers/profile` (update `fullName`, `email`)

