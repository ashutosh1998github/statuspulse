#!/bin/bash

BACKUP_DIR="/opt/statuspulse/backups"
LOG_FILE="/var/log/statuspulse-monitor.log"
MAX_BACKUPS=7
TIMESTAMP=$(date '+%Y-%m-%d_%H%M%S')
BACKUP_FILE="$BACKUP_DIR/statuspulse_db_${TIMESTAMP}.sql.gz"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== Starting backup ==="

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Dump PostgreSQL
log "Dumping PostgreSQL..."
docker exec statuspulse-postgres pg_dump \
    -U statuspulse \
    -d statuspulse \
    | gzip > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    log "✅ Backup created: $BACKUP_FILE"
else
    log "❌ Backup failed!"
    exit 1
fi

# Keep only last 7 backups
log "Rotating old backups..."
ls -t "$BACKUP_DIR"/*.sql.gz 2>/dev/null | tail -n +$((MAX_BACKUPS + 1)) | xargs -r rm
log "✅ Old backups rotated"

# Upload to S3 if configured
if [ -n "$S3_BUCKET" ]; then
    log "Uploading to S3..."
    aws s3 cp "$BACKUP_FILE" "s3://$S3_BUCKET/backups/"
    log "✅ Uploaded to S3"
fi

log "=== Backup complete ==="