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

# Save current image as previous
PREVIOUS=$(docker inspect --format='{{.Image}}' statuspulse-app 2>/dev/null || echo "none")
log "Previous image: $PREVIOUS"

# Pull latest image
log "Pulling latest image..."
docker pull "$IMAGE"

# Start new containers
log "Starting new containers..."
docker compose up -d --build

# Wait for health check
log "Waiting for health check..."
for i in $(seq 1 30); do
    STATUS=$(curl -s http://localhost:8000/health | python3 -c "import sys,json; print(json.load(sys.stdin)['status'])" 2>/dev/null)
    if [ "$STATUS" = "healthy" ]; then
        log "✅ Deployment successful!"
        exit 0
    fi
    log "Attempt $i: not healthy yet..."
    sleep 3
done

# Rollback if health check failed
log "❌ Health check failed! Rolling back..."
docker compose down
docker tag "$PREVIOUS" "$IMAGE" 2>/dev/null || true
docker compose up -d
log "⚠️ Rolled back to previous version"
exit 1