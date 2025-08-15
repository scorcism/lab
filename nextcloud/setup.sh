#!/bin/bash
set -e 

echo "Starting ..."

NEXTCLOUD_DIR="$HOME/nextcloud"
COMPOSE_FILE="docker-compose.yml"

check_docker() {
    if ! docker info >/dev/null 2>&1; then
        echo "Error: Docker is not running. Please start Docker and try again."
        exit 1
    fi
    echo "Docker is running"
}

# Function to check if docker-compose is available
check_docker_compose() {
    if command -v docker-compose >/dev/null 2>&1; then
        COMPOSE_CMD="docker-compose"
    elif docker compose version >/dev/null 2>&1; then
        COMPOSE_CMD="docker compose"
    else
        echo "Error: Neither 'docker-compose' nor 'docker compose' is available."
        echo "Please install Docker Compose and try again."
        exit 1
    fi
    echo "Docker Compose is available: $COMPOSE_CMD"
}

# Function to create nextcloud directory
create_directories() {
    echo "Creating Nextcloud data directory: $NEXTCLOUD_DIR"
    
    if [ -d "$NEXTCLOUD_DIR" ]; then
        echo "Directory $NEXTCLOUD_DIR already exists"
        read -p "Do you want to continue? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Setup cancelled by user"
            exit 1
        fi
    else
        mkdir -p "$NEXTCLOUD_DIR"
        echo "Created directory: $NEXTCLOUD_DIR"
    fi
}

# Function to set proper permissions
set_permissions() {
    echo "Setting proper permissions for Nextcloud directory..."
    
    # Check if we need sudo for chown
    if [ "$(stat -c '%u' "$NEXTCLOUD_DIR")" != "33" ]; then
        echo "Setting ownership to www-data (UID: 33)..."
        if sudo -n true 2>/dev/null; then
            # Can use sudo without password
            sudo chown -R 33:33 "$NEXTCLOUD_DIR"
        else
            # Need to prompt for sudo
            echo "Administrator privileges required to set proper ownership."
            sudo chown -R 33:33 "$NEXTCLOUD_DIR"
        fi
        echo "Permissions set successfully"
    else
        echo "Permissions already correct"
    fi
}

# Function to check if compose file exists
check_compose_file() {
    if [ ! -f "$COMPOSE_FILE" ]; then
        echo "Error: $COMPOSE_FILE not found in current directory"
        echo "Please make sure the docker-compose.yml file is in the current directory"
        exit 1
    fi
    echo "Found docker-compose.yml file"
}

# Function to start services
start_services() {
    echo "Starting Nextcloud services..."
    
    # Pull latest images
    echo "Pulling latest Docker images..."
    $COMPOSE_CMD pull
    
    # Start services in detached mode
    echo "Starting containers..."
    $COMPOSE_CMD up -d
    
    # Check if services are running
    sleep 5
    if $COMPOSE_CMD ps | grep -q "Up"; then
        echo "Services started successfully!"
        echo ""
        echo "Nextcloud is now accessible at: http://localhost:8082"
        echo "Data directory: $NEXTCLOUD_DIR"
        echo ""
        echo "Service status:"
        $COMPOSE_CMD ps
        echo ""
        echo "To view logs: $COMPOSE_CMD logs -f"
        echo "To stop services: $COMPOSE_CMD down"
    else
        echo "Some services failed to start. Check the logs:"
        $COMPOSE_CMD logs
        exit 1
    fi
}

# Function to show completion message
show_completion() {
    echo ""
    echo "Nextcloud setup completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Open your browser and go to: http://localhost:8082"
    echo "2. Follow the Nextcloud setup wizard"
    echo "3. Database settings are already configured in the compose file"
    echo ""
    echo "Useful commands:"
    echo "• View logs: $COMPOSE_CMD logs -f [service_name]"
    echo "• Restart services: $COMPOSE_CMD restart"
    echo "• Stop services: $COMPOSE_CMD down"
    echo "• Update services: $COMPOSE_CMD pull && $COMPOSE_CMD up -d"
}

main() {
    echo "Starting Setup..."
    
    check_docker
    check_docker_compose
    check_compose_file
    create_directories
    set_permissions
    start_services
    show_completion
}

main "$@"
