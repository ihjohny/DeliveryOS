# 07 — DevOps, Docker & Environment Setup

This document provides the deployment configuration, **Docker Compose** environment, **Nginx** reverse proxy rules, and **Environment Variables specification** for running **DeliveryOS** in development, staging, and production.

---

## 1. Docker Compose Multi-Container Topology

```yaml
# deploy/docker-compose.yml
version: '3.8'

services:
  # 1. PostgreSQL 16 with PostGIS 3.4
  postgres:
    image: postgis/postgis:16-3.4-alpine
    container_name: deliveryos_db
    restart: always
    environment:
      POSTGRES_DB: ${DB_NAME:-deliveryos}
      POSTGRES_USER: ${DB_USER:-postgres}
      POSTGRES_PASSWORD: ${DB_PASSWORD:-secretpassword}
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./init-postgis.sql:/docker-entrypoint-initdb.d/10-postgis.sql
    ports:
      - "5432:5432"
    networks:
      - deliveryos_network

  # 2. Redis 7.2 Cache & Pub/Sub
  redis:
    image: redis:7.2-alpine
    container_name: deliveryos_redis
    restart: always
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD:-redispassword}
    volumes:
      - redisdata:/data
    ports:
      - "6379:6379"
    networks:
      - deliveryos_network

  # 3. NestJS Backend API
  backend:
    build:
      context: ../services/backend_api
      dockerfile: Dockerfile
    container_name: deliveryos_api
    restart: always
    depends_on:
      - postgres
      - redis
    env_file:
      - ../services/backend_api/.env
    ports:
      - "4000:4000"
    networks:
      - deliveryos_network

  # 4. Super Admin Master Console (Vite + Nginx)
  admin_portal:
    build:
      context: ../apps/admin_portal
      dockerfile: Dockerfile
    container_name: deliveryos_admin_portal
    restart: always
    ports:
      - "3000:80"
    networks:
      - deliveryos_network

  # 5. Vendor Store & Kitchen Console KDS (Vite + Nginx)
  vendor_portal:
    build:
      context: ../apps/vendor_portal
      dockerfile: Dockerfile
    container_name: deliveryos_vendor_portal
    restart: always
    ports:
      - "3001:80"
    networks:
      - deliveryos_network

  # 6. Edge Nginx Reverse Proxy
  nginx:
    image: nginx:1.25-alpine
    container_name: deliveryos_nginx
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./certs:/etc/nginx/certs:ro
    depends_on:
      - backend
      - admin_portal
      - vendor_portal
    networks:
      - deliveryos_network

volumes:
  pgdata:
  redisdata:

networks:
  deliveryos_network:
    driver: bridge
```

---

## 2. Nginx Reverse Proxy Configuration

```nginx
# deploy/nginx.conf
events { worker_connections 1024; }

http {
    upstream backend_api {
        server backend:4000;
    }
    upstream frontend_portal {
        server web_portal:80;
    }

    server {
        listen 80;
        server_name api.deliveryos.local portal.deliveryos.local;

        # Static Web Portal
        location / {
            proxy_pass http://frontend_portal;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }

        # Backend REST API
        location /api/ {
            proxy_pass http://backend_api;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }

        # WebSocket Gateway
        location /events/ {
            proxy_pass http://backend_api;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}
```

---

## 3. Environment Variables Specification (`.env.example`)

```bash
# ==========================================
# DeliveryOS Backend Configuration
# ==========================================
NODE_ENV=production
PORT=4000

# Database (PostgreSQL + PostGIS)
DATABASE_URL="postgresql://postgres:secretpassword@postgres:5432/deliveryos?schema=public"

# Redis Cache & WebSockets
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=redispassword

# JWT Authentication Secrets
JWT_ACCESS_SECRET="super-secret-access-token-key"
JWT_ACCESS_EXPIRATION="1d"
JWT_REFRESH_SECRET="super-secret-refresh-token-key"
JWT_REFRESH_EXPIRATION="30d"

# Regional Settings (SAR vs BDT)
DEFAULT_REGION="BD" # "BD" | "KSA"
DEFAULT_CURRENCY="BDT" # "BDT" | "SAR"
CURRENCY_SYMBOL="৳" # "৳" | "﷼"

# Default Delivery Fee Settings
DELIVERY_FEE_MODE="FIXED_FLAT" # "FIXED_FLAT" | "DISTANCE_TIERED"
FLAT_DELIVERY_FEE=50.0
BASE_DELIVERY_FEE=30.0
BASE_DELIVERY_KM=2.0
PER_KM_DELIVERY_RATE=10.0

# Order Fulfillment Sequence Flow
ORDER_FLOW_MODE="RIDER_FIRST" # "RIDER_FIRST" (Zero Food Waste) | "VENDOR_FIRST" | "PARALLEL"
RIDER_SEARCH_TIMEOUT_SECONDS=90

# Google Maps API
GOOGLE_MAPS_API_KEY="AIzaSy..."

# Push Notifications (Firebase)
FIREBASE_PROJECT_ID="deliveryos-prod"
FIREBASE_CLIENT_EMAIL="firebase-adminsdk@deliveryos-prod.iam.gserviceaccount.com"
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqh..."

# SMS Gateway (Twilio / Local Provider)
SMS_PROVIDER="TWILIO" # "TWILIO" | "MOCK"
TWILIO_ACCOUNT_SID="AC..."
TWILIO_AUTH_TOKEN="..."
TWILIO_PHONE_NUMBER="+1..."

# Media Storage (AWS S3 / Cloudflare R2)
STORAGE_PROVIDER="S3" # "S3" | "R2"
AWS_ACCESS_KEY_ID="..."
AWS_SECRET_ACCESS_KEY="..."
AWS_REGION="ap-southeast-1"
S3_BUCKET_NAME="deliveryos-assets"
```

---

## 4. PostGIS Initialization Script

```sql
-- deploy/init-postgis.sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "postgis_topology";
```

---

## 5. Seed Data Strategy for 10 Pilot Vendors

When initializing the database for the pilot, the seed script (`services/backend_api/prisma/seed.ts` or `src/database/seed.ts`) automatically populates:
1. **1 Super Admin Account** (`admin@deliveryos.local` / `+8801700000000`).
2. **10 Pilot Vendors** (7 popular restaurants across Burgers, Pizza, Biryani, Coffee/Bakery + 3 Super Shops/Groceries) complete with geo-coordinates, operating hours, categories, dishes, and image placeholders.
3. **5 Pre-Approved Pilot Riders** equipped with mock locations within the pilot radius.
4. **Default Delivery Fee Configuration** set to `FIXED_FLAT` (50 BDT / 10 SAR).
