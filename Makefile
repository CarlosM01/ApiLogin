# ──────────────────────────────────────────────────────────
#  Login API – Makefile
# ──────────────────────────────────────────────────────────

APP_MODULE  := main:app
HOST        := 0.0.0.0
PORT        := 8000
VENV        := .venv
PIP         := $(VENV)/bin/pip
PYTHON      := $(VENV)/bin/python
UVICORN     := $(VENV)/bin/uvicorn
IMAGE_NAME  := login-api

# An attempt is made to run 'docker compose version'. If it fails, 'docker-compose' is assumed.
DOCKER_COMPOSE := $(shell docker compose version > /dev/null 2>&1 && echo "docker compose" || echo "docker-compose")
.PHONY: help setup venv install run dev clean lint format \
        build run-image up down logs

## ── Help ────────────────────────────────────────────────
help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

## ── Setup & Dependencies ─────────────────────────────────
setup: ## Configure the entire API environment (venv, .env, install, build)
	@if [ ! -f .env ]; then cp .env.example .env; echo ".env file created from .env.example"; fi
	@$(MAKE) install
	@$(MAKE) build

venv: ## Create a Python virtual environment
	python3 -m venv $(VENV)

install: venv ## Install dependencies into the venv
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements.txt

## ── Run ─────────────────────────────────────────────────
run: ## Start the API server
	$(UVICORN) $(APP_MODULE) --host $(HOST) --port $(PORT)

dev: ## Start the API server with hot-reload
	$(UVICORN) $(APP_MODULE) --host $(HOST) --port $(PORT) --reload

## ── Code Quality ────────────────────────────────────────
lint: ## Run ruff linter
	$(VENV)/bin/ruff check .

format: ## Auto-format code with ruff
	$(VENV)/bin/ruff format .

## ── Docker ──────────────────────────────────────────────
build: ## Build the Docker image
	docker build -t $(IMAGE_NAME) .

run-image: ## Run the Docker container standalone
	docker run --rm -p $(PORT):$(PORT) --env-file .env $(IMAGE_NAME)

up: ## Start services with docker-compose
	$(DOCKER_COMPOSE) up -d --build

down: ## Stop docker-compose services
	$(DOCKER_COMPOSE) down

logs: ## Tail docker-compose logs
	$(DOCKER_COMPOSE) logs -f

## ── Cleanup ─────────────────────────────────────────────
clean: ## Remove venv, caches, and compiled files
	rm -rf $(VENV) __pycache__ .ruff_cache
	find . -name '*.pyc' -delete
	find . -name '__pycache__' -type d -exec rm -rf {} +
