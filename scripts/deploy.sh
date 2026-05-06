#!/bin/bash

set -e

DEPLOY_DIR="/opt/statuspulse"
IMAGE="ghcr.io/ashutosh1998github/statuspulse:latest"
LOG_FILE="/var/log/statuspulse-deploy.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== Starting deployment ==="

cd "$DEPLOY_DIR"

# Pull latest image
log "Pulling latest image..."
docker pull "$IMAGE"

# Start new containers
log "Starting new containers..."
docker compose up -d

# Wait for health check
log "Waiting for health check..."
for i in $(seq 1 30); do
    STATUS=$(curl -s https://statuspulse.duckdns.org/health | python3 -c "import sys,json; print(json.load(sys.stdin)['status'])" 2>/dev/null)
    if [ "$STATUS" = "healthy" ]; then
        log "✅ Deployment successful!"
        exit 0
    fi
    log "Attempt $i: not healthy yet..."
    sleep 3
done

log "❌ Health check failed!"
exit 1