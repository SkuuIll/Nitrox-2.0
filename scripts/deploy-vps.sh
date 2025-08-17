#!/bin/bash
set -e

# Nitrox VPS Deployment Script
# This script deploys Nitrox server to a VPS using Docker

# Configuration
DEFAULT_IMAGE="nitrox/server:latest"
DEFAULT_PORT=11000
DEFAULT_SERVER_NAME="Nitrox VPS Server"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    cat << EOF
Nitrox VPS Deployment Script

Usage: $0 [OPTIONS]

Options:
    --image IMAGE           Docker image to deploy (default: $DEFAULT_IMAGE)
    --port PORT             Server port (default: $DEFAULT_PORT)
    --server-name NAME      Server name (default: "$DEFAULT_SERVER_NAME")
    --admin-password PASS   Admin password (required)
    --server-password PASS  Server password (optional, for private servers)
    --steam-user USER       Steam username for game file download
    --steam-pass PASS       Steam password for game file download
    --game-mode MODE        Game mode: Survival, Creative, Hardcore (default: Survival)
    --max-players NUM       Maximum players (default: 100)
    --data-dir DIR          Data directory on host (default: /opt/nitrox)
    --compose               Use Docker Compose for deployment
    --update                Update existing deployment
    --stop                  Stop running server
    --logs                  Show server logs
    --status                Show server status
    --help                  Show this help message

Examples:
    # Basic deployment
    $0 --admin-password mySecurePassword123 --steam-user myuser --steam-pass mypass

    # Private server deployment
    $0 --admin-password admin123 --server-password server123 --server-name "My Private Server"

    # Update existing deployment
    $0 --update --image nitrox/server:v1.2.0

    # Check server status
    $0 --status

EOF
}

# Parse command line arguments
IMAGE="$DEFAULT_IMAGE"
PORT="$DEFAULT_PORT"
SERVER_NAME="$DEFAULT_SERVER_NAME"
ADMIN_PASSWORD=""
SERVER_PASSWORD=""
STEAM_USERNAME=""
STEAM_PASSWORD=""
GAME_MODE="Survival"
MAX_PLAYERS=100
DATA_DIR="/opt/nitrox"
USE_COMPOSE=false
UPDATE_MODE=false
STOP_SERVER=false
SHOW_LOGS=false
SHOW_STATUS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --image)
            IMAGE="$2"
            shift 2
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        --server-name)
            SERVER_NAME="$2"
            shift 2
            ;;
        --admin-password)
            ADMIN_PASSWORD="$2"
            shift 2
            ;;
        --server-password)
            SERVER_PASSWORD="$2"
            shift 2
            ;;
        --steam-user)
            STEAM_USERNAME="$2"
            shift 2
            ;;
        --steam-pass)
            STEAM_PASSWORD="$2"
            shift 2
            ;;
        --game-mode)
            GAME_MODE="$2"
            shift 2
            ;;
        --max-players)
            MAX_PLAYERS="$2"
            shift 2
            ;;
        --data-dir)
            DATA_DIR="$2"
            shift 2
            ;;
        --compose)
            USE_COMPOSE=true
            shift
            ;;
        --update)
            UPDATE_MODE=true
            shift
            ;;
        --stop)
            STOP_SERVER=true
            shift
            ;;
        --logs)
            SHOW_LOGS=true
            shift
            ;;
        --status)
            SHOW_STATUS=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Handle status command
if [ "$SHOW_STATUS" = true ]; then
    log_info "Checking Nitrox server status..."
    
    if docker ps --filter "name=nitrox-server" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q nitrox-server; then
        log_success "Nitrox server is running:"
        docker ps --filter "name=nitrox-server" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        
        # Show resource usage
        log_info "Resource usage:"
        docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" nitrox-server
    else
        log_warning "Nitrox server is not running"
    fi
    exit 0
fi

# Handle logs command
if [ "$SHOW_LOGS" = true ]; then
    log_info "Showing Nitrox server logs..."
    docker logs -f nitrox-server
    exit 0
fi

# Handle stop command
if [ "$STOP_SERVER" = true ]; then
    log_info "Stopping Nitrox server..."
    
    if USE_COMPOSE && [ -f "docker-compose.yml" ]; then
        docker-compose down
    else
        docker stop nitrox-server || true
        docker rm nitrox-server || true
    fi
    
    log_success "Nitrox server stopped"
    exit 0
fi

# Validate prerequisites
log_info "Validating prerequisites..."

if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed. Please install Docker first."
    exit 1
fi

if ! docker info &> /dev/null; then
    log_error "Docker daemon is not running or not accessible"
    exit 1
fi

# Validate required parameters for deployment
if [ "$UPDATE_MODE" = false ] && [ -z "$ADMIN_PASSWORD" ]; then
    log_error "Admin password is required for new deployments"
    log_info "Use --admin-password to set the admin password"
    exit 1
fi

# Create data directories
log_info "Setting up data directories..."
sudo mkdir -p "$DATA_DIR"/{gamefiles,saves,config,logs}
sudo chown -R 1000:1000 "$DATA_DIR"

# Stop existing container if updating
if [ "$UPDATE_MODE" = true ]; then
    log_info "Stopping existing Nitrox server for update..."
    docker stop nitrox-server 2>/dev/null || true
    docker rm nitrox-server 2>/dev/null || true
fi

# Deploy using Docker Compose or direct Docker
if [ "$USE_COMPOSE" = true ]; then
    deploy_with_compose
