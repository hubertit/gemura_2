#!/usr/bin/env bash
# Install Cloudflare Origin certificate for app.gemura.rw on the Kwezi server.
# Requires: cert and key in scripts/shared/deployment/ssl/gemura-origin.crt and .key
#           server-credentials.sh (SERVER_PASS, SERVER_IP, SERVER_USER)
#
# Usage: ./scripts/shared/deployment/install-cloudflare-origin-cert-gemura.sh

set -e
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CREDS_FILE="$SCRIPT_DIR/server-credentials.sh"
SSL_DIR="$SCRIPT_DIR/ssl"
CERT_SRC="$SSL_DIR/gemura-origin.crt"
KEY_SRC="$SSL_DIR/gemura-origin.key"
NGINX_CONF_SRC="$REPO_ROOT/docker/nginx/gemura-orora.conf"
CONF_NAME="gemura-orora.conf"
REMOTE_SSL_DIR="/etc/nginx/ssl"
SITES_AVAILABLE="/etc/nginx/sites-available"

if [ ! -f "$CREDS_FILE" ]; then
  echo "❌ Missing $CREDS_FILE"
  exit 1
fi
source "$CREDS_FILE"
SERVER_IP="${SERVER_IP:-209.74.80.195}"
SERVER_USER="${SERVER_USER:-root}"
[ -n "$SERVER_PASS" ] || { echo "❌ SERVER_PASS not set"; exit 1; }

if [ ! -f "$CERT_SRC" ] || [ ! -f "$KEY_SRC" ]; then
  echo "❌ Missing $CERT_SRC or $KEY_SRC"
  exit 1
fi
if [ ! -f "$NGINX_CONF_SRC" ]; then
  echo "❌ Missing $NGINX_CONF_SRC"
  exit 1
fi

echo "═══════════════════════════════════════════════════════════════"
echo "  Install Cloudflare Origin cert for app.gemura.rw"
echo "  Server: $SERVER_USER@$SERVER_IP"
echo "═══════════════════════════════════════════════════════════════"

# Upload cert and key
echo ""
echo "📤 Uploading certificate and key..."
sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "mkdir -p $REMOTE_SSL_DIR && chmod 755 $REMOTE_SSL_DIR"
sshpass -p "$SERVER_PASS" scp -o StrictHostKeyChecking=no "$CERT_SRC" "$KEY_SRC" "$SERVER_USER@$SERVER_IP:$REMOTE_SSL_DIR/"
sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "chmod 644 $REMOTE_SSL_DIR/gemura-origin.crt && chmod 600 $REMOTE_SSL_DIR/gemura-origin.key"

# Upload updated nginx config
echo "📤 Uploading Nginx config..."
sshpass -p "$SERVER_PASS" scp -o StrictHostKeyChecking=no "$NGINX_CONF_SRC" "$SERVER_USER@$SERVER_IP:/tmp/$CONF_NAME"

# Install config and reload
echo "🔧 Installing config and reloading Nginx..."
sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" 'bash -s' << 'ENDSSH'
cp /tmp/gemura-orora.conf /etc/nginx/sites-available/gemura-orora.conf
rm -f /tmp/gemura-orora.conf
ln -sf /etc/nginx/sites-available/gemura-orora.conf /etc/nginx/sites-enabled/gemura-orora.conf
command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active" && ufw allow 443/tcp 2>/dev/null || true
nginx -t && systemctl reload nginx
echo "Nginx reloaded."
ENDSSH

echo ""
echo "✅ Cloudflare Origin certificate installed for app.gemura.rw"
echo "   HTTPS: https://app.gemura.rw (port 443)"
echo "   Set Cloudflare SSL/TLS to Full or Full (strict) for gemura.rw."
echo "═══════════════════════════════════════════════════════════════"
