# Deployment Workflow

## Recommended Deployment Process

### Step 1: Check Available Ports

**Always check available ports first before deploying!**

```bash
cd /Users/macbookpro/projects/flutter/gemura2
./scripts/deployment/check-available-ports.sh
```

This will show you:
- ✅ Available ports (green)
- ❌ Ports in use (red)
- 📌 Recommended port to use

**Example:**
```
==========================================
Checking Available Ports on 159.198.65.38
Range: 3000-3020
==========================================

Port 3000: ✗ IN USE (listening)
Port 3001: ✗ IN USE (listening)
Port 3002: ✓ AVAILABLE
Port 3003: ✓ AVAILABLE
Port 3004: ✓ AVAILABLE
...

==========================================
Summary
==========================================

Available Ports: 3002 3003 3004 3005 3006 3007 3008 3009 3010 3011 3012 3013 3014 3015 3016 3017 3018 3019 3020

Recommended: Use port 3002

To deploy with a specific port:
  ./scripts/deployment/deploy-to-server.sh 3002
```

### Step 2: Deploy with Selected Port

Once you know which port is available, deploy with that port:

```bash
./scripts/deployment/deploy-to-server.sh 3002
```

The script will:
1. ✅ Verify port 3002 is available
2. 📤 Upload project files to server
3. 🗄️  Setup database (if needed)
4. 🔨 Build Docker images
5. 🚀 Deploy containers with port 3002

### Step 3: Verify Deployment

After deployment, the script will show you the URLs:

```
✅ Deployment Complete!
================================================

🌐 Access your application:
   Backend API: http://159.198.65.38:3002/api
   API Docs: http://159.198.65.38:3002/api/docs
   Health Check: http://159.198.65.38:3002/api/health

📌 Port Information:
   Backend Port: 3002
   Frontend Port: 3003 (when ready)
```

## Quick Reference

### Check Ports
```bash
./scripts/deployment/check-available-ports.sh
```

### Deploy with Specific Port
```bash
./scripts/deployment/deploy-to-server.sh <PORT>
```

### Deploy with Auto-Detection
```bash
./scripts/deployment/deploy-to-server.sh
```

### View Logs
```bash
ssh root@159.198.65.38 'cd /opt/gemura && docker compose -f docker-compose.gemura.yml logs -f'
```

### Restart Services
```bash
ssh root@159.198.65.38 'cd /opt/gemura && docker compose -f docker-compose.gemura.yml restart'
```

## Why Check Ports First?

1. **Transparency**: You see exactly which ports are available
2. **Control**: You choose which port to use
3. **Verification**: Confirms the port is actually free
4. **Planning**: Helps plan port allocation across services

## Port Allocation

Current known port usage:
- **3000**: ResolveIt Backend
- **3001**: ResolveIt Frontend
- **3002-3020**: Available for Gemura and other services

Gemura will use:
- **Backend**: Selected port (e.g., 3002)
- **Frontend**: Selected port + 1 (e.g., 3003)
