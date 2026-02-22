#!/bin/bash
# Gemura deployment credentials for Kwezi server (209.74.80.195)
# Do not commit - in .gitignore

# Server details (same server as Orchestrate v2, Kwezi, HcRF)
SERVER_IP="209.74.80.195"
SERVER_USER="root"
SERVER_PASS="yZ961O53GtQdP2prAu"
SERVER_PORT="22"

# Deployment paths
DEPLOY_PATH="/opt/gemura"

# Ports (avoiding conflict with existing apps)
# - 3000: Kwezi UI
# - 3002: HcRF UI
# - 3003: HcRF API
# - 3004: Orchestrate UI
# - 3005: Orchestrate API
# - 3006: Gemura UI (new)
# - 3007: Gemura API (new)
UI_PORT="3006"
API_PORT="3007"

# Database (using existing Kwezi PostgreSQL)
DB_NAME="gemura_db"
DB_USER="kwezi"
# DB_PASS is in Kwezi's .env on server (/opt/kwezi/.env -> POSTGRES_PASSWORD)

# Export for use in other scripts
export SERVER_IP SERVER_USER SERVER_PASS SERVER_PORT
export DEPLOY_PATH UI_PORT API_PORT DB_NAME DB_USER
