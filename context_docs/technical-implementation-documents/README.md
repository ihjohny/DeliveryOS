# Technical Implementation Documents (TID) Suite
### DeliveryOS — Engineering Specifications & AI Agent Implementation Guide

This directory contains the engineering specifications, architectural blueprints, database schemas, API contracts, and real-time protocols for the **DeliveryOS** platform.

It is structured to serve as an authoritative source of truth for **AI Software Engineering Agents** (e.g. Gemini, Claude, GPT-4, Cursor, Antigravity) and human engineers to develop, test, and deploy the production codebase without ambiguity.

---

## 📑 Document Index

| File | Document Title | Primary Focus for AI Implementation Agents |
| :--- | :--- | :--- |
| **[01-system-architecture-and-tech-stack.md](./01-system-architecture-and-tech-stack.md)** | **System Architecture & Tech Stack** | High-level topology, monorepo/polyrepo directory structure, TypeScript/Flutter coding conventions. |
| **[02-database-schema-and-data-models.md](./02-database-schema-and-data-models.md)** | **Database Schema & Data Models** | Complete PostgreSQL 16 + PostGIS relational DDL / Prisma schema, spatial types, indexes, and enums. |
| **[03-api-specifications-and-endpoints.md](./03-api-specifications-and-endpoints.md)** | **API Specifications & Endpoints** | REST API endpoints, DTOs, request/response JSON contracts, JWT auth, and error formats. |
| **[04-realtime-events-and-websocket-protocol.md](./04-realtime-events-and-websocket-protocol.md)** | **Real-Time WebSockets & Event Protocol** | Socket.IO namespaces, rooms, connection handshake, and real-time event schemas (audio alerts, map tracking). |
| **[05-order-state-machine-and-dispatch-engine.md](./05-order-state-machine-and-dispatch-engine.md)** | **Order State Machine & Dispatch Engine** | Strict FSM state transitions, Redis geospatial radius queries (`GEORADIUS`), distributed locking, and broadcast dispatch. |
| **[06-frontend-and-mobile-architecture.md](./06-frontend-and-mobile-architecture.md)** | **Frontend & Mobile Architecture** | Flutter Customer & Rider app patterns (Riverpod, RTL i18n, background GPS) and React.js SPA portal architecture. |
| **[07-deployment-devops-and-environment-setup.md](./07-deployment-devops-and-environment-setup.md)** | **DevOps, Docker & Environment Setup** | Docker Compose configurations, PostGIS setup, Nginx reverse proxy, `.env.example`, and seed data scripts. |

---

## 🤖 Instructions for AI Coding Agents

When tasked with generating code or implementing features for DeliveryOS:
1. **Strict Type Safety**: All backend code must be strictly typed TypeScript in NestJS. All frontend code must use TypeScript with React.js or strongly typed Dart with Flutter 3.x.
2. **ACID Financial Integrity**: Never update order statuses or financial balances in disconnected steps. Always wrap order creation, status transitions, and payments inside a PostgreSQL database transaction (`prisma.$transaction` or TypeORM `QueryRunner`).
3. **Geospatial Queries**: Use native PostGIS functions (`ST_DWithin`, `ST_DistanceSphere`) for database-level spatial searches. Use Redis `GEOADD` and `GEORADIUS` for live rider tracking.
4. **Lean MVP Rules**:
   - Deliveries are 1-vendor per checkout.
   - Delivery fee supports either a **Fixed Flat Fee** or **Distance-Based Fee** via config.
   - Rider fulfillment must follow the streamlined 3-step action pattern (Accept -> Pickup -> Deliver).
   - In-app calling is implemented as a simple device `tel:` URL scheme shortcut (no WebRTC / in-app chat).
   - Re-order must validate real-time stock and store operational status before returning cart items.
