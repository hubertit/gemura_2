#!/bin/bash
# SSH tunnel to Kwezi production DB so localhost can connect to gemura_db.
# Run in a terminal and leave it open. Then start backend with remote DB.
# Usage: ./scripts/shared/db/tunnel-kwezi-db.sh
# Requires: SERVER_PASS or server-credentials.sh
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
[ -f "$REPO_ROOT/scripts/shared/deployment/server-credentials.sh" ] && source "$REPO_ROOT/scripts/shared/deployment/server-credentials.sh"
SERVER_IP="${SERVER_IP:-209.74.80.195}"
SERVER_USER="${SERVER_USER:-root}"
SERVER_PASS="${SERVER_PASS:-}"
LOCAL_PORT="${LOCAL_PORT:-5433}"
REMOTE_PORT="${REMOTE_PORT:-5432}"
if [ -z "$SERVER_PASS" ]; then
  echo "❌ SERVER_PASS not set. Export it or source server-credentials.sh"
  exit 1
fi
echo "Tunnel: localhost:$LOCAL_PORT -> $SERVER_USER@$SERVER_IP:$REMOTE_PORT (gemura_db)"
echo "Keep this running. Backend .env should use DATABASE_URL with host=localhost port=$LOCAL_PORT"
exec sshpass -p "$SERVER_PASS" ssh -L "$LOCAL_PORT:127.0.0.1:$REMOTE_PORT" -o StrictHostKeyChecking=no -N "$SERVER_USER@$SERVER_IP"
