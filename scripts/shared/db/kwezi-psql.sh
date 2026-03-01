#!/bin/bash
# Run psql against Kwezi's gemura_db via SSH into the kwezi-postgres container.
# This bypasses devslab completely.
#
# Usage examples (from repo root):
#   ./scripts/shared/db/kwezi-psql.sh -c "SELECT 1;"
#   cat my.sql | ./scripts/shared/db/kwezi-psql.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=/dev/null
source "$REPO_ROOT/scripts/shared/deployment/server-credentials.sh"

if ! command -v sshpass >/dev/null 2>&1; then
  echo "sshpass is required (brew install sshpass)." >&2
  exit 1
fi

SSH_OPTS="-o StrictHostKeyChecking=no -p ${SERVER_PORT:-22}"
REMOTE_CMD="docker exec -i kwezi-postgres psql -U $DB_USER -d $DB_NAME"

if [ "$#" -gt 0 ]; then
  # Pass explicit psql arguments
  sshpass -p "$SERVER_PASS" ssh $SSH_OPTS "$SERVER_USER@$SERVER_IP" "$REMOTE_CMD $*"
else
  # Read SQL from stdin and pipe to psql
  sshpass -p "$SERVER_PASS" ssh $SSH_OPTS "$SERVER_USER@$SERVER_IP" "$REMOTE_CMD" < /dev/stdin
fi
