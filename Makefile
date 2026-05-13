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

# SSH tunnel settings (loaded from .env via shell)
SSH_USER    := $(shell grep '^SSH_USER=' .env 2>/dev/null | cut -d= -f2)
SSH_HOST    := $(shell grep '^SSH_HOST=' .env 2>/dev/null | cut -d= -f2)
SSH_KEY     := $(shell grep '^SSH_KEY=' .env 2>/dev/null | cut -d= -f2)
SSH_LOCAL   := $(shell grep '^SSH_LOCAL_PORT=' .env 2>/dev/null | cut -d= -f2)
SSH_REMOTE  := $(shell grep '^SSH_REMOTE_PORT=' .env 2>/dev/null | cut -d= -f2)
TUNNEL_PID  := .tunnel.pid

.PHONY: help setup venv install run dev clean lint format \
        build run-image up down logs \
        tunnel tunnel-status tunnel-stop

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
	docker compose up -d --build

down: ## Stop docker-compose services
	docker compose down

logs: ## Tail docker-compose logs
	docker compose logs -f

## ── SSH Tunnel (Port Forwarding) ────────────────────────
tunnel: ## Open SSH tunnel to forward local port to remote API
	@if [ -f $(TUNNEL_PID) ] && kill -0 $$(cat $(TUNNEL_PID)) 2>/dev/null; then \
		echo "Tunnel already running (PID $$(cat $(TUNNEL_PID)))"; \
	else \
		echo "Opening SSH tunnel: localhost:$(SSH_LOCAL) -> $(SSH_HOST):$(SSH_REMOTE)…"; \
		ssh -fNL $(SSH_LOCAL):localhost:$(SSH_REMOTE) \
			-i $(SSH_KEY) $(SSH_USER)@$(SSH_HOST) \
			-o ExitOnForwardFailure=yes \
			-o ServerAliveInterval=60 \
			-o ServerAliveCountMax=3; \
		lsof -ti :$(SSH_LOCAL) -sTCP:LISTEN > $(TUNNEL_PID); \
		echo "Tunnel open (PID $$(cat $(TUNNEL_PID)))"; \
	fi

tunnel-status: ## Check if the SSH tunnel is running
	@if [ -f $(TUNNEL_PID) ] && kill -0 $$(cat $(TUNNEL_PID)) 2>/dev/null; then \
		echo "Tunnel is RUNNING (PID $$(cat $(TUNNEL_PID)))"; \
	else \
		echo "Tunnel is NOT running"; \
		rm -f $(TUNNEL_PID); \
	fi

tunnel-stop: ## Close the SSH tunnel
	@if [ -f $(TUNNEL_PID) ]; then \
		kill $$(cat $(TUNNEL_PID)) 2>/dev/null && echo "Tunnel stopped" || echo "Tunnel was not running"; \
		rm -f $(TUNNEL_PID); \
	else \
		echo "No tunnel PID file found"; \
	fi

## ── Cleanup ─────────────────────────────────────────────
clean: ## Remove venv, caches, and compiled files
	rm -rf $(VENV) __pycache__ .ruff_cache $(TUNNEL_PID)
	find . -name '*.pyc' -delete
	find . -name '__pycache__' -type d -exec rm -rf {} +
