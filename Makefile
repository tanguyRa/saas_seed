DEV_COMPOSE=docker compose --env-file .env.dev -f compose.yml -p ${PROJECT_NAME}

PROJECT_NAME ?= project
DOCKER_TARGET ?= development
BACKEND_SERVICE := back

.PHONY: help build start stop restart logs clean \
        check-backend-running migrate-up migrate-down migration sqlc \
        front back test

# ============================================
# Help
# ============================================
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Development:"
	@echo "  start         Start all services (front, back, db)"
	@echo "  stop          Stop all services"
	@echo "  restart       Restart all services"
	@echo "  logs          View logs from all services"
	@echo "  clean         Remove containers and volumes"
	@echo ""
	@echo "Database:"
	@echo "  migrate-up    Run database migrations (N optional, default: all)"
	@echo "  migrate-down  Rollback migrations (N optional, default: 1)"
	@echo "  migration     Create new migration (name=\"...\")"
	@echo "  sqlc          Generate SQL code"
	@echo ""
	@echo "Utilities:"
	@echo "  front         SSH into frontend container"
	@echo "  back          SSH into backend container"
	@echo "  test          Run tests"
	@echo "  pull          Pull latest images"
	@echo ""
	@echo "Production:"
	@echo "  build-prod    Build production images"

# ============================================
# Development
# ============================================
start: build start-all migrate
	@echo ""
	@echo "Done. Happy coding!"

build:
	${DEV_COMPOSE} build --pull

start-all:
	@echo "Starting ${PROJECT_NAME}..."
	${DEV_COMPOSE} up -d --remove-orphans
	@echo ""
	@echo "Services running:"
	@echo "  - front (SvelteKit frontend): http://localhost:3000"
	@echo "  - back (Go backend):         http://localhost:8080"
	@echo "  - db (local database):     http://localhost:5432"

stop:
	${DEV_COMPOSE} down

restart: stop start

logs:
	${DEV_COMPOSE} logs -f

clean:
	${DEV_COMPOSE} down -v --remove-orphans
	@echo "Cleaned up containers and volumes"

# ============================================
# Database Management
# ============================================
check-backend-running:
	@${DEV_COMPOSE} ps --status running --services | grep -qx "${BACKEND_SERVICE}" || (echo "backend service '${BACKEND_SERVICE}' is not running. Start it with 'make start'."; exit 1)

migrate: migrate-up
migrate-up: check-backend-running
	@echo "Applying migrations..."
	${DEV_COMPOSE} exec ${BACKEND_SERVICE} sh -c 'migrate -path /db/migrations -database "$$DATABASE_URL" up ${N}'

migrate-down: check-backend-running
	@echo "Rolling back $(if $(N),$(N),1) migrations..."
	${DEV_COMPOSE} exec ${BACKEND_SERVICE} sh -c 'migrate -path /db/migrations -database "$$DATABASE_URL" down $(if $(N),$(N),1)'

migration:
	@if [ -z "$(name)" ]; then \
		echo "Usage: make migration name=\"migration_name\""; \
		exit 1; \
	fi
	@echo "Creating migration: $(name)"
	@mkdir -p db/migrations
	@touch db/migrations/$$(date +%Y%m%d%H%M%S)_$(name).up.sql
	@touch db/migrations/$$(date +%Y%m%d%H%M%S)_$(name).down.sql
	@echo "Created migration files"

sqlc: check-backend-running
	@echo "Generating SQL code..."
	${DEV_COMPOSE} exec ${BACKEND_SERVICE} go run -mod=mod github.com/sqlc-dev/sqlc/cmd/sqlc@latest generate -f /db/sqlc.yml
	@echo "Done"

# ============================================
# Utilities
# ============================================
front:
	${DEV_COMPOSE} exec front sh

back:
	${DEV_COMPOSE} exec ${BACKEND_SERVICE} sh

test:
	${DEV_COMPOSE} exec ${BACKEND_SERVICE} go test ./...
	docker run --rm --env-file .env.dev -v ./worker:/app -w /app golang:1.25-alpine sh -c "apk add --no-cache git >/dev/null && go test ./..."

# ============================================
# Production
# ============================================
build-prod:
	docker compose --env-file .env.prod -f compose.yml -p ${PROJECT_NAME} build
