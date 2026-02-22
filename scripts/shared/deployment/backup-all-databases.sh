#!/bin/bash
# Backup all databases from devslab-postgres so "latest" is always captured.
# Single source of truth: container devslab-postgres (volume devslab_postgres_data).
# Run on server: ./scripts/deployment/backup-all-databases.sh
# Or from repo root after deploy: ssh root@SERVER 'cd /opt/gemura && ./scripts/deployment/backup-all-databases.sh'

set -e

CONTAINER="${PG_CONTAINER:-devslab-postgres}"
PG_USER="${POSTGRES_USER:-devslab_admin}"
PG_PASS="${POSTGRES_PASSWORD:-devslab_secure_password_2024}"
BACKUP_ROOT="${BACKUP_ROOT:-/opt/gemura/backups}"
STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="${BACKUP_DIR:-$BACKUP_ROOT/db-$STAMP}"

if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
  echo "Container $CONTAINER is not running. Start devslab-postgres first." >&2
  exit 1
fi

mkdir -p "$BACKUP_DIR"
export PGPASSWORD="$PG_PASS"

DBS=$(docker exec "$CONTAINER" psql -U "$PG_USER" -d postgres -t -A -c \
  "SELECT datname FROM pg_database WHERE datname NOT IN ('postgres','template0','template1');" 2>/dev/null || true)

if [ -z "$DBS" ]; then
  echo "No databases to backup (or could not list)." >&2
  exit 0
fi

for db in $DBS; do
  echo "Backing up $db..."
  docker exec "$CONTAINER" pg_dump -U "$PG_USER" -d "$db" --no-owner --no-acl > "$BACKUP_DIR/$db.sql" 2>/dev/null || \
    docker exec -i "$CONTAINER" pg_dump -U "$PG_USER" -d "$db" --no-owner --no-acl > "$BACKUP_DIR/$db.sql"
done

unset PGPASSWORD
echo "Latest DBs backed up to: $BACKUP_DIR"
ls -la "$BACKUP_DIR"
