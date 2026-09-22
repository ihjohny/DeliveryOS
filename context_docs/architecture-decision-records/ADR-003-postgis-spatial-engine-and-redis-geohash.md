# ADR-003: Tiered Spatial Architecture (PostGIS Ellipsoid Geofencing & Redis Geohash Radar)

## Status
Accepted (2026-09-19)

## Context & Problem Statement
Hyperlocal logistics requires handling two fundamentally different types of geographic calculations:
1. **Persistent Boundaries & Radius Coverage**: Validating whether a customer's delivery address falls within a merchant's 3–10 km delivery coverage radius.
2. **High-Frequency Courier Telemetry**: Tracking 50–500 active couriers reporting GPS coordinates every 3–5 seconds and discovering nearby online couriers within 3–5 km of a restaurant.

Handling high-frequency courier GPS pings with database disk writes leads to database connection pool exhaustion and table bloat. Conversely, storing authoritative merchant polygons or calculating spherical distances exclusively in application memory leads to distortion errors and slow full-table scans.

## Decision Drivers
- **Spherical Accuracy**: Earth's curvature must be accounted for over real-world geographies (Dhaka, Riyadh) to prevent coverage radius false positives.
- **Sub-Millisecond Search Latency**: Finding 10 nearby available couriers must complete in under 5 milliseconds.
- **Zero Database Write Contention**: High-frequency rider location updates must not write to relational disk tables on every ping.

## Considered Options
1. **All-in-PostgreSQL**: Store rider GPS pings directly into PostgreSQL via `UPDATE couriers SET location = ...`. (Rejected: Causes extreme write contention, vacuuming overhead, and disk I/O bottlenecks).
2. **All-in-Application Memory**: Keep merchants and riders in Node.js in-memory spatial trees (e.g. `rbush` or `kdbush`). (Rejected: Fails across multi-process clusters; loses data on process restart).
3. **Tiered Spatial Architecture (PostGIS + Redis) (Chosen)**: PostGIS for ACID coverage boundary queries; Redis Geospatial indexing (`GEOADD`/`GEORADIUS`) for live fleet telemetry.

## Decision Outcome
Chosen option: **Tiered Spatial Architecture**, because:
- **PostgreSQL 16 + PostGIS 3.4**: Uses `geography(Point, 4326)` with a GiST spatial index. PostGIS executes great-circle spherical distance over the WGS 84 ellipsoid via `ST_DWithin` in sub-milliseconds during checkout.
- **Redis 7.2 In-Memory Geohash**: Couriers stream pings to the WebSocket gateway, which executes in-memory `GEOADD fleet:riders <lon> <lat> <rider_id>`. Radius queries (`GEORADIUS`) execute in microseconds with zero relational database disk impact.

```
┌─────────────────────────────────────────────────────────────┐
│             Tier 1: Relational Spatial Engine               │
│  PostgreSQL 16 + PostGIS 3.4 (Host Port 5433)               │
│  - Authoritative merchant outlet coordinates                │
│  - Customer saved delivery addresses                        │
│  - Spatial index: CREATE INDEX USING GIST (location)        │
│  - Query: ST_DWithin(v.location, customer_pt, radius * 1000)│
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│             Tier 2: Volatile Geospatial Cache               │
│  Redis 7.2 In-Memory Key-Value Store (Host Port 6380)       │
│  - 52-bit integer Geohash indexing                          │
│  - High-frequency courier telemetry (GEOADD fleet:riders)   │
│  - Radius dispatch query: GEORADIUS fleet:riders 5 km       │
│  - Volatile telemetry hashes: rider:telemetry:<id>          │
└─────────────────────────────────────────────────────────────┘
```

### Positive Consequences
- **Zero Planar Distortion**: Distances are accurate to within centimeters regardless of global latitude.
- **Extreme High Concurrency**: Thousands of courier telemetry pings per minute cause 0% database CPU overhead.
- **Instant Dispatch Discovery**: `GEORADIUS` finds couriers near a restaurant in $<1$ ms.

### Negative Consequences / Trade-offs
- Requires maintaining two separate geospatial stores.
- Couriers' long-term historical breadcrumb tracks require async batching if persistent trip playback is needed later.

## Technical Implementation Details
- PostGIS setup automated via [`deploy/init-postgis.sql`](file:///Users/bs0650/BS-23-Pro/DeliveryOS/deploy/init-postgis.sql):
  ```sql
  CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
  CREATE EXTENSION IF NOT EXISTS "postgis";
  ```
- Coverage check implemented in [`vendor.service.ts`](file:///Users/bs0650/BS-23-Pro/DeliveryOS/services/backend_api/src/modules/vendors/vendor.service.ts).
- Courier tracking implemented in [`tracking.gateway.ts`](file:///Users/bs0650/BS-23-Pro/DeliveryOS/services/backend_api/src/modules/realtime/tracking.gateway.ts) and [`rider.service.ts`](file:///Users/bs0650/BS-23-Pro/DeliveryOS/services/backend_api/src/modules/riders/rider.service.ts).

## Compliance & Verification
- Validated via database initialization health check.
- Verified in `apps/admin_portal/scripts/test-admin-console.ts` (Section 3: Fleet Radar telemetry retrieval).
