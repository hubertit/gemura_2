#!/bin/bash
# Clean dead/stopped Docker containers on the server, except devslab-postgres (database).
# Run from project root. Uses same credentials as deploy-to-server.sh.
#
# Usage:
#   ./scripts/deployment/clean-dead-containers-on-server.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CREDS_FILE="$SCRIPT_DIR/server-credentials.sh"
[ -f "$CREDS_FILE" ] && source "$CREDS_FILE"
[ -n "${GEMURA_SERVER_CREDS:-}" ] && [ -f "$GEMURA_SERVER_CREDS" ] && source "$GEMURA_SERVER_CREDS"
SERVER_IP="${SERVER_IP:-159.198.65.38}"
SERVER_USER="${SERVER_USER:-root}"
SERVER_PASS="${SERVER_PASS:-}"

if [ -z "$SERVER_PASS" ]; then
  echo "❌ SERVER_PASS not set. Configure scripts/deployment/server-credentials.sh (see server-credentials.sh.example)."
  exit 1
fi

SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=15"
echo "Cleaning dead containers on $SERVER_USER@$SERVER_IP (keeping devslab-postgres)..."
sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP 'bash -s' << 'ENDSSH'
docker ps -a --format "{{.Names}} {{.Status}}" | awk '$2=="Exited" || $2=="Dead" || $2=="Created" {print $1}' | grep -v '^devslab-postgres$' | while read -r c; do echo "  Removing: $c"; docker rm -f "$c" 2>/dev/null || true; done
echo "Done. Running containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
ENDSSH
echo "✅ Cleanup complete."
