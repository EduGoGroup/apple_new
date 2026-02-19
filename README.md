# EduGo Modules

Modulos Swift para la plataforma educativa EduGo.

## Estructura

```
EduGoModules/
├── Packages/           # Swift Packages principales
│   ├── Foundation/     # Tipos base y extensiones
│   ├── Core/           # Modelos, Logger, Utilities
│   ├── Infrastructure/ # Network, Storage, Persistence
│   ├── Domain/         # Logica de negocio, UseCases
│   ├── Presentation/   # UI, Theme, ViewModels
│   └── Features/       # AI, API, Analytics
├── Apps/               # Aplicaciones demo
│   └── DemoApp/        # App de demostración
├── Documentation/      # Documentacion centralizada
└── Tools/              # Scripts y templates
```

## Quick Start

```bash
# Compilar todo
cd EduGoModules
swift build

# Ejecutar tests
swift test

# Compilar DemoApp
cd Apps/DemoApp
swift build

# Abrir en Xcode
open Package.swift
```

## Dependencias

```
Foundation <- Core <- Infrastructure <- Domain <- Presentation <- Features
```

## Módulos

### Foundation (EduFoundation)
Tipos base, extensiones de Swift Foundation, y utilidades fundamentales.

### Core (EduCore)
- **Logger**: Sistema de logging unificado
- **Models**: Modelos de datos compartidos
- **Utilities**: Utilidades generales

### Infrastructure (EduInfrastructure)
- **Network**: Cliente de red y servicios HTTP
- **Storage**: Almacenamiento seguro
- **Persistence**: Persistencia local con SwiftData

### Domain (EduDomain)
- **CQRS**: Patrón Command Query Responsibility Segregation
- **StateManagement**: Gestión de estado reactivo
- **UseCases**: Casos de uso de la aplicación
- **Services**: Auth, Roles

### Presentation (EduPresentation)
- **DesignSystem**: Theme, Effects, Accessibility
- **Components**: Componentes UI reutilizables
- **Navigation**: Sistema de navegación
- **ViewModels**: ViewModels de la aplicación

### Features (EduFeatures)
- **AI**: Integración con servicios de IA
- **API**: Cliente API de alto nivel
- **Analytics**: Sistema de analytics

## Documentacion

Ver `Documentation/` para guias detalladas:
- `Architecture/` - Documentación de arquitectura
- `Guides/` - Guías de desarrollo
- `Decisions/` - ADRs (Architecture Decision Records)
