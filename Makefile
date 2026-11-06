# Variables
DOCKER_COMPOSE = docker compose

# Makefile for managing the Design-First API governance ecosystem
# (Data Governance nginx, Swagger Editor, Backstage developer portal).
.PHONY: help
help:
	@cmd /C "echo Usage:"
	@cmd /C "echo 	make up             	- Start all containers (builds backstage on first run)"
	@cmd /C "echo 	make build          	- Build the backstage image"
	@cmd /C "echo 	make build-no-cache 	- Rebuild the backstage image without cache"
	@cmd /C "echo 	make down           	- Stop and remove all containers"
	@cmd /C "echo 	make restart        	- Restart all containers"
	@cmd /C "echo 	make logs           	- Show logs from all containers"
	@cmd /C "echo 	make backstage-logs 	- Show logs from the Backstage container"
	@cmd /C "echo 	make governance-logs	- Show logs from the Data Governance (nginx) container"
	@cmd /C "echo 	make ps             	- Show container status"
	@cmd /C "echo 	make verify         	- Curl all acceptance endpoints and print status codes"
	@cmd /C "echo 	make clean          	- Stop containers and remove volumes/images built by this project"

# Build the backstage image
.PHONY: build
build:
	@echo "Building the Backstage image..."
	$(DOCKER_COMPOSE) build backstage

# Build the backstage image without cache
.PHONY: build-no-cache
build-no-cache:
	@echo "Building the Backstage image without cache..."
	$(DOCKER_COMPOSE) build --no-cache --progress=plain backstage

# Start all containers
.PHONY: up
up:
	@echo "Starting the governance, swagger-editor and backstage containers..."
	$(DOCKER_COMPOSE) up -d

# Stop and remove all containers
.PHONY: down
down:
	@echo "Stopping and removing containers..."
	$(DOCKER_COMPOSE) down

# Restart all containers
.PHONY: restart
restart: down up
	@echo "Restarted the containers."

# Show logs from all containers
.PHONY: logs
logs:
	@echo "Showing logs from all containers..."
	$(DOCKER_COMPOSE) logs -f

# Show logs from the backstage container
.PHONY: backstage-logs
backstage-logs:
	@echo "Showing logs from the Backstage container..."
	$(DOCKER_COMPOSE) logs -f backstage

# Show logs from the governance container
.PHONY: governance-logs
governance-logs:
	@echo "Showing logs from the Data Governance container..."
	$(DOCKER_COMPOSE) logs -f governance

# Show container status
.PHONY: ps
ps:
	$(DOCKER_COMPOSE) ps

# Curl the acceptance endpoints (use --noproxy to bypass a corporate proxy
# that may otherwise intercept localhost requests)
.PHONY: verify
verify:
	@echo "Checking governance shared-models.yaml..."
	@curl --noproxy '*' -sS -o NUL -w "  shared-models.yaml: %{http_code}\n" http://localhost:8081/shared-models.yaml
	@curl --noproxy '*' -sS -o NUL -w "  sample-orders-api/openapi.yaml: %{http_code}\n" http://localhost:8081/apis/sample-orders-api/openapi.yaml
	@echo "Checking swagger editor..."
	@curl --noproxy '*' -sS -o NUL -w "  swagger-editor: %{http_code}\n" http://localhost:8082
	@echo "Checking backstage..."
	@curl --noproxy '*' -sS -o NUL -w "  backstage frontend: %{http_code}\n" http://localhost:3000
	@curl --noproxy '*' -sS -o NUL -w "  backstage catalog entities: %{http_code}\n" http://localhost:7007/api/catalog/entities

# Clean up containers, networks and the built backstage image
.PHONY: clean
clean:
	@echo "Stopping containers and removing volumes/images..."
	$(DOCKER_COMPOSE) down -v --rmi local
	@echo "Clean complete."
