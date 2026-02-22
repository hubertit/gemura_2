#!/bin/bash

# Simple Backend Status Test
SERVER="159.198.65.38"
PORT="3004"
URL="http://$SERVER:$PORT/api/health"

echo "Testing backend at $SERVER:$PORT..."
echo ""

# Test health endpoint
RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}\nTIME:%{time_total}" --max-time 5 "$URL" 2>&1)

HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
TIME=$(echo "$RESPONSE" | grep "TIME" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | grep -v "HTTP_CODE" | grep -v "TIME")

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ BACKEND IS UP"
    echo "   Status: HTTP $HTTP_CODE"
    echo "   Response time: ${TIME}s"
    if [ -n "$BODY" ]; then
        echo "   Response: $BODY"
    fi
    exit 0
elif [ "$HTTP_CODE" = "000" ] || [ -z "$HTTP_CODE" ]; then
    echo "❌ BACKEND IS DOWN"
    echo "   Error: Connection failed or timeout"
    echo "   The server may be down or unreachable"
    exit 1
else
    echo "⚠️  BACKEND RESPONDED WITH ERROR"
    echo "   Status: HTTP $HTTP_CODE"
    echo "   Response: $BODY"
    exit 1
fi
