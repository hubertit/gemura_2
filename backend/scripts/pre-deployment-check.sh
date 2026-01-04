#!/bin/bash

# Complete pre-deployment check script
# Run this on the deployment server before deploying Gemura

echo "=========================================="
echo "Gemura Pre-Deployment Check"
echo "=========================================="
echo "Date: $(date)"
echo ""

# Run port check
echo "1. Checking Port Availability..."
echo "=================================="
./scripts/check-ports.sh
echo ""

# Check database
echo "2. Checking Database Connection..."
echo "==================================="
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
    ./scripts/check-database.sh
else
    echo "⚠ .env file not found. Using defaults."
    echo "Create .env file from .env.example first."
    ./scripts/check-database.sh
fi
echo ""

# Check Docker
echo "3. Checking Docker Setup..."
echo "============================"
if command -v docker &> /dev/null; then
    echo "✓ Docker is installed"
    docker --version
    if docker ps &> /dev/null; then
        echo "✓ Docker daemon is running"
    else
        echo "✗ Docker daemon is not running or not accessible"
    fi
else
    echo "✗ Docker is not installed"
fi

if command -v docker-compose &> /dev/null; then
    echo "✓ Docker Compose is installed"
    docker-compose --version
else
    echo "✗ Docker Compose is not installed"
fi
echo ""

# Check Node.js (for local development)
echo "4. Checking Node.js (optional for local dev)..."
echo "================================================"
if command -v node &> /dev/null; then
    echo "✓ Node.js is installed"
    node --version
    npm --version
else
    echo "⚠ Node.js is not installed (not required for Docker deployment)"
fi
echo ""

# Check Prisma (if Node.js is available)
if command -v node &> /dev/null && [ -f "package.json" ]; then
    echo "5. Checking Prisma Setup..."
    echo "============================"
    if [ -f "node_modules/.bin/prisma" ] || command -v npx &> /dev/null; then
        echo "✓ Prisma can be run via npx"
        if [ -f "prisma/schema.prisma" ]; then
            echo "✓ Prisma schema file exists"
        else
            echo "✗ Prisma schema file not found"
        fi
    else
        echo "⚠ Prisma not installed (run: npm install)"
    fi
    echo ""
fi

# Final summary
echo "=========================================="
echo "Pre-Deployment Checklist:"
echo "=========================================="
echo "[ ] Ports 3100 and 3101 are available"
echo "[ ] Database connection works"
echo "[ ] Database 'gemura_db' exists (or can be created)"
echo "[ ] Docker and Docker Compose are installed"
echo "[ ] .env file is configured with correct credentials"
echo "[ ] Prisma schema is ready"
echo ""
echo "Next steps:"
echo "1. Fix any issues above"
echo "2. Create database: ./scripts/create-database.sh"
echo "3. Deploy: docker-compose up -d --build"
echo ""