else
    deploy_with_docker
fi

# Function to deploy with Docker Compose
deploy_with_compose() {
    log_info "Deploying with Docker Compose..."
    
    # Create docker-compose.yml if it doesn't exist
    if [ ! -f "docker-compose.yml" ]; then
        log_info "Creating docker-compose.yml..."
        cat > docker-compose.yml << EOF
version: '3.8'

services:
  nitrox-server:
    image: $IMAGE
    container_name: nitrox-server
    restart: unless-stopped
    ports:
      - "$PORT:11000/udp"
    environment:
      - NITROX_SERVER_NAME=$SERVER_NAME
      - NITROX_SERVER_PORT=11000
      - NITROX_ADMIN_PASSWORD=$ADMIN_PASSWORD
      - NITROX_SERVER_PASSWORD=$SERVER_PASSWORD
      - NITROX_GAME_MODE=$GAME_MODE
      - NITROX_MAX_PLAYERS=$MAX_PLAYERS
      - NITROX_ENABLE_STEAM_DOWNLOAD=true
      - STEAM_USERNAME=$STEAM_USERNAME
      - STEAM_PASSWORD=$STEAM_PASSWORD
    volumes:
      - $DATA_DIR/gamefiles:/app/gamefiles
      - $DATA_DIR/saves:/app/saves
      - $DATA_DIR/config:/app/config
      - $DATA_DIR/logs:/app/logs
    healthcheck:
      test: ["/app/healthcheck.sh"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 120s
EOF
    fi
    
    # Deploy with Docker Compose
    docker-compose up -d
    
    if [ $? -eq 0 ]; then
        log_success "Nitrox server deployed successfully with Docker Compose"
    else
        log_error "Docker Compose deployment failed"
        exit 1
    fi
}

# Function to deploy with direct Docker
deploy_with_docker() {
    log_info "Deploying with Docker..."
    
    # Pull latest image
    log_info "Pulling Docker image: $IMAGE"
    docker pull "$IMAGE"
    
    # Build Docker run command
    DOCKER_CMD="docker run -d"
    DOCKER_CMD="$DOCKER_CMD --name nitrox-server"
    DOCKER_CMD="$DOCKER_CMD --restart unless-stopped"
    DOCKER_CMD="$DOCKER_CMD -p $PORT:11000/udp"
    
    # Environment variables
    DOCKER_CMD="$DOCKER_CMD -e NITROX_SERVER_NAME='$SERVER_NAME'"
    DOCKER_CMD="$DOCKER_CMD -e NITROX_SERVER_PORT=11000"
    DOCKER_CMD="$DOCKER_CMD -e NITROX_ADMIN_PASSWORD='$ADMIN_PASSWORD'"
    DOCKER_CMD="$DOCKER_CMD -e NITROX_SERVER_PASSWORD='$SERVER_PASSWORD'"
    DOCKER_CMD="$DOCKER_CMD -e NITROX_GAME_MODE='$GAME_MODE'"
    DOCKER_CMD="$DOCKER_CMD -e NITROX_MAX_PLAYERS=$MAX_PLAYERS"
    DOCKER_CMD="$DOCKER_CMD -e NITROX_ENABLE_STEAM_DOWNLOAD=true"
    DOCKER_CMD="$DOCKER_CMD -e STEAM_USERNAME='$STEAM_USERNAME'"
    DOCKER_CMD="$DOCKER_CMD -e STEAM_PASSWORD='$STEAM_PASSWORD'"
    
    # Volume mounts
    DOCKER_CMD="$DOCKER_CMD -v $DATA_DIR/gamefiles:/app/gamefiles"
    DOCKER_CMD="$DOCKER_CMD -v $DATA_DIR/saves:/app/saves"
    DOCKER_CMD="$DOCKER_CMD -v $DATA_DIR/config:/app/config"
    DOCKER_CMD="$DOCKER_CMD -v $DATA_DIR/logs:/app/logs"
    
    # Image
    DOCKER_CMD="$DOCKER_CMD $IMAGE"
    
    log_info "Starting Nitrox server container..."
    if eval $DOCKER_CMD; then
        log_success "Nitrox server deployed successfully"
    else
        log_error "Docker deployment failed"
        exit 1
    fi
}

# Deploy the server
if [ "$USE_COMPOSE" = true ]; then
    deploy_with_compose
else
    deploy_with_docker
fi

# Wait for container to start
log_info "Waiting for server to start..."
sleep 10

# Check if container is running
if docker ps --filter "name=nitrox-server" --format "{{.Names}}" | grep -q nitrox-server; then
    log_success "Nitrox server is running!"
    
    # Show connection information
    log_info "Server Information:"
    echo "  Server Name: $SERVER_NAME"
    echo "  Port: $PORT (UDP)"
    echo "  Game Mode: $GAME_MODE"
    echo "  Max Players: $MAX_PLAYERS"
    echo ""
    
    # Get server IP
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "YOUR_SERVER_IP")
    log_info "Connection Details:"
    echo "  Server IP: $SERVER_IP"
    echo "  Port: $PORT"
    echo ""
    
    log_info "Useful Commands:"
    echo "  View logs: $0 --logs"
    echo "  Check status: $0 --status"
    echo "  Stop server: $0 --stop"
    echo "  Update server: $0 --update --image nitrox/server:latest"
    
else
    log_error "Server failed to start. Check logs with: docker logs nitrox-server"
    exit 1
fi