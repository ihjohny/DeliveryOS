# ADR-005: Micro-Frontend Separation & Nginx Subpath Proxying (`/` vs `/vendor/`)

## Status
Accepted (2026-09-21)

## Context & Problem Statement
The platform requires two distinct web management consoles:
1. **Super Admin Console**: Authoritative system-wide platform governance (fleet radar, dispatch overrides, system settings, global financial statements).
2. **Vendor Kitchen Console (KDS)**: Store-level kitchen display system, instant out-of-stock board, preparation countdown timers, and brand outlet switching.

Originally, consideration was given to bundling both into a single large React application. However, this created role leakage risks, theme collisions (Enterprise Indigo vs Culinary Amber), large bundle sizes, and security audit concerns. We separated them into two distinct React Vite Single Page Applications (SPAs) that must run smoothly behind a single Nginx reverse proxy on port `8080`.

## Decision Drivers
- **Strict Role Isolation**: Super Admin code and components must not exist in the bundle downloaded by kitchen staff.
- **Independent Visual Design Systems**: Admin uses an authoritative Indigo/Slate palette; Vendor uses a high-contrast culinary Amber/Orange palette designed for kitchen tablets.
- **Single Public Port**: Both portals must be accessible through the main ingress port (`8080`) without exposing raw internal container ports (`3000`, `3001`).
- **Session & Storage Isolation**: An admin testing both portals simultaneously on the same browser origin must not suffer session token overwrites.

## Considered Options
1. **Monolithic Unified React SPA**: Both portals in one codebase with role-based routing. (Rejected: Code leakage, asset bundle bloat, theme collision).
2. **Subdomain Routing (`admin.deliveryos.local` vs `vendor.deliveryos.local`)**: Requires complex local DNS setup or `/etc/hosts` file modifications. (Rejected: High friction for developer onboarding and AI agents).
3. **Dedicated React SPAs with Nginx Subpath Routing (Chosen)**:
   - Super Admin served on `/` (proxied to `admin_portal:80`)
   - Vendor KDS served on `/vendor/` (proxied to `vendor_portal:80`)

## Decision Outcome
Chosen option: **Dedicated React SPAs with Nginx Subpath Routing**, configured as follows:
- **`apps/admin_portal`**: Configured with Vite `base: '/'` and React Router `basename: '/'`.
- **`apps/vendor_portal`**: Configured with Vite `base: '/vendor/'` and React Router `basename: '/vendor'`.
- **LocalStorage Namespace Isolation**:
  - Admin Portal uses `deliveryos_admin_auth` and `deliveryos_admin_token`.
  - Vendor Portal uses `deliveryos_vendor_auth` and `deliveryos_vendor_token`.

### Positive Consequences
- **Zero Asset 404s**: All JS/CSS bundles in `vendor_portal` load from `/vendor/assets/...` cleanly.
- **Zero Session Collisions**: Logging into Super Admin and Vendor KDS in separate browser tabs on `localhost:8080` preserves independent JWT sessions.
- **Tight Security Boundaries**: Super Admin cannot access `/vendor/` (must use Admin Portal); Vendor Admin cannot access `/admin`.

### Negative Consequences / Trade-offs
- Nginx configuration must cleanly rewrite HTML5 history API routes using `try_files` for both root and subpath contexts.

## Technical Implementation Details
In [`deploy/nginx.local.conf`](file:///Users/bs0650/BS-23-Pro/DeliveryOS/deploy/nginx.local.conf):
```nginx
# Super Admin Portal (Root)
location / {
    proxy_pass http://admin_portal:80;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}

# Vendor KDS Portal (Subpath)
location /vendor/ {
    proxy_pass http://vendor_portal:80/vendor/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
```

In [`apps/vendor_portal/vite.config.ts`](file:///Users/bs0650/BS-23-Pro/DeliveryOS/apps/vendor_portal/vite.config.ts):
```typescript
export default defineConfig({
  base: '/vendor/',
  plugins: [react()],
});
```

## Compliance & Verification
- Validated by scaffolding and route guard tests in `apps/admin_portal/scripts/test-scaffolding.ts` and `apps/vendor_portal/scripts/test-scaffolding.ts`.
- Ingress verified via HTTP 200 headers on both `curl http://localhost:8080/` and `curl http://localhost:8080/vendor/`.
