#!/bin/bash

LOG_FILE="setup.log"
SYNC_SCRIPT_PATH="$HOME/lab/sync-s3.sh"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

handle_error() {
    log "Error occurred in script execution. Exiting."
    exit 1
}

trap handle_error ERR
set -e  # Exit on error

log "Starting Nextcloud, Netdata, and S3 sync setup..."

if [[ $EUID -ne 0 ]]; then
    log "Error: This script must be run as root or with sudo."
    exit 1
fi

install_package() {
    if ! command -v "$1" &> /dev/null; then
        log "$1 is not installed. Installing now..."
        apt update && apt install -y "$2"
    else
        log "$1 is already installed."
    fi
}

install_package docker docker.io
install_package docker-compose docker-compose
install_package aws awscli

log "Running Netdata setup..."
chmod +x netdata.sh
./netdata.sh || { log "Error running netdata.sh"; exit 1; }
log "Netdata setup completed successfully."

log "Starting Nextcloud with Docker Compose..."
docker-compose -f nextcloud-docker-compose.yml up -d || { log "Error running Nextcloud docker-compose"; exit 1; }
log "Nextcloud started successfully."

log "Currently running containers:"
docker ps | tee -a "$LOG_FILE"

log "Checking for AWS credentials..."
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    log "AWS credentials not found. Prompting user for setup."
    read -p "Enter AWS Access Key: " AWS_ACCESS_KEY_ID
    read -s -p "Enter AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
    echo
    read -p "Enter S3 Bucket Name: " AWS_S3_BUCKET

    mkdir -p ~/.aws
    cat > ~/.aws/credentials <<EOF
[default]
aws_access_key_id = $AWS_ACCESS_KEY_ID
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY
EOF

    cat > ~/.aws/config <<EOF
[default]
region = us-east-1
output = json
EOF

    log "AWS credentials configured successfully."
else
    log "AWS credentials already configured."
fi

log "Setting up cron job for daily S3 sync..."
CRON_JOB="0 0 * * * $SYNC_SCRIPT_PATH >> $LOG_FILE 2>&1"

(crontab -l 2>/dev/null | grep -v "$SYNC_SCRIPT_PATH"; echo "$CRON_JOB") | crontab -

log "Cron job added successfully to run sync-s3.sh daily at 12 AM."
log "Setup completed successfully."

exit 0
