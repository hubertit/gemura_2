# Backend Status Check Guide

## Quick Check Script

Run the status check script:
```bash
./scripts/check-backend-status.sh
```

Or specify a different server:
```bash
./scripts/check-backend-status.sh 159.198.65.38 3004
```

## Manual Checks

### 1. Test Health Endpoint
```bash
curl -v --max-time 5 http://159.198.65.38:3004/api/health
```

**Expected Response:**
- HTTP 200 OK
- JSON response with status

**If Failed:**
- Connection timeout = Server is down
- Connection refused = Service not running
- No route to host = Network/firewall issue

### 2. Test API Root
```bash
curl -v --max-time 5 http://159.198.65.38:3004/api
```

### 3. Test Swagger Docs
```bash
curl -v --max-time 5 http://159.198.65.38:3004/api/docs
```

## If Backend is Down

### Step 1: SSH into Server
```bash
ssh user@159.198.65.38
```

### Step 2: Check Docker Containers
```bash
# List all containers
docker ps -a

# Check for gemura backend container
docker ps | grep gemura

# Check container status
docker ps -a | grep gemura
```

### Step 3: Check Container Logs
```bash
# Find container name/ID
docker ps -a | grep gemura

# View logs
docker logs <container-name-or-id>

# Follow logs in real-time
docker logs -f <container-name-or-id>
```

### Step 4: Restart Backend Service

#### Option A: Restart Container
```bash
cd /path/to/gemura2
docker-compose -f docker-compose.gemura.yml restart backend
```

#### Option B: Restart Entire Stack
```bash
cd /path/to/gemura2
docker-compose -f docker-compose.gemura.yml down
docker-compose -f docker-compose.gemura.yml up -d
```

#### Option C: Rebuild and Restart
```bash
cd /path/to/gemura2
docker-compose -f docker-compose.gemura.yml down
docker-compose -f docker-compose.gemura.yml build
docker-compose -f docker-compose.gemura.yml up -d
```

### Step 5: Verify Backend is Running
```bash
# Check if container is running
docker ps | grep gemura

# Check if port is listening
netstat -tuln | grep 3004
# or
ss -tuln | grep 3004

# Test health endpoint from server
curl http://localhost:3004/api/health
```

## Common Issues

### Issue 1: Container Exited
**Symptoms:** Container shows status "Exited"
**Solution:**
```bash
# Check exit code
docker ps -a | grep gemura

# View logs to see why it exited
docker logs <container-id>

# Restart container
docker start <container-id>
```

### Issue 2: Port Already in Use
**Symptoms:** Error "port 3004 is already allocated"
**Solution:**
```bash
# Find what's using port 3004
lsof -i :3004
# or
netstat -tuln | grep 3004

# Kill the process or change port in docker-compose.yml
```

### Issue 3: Database Connection Failed
**Symptoms:** Logs show database connection errors
**Solution:**
```bash
# Check if database container is running
docker ps | grep postgres

# Check database connection from backend container
docker exec -it <backend-container> ping devslab-postgres
```

### Issue 4: Out of Memory
**Symptoms:** Container killed, logs show OOM
**Solution:**
```bash
# Check system memory
free -h

# Check container memory usage
docker stats

# Increase memory limits in docker-compose.yml or add swap
```

## Monitoring Commands

### Check Container Status
```bash
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### Check Resource Usage
```bash
docker stats --no-stream
```

### Check Recent Logs
```bash
docker logs --tail 50 <container-name>
```

### Check System Resources
```bash
# CPU and Memory
top

# Disk space
df -h

# Network connections
netstat -an | grep 3004
```

## Automated Monitoring

### Create a Monitoring Script
```bash
#!/bin/bash
# monitor-backend.sh

while true; do
    if ! curl -s --max-time 5 http://159.198.65.38:3004/api/health > /dev/null; then
        echo "$(date): Backend is DOWN!"
        # Add alert/notification here
    else
        echo "$(date): Backend is UP"
    fi
    sleep 60
done
```

## Contact Information

If backend continues to be down:
1. Check server status with hosting provider
2. Review server logs for errors
3. Check for scheduled maintenance
4. Verify network connectivity

---

**Last Updated:** 2025-01-XX
