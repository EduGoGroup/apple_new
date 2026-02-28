# EduGo Apple - Makefile
# La app es un paquete SPM puro, se compila y ejecuta con `swift run`
#
# Uso:
#   make              Muestra ayuda
#   make run          Compila y ejecuta en macOS con staging (default)
#   make run-dev      Compila y ejecuta con development (localhost)
#   make run-prod     Compila y ejecuta con production
#   make build        Compila sin ejecutar
#   make test         Ejecuta todos los tests
#   make clean        Limpia artefactos de build
#   make info         Muestra URLs de cada ambiente

DEMO_APP_DIR := Apps/DemoApp
ROOT_DIR     := $(shell pwd)

# Ambiente por defecto
ENV ?= staging

# Colores
BOLD   := \033[1m
GREEN  := \033[32m
YELLOW := \033[33m
CYAN   := \033[36m
RED    := \033[31m
RESET  := \033[0m

.PHONY: help run run-dev run-prod build test clean info

## Muestra esta ayuda
help:
	@echo ""
	@echo "$(BOLD)EduGo Apple — Comandos disponibles$(RESET)"
	@echo ""
	@echo "$(CYAN)Ejecucion en macOS:$(RESET)"
	@echo "  $(BOLD)make run$(RESET)          Compila y ejecuta con staging (default)"
	@echo "  $(BOLD)make run-dev$(RESET)      Compila y ejecuta con development (localhost)"
	@echo "  $(BOLD)make run-prod$(RESET)     Compila y ejecuta con production"
	@echo "  $(BOLD)make run ENV=staging$(RESET)  Especifica ambiente manualmente"
	@echo ""
	@echo "$(CYAN)Build y tests:$(RESET)"
	@echo "  $(BOLD)make build$(RESET)        Compila sin ejecutar"
	@echo "  $(BOLD)make test$(RESET)         Ejecuta todos los tests del proyecto"
	@echo "  $(BOLD)make clean$(RESET)        Limpia artefactos de build"
	@echo ""
	@echo "$(CYAN)Utilidades:$(RESET)"
	@echo "  $(BOLD)make info$(RESET)         Muestra URLs de cada ambiente"
	@echo ""

## Compila y ejecuta en macOS con el ambiente especificado (default: staging)
run:
	@echo "$(GREEN)$(BOLD)▶ Ejecutando DemoApp [$(ENV)]$(RESET)"
	@echo ""
	cd $(DEMO_APP_DIR) && EDUGO_ENVIRONMENT=$(ENV) swift run DemoApp

## Ejecuta con ambiente development (localhost)
run-dev:
	@$(MAKE) run ENV=development

## Ejecuta con ambiente production
run-prod:
	@$(MAKE) run ENV=production

## Compila sin ejecutar
build:
	@echo "$(GREEN)$(BOLD)▶ Compilando DemoApp [$(ENV)]$(RESET)"
	cd $(DEMO_APP_DIR) && EDUGO_ENVIRONMENT=$(ENV) swift build
	@echo "$(GREEN)✓ Build completado$(RESET)"

## Ejecuta todos los tests de cada paquete (Packages/ y modulos/)
test:
	@echo "$(GREEN)$(BOLD)▶ Ejecutando tests$(RESET)"
	@for dir in Packages/Foundation Packages/Core Packages/Infrastructure Packages/Domain Packages/DynamicUI Packages/Presentation Packages/Features modulos/CQRSKit modulos/DesignSystemSDK modulos/FormsSDK modulos/FoundationToolkit modulos/LoggerSDK modulos/NetworkSDK modulos/UIComponentsSDK; do \
		echo "$(CYAN)Testing $$dir$(RESET)"; \
		(cd $$dir && swift test) || exit 1; \
	done
	@echo "$(GREEN)✓ Tests completados$(RESET)"

## Limpia artefactos de build (raiz y DemoApp)
clean:
	@echo "$(YELLOW)▶ Limpiando...$(RESET)"
	swift package clean 2>/dev/null || true
	cd $(DEMO_APP_DIR) && swift package clean 2>/dev/null || true
	@echo "$(GREEN)✓ Limpieza completada$(RESET)"

## Muestra la configuracion de cada ambiente
info:
	@echo ""
	@echo "$(BOLD)Ambientes disponibles$(RESET)"
	@echo ""
	@echo "$(CYAN)development$(RESET)"
	@echo "  EDUGO_ENVIRONMENT=development"
	@echo "  IAM API:    http://localhost:8070"
	@echo "  Admin API:  http://localhost:8060"
	@echo "  Mobile API: http://localhost:8065"
	@echo "  Timeout:    30s"
	@echo ""
	@echo "$(CYAN)staging$(RESET) $(YELLOW)(default)$(RESET)"
	@echo "  EDUGO_ENVIRONMENT=staging"
	@echo "  IAM API:    https://edugo-api-iam-platform.wittyhill-f6d656fb.eastus.azurecontainerapps.io"
	@echo "  Admin API:  https://edugo-api-admin-new.wittyhill-f6d656fb.eastus.azurecontainerapps.io"
	@echo "  Mobile API: https://edugo-api-mobile-new.wittyhill-f6d656fb.eastus.azurecontainerapps.io"
	@echo "  Timeout:    60s"
	@echo ""
	@echo "$(CYAN)production$(RESET)"
	@echo "  EDUGO_ENVIRONMENT=production"
	@echo "  IAM API:    https://api-iam.edugo.com"
	@echo "  Admin API:  https://api.edugo.com"
	@echo "  Mobile API: https://api-mobile.edugo.com"
	@echo "  Timeout:    60s"
	@echo ""
