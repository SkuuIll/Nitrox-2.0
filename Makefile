# Nitrox Docker Deployment Makefile
# Provides convenient commands for building and deploying Nitrox server

# Configuration
IMAGE_NAME := nitrox/server
TAG := latest
REGISTRY := 
PLATFORM := linux/amd64,linux/arm64

# Docker build arguments
BUILD_ARGS := 
DOCKERFILE := Dockerfile

# Deployment configuration
VPS_HOST := 
VPS_USER := root
DATA_DIR := /opt/nitrox
SERVER_PORT := 11000

# Colors
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

.PHONY: help build push deploy clean test lint security-scan setup-vps

# Default target
help: ## Show this help message
	@echo "$(BLUE)Nitrox Docker Deployment$(NC)"
	@echo ""
	@echo "$(GREEN)Available targets:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build Docker image
	@echo "$(BLUE)[BUILD]$(NC) Building Docker image: $(IMAGE_NAME):$(TAG)"
	@chmod +x scripts/build-docker.sh
	@./scripts/build-docker.sh --tag $(TAG) $(if $(BUILD_ARGS),--build-arg $(BUILD_ARGS))
	@echo "$(GREEN)[SUCCESS]$(NC) Docker image built successfully"

build-multi: ## Build multi-platform Docker image
	@echo "$(BLUE)[BUILD]$(NC) Building multi-platform Docker image: $(IMAGE_NAME):$(TAG)"
	@docker buildx create --use --name nitrox-builder || true
	@docker buildx build --platform $(PLATFORM) -t $(IMAGE_NAME):$(TAG) $(if $(REGISTRY),--push) .
	@echo "$(GREEN)[SUCCESS]$(NC) Multi-platform Docker image built successfully"

push: build ## Build and push Docker image to registry
	@echo "$(BLUE)[PUSH]$(NC) Pushing Docker image to registry"
	@./scripts/build-docker.sh --tag $(TAG) --push
	@echo "$(GREEN)[SUCCESS]$(NC) Docker image pushed successfully"

test: ## Run tests for Docker deployment
	@echo "$(BLUE)[TEST]$(NC) Running Docker deployment tests"
	@docker run --rm -v $(PWD):/workspace -w /workspace $(IMAGE_NAME):$(TAG) dotnet test --logger console
	@echo "$(GREEN)[SUCCESS]$(NC) Tests completed successfully"

