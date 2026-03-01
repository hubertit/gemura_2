#!/bin/bash
#
# Deploy Orora + Backend to Kwezi server (209.74.80.195)
# Same flow as kwezi app: archive → upload → docker compose up on server.
#
# 1. Backend (shared API) + Gemura Web → /opt/gemura (ports 3007, 3006)
# 2. Orora Web → /opt/orora (port 3011)
#
# Prerequisites on server:
#   - Docker + Docker Compose
#   - Kwezi stack running at /opt/kwezi (postgres + kwezi-ui) so network kwezi_default exists
#
# Usage (from project root):
#   ./scripts/orora/deployment/deploy-orora-and-backend-to-kwezi.sh
#
# Requires: scripts/shared/deployment/server-credentials.sh (SERVER_PASS, optional SERVER_IP/SERVER_USER)
#
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CREDS_FILE="$REPO_ROOT/scripts/shared/deployment/server-credentials.sh"

if [ ! -f "$CREDS_FILE" ]; then
  echo "❌ Credentials not found. Create:"
  echo "   cp scripts/shared/deployment/server-credentials.sh.example scripts/shared/deployment/server-credentials.sh"
  echo "   Edit server-credentials.sh and set SERVER_PASS (and SERVER_IP/SERVER_USER if needed)."
  exit 1
fi
source "$CREDS_FILE"
if [ -z "${SERVER_PASS:-}" ]; then
  echo "❌ SERVER_PASS not set in server-credentials.sh (or export it)."
  exit 1
fi

echo "🚀 Deploy Orora + Backend to Kwezi"
echo "================================================"
echo "   Server: ${SERVER_IP:-209.74.80.195}"
echo "   Backend: 3007  |  Gemura Web: 3006  |  Orora Web: 3011"
echo ""

echo "▶ Step 1/2: Deploying Backend + Gemura Web to /opt/gemura..."
"$REPO_ROOT/scripts/shared/deployment/deploy-gemura-only-safe.sh" || exit 1

echo ""
echo "▶ Step 2/2: Deploying Orora Web to /opt/orora..."
"$REPO_ROOT/scripts/orora/deployment/deploy-orora-web.sh" || exit 1

echo ""
echo "✅ Orora + Backend deployment complete"
echo "================================================"
echo "   Backend API:  http://${SERVER_IP:-209.74.80.195}:3007/api"
echo "   Gemura Web:   http://${SERVER_IP:-209.74.80.195}:3006"
echo "   Orora Web:    http://${SERVER_IP:-209.74.80.195}:3011"
echo ""
