# Arquitectura — EduGo Apple

> Documentacion generada desde analisis directo del codigo fuente (marzo 2026).

---

## 1. Vision General

Aplicacion nativa Apple (iOS, iPadOS, macOS) construida con **Swift 6.2** y **SwiftUI** usando Liquid Glass como paradigma visual. Soporta iOS 26, macOS 26 e iPadOS 26.

El proyecto es la version nativa del frontend KMP (`kmp_new`), con acceso a las APIs nativas de Apple y rendimiento optimizado para dispositivos Apple.

---

## 2. Stack Tecnologico

| Componente | Tecnologia |
|-----------|-----------|
| Lenguaje | Swift 6.2 (Strict Concurrency Mode) |
| UI | SwiftUI + Liquid Glass |
| Concurrencia | async/await, Actor, AsyncSequence/AsyncStream |
| Persistencia | SwiftData |
| Almacenamiento seguro | Keychain (Security framework) |
| Networking | URLSession nativo |
| Testing | Swift Testing (@Suite, @Test, #expect) |
| Build | Swift Package Manager (SPM) |
| IDE | Xcode 26 |
| Plataformas | iOS 26, macOS 26, iPadOS 26 |

---

## 3. Estructura del Proyecto

```
apple_new/
├── Package.swift              # Umbrella product (EduGoModules)
├── CLAUDE.md                  # Guia para Claude Code
├── Makefile                   # Comandos de build/run/test
├── README.md
├── Packages/                  # 7 paquetes SPM principales (6-tier + DynamicUI)
│   ├── Foundation/            # Tier 0: tipos base, errores, protocolos
│   ├── Core/                  # Tier 1: modelos, logger, utilidades
│   ├── Infrastructure/        # Tier 2: network, storage, persistence
│   ├── DynamicUI/             # Tier lateral: Server-Driven UI
│   ├── Domain/                # Tier 3: casos de uso, CQRS, estado
│   ├── Presentation/          # Tier 4: ViewModels, navegacion, design system
│   └── Features/              # Tier 5: features integrales
├── modulos/                   # 7 SDKs standalone reutilizables
│   ├── FoundationToolkit/
│   ├── LoggerSDK/
│   ├── NetworkSDK/
│   ├── CQRSKit/
│   ├── DesignSystemSDK/
│   ├── FormsSDK/
│   └── UIComponentsSDK/
├── Apps/
│   └── DemoApp/               # App ejecutable (macOS + iOS)
├── Sources/                   # Umbrella target
├── Tools/                     # Herramientas auxiliares
├── .agents/                   # Skills de Claude Code
└── docs_new/                  # Esta documentacion
```

---

## 4. Jerarquia de Paquetes SPM (6-Tier)

Cadena de dependencias estrictamente unidireccional:

```
EduFoundation → EduCore → EduInfrastructure → EduDomain → EduPresentation → EduFeatures
                                         ↘ EduDynamicUI ↗
```

| Tier | Paquete | Products | Responsabilidad |
|------|---------|----------|----------------|
| 0 | `Packages/Foundation` | `EduFoundation` | Tipos base, protocolos de errores (DomainError, RepositoryError, UseCaseError), entity base |
| 1 | `Packages/Core` | `EduCore`, `EduModels`, `EduLogger`, `EduUtilities` | DTOs, modelos de dominio, mappers, validacion, logger, `APIConfiguration`, `AppEnvironment` |
| 2 | `Packages/Infrastructure` | `EduNetwork`, `EduStorage`, `EduPersistence` | `NetworkClient` (actor), interceptors, `CircuitBreaker`, `RateLimiter`, SwiftData, Keychain |
| Lateral | `Packages/DynamicUI` | `EduDynamicUI` | Server-Driven UI: `ScreenLoader` (LRU + ETag), `DataLoader` (dual-API routing), resolvers |
| 3 | `Packages/Domain` | `EduDomain` | Use cases, CQRS (Command/Query/Event), state machines, `StatePublisher` via `AsyncSequence` |
| 4 | `Packages/Presentation` | `EduPresentation` | `@Observable` ViewModels, coordinator navigation, validators, design system |
| 5 | `Packages/Features` | `EduFeatures` | Integraciones (AI, analytics) |

### Diagrama de dependencias detallado

```
┌─────────────────────────────────────────────────────────────┐
│                     Apps/DemoApp                             │
│  (executable: importa todos los packages)                   │
└───┬───────┬───────┬────────┬─────────┬────────┬────────────┘
    │       │       │        │         │        │
    ▼       ▼       ▼        ▼         ▼        ▼
Features Presentation Domain DynamicUI Infra   Core
    │       │         │        │         │        │
    │       │         ├────────┤         │        │
    │       │         │        │         │        │
    │       ▼         ▼        ▼         ▼        ▼
    │    Domain   Infra+DUI  Core+Infra  Core   Foundation
    │       │         │        │         │
    └───────┴─────────┴────────┴─────────┘
                      │
                      ▼
                 Foundation
```

---

## 5. Root Package.swift

El `Package.swift` raiz expone un producto umbrella que reexporta todos los paquetes:

```swift
// swift-tools-version: 6.2
let package = Package(
    name: "EduGoModules",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "EduGoModules", targets: ["EduGoModulesUmbrella"])
    ],
    dependencies: [
        .package(path: "Packages/Foundation"),
        .package(path: "Packages/Core"),
        .package(path: "Packages/Infrastructure"),
        .package(path: "Packages/Domain"),
        .package(path: "Packages/Presentation"),
        .package(path: "Packages/Features"),
        .package(path: "Packages/DynamicUI")
    ],
    targets: [
        .target(name: "EduGoModulesUmbrella", dependencies: [
            .product(name: "EduFoundation", package: "Foundation"),
            .product(name: "EduCore", package: "Core"),
            .product(name: "EduInfrastructure", package: "Infrastructure"),
            .product(name: "EduDomain", package: "Domain"),
            .product(name: "EduPresentation", package: "Presentation"),
            .product(name: "EduFeatures", package: "Features"),
            .product(name: "EduDynamicUI", package: "DynamicUI")
        ])
    ]
)
```

---

## 6. DemoApp — Punto de Entrada

**Archivo:** `Apps/DemoApp/Sources/DemoApp.swift`

### ServiceContainer

`ServiceContainer` es un `@MainActor @Observable` que inicializa todos los servicios en orden de dependencias:

```
1.  APIConfiguration (segun AppEnvironment)
2.  plainNetworkClient (sin interceptors, para auth)
3.  NetworkObserver (conectividad)
4.  AuthService (usa plain client)
5.  AuthenticationInterceptor + authenticatedNetworkClient
6.  LocalSyncStore
7.  MenuService
8.  SyncService
9.  ScreenLoader + DataLoader (DynamicUI)
10. ContractRegistry + OptimisticUpdateManager + EventOrchestrator
11. MutationQueue + SyncEngine + ConnectivitySyncManager (offline)
12. BreadcrumbTracker (navegacion)
13. ServerStringResolver + GlossaryProvider + LocaleService (i18n)
14. ToastManager (feedback)
```

### Flujo de la App

```
Splash → Login → Main
           │
           ├─ onLoginSuccess → fullSync() → seedScreens → navigate(.main)
           │
           └─ sessionStream → .loggedOut/.expired → navigate(.login)
```

### Ambientes

| Ambiente | IAM API | Admin API | Mobile API |
|----------|---------|-----------|------------|
| `development` | `localhost:8070` | `localhost:8060` | `localhost:8065` |
| `staging` | Azure Container Apps | Azure Container Apps | Azure Container Apps |
| `production` | `api-iam.edugo.com` | `api.edugo.com` | `api-mobile.edugo.com` |

Deteccion automatica via variable de entorno `EDUGO_ENVIRONMENT`. Default: `staging` en DEBUG.

---

## 7. Cifras del Proyecto

| Metrica | Valor |
|---------|-------|
| Archivos Swift totales | ~780+ |
| Archivos fuente (Packages/) | ~430+ |
| Archivos de test (Packages/) | ~133 |
| Tests totales | ~2,083 |
| Paquetes SPM principales | 7 (6-tier + DynamicUI) |
| SDKs standalone (modulos/) | 7 |
| Warnings de deprecacion | 0 |
| Uso de codigo prohibido | 0 |

---

*Generado: marzo 2026 | Basado en analisis directo del codigo fuente*
