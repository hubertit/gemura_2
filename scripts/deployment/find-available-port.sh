#!/bin/bash

# Find available port on remote server (3000-3020)
# Returns the first available port number to stdout
# Credentials: source from scripts/deployment/server-credentials.sh (or pass as args: IP USER PASS)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$SCRIPT_DIR/server-credentials.sh" ] && source "$SCRIPT_DIR/server-credentials.sh"
[ -n "${GEMURA_SERVER_CREDS:-}" ] && [ -f "$GEMURA_SERVER_CREDS" ] && source "$GEMURA_SERVER_CREDS"

SERVER_IP="${1:-${SERVER_IP:-159.198.65.38}}"
SERVER_USER="${2:-${SERVER_USER:-root}}"
SERVER_PASS="${3:-${SERVER_PASS:-}}"
if [ -z "$SERVER_PASS" ]; then
    echo "❌ SERVER_PASS not set. Use scripts/deployment/server-credentials.sh or: $0 <IP> <USER> <PASS>" >&2
    exit 1
fi

echo "🔍 Finding available port on $SERVER_IP (range: 3000-3020)..." >&2

# Test ports via SSH
AVAILABLE_PORT=""
for port in {3000..3020}; do
    # Check if port is in use by checking if something is listening on it
    result=$(sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP \
        "netstat -tuln 2>/dev/null | grep -q ':$port ' || ss -tuln 2>/dev/null | grep -q ':$port ' || echo 'available'" 2>/dev/null)
    
    if [ "$result" = "available" ]; then
        # Double check by trying to connect
        http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 http://$SERVER_IP:$port 2>/dev/null || echo "000")
        
        if [ "$http_code" = "000" ] || [ -z "$http_code" ]; then
            AVAILABLE_PORT=$port
            echo "✅ Found available port: $port" >&2
            break
        else
            echo "   Port $port is in use (HTTP $http_code)" >&2
        fi
    else
        echo "   Port $port is in use (listening)" >&2
    fi
done

if [ -z "$AVAILABLE_PORT" ]; then
    echo "❌ No available ports found in range 3000-3020" >&2
    exit 1
fi

# Output only the port number to stdout
echo "$AVAILABLE_PORT"
