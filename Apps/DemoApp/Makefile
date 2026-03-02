# Makefile for DemoApp
# Swift 6.2 | iOS 26 / macOS 26 | Xcode 26

.PHONY: help run run-dev run-staging run-prod build clean test

# Default target
.DEFAULT_GOAL := help

## help: Show this help message
help:
	@echo "📱 DemoApp - EduGo Apple Application"
	@echo ""
	@echo "Usage:"
	@echo "  make run           Run app with Azure APIs (staging) - DEFAULT"
	@echo "  make run-dev       Run app with localhost APIs (development)"
	@echo "  make run-staging   Run app with Azure APIs (staging) - ALIAS"
	@echo "  make run-prod      Run app with production APIs"
	@echo "  make build         Build the app without running"
	@echo "  make clean         Clean build artifacts"
	@echo "  make test          Run all tests"
	@echo ""
	@echo "🌐 Environments:"
	@echo "  • development: localhost:8060/8065/8070"
	@echo "  • staging:     Azure Container Apps (default)"
	@echo "  • production:  Production URLs"
	@echo ""
	@echo "📖 See CONFIGURACION_AMBIENTES.md for details"

## run: Run app with Azure APIs (staging) - DEFAULT
run: run-staging

## run-staging: Run app with Azure APIs (staging)
run-staging:
	@echo "🚀 Running DemoApp with Azure APIs (staging)..."
	@EDUGO_ENVIRONMENT=staging swift run

## run-dev: Run app with localhost APIs (development)
run-dev:
	@echo "🚀 Running DemoApp with localhost APIs (development)..."
	@echo "⚠️  Make sure your local APIs are running on ports 8060, 8065, 8070"
	@EDUGO_ENVIRONMENT=development swift run

## run-prod: Run app with production APIs
run-prod:
	@echo "🚀 Running DemoApp with production APIs..."
	@EDUGO_ENVIRONMENT=production swift run

## build: Build the app without running
build:
	@echo "🔨 Building DemoApp..."
	@swift build

## clean: Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@swift package clean
	@rm -rf .build

## test: Run all tests
test:
	@echo "🧪 Running tests..."
	@swift test
