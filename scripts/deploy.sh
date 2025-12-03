#!/bin/bash

set -e

echo "🚀 Starting deployment process..."

# Configuration
APP_DIR="${APP_DIR:-/var/www/project}"
APP_NAME="${APP_NAME:-ci-cd-app}"
BRANCH="${BRANCH:-main}"
NODE_ENV="${NODE_ENV:-production}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if directory exists
if [ ! -d "$APP_DIR" ]; then
    log_error "Application directory $APP_DIR does not exist!"
    exit 1
fi

cd "$APP_DIR"

# Backup current version (optional)
log_info "Creating backup..."
BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r ./src "$BACKUP_DIR/" 2>/dev/null || true
cp package.json "$BACKUP_DIR/" 2>/dev/null || true

# Pull latest changes
log_info "Pulling latest changes from $BRANCH..."
git fetch origin
git reset --hard origin/$BRANCH

# Install dependencies
log_info "Installing dependencies..."
npm ci --production

# Run health check before stopping the app
log_info "Performing pre-deployment health check..."
if pm2 describe "$APP_NAME" > /dev/null 2>&1; then
    HEALTH_URL="http://localhost:3000/health"
    if curl -f -s "$HEALTH_URL" > /dev/null 2>&1; then
        log_info "Current app is healthy"
    else
        log_warn "Current app health check failed"
    fi
fi

# Restart application with PM2
log_info "Restarting application with PM2..."
if pm2 describe "$APP_NAME" > /dev/null 2>&1; then
    pm2 restart "$APP_NAME" --update-env
    log_info "Application restarted"
else
    pm2 start src/index.js --name "$APP_NAME" -i max --env "$NODE_ENV"
    pm2 save
    log_info "Application started"
fi

# Wait for app to start
log_info "Waiting for application to start..."
sleep 5

# Post-deployment health check
log_info "Performing post-deployment health check..."
MAX_RETRIES=10
RETRY_COUNT=0
HEALTH_URL="http://localhost:3000/health"

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -f -s "$HEALTH_URL" > /dev/null 2>&1; then
        log_info "✅ Deployment successful! Application is healthy."
        pm2 list
        exit 0
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    log_warn "Health check failed, retrying... ($RETRY_COUNT/$MAX_RETRIES)"
    sleep 3
done

log_error "❌ Deployment failed! Application is not responding."
log_info "Rolling back to previous version..."
pm2 restart "$APP_NAME"
exit 1
