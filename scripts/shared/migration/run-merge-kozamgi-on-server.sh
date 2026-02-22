#!/usr/bin/env bash
# Run merge-kozamgi-accounts.sql on production (gemura_db) via SSH.
# Usage: from repo root, ./scripts/migration/run-merge-kozamgi-on-server.sh
# Requires: server-credentials.sh with SERVER_PASS, SERVER_IP, SERVER_USER.

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CREDS="$SCRIPT_DIR/../deployment/server-credentials.sh"
if [ -f "$CREDS" ]; then source "$CREDS"; fi
[ -n "$SERVER_PASS" ] || { echo "SERVER_PASS not set. Source server-credentials.sh."; exit 1; }
SERVER_IP="${SERVER_IP:-159.198.65.38}"
SERVER_USER="${SERVER_USER:-root}"

SQL_FILE="$SCRIPT_DIR/merge-kozamgi-accounts.sql"
[ -f "$SQL_FILE" ] || { echo "Not found: $SQL_FILE"; exit 1; }

echo "Applying merge-kozamgi-accounts.sql on $SERVER_IP (gemura_db)..."
sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" \
  "docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -v ON_ERROR_STOP=1" < "$SQL_FILE"

echo "Done. Verifying..."
sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" \
  "docker exec devslab-postgres psql -U devslab_admin -d gemura_db -t -c \"
SELECT id, code, name, status FROM accounts WHERE name ILIKE '%kozamgi%' OR code ILIKE '%kozamgi%' ORDER BY status, name;
\""

echo "User count for KOPERATIVE KOZAMGI (A_16C846):"
sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" \
  "docker exec devslab-postgres psql -U devslab_admin -d gemura_db -t -c \"
SELECT COUNT(*) FROM user_accounts WHERE account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3';
\""
