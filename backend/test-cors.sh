#!/bin/bash
# Test CORS configuration

echo "Testing CORS for localhost:3000..."
echo ""

# Test OPTIONS request (preflight)
echo "1. Testing OPTIONS (preflight) request:"
curl -X OPTIONS http://localhost:3004/api/auth/login \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" \
  -v 2>&1 | grep -E "< HTTP|< Access-Control" | head -10

echo ""
echo "2. Testing actual POST request:"
curl -X POST http://localhost:3004/api/auth/login \
  -H "Origin: http://localhost:3000" \
  -H "Content-Type: application/json" \
  -d '{"identifier":"test@example.com","password":"test123"}' \
  -v 2>&1 | grep -E "< HTTP|< Access-Control" | head -10

echo ""
echo "✅ If you see 'Access-Control-Allow-Origin: http://localhost:3000', CORS is working!"