lint: ## Lint Dockerfile and scripts
	@echo "$(BLUE)[LINT]$(NC) Linting Dockerfile and scripts"
	@if command -v hadolint >/dev/null 2>&1; then \
		hadolint $(DOCKERFILE); \
	else \
		echo "$(YELLOW)[WARNING]$(NC) hadolint not found, skipping Dockerfile linting"; \
	fi
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck scripts/*.sh docker/*.sh; \
	else \
		echo "$(YELLOW)[WARNING]$(NC) shellcheck not found, skipping shell script linting"; \
	fi
	@echo "$(GREEN)[SUCCESS]$(NC) Linting completed"

security-scan: ## Run security scan on Docker image
	@echo "$(BLUE)[SECURITY]$(NC) Running security scan on Docker image"
	@if docker --help | grep -q scout; then \
		docker scout cves $(IMAGE_NAME):$(TAG); \
	elif command -v trivy >/dev/null 2>&1; then \
		trivy image $(IMAGE_NAME):$(TAG); \
	else \
		echo "$(YELLOW)[WARNING]$(NC) No security scanner found (docker scout or trivy)"; \
	fi

setup-vps: ## Setup VPS for Nitrox deployment (requires VPS_HOST and VPS_USER)
	@if [ -z "$(VPS_HOST)" ]; then \
		echo "$(RED)[ERROR]$(NC) VPS_HOST is required. Usage: make setup-vps VPS_HOST=your-server.com"; \
		exit 1; \
	fi
	@echo "$(BLUE)[SETUP]$(NC) Setting up VPS: $(VPS_HOST)"
	@scp scripts/setup-vps.sh $(VPS_USER)@$(VPS_HOST):/tmp/
	@ssh $(VPS_USER)@$(VPS_HOST) "chmod +x /tmp/setup-vps.sh && /tmp/setup-vps.sh"
	@echo "$(GREEN)[SUCCESS]$(NC) VPS setup completed"

deploy: ## Deploy to VPS (requires VPS_HOST)
	@if [ -z "$(VPS_HOST)" ]; then \
		echo "$(RED)[ERROR]$(NC) VPS_HOST is required. Usage: make deploy VPS_HOST=your-server.com"; \
		exit 1; \
	fi
	@echo "$(BLUE)[DEPLOY]$(NC) Deploying to VPS: $(VPS_HOST)"
	@scp scripts/deploy-vps.sh $(VPS_USER)@$(VPS_HOST):/tmp/
	@scp docker-compose.yml $(VPS_USER)@$(VPS_HOST):/opt/nitrox/
	@ssh $(VPS_USER)@$(VPS_HOST) "chmod +x /tmp/deploy-vps.sh && /tmp/deploy-vps.sh --compose"
	@echo "$(GREEN)[SUCCESS]$(NC) Deployment completed"

deploy-local: ## Deploy locally using Docker Compose
	@echo "$(BLUE)[DEPLOY]$(NC) Deploying locally with Docker Compose"
	@if [ ! -f docker-compose.yml ]; then \
		echo "$(RED)[ERROR]$(NC) docker-compose.yml not found"; \
		exit 1; \
	fi
	@docker-compose up -d
	@echo "$(GREEN)[SUCCESS]$(NC) Local deployment completed"

stop: ## Stop running Nitrox server
	@echo "$(BLUE)[STOP]$(NC) Stopping Nitrox server"
	@docker-compose down || docker stop nitrox-server || true
	@echo "$(GREEN)[SUCCESS]$(NC) Nitrox server stopped"

logs: ## Show Nitrox server logs
	@echo "$(BLUE)[LOGS]$(NC) Showing Nitrox server logs"
	@docker logs -f nitrox-server

status: ## Show Nitrox server status
	@echo "$(BLUE)[STATUS]$(NC) Nitrox server status"
	@docker ps --filter "name=nitrox-server" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.RunningFor}}"
	@echo ""
	@if docker ps --filter "name=nitrox-server" --format "{{.Names}}" | grep -q nitrox-server; then \
		echo "$(GREEN)[INFO]$(NC) Resource usage:"; \
		docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" nitrox-server; \
	fi

update: ## Update Nitrox server to latest version
	@echo "$(BLUE)[UPDATE]$(NC) Updating Nitrox server"
	@docker pull $(IMAGE_NAME):latest
	@docker-compose down || docker stop nitrox-server || true
	@docker-compose up -d || docker run -d --name nitrox-server $(IMAGE_NAME):latest
	@echo "$(GREEN)[SUCCESS]$(NC) Nitrox server updated"

backup: ## Create backup of server data
	@echo "$(BLUE)[BACKUP]$(NC) Creating backup of server data"
	@BACKUP_NAME="nitrox-backup-$(shell date +%Y%m%d-%H%M%S)"; \
	docker exec nitrox-server tar -czf /tmp/$$BACKUP_NAME.tar.gz -C /app saves config; \
	docker cp nitrox-server:/tmp/$$BACKUP_NAME.tar.gz ./$$BACKUP_NAME.tar.gz; \
	echo "$(GREEN)[SUCCESS]$(NC) Backup created: $$BACKUP_NAME.tar.gz"

restore: ## Restore server data from backup (requires BACKUP_FILE)
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "$(RED)[ERROR]$(NC) BACKUP_FILE is required. Usage: make restore BACKUP_FILE=backup.tar.gz"; \
		exit 1; \
	fi
	@echo "$(BLUE)[RESTORE]$(NC) Restoring from backup: $(BACKUP_FILE)"
	@docker cp $(BACKUP_FILE) nitrox-server:/tmp/restore.tar.gz
	@docker exec nitrox-server tar -xzf /tmp/restore.tar.gz -C /app
	@docker restart nitrox-server
	@echo "$(GREEN)[SUCCESS]$(NC) Backup restored successfully"

clean: ## Clean up Docker images and containers
	@echo "$(BLUE)[CLEAN]$(NC) Cleaning up Docker resources"
	@docker system prune -f
	@docker image prune -f
	@echo "$(GREEN)[SUCCESS]$(NC) Cleanup completed"

clean-all: ## Clean up all Docker resources (including volumes)
	@echo "$(BLUE)[CLEAN]$(NC) Cleaning up all Docker resources"
	@echo "$(YELLOW)[WARNING]$(NC) This will remove all unused Docker resources including volumes"
	@read -p "Are you sure? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	@docker system prune -a --volumes -f
	@echo "$(GREEN)[SUCCESS]$(NC) Complete cleanup finished"

dev: ## Start development environment
	@echo "$(BLUE)[DEV]$(NC) Starting development environment"
	@docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
	@echo "$(GREEN)[SUCCESS]$(NC) Development environment started"

# Kubernetes targets
k8s-deploy: ## Deploy to Kubernetes
	@echo "$(BLUE)[K8S]$(NC) Deploying to Kubernetes"
	@kubectl apply -f kubernetes/
	@echo "$(GREEN)[SUCCESS]$(NC) Kubernetes deployment completed"

k8s-status: ## Show Kubernetes deployment status
	@echo "$(BLUE)[K8S]$(NC) Kubernetes deployment status"
	@kubectl get pods,services,pvc -l app=nitrox-server

k8s-logs: ## Show Kubernetes pod logs
	@echo "$(BLUE)[K8S]$(NC) Kubernetes pod logs"
	@kubectl logs -f deployment/nitrox-server

k8s-delete: ## Delete Kubernetes deployment
	@echo "$(BLUE)[K8S]$(NC) Deleting Kubernetes deployment"
	@kubectl delete -f kubernetes/
	@echo "$(GREEN)[SUCCESS]$(NC) Kubernetes deployment deleted"

# Docker Swarm targets
swarm-deploy: ## Deploy to Docker Swarm
	@echo "$(BLUE)[SWARM]$(NC) Deploying to Docker Swarm"
	@docker stack deploy -c docker-swarm/docker-stack.yml nitrox
	@echo "$(GREEN)[SUCCESS]$(NC) Docker Swarm deployment completed"

swarm-status: ## Show Docker Swarm service status
	@echo "$(BLUE)[SWARM]$(NC) Docker Swarm service status"
	@docker service ls
	@docker service ps nitrox_nitrox-server

swarm-logs: ## Show Docker Swarm service logs
	@echo "$(BLUE)[SWARM]$(NC) Docker Swarm service logs"
	@docker service logs -f nitrox_nitrox-server

swarm-remove: ## Remove Docker Swarm stack
	@echo "$(BLUE)[SWARM]$(NC) Removing Docker Swarm stack"
	@docker stack rm nitrox
	@echo "$(GREEN)[SUCCESS]$(NC) Docker Swarm stack removed"

# Development and testing targets
install-tools: ## Install development tools
	@echo "$(BLUE)[TOOLS]$(NC) Installing development tools"
	@if ! command -v hadolint >/dev/null 2>&1; then \
		echo "Installing hadolint..."; \
		wget -O /usr/local/bin/hadolint https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64; \
		chmod +x /usr/local/bin/hadolint; \
	fi
	@if ! command -v shellcheck >/dev/null 2>&1; then \
		echo "Installing shellcheck..."; \
		apt-get update && apt-get install -y shellcheck || yum install -y shellcheck || echo "Please install shellcheck manually"; \
	fi
	@echo "$(GREEN)[SUCCESS]$(NC) Development tools installed"

# Help target should be first for default
.DEFAULT_GOAL := help