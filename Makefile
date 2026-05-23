# =============================================================================
# Makefile - atajos para operar el laboratorio
# =============================================================================

SHELL        := /bin/bash
COMPOSE      ?= docker compose
PROJECT      ?= lab-vulnerable
ENV_FILE     ?= .env

.DEFAULT_GOAL := help

.PHONY: help up down restart build rebuild ps logs status health setup reset clean nuke

help: ## Muestra esta ayuda
	@awk 'BEGIN{FS=":.*##"; printf "\nObjetivos disponibles:\n"} \
	      /^[a-zA-Z_-]+:.*##/ {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Crea .env si no existe y construye imagenes
	@test -f $(ENV_FILE) || cp .env.example $(ENV_FILE)
	$(COMPOSE) build

up: setup ## Levanta todo el laboratorio en background
	$(COMPOSE) up -d
	@echo ""
	@echo "Laboratorio arriba."
	@echo "  - Landing : http://localhost:$$(grep ^LAB_HTTP_PORT   $(ENV_FILE) | cut -d= -f2)/"
	@echo "  - DVWA    : http://localhost:$$(grep ^LAB_DVWA_PORT   $(ENV_FILE) | cut -d= -f2)/"
	@echo "  - Juice   : http://localhost:$$(grep ^LAB_JUICE_PORT  $(ENV_FILE) | cut -d= -f2)/"
	@echo "  - Status  : http://localhost:$$(grep ^LAB_STATUS_PORT $(ENV_FILE) | cut -d= -f2)/"

down: ## Para los contenedores (preserva datos)
	$(COMPOSE) down

restart: down up ## Reinicia el laboratorio

build: ## Construye imagenes locales (proxy)
	$(COMPOSE) build

rebuild: ## Reconstruye imagenes locales sin cache
	$(COMPOSE) build --no-cache

ps: ## Lista contenedores
	$(COMPOSE) ps

logs: ## Tail de logs de todos los servicios
	$(COMPOSE) logs -f --tail=100

status: ps ## Alias de ps

health: ## Verifica que la landing y los servicios respondan
	@bash scripts/health.sh

reset: ## Reinicio limpio: para todo, borra volumenes y vuelve a levantar
	@bash scripts/reset.sh

clean: ## Para todo y elimina volumenes y redes
	$(COMPOSE) down -v --remove-orphans

nuke: clean ## Igual que clean + elimina las imagenes construidas localmente
	-docker image rm lab-vulnerable/proxy:latest 2>/dev/null || true
