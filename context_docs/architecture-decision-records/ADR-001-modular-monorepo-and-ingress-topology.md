# ADR-001: Modular Monorepo Architecture & Nginx Edge Ingress Topology

## Status
Accepted (2026-09-18)

## Context & Problem Statement
DeliveryOS is a multi-stakeholder ecosystem comprising four distinct frontends (Customer Mobile App, Rider Mobile App, Super Admin Console, and Vendor Kitchen Console), a centralized backend API, real-time WebSocket streaming, and persistent/caching data stores.

We needed an architectural layout that allows rapid iteration, shared business contracts, simplified local development for both humans and AI agents, and a unified production deployment boundary without introducing the network and distributed tracing overhead of separate repositories or microservice network hops.

## Decision Drivers
- **Cognitive Cohesion**: Frontends, backend, and data models must evolve together under shared TypeScript and Dart types.
- **AI Agent Context Window Efficiency**: An AI coding agent must be able to explore the client and server code in a single workspace.
- **Zero-Port Collision Edge Ingress**: A single unified public port (`8080`) must route to the appropriate micro-frontend or API service seamlessly.
- **Production Parity**: Local Docker Compose setup must reflect production Nginx reverse proxying.

## Considered Options
1. **Multi-Repo Architecture**: Separate git repositories for backend, admin portal, vendor portal, customer app, and rider app.
2. **Polyrepo with Microservices**: Microservice backend (Auth service, Order service, Dispatch service) with independent repositories.
3. **Modular Monorepo with Nginx Edge Ingress (Chosen)**: Single repository with `/apps`, `/services`, `/deploy`, and a centralized Nginx edge reverse proxy routing all traffic through port `8080`.

## Decision Outcome
Chosen option: **Modular Monorepo with Nginx Edge Ingress**, because:
- It eliminates the overhead of managing multiple git remotes, version drift, and multi-repo CI/CD orchestration.
- A single `docker compose -f deploy/docker-compose.yml up -d` spins up the entire working environment (Postgres, Redis, Backend API, Admin Portal, Vendor Portal, Nginx) deterministically.
- Nginx acts as the single entry point, managing SSL termination, rate limiting, and subpath routing.

### Positive Consequences
- Immediate local verification of end-to-end flows.
- Clean directory layout separating presentation (`apps/`), domain logic (`services/`), and orchestration (`deploy/`).
- Seamless path-based routing: `/` routes to Super Admin, `/vendor/` routes to Vendor KDS, `/api/v1/` routes to NestJS API, and `/events` routes to Socket.IO.

### Negative Consequences / Trade-offs
- Monorepo git repository size is larger than individual repos.
- Build artifacts must be strictly cached to avoid rebuilds of unchanged apps.

## Technical Implementation Details

```text
DeliveryOS/
├── apps/
│   ├── admin_portal/       # React 18 + Vite (Super Admin Master Console)
│   ├── vendor_portal/      # React 18 + Vite (Vendor Kitchen KDS)
│   ├── customer_app/       # Flutter Cross-Platform Mobile
│   └── rider_app/          # Flutter Cross-Platform Mobile
├── services/
│   └── backend_api/        # NestJS 10 + Prisma ORM
└── deploy/
    ├── docker-compose.yml  # Multi-container local orchestration
    └── nginx.local.conf    # Edge ingress reverse proxy
```

### Ingress Port Mapping (`deploy/docker-compose.yml`):
- `http://localhost:8080/` $\rightarrow$ Nginx reverse proxies to `deliveryos_admin_portal:80` (Port 3000)
- `http://localhost:8080/vendor/` $\rightarrow$ Nginx reverse proxies to `deliveryos_vendor_portal:80` (Port 3001)
- `http://localhost:8080/api/v1/` $\rightarrow$ Nginx reverse proxies to `deliveryos_api:4000/api/v1/`
- `ws://localhost:8080/events` $\rightarrow$ Nginx upgrades connection to `deliveryos_api:4000/events`

## Compliance & Verification
- CI build checks run `npm run build` across `services/backend_api`, `apps/admin_portal`, and `apps/vendor_portal`.
- Ingress integration verified via automated test scripts (`npm test` in both portals and health check `GET /api/v1/health` via Nginx).
