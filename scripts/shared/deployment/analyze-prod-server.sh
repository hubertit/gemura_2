#!/usr/bin/env bash
# Analyze production server (Kwezi 209.74.80.195): containers, ports, deploy paths, nginx.
# Run from repo root. Requires: server-credentials.sh (SERVER_PASS, SERVER_IP, SERVER_USER).

set -e
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CREDS_FILE="$SCRIPT_DIR/server-credentials.sh"

if [ ! -f "$CREDS_FILE" ]; then
  echo "❌ Missing $CREDS_FILE. Copy from server-credentials.sh.example and set SERVER_PASS."
  exit 1
fi
source "$CREDS_FILE"
SERVER_IP="${SERVER_IP:-209.74.80.195}"
SERVER_USER="${SERVER_USER:-root}"
[ -n "$SERVER_PASS" ] || { echo "❌ SERVER_PASS not set in server-credentials.sh"; exit 1; }

echo "═══════════════════════════════════════════════════════════════"
echo "  Production server analysis: $SERVER_USER@$SERVER_IP"
echo "═══════════════════════════════════════════════════════════════"

sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" 'bash -s' << 'ENDSSH'
echo ""
echo "── Docker containers (all) ──"
docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || docker ps -a

echo ""
echo "── Listening ports (host) ──"
( command -v ss >/dev/null 2>&1 && ss -tlnp ) || netstat -tlnp 2>/dev/null || true

echo ""
echo "── /opt directory ──"
ls -la /opt 2>/dev/null || echo "(no /opt or not readable)"

echo ""
echo "── Deploy paths: /opt/gemura, /opt/orora, /opt/kwezi ──"
for d in /opt/gemura /opt/orora /opt/kwezi; do
  if [ -d "$d" ]; then
    echo "  $d:"
    ls -la "$d" 2>/dev/null | head -20
    [ -d "$d/docker" ] && echo "    docker compose files: $(ls "$d/docker" 2>/dev/null)"
  else
    echo "  $d: (not present)"
  fi
done

echo ""
echo "── Nginx (if installed) ──"
if command -v nginx >/dev/null 2>&1; then
  nginx -v 2>&1
  echo "  sites-enabled:"
  ls -la /etc/nginx/sites-enabled/ 2>/dev/null || true
  for f in /etc/nginx/sites-enabled/*; do
    [ -f "$f" ] && echo "  --- $f ---" && cat "$f" 2>/dev/null
  done
else
  echo "  nginx not installed"
fi

echo ""
echo "── Docker Compose projects ──"
docker compose ls -a 2>/dev/null || docker-compose ls -a 2>/dev/null || echo "(docker compose ls not available)"

echo ""
echo "── Disk & memory ──"
df -h / 2>/dev/null | head -2
free -h 2>/dev/null | head -2
ENDSSH

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  Done."
echo "═══════════════════════════════════════════════════════════════"