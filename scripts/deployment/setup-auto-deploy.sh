#!/bin/bash

# Setup Auto-Deploy Git Hook
# This script sets up the git post-commit hook for automatic backend deployment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK_FILE="$PROJECT_ROOT/.git/hooks/post-commit"
HOOK_TEMPLATE="$SCRIPT_DIR/post-commit-hook-template"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🔧 Setting up Auto-Deploy Git Hook${NC}"
echo "================================================"
echo ""

# Check if we're in a git repository
if [ ! -d "$PROJECT_ROOT/.git" ]; then
    echo -e "${RED}❌ Error: Not a git repository${NC}"
    exit 1
fi

# Create hooks directory if it doesn't exist
mkdir -p "$PROJECT_ROOT/.git/hooks"

# Check if hook already exists
if [ -f "$HOOK_FILE" ]; then
    echo -e "${YELLOW}⚠️  Git hook already exists${NC}"
    echo ""
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}⏭️  Skipping hook installation${NC}"
        exit 0
    fi
fi

# Create the hook
cat > "$HOOK_FILE" << 'HOOK_EOF'
#!/bin/bash

# Git post-commit hook: Auto-deploy backend on backend changes
# This hook automatically deploys backend changes to production after commit

# Get the project root
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
AUTO_DEPLOY_SCRIPT="$PROJECT_ROOT/scripts/deployment/auto-deploy-backend.sh"

# Check if auto-deploy script exists
if [ ! -f "$AUTO_DEPLOY_SCRIPT" ]; then
    exit 0
fi

# Check if backend files changed in this commit
BACKEND_CHANGED=$(git diff-tree --no-commit-id --name-only -r HEAD | grep -E "^backend/" | grep -vE "node_modules|dist|\.log" | head -1)

if [ -n "$BACKEND_CHANGED" ]; then
    echo ""
    echo "🚀 Backend files changed - Auto-deploying to production..."
    echo ""
    
    # Run auto-deploy script in background (non-blocking)
    # Use nohup to prevent it from being killed when terminal closes
    nohup bash "$AUTO_DEPLOY_SCRIPT" > /tmp/gemura-auto-deploy.log 2>&1 &
    
    echo "   Deployment started in background"
    echo "   Check logs: tail -f /tmp/gemura-auto-deploy.log"
    echo ""
fi

exit 0
HOOK_EOF

# Make hook executable
chmod +x "$HOOK_FILE"

echo -e "${GREEN}✅ Git hook installed successfully!${NC}"
echo ""
echo "The hook will automatically deploy backend changes to production after each commit."
echo ""
echo "To test it:"
echo "  1. Make a change to a backend file"
echo "  2. Commit the change: git commit -m 'test'"
echo "  3. The hook will automatically trigger deployment"
echo ""
echo "To disable auto-deployment:"
echo "  rm .git/hooks/post-commit"
echo ""
echo "To manually deploy:"
echo "  ./scripts/deployment/auto-deploy-backend.sh"
echo ""
