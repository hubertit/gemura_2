#!/bin/bash

# Auto-deploy Backend to Production
# This script checks if backend files were changed and automatically deploys to production
#
# Usage:
#   ./auto-deploy-backend.sh              # Check last commit and deploy if backend changed
#   ./auto-deploy-backend.sh --force      # Force deploy regardless of changes

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEPLOY_SCRIPT="$SCRIPT_DIR/deploy-to-server.sh"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Auto-Deploy Backend to Production${NC}"
echo "================================================"
echo ""

# Check if force flag is set
FORCE_DEPLOY=false
if [ "$1" == "--force" ] || [ "$1" == "-f" ]; then
    FORCE_DEPLOY=true
    echo -e "${YELLOW}⚠️  Force deploy mode: Will deploy regardless of changes${NC}"
    echo ""
fi

# Function to check if backend files changed
check_backend_changes() {
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Not a git repository, will deploy anyway${NC}"
        return 0
    fi

    # Get the last commit
    LAST_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "")
    if [ -z "$LAST_COMMIT" ]; then
        echo -e "${YELLOW}⚠️  No commits found, will deploy anyway${NC}"
        return 0
    fi

    # Check if backend files changed in the last commit
    BACKEND_CHANGED=$(git diff-tree --no-commit-id --name-only -r HEAD | grep -E "^backend/" | grep -vE "node_modules|dist|\.log" | head -1)

    if [ -n "$BACKEND_CHANGED" ]; then
        echo -e "${GREEN}✅ Backend files changed in last commit${NC}"
        echo ""
        echo "Changed backend files:"
        git diff-tree --no-commit-id --name-only -r HEAD | grep -E "^backend/" | grep -vE "node_modules|dist|\.log" | sed 's/^/   - /'
        echo ""
        return 0
    else
        # Also check uncommitted changes
        UNCOMMITTED=$(git diff --name-only | grep -E "^backend/" | grep -vE "node_modules|dist|\.log" | head -1)
        if [ -n "$UNCOMMITTED" ]; then
            echo -e "${GREEN}✅ Backend files have uncommitted changes${NC}"
            echo ""
            echo "Uncommitted backend files:"
            git diff --name-only | grep -E "^backend/" | grep -vE "node_modules|dist|\.log" | sed 's/^/   - /'
            echo ""
            return 0
        else
            echo -e "${YELLOW}ℹ️  No backend changes detected${NC}"
            return 1
        fi
    fi
}

# Check for backend changes (unless force deploy)
if [ "$FORCE_DEPLOY" = false ]; then
    if ! check_backend_changes; then
        echo -e "${YELLOW}⏭️  Skipping deployment - no backend changes detected${NC}"
        echo ""
        echo "To force deployment, run:"
        echo "  ./scripts/deployment/auto-deploy-backend.sh --force"
        echo ""
        exit 0
    fi
fi

# Confirm deployment
echo -e "${GREEN}📦 Ready to deploy backend to production${NC}"
echo ""
echo "This will:"
echo "  1. Upload backend files to server"
echo "  2. Rebuild Docker image"
echo "  3. Restart backend service"
echo ""
echo -e "${YELLOW}Press Enter to continue or Ctrl+C to cancel...${NC}"
read -r

# Run deployment script
echo ""
echo "🚀 Starting deployment..."
echo ""
cd "$PROJECT_ROOT"
bash "$DEPLOY_SCRIPT"

echo ""
echo -e "${GREEN}✅ Auto-deployment complete!${NC}"
