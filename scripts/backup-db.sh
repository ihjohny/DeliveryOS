#!/usr/bin/env bash
# ==============================================================================
# DeliveryOS — Automated PostgreSQL Database Backup Script
# Task 7.2: Daily / On-Demand Backup & 7-Day Retention
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKUP_DIR="$PROJECT_ROOT/backups"
TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"
BACKUP_FILE="$BACKUP_DIR/deliveryos_backup_${TIMESTAMP}.sql.gz"
CONTAINER_NAME="${DB_CONTAINER:-deliveryos_db}"
DB_NAME="${DB_NAME:-deliveryos}"
DB_USER="${DB_USER:-postgres}"

mkdir -p "$BACKUP_DIR"

echo "===================================================="
echo " DeliveryOS PostgreSQL Database Backup"
echo "===================================================="
echo "Timestamp:      $TIMESTAMP"
echo "Target Container: $CONTAINER_NAME"
echo "Database:       $DB_NAME"
echo "Backup Path:    $BACKUP_FILE"
echo "----------------------------------------------------"

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}\$"; then
  echo "❌ Error: Docker container '$CONTAINER_NAME' is not currently running!"
  exit 1
fi

echo "📦 Dumping database and compressing with gzip..."
docker exec -e PGPASSWORD="${DB_PASSWORD:-secretpassword}" "$CONTAINER_NAME" pg_dump -h localhost -U "$DB_USER" -d "$DB_NAME" --clean --if-exists | gzip > "$BACKUP_FILE"

# Verify backup was created and has non-zero size
if [ -s "$BACKUP_FILE" ]; then
  BACKUP_SIZE="$(du -h "$BACKUP_FILE" | cut -f1)"
  echo "✅ Database backup created successfully! Size: $BACKUP_SIZE"
else
  echo "❌ Backup file was created empty or failed!"
  rm -f "$BACKUP_FILE"
  exit 1
fi

# Retention policy: Purge backups older than 7 days
echo "🧹 Applying 7-day retention cleanup policy..."
DELETED_COUNT=0
while IFS= read -r old_file; do
  if [ -n "$old_file" ]; then
    rm -f "$old_file"
    echo "   Removed expired backup: $(basename "$old_file")"
    DELETED_COUNT=$((DELETED_COUNT + 1))
  fi
done < <(find "$BACKUP_DIR" -name "deliveryos_backup_*.sql.gz" -type f -mtime +7)

echo "   Expired backups purged: $DELETED_COUNT"
echo "🎉 PostgreSQL Backup Complete!"
echo "===================================================="
