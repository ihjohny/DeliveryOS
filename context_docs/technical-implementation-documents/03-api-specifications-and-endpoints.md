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
- **Response**:
```json
{
  "success": true,
  "statusCode": 200,
  "message": "OTP sent successfully",
  "data": { "retryAfterSeconds": 60 }
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
- **Response**:
```json
{
  "success": true,
  "statusCode": 200,
  "data": {
    "user": {
      "id": "c1f7a4e2-...",
      "phone": "+8801700000000",
      "fullName": "Tariq Ahmed",
      "role": "CUSTOMER",
      "status": "ACTIVE"
    },
    "accessToken": "eyJhbGciOi...",
    "refreshToken": "d8e3b1c..."
  }
}
```

---

## 3. Customer Discovery & Ordering Module

### 3.1 Get Nearby Vendors
- **Endpoint**: `GET /vendors/nearby`
- **Access**: Public / Authenticated
- **Query Params**:
  - `lat` (required, float): e.g. `23.780887`
  - `lng` (required, float): e.g. `90.419065`
  - `vertical` (optional, string): `FOOD` | `GROCERY` | `SUPER_SHOP`
- **Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": "v-101-...",
      "name": "Burger Spot",
      "vertical": "FOOD",
      "logoUrl": "https://cdn.../logo.png",
      "distanceKm": 1.45,
      "deliveryFee": 50.0,
      "isOpen": true,
      "rating": 4.8
    }
  ]
}
```

### 3.2 Validate Re-Order
- **Endpoint**: `POST /orders/validate-reorder`
- **Access**: Authenticated (`CUSTOMER`)
- **Request Body**:
```json
{
  "previousOrderId": "ord-uuid-..."
}
```
- **Response**:
```json
{
  "success": true,
  "data": {
    "isStoreOperational": true,
    "hasStockChanges": false,
    "validItems": [
      {
        "productId": "p-201-...",
        "name": "Classic Burger",
        "currentPrice": 250.0,
        "quantity": 2,
        "isAvailable": true
      }
    ],
    "unavailableItems": []
  }
}
```

### 3.3 Create Order Checkout
- **Endpoint**: `POST /orders/checkout`
- **Access**: Authenticated (`CUSTOMER`)
- **Request Body**:
```json
{
  "vendorId": "v-101-...",
  "deliveryAddressId": "addr-uuid-...",
  "paymentMethod": "CASH_ON_DELIVERY", // or "ONLINE_GATEWAY"
  "customerNotes": "Please leave at security desk",
  "items": [
    {
      "productId": "p-201-...",
      "quantity": 2,
      "variantId": "var-301-...",
      "addonIds": ["add-401-...", "add-402-..."]
    }
  ]
}
```
- **Response**:
```json
{
  "success": true,
  "statusCode": 201,
  "data": {
    "orderId": "ord-uuid-...",
    "orderNumber": "ORD-20261001-1042",
    "subtotal": 500.0,
    "deliveryFee": 50.0,
    "totalAmount": 550.0,
    "status": "PLACED"
  }
}
```

---

## 4. Vendor Store Console Module

### 4.1 Get Live Store Orders (Kitchen Display)
- **Endpoint**: `GET /vendor/orders/live`
- **Access**: Authenticated (`VENDOR_ADMIN`, `SUPER_ADMIN`)
- **Response**: Returns arrays of orders grouped by `PLACED`, `ACCEPTED`, `PREPARING`, `READY_FOR_PICKUP`.

### 4.2 Accept Incoming Order
- **Endpoint**: `PATCH /vendor/orders/:id/accept`
- **Request Body**:
```json
{
  "prepTimeMinutes": 20
}
```

### 4.3 Mark Order Ready for Pickup
- **Endpoint**: `PATCH /vendor/orders/:id/ready`
- **Action**: Transitions status to `READY_FOR_PICKUP` and broadcasts to nearby riders.

### 4.4 Toggle Product Stock Availability
- **Endpoint**: `PATCH /vendor/products/:id/stock`
- **Request Body**:
```json
{
  "isInStock": false
}
```

---

## 5. Rider Operations Module

### 5.1 Toggle Duty Status
- **Endpoint**: `PATCH /rider/duty`
- **Access**: Authenticated (`RIDER`)
- **Request Body**:
```json
{
  "isOnline": true
}
```

### 5.2 Claim Broadcasted Order
- **Endpoint**: `POST /rider/orders/:id/claim`
- **Action**: Claims order via atomic distributed lock (Redis mutex). Returns 409 Conflict if already claimed by another rider.

### 5.3 Order Picked Up (Step 2)
- **Endpoint**: `PATCH /rider/orders/:id/pickup`
- **Action**: Transitions status to `DISPATCHED`.

### 5.4 Order Delivered (Step 3)
- **Endpoint**: `PATCH /rider/orders/:id/deliver`
- **Request Body**:
```json
{
  "codCashCollected": true,
  "amountCollected": 550.0
}
```
- **Action**: Transitions status to `DELIVERED`, updates rider cash ledger, and closes the trip.

---

## 6. Super Admin Master Governance Module

### 6.1 Real-Time Fleet Radar
- **Endpoint**: `GET /admin/fleet`
- **Access**: Authenticated (`SUPER_ADMIN`)
- **Response**: List of all online riders with current latitude, longitude, and active trip status.

### 6.2 Manual Dispatch Override
- **Endpoint**: `POST /admin/orders/:id/force-assign`
- **Access**: Authenticated (`SUPER_ADMIN`)
- **Request Body**:
```json
{
  "riderId": "rider-uuid-..."
}
```

### 6.3 Update Delivery Fee Settings
- **Endpoint**: `PATCH /admin/settings/delivery-fee`
- **Access**: Authenticated (`SUPER_ADMIN`)
- **Request Body**:
```json
{
  "mode": "FIXED_FLAT", // or "DISTANCE_TIERED"
  "flatRate": 50.0,
  "baseFee": 30.0,
  "baseKm": 2.0,
  "perKmRate": 10.0
}
```

### 6.4 Update Order Flow Sequence Settings
- **Endpoint**: `PATCH /admin/settings/order-flow`
- **Access**: Authenticated (`SUPER_ADMIN`)
- **Request Body**:
```json
{
  "mode": "RIDER_FIRST", // "RIDER_FIRST" (Zero Food Waste) | "VENDOR_FIRST" | "PARALLEL"
  "riderSearchTimeoutSeconds": 90
}
```

### 6.5 Export Vendor Settlement Report
- **Endpoint**: `GET /admin/finance/settlement-export`
- **Query Params**: `startDate=2026-10-01&endDate=2026-10-07&format=csv`
- **Response**: Downloadable CSV file containing vendor earnings and platform commissions.
