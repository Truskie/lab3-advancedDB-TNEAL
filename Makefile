# Makefile for lab2-terrylneal

# Variables
GO = go
MIGRATE = migrate
DB_URL = postgresql://lab2_user:lab2pass@localhost/lab2_terrylneal?sslmode=disable
PORT = 4000

# Colors for output
GREEN = \033[0;32m
RED = \033[0;31m
NC = \033[0m # No Color

.PHONY: help run build test migrate-up migrate-down migrate-force clean db-create db-drop

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

run: ## Run the application
	@echo "$(GREEN)Starting server on port $(PORT)...$(NC)"
	$(GO) run cmd/api/main.go

build: ## Build the application
	@echo "$(GREEN)Building application...$(NC)"
	$(GO) build -o bin/api cmd/api/main.go
	@echo "$(GREEN)Build complete! Binary saved to bin/api$(NC)"

test: ## Run tests
	@echo "$(GREEN)Running tests...$(NC)"
	$(GO) test -v ./...

test-json: ## Run tests with JSON output
	$(GO) test -json ./...

cover: ## Run tests with coverage
	$(GO) test -cover ./...

migrate-up: ## Run all up migrations
	@echo "$(GREEN)Running migrations up...$(NC)"
	$(MIGRATE) -path ./migrations -database "$(DB_URL)" up

migrate-down: ## Rollback the last migration
	@echo "$(RED)Rolling back last migration...$(NC)"
	$(MIGRATE) -path ./migrations -database "$(DB_URL)" down 1

migrate-down-all: ## Rollback all migrations
	@echo "$(RED)Rolling back all migrations...$(NC)"
	$(MIGRATE) -path ./migrations -database "$(DB_URL)" down -all

migrate-force: ## Force set migration version (usage: make migrate-force VERSION=1)
	@echo "$(RED)Forcing migration version to $(VERSION)...$(NC)"
	$(MIGRATE) -path ./migrations -database "$(DB_URL)" force $(VERSION)

migrate-version: ## Show current migration version
	$(MIGRATE) -path ./migrations -database "$(DB_URL)" version

db-create: ## Create the database and user (requires postgres superuser)
	@echo "$(GREEN)Creating database and user...$(NC)"
	sudo -u postgres psql -c "CREATE DATABASE lab2_terrylneal;"
	sudo -u postgres psql -c "CREATE USER lab2_user WITH PASSWORD 'lab2pass';"
	sudo -u postgres psql -c "ALTER DATABASE lab2_terrylneal OWNER TO lab2_user;"
	sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE lab2_terrylneal TO lab2_user;"
	sudo -u postgres psql -d lab2_terrylneal -c "GRANT ALL ON SCHEMA public TO lab2_user;"

db-drop: ## Drop the database and user (careful!)
	@echo "$(RED)Dropping database and user...$(NC)"
	sudo -u postgres psql -c "DROP DATABASE IF EXISTS lab2_terrylneal;"
	sudo -u postgres psql -c "DROP USER IF EXISTS lab2_user;"

db-reset: db-drop db-create migrate-up ## Reset database and run migrations

deps: ## Download dependencies
	$(GO) mod download
	$(GO) mod tidy

clean: ## Clean build artifacts
	@echo "$(GREEN)Cleaning...$(NC)"
	rm -rf bin/
	$(GO) clean

fmt: ## Format code
	$(GO) fmt ./...

lint: ## Run linter (requires golangci-lint)
	@which golangci-lint > /dev/null && golangci-lint run || echo "golangci-lint not installed"

dev: ## Run with live reload (requires air)
	@which air > /dev/null && air || echo "air not installed, using regular run"
	$(MAKE) run

curl-get: ## Test GET endpoints with curl
	@echo "$(GREEN)Testing / endpoint...$(NC)"
	curl -s http://localhost:$(PORT)/
	@echo "\n$(GREEN)Testing /about endpoint...$(NC)"
	curl -s http://localhost:$(PORT)/about
	@echo "\n$(GREEN)Testing /api/info endpoint...$(NC)"
	curl -s http://localhost:$(PORT)/api/info | jq '.' 2>/dev/null || curl -s http://localhost:$(PORT)/api/info
	@echo "\n$(GREEN)Testing /api/users endpoint...$(NC)"
	curl -s http://localhost:$(PORT)/api/users | jq '.' 2>/dev/null || curl -s http://localhost:$(PORT)/api/users

curl-post: ## Test POST endpoint with curl
	@echo "$(GREEN)Testing POST /api/users/create endpoint...$(NC)"
	curl -X POST http://localhost:$(PORT)/api/users/create \
		-H "Content-Type: application/json" \
		-d '{"username":"testuser","email":"test@example.com"}' \
		| jq '.' 2>/dev/null || curl -X POST http://localhost:$(PORT)/api/users/create \
		-H "Content-Type: application/json" \
		-d '{"username":"testuser","email":"test@example.com"}'

.PHONY: install-tools
install-tools: ## Install development tools
	go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest
	go install github.com/air-verse/air@latest
	go install github.com/go-delve/delve/cmd/dlv@latest

# Default target
all: deps build