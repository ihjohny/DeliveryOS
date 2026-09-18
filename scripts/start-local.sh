#!/usr/bin/env bash
# ==============================================================================
# DeliveryOS — Localhost System Launcher Script
# Task 7.2: Start and Manage DeliveryOS Services on Localhost
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

MODE="${1:-}"

echo "=================================================================="
echo " DeliveryOS Localhost Launcher"
echo "=================================================================="

if [ "$MODE" == "--stop" ]; then
  echo "🛑 Stopping all DeliveryOS local containers..."
  docker compose -f "$PROJECT_ROOT/deploy/docker-compose.yml" down 2>/dev/null || true
  echo "✅ All containers stopped."
  exit 0
fi

if [ "$MODE" == "--docker" ]; then
  echo "🚀 Launching complete 5-container Docker stack (DB, Redis, Backend, Portal, Nginx)..."
  docker compose -f "$PROJECT_ROOT/deploy/docker-compose.yml" up -d --build
  echo ""
  echo "Waiting 5 seconds for services to initialize..."
  sleep 5
  "$SCRIPT_DIR/verify-local.sh"
  exit 0
fi

# Default: Ensure core database & cache containers are up
echo "🐘 Starting core PostgreSQL (PostGIS) & Redis containers..."
docker compose -f "$PROJECT_ROOT/deploy/docker-compose.yml" up -d postgres redis

echo ""
echo "Waiting for services to become healthy..."
sleep 3

"$SCRIPT_DIR/verify-local.sh"

echo ""
echo "=================================================================="
echo " 🌟 Next Steps to run locally on your host machine:"
echo "=================================================================="
echo " 1. Start Backend API (Port 4000):"
echo "    cd services/backend_api && npm run start:dev"
echo "    • Health Check: http://localhost:4000/api/v1/health"
echo "    • Swagger Docs: http://localhost:4000/docs"
echo ""
echo " 2. Start Web Portal (Port 3000):"
echo "    cd apps/web_portal && npm run dev"
echo "    • Open Portal:  http://localhost:3000"
echo ""
echo " 3. Or to run the entire stack inside Docker (with Nginx proxy on 8080):"
echo "    ./scripts/start-local.sh --docker"
echo "=================================================================="
