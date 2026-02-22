#!/bin/bash
# Run this script ON THE SERVER (e.g. after: ssh root@159.198.65.38)
# Usage: cd /opt/gemura && bash scripts/deployment/check-backend-on-server.sh
#
# Diagnoses why http://159.198.65.38:3004/api/health may be unreachable.

set -e

echo "=========================================="
echo "Gemura backend diagnostic (on server)"
echo "=========================================="
echo ""

echo "1. Container status:"
docker ps -a --filter name=gemura-backend --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

echo "2. Is port 3004 listening on the host?"
(ss -tlnp 2>/dev/null || netstat -tlnp 2>/dev/null) | grep -E '3004|Address' || echo "  (no output or port not found)"
echo ""

echo "3. Health check from localhost (on server):"
curl -s -o /dev/null -w "  HTTP %{http_code}\n" http://127.0.0.1:3004/api/health 2>/dev/null || echo "  Failed to connect"
echo ""

echo "4. Last 40 lines of backend logs:"
docker logs gemura-backend --tail 40 2>&1 || echo "  (container not found or no logs)"
echo ""

echo "5. Firewall (if ufw is active, port 3004 must be allowed):"
if command -v ufw &>/dev/null && ufw status 2>/dev/null | grep -q "Status: active"; then
  ufw status | grep 3004 || echo "  Port 3004 may be BLOCKED. Run: sudo ufw allow 3004/tcp && sudo ufw reload"
else
  echo "  ufw not active or not installed (firewall may be iptables/other)"
fi
echo ""

echo "=========================================="
echo "If container is 'Up' but health fails: check logs above (migrations, DB, bind)."
echo "If health works from localhost but not from your machine: open firewall (ufw allow 3004)."
echo "=========================================="
