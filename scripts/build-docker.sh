#!/bin/bash
set -e

# Nitrox Docker Build Script
# This script builds the Nitrox Docker image with proper versioning and optimization

# Configuration
IMAGE_NAME="nitrox/server"
BUILD_CONTEXT="."
DOCKERFILE="Dockerfile"

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

# Parse command line arguments
PUSH_IMAGE=false
TAG="latest"
BUILD_ARGS=""
PLATFORM=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --push)
            PUSH_IMAGE=true
            shift
            ;;
        --tag)
            TAG="$2"
            shift 2
            ;;
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        --build-arg)
            BUILD_ARGS="$BUILD_ARGS --build-arg $2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --push              Push image to registry after build"
            echo "  --tag TAG           Tag for the image (default: latest)"
            echo "  --platform PLATFORM Build for specific platform (e.g., linux/amd64,linux/arm64)"
            echo "  --build-arg ARG     Pass build argument to Docker"
            echo "  --help              Show this help message"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Validate prerequisites
log_info "Validating prerequisites..."

if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed or not in PATH"
    exit 1
fi

if ! docker info &> /dev/null; then
    log_error "Docker daemon is not running or not accessible"
    exit 1
fi

if [ ! -f "$DOCKERFILE" ]; then
    log_error "Dockerfile not found: $DOCKERFILE"
    exit 1
fi

# Get version information
if [ -f "NitroxModel/NitroxEnvironment.cs" ]; then
    VERSION=$(grep -o 'Version.*=.*new.*Version.*(\([^)]*\))' NitroxModel/NitroxEnvironment.cs | head -1 | sed 's/.*(\([^)]*\)).*/\1/' | tr -d '"' | tr -d ' ')
    if [ -n "$VERSION" ]; then
        log_info "Detected Nitrox version: $VERSION"
        if [ "$TAG" = "latest" ]; then
            TAG="$VERSION"
        fi
    fi
fi

# Build Docker image
log_info "Building Docker image: $IMAGE_NAME:$TAG"

DOCKER_BUILD_CMD="docker build"

# Add platform if specified
if [ -n "$PLATFORM" ]; then
    DOCKER_BUILD_CMD="$DOCKER_BUILD_CMD --platform $PLATFORM"
fi

# Add build arguments
if [ -n "$BUILD_ARGS" ]; then
    DOCKER_BUILD_CMD="$DOCKER_BUILD_CMD $BUILD_ARGS"
fi

# Add tags
DOCKER_BUILD_CMD="$DOCKER_BUILD_CMD -t $IMAGE_NAME:$TAG"

# Add latest tag if not building latest
if [ "$TAG" != "latest" ]; then
    DOCKER_BUILD_CMD="$DOCKER_BUILD_CMD -t $IMAGE_NAME:latest"
fi

# Add build context and dockerfile
DOCKER_BUILD_CMD="$DOCKER_BUILD_CMD -f $DOCKERFILE $BUILD_CONTEXT"

log_info "Executing: $DOCKER_BUILD_CMD"

if eval $DOCKER_BUILD_CMD; then
    log_success "Docker image built successfully: $IMAGE_NAME:$TAG"
else
    log_error "Docker build failed"
    exit 1
fi

# Show image information
log_info "Image information:"
docker images $IMAGE_NAME:$TAG --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

# Push image if requested
if [ "$PUSH_IMAGE" = true ]; then
    log_info "Pushing image to registry..."
    
    if docker push $IMAGE_NAME:$TAG; then
        log_success "Image pushed successfully: $IMAGE_NAME:$TAG"
        
        # Push latest tag if different
        if [ "$TAG" != "latest" ]; then
            if docker push $IMAGE_NAME:latest; then
                log_success "Latest tag pushed successfully: $IMAGE_NAME:latest"
            else
                log_warning "Failed to push latest tag"
            fi
        fi
    else
        log_error "Failed to push image"
        exit 1
    fi
fi

# Security scan (if available)
if command -v docker &> /dev/null && docker --help | grep -q "scout"; then
    log_info "Running security scan..."
    docker scout cves $IMAGE_NAME:$TAG || log_warning "Security scan failed or not available"
fi

log_success "Build process completed successfully!"
log_info "To run the container:"
log_info "  docker run -d -p 11000:11000/udp $IMAGE_NAME:$TAG"
log_info ""
log_info "To run with Docker Compose:"
log_info "  docker-compose up -d"