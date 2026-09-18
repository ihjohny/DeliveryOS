#!/usr/bin/env bash
# ==============================================================================
# DeliveryOS — Database Seeding Script
# Usage:
#   ./scripts/seed-database.sh            # Standard baseline seeding
#   ./scripts/seed-database.sh --massive  # Massive production-grade showcase seeding
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

MODE="${1:-}"

echo "=================================================================="
echo " DeliveryOS Database Seeder"
echo "=================================================================="

if [ "$MODE" == "--massive" ]; then
  echo "🚀 Running MASSIVE Database Seeder (All Verticals, 100+ Orders)..."
  npm --prefix "$PROJECT_ROOT/services/backend_api" run prisma:seed:massive
else
  echo "🌱 Running Standard Baseline Seeder..."
  npm --prefix "$PROJECT_ROOT/services/backend_api" run prisma:seed
fi

echo ""
echo "✅ Seeding Complete! Verifying system health..."
"$SCRIPT_DIR/verify-local.sh"
