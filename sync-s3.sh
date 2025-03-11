#!/bin/bash

LOG_FILE="sync-s3.log"
CONTAINER_NAME="nextcloud"
SRC_PATH="/var/www/html/data"
DEST_PATH="$HOME/nextcloud_backup"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

handle_error() {
    log "Error occurred. Exiting."
    exit 1
}

trap handle_error ERR
set -e

log "Starting Nextcloud backup process..."

AWS_S3_BUCKET=$(awk -F' = ' '/aws_s3_bucket/ {print $2}' ~/.aws/credentials)

if [ -z "$AWS_S3_BUCKET" ]; then
    log "Error: AWS S3 bucket name is missing in ~/.aws/credentials"
    exit 1
fi

log "Using AWS S3 Bucket: $AWS_S3_BUCKET"

mkdir -p "$DEST_PATH"

log "Copying files from container: $CONTAINER_NAME..."
docker cp "$CONTAINER_NAME:$SRC_PATH" "$DEST_PATH"

ARCHIVE_NAME="nextcloud_backup_$(date +%Y-%m-%d).tar.zst"

log "Compressing backup..."
tar --zstd -cf "$ARCHIVE_NAME" -C "$DEST_PATH" .

log "Uploading to S3: s3://$AWS_S3_BUCKET"
aws s3 cp "$ARCHIVE_NAME" "s3://$AWS_S3_BUCKET/"

log "Backup uploaded successfully!"
exit 0
