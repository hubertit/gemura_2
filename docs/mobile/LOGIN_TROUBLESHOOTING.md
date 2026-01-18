# Login Troubleshooting Guide

## Issue: Login Stuck / Connection Timeout

### Symptoms
- Login request hangs for 30 seconds
- Error: `DioException [connection timeout]`
- Request shows: `identifier: +250788606765`

### Root Cause
The server at `http://159.198.65.38:3004` is not reachable from your network. This could be due to:
1. Server is down or not running
2. Network connectivity issues
3. Firewall blocking the connection
4. VPN required to access the server
5. Server IP address changed

### Solutions

#### 1. Check Server Connectivity
Test if the server is reachable:
```bash
# Test basic connectivity
curl -v http://159.198.65.38:3004/api/health

# Test with timeout
curl --max-time 5 http://159.198.65.38:3004/api/health
```

#### 2. Verify Server Status
- Check if the NestJS backend is running on the server
- Verify the server is listening on port 3004
- Check server logs for any errors

#### 3. Network Configuration
- Ensure you're on the correct network
- Check if VPN is required to access the server
- Verify firewall rules allow connections to port 3004

#### 4. Phone Number Format
The backend automatically handles phone number formatting:
- Input: `+250788606765` → Backend processes: `250788606765`
- The `+` sign and other non-digits are stripped automatically
- Both formats should work: `+250788606765` or `250788606765`

#### 5. Alternative: Use IP Address or Domain
If the server IP changed, update in:
```
mobile/lib/core/config/app_config.dart
```
Change:
```dart
static const String apiBaseUrl = 'http://159.198.65.38:3004/api';
```

### Testing Login Manually

#### Using cURL
```bash
# Test login endpoint
curl -X POST http://159.198.65.38:3004/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"identifier": "250788606765", "password": "Pass123"}' \
  --max-time 10
```

#### Using Swagger UI
1. Open: http://159.198.65.38:3004/api/docs
2. Navigate to `/api/auth/login`
3. Click "Try it out"
4. Enter credentials:
   ```json
   {
     "identifier": "250788606765",
     "password": "Pass123"
   }
   ```
5. Click "Execute"

### Error Messages

#### Connection Timeout
- **Message**: `The request connection took longer than 0:00:30.000000`
- **Cause**: Server not responding within 30 seconds
- **Solution**: Check server status and network connectivity

#### Connection Error
- **Message**: `Connection error` or `Failed host lookup`
- **Cause**: Cannot resolve hostname or reach server
- **Solution**: Verify server IP/domain and network connection

### Code Changes Made

1. **Phone Number Normalization**: 
   - Removed `+` sign and non-digits before sending to backend
   - Backend also handles this, but normalization on client side ensures consistency

2. **Better Error Logging**:
   - Added debug logs for connection issues
   - More descriptive error messages

### Next Steps

1. ✅ Verify server is running and accessible
2. ✅ Test connectivity using cURL or Swagger
3. ✅ Check network/VPN requirements
4. ✅ Update API base URL if server IP changed
5. ✅ Test login with normalized phone number format

---

**Note**: The phone number format (`+250788606765` vs `250788606765`) is not the issue - the backend handles both. The problem is server connectivity.
