#!/bin/bash

HEALTH_URL="https://statuspulse.duckdns.org/health"
ALERT_WEBHOOK_URL="${ALERT_WEBHOOK_URL:-}"
LOG_FILE="/var/log/statuspulse-monitor.log"
DOMAIN="statuspulse.duckdns.org"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

send_alert() {
    local MESSAGE=$1
    log "🚨 ALERT: $MESSAGE"
    if [ -n "$ALERT_WEBHOOK_URL" ]; then
        curl -s -X POST "$ALERT_WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "{\"content\": \"🚨 StatusPulse Alert: $MESSAGE\"}" \
            > /dev/null 2>&1
    fi
}

log "=== Health Check Started ==="

# Check 1 - API Health
log "Checking API health..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$HEALTH_URL" 2>/dev/null)
if [ "$HTTP_CODE" != "200" ]; then
    send_alert "API health check failed! HTTP code: $HTTP_CODE"
else
    log "✅ API healthy (HTTP $HTTP_CODE)"
fi

# Check 2 - Disk Usage
log "Checking disk usage..."
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
if [ "$DISK_USAGE" -gt 80 ]; then
    send_alert "Disk usage is ${DISK_USAGE}% - above 80% threshold!"
else
    log "✅ Disk usage: ${DISK_USAGE}%"
fi

# Check 3 - Memory Usage
log "Checking memory usage..."
MEM_USAGE=$(free | awk 'NR==2 {printf "%.0f", $3/$2*100}')
if [ "$MEM_USAGE" -gt 90 ]; then
    send_alert "Memory usage is ${MEM_USAGE}% - above 90% threshold!"
else
    log "✅ Memory usage: ${MEM_USAGE}%"
fi

# Check 4 - Docker Containers
log "Checking Docker containers..."
EXPECTED_CONTAINERS=("statuspulse-app" "statuspulse-postgres" "statuspulse-redis" "statuspulse-caddy" "statuspulse-uptime-kuma")
for CONTAINER in "${EXPECTED_CONTAINERS[@]}"; do
    STATUS=$(docker inspect --format='{{.State.Running}}' "$CONTAINER" 2>/dev/null)
    if [ "$STATUS" != "true" ]; then
        send_alert "Container $CONTAINER is not running!"
    else
        log "✅ Container $CONTAINER is running"
    fi
done

# Check 5 - TLS Certificate
log "Checking TLS certificate..."
CERT_EXPIRY=$(echo | openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
if [ -n "$CERT_EXPIRY" ]; then
    EXPIRY_EPOCH=$(date -d "$CERT_EXPIRY" +%s 2>/dev/null)
    NOW_EPOCH=$(date +%s)
    DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))
    if [ "$DAYS_LEFT" -lt 14 ]; then
        send_alert "TLS certificate expires in $DAYS_LEFT days!"
    else
        log "✅ TLS certificate valid for $DAYS_LEFT days"
    fi
fi

log "=== Health Check Complete ==="