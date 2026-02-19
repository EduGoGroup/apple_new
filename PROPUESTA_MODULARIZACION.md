# Propuesta de Modularización - EduGoModules

**Fecha:** 06 de Febrero 2026  
**Versión:** 1.0  
**Objetivo:** Separar módulos en paquetes independientes y/o selectivos para reutilización entre proyectos

---

## Índice

1. [Análisis Actual](#análisis-actual)
2. [Estrategias de Separación](#estrategias-de-separación)
3. [Propuestas de Modularización](#propuestas-de-modularización)
4. [Implementación Recomendada](#implementación-recomendada)
5. [Roadmap de Migración](#roadmap-de-migración)

---

## Análisis Actual

### Estructura Existente

```
EduGoModules/
├── Packages/
│   ├── Foundation/          # Base (Errores, Protocolos, Entity)
│   ├── Core/                # Models, Logger, Utilities
│   ├── Infrastructure/      # Network, Storage, Persistence
│   ├── Domain/              # UseCases, CQRS, StateManagement
│   ├── Presentation/        # ViewModels, Components, Navigation
│   └── Features/            # Features completas
└── Apps/
    └── DemoApp/
```

### Dependencias Actuales

```
Foundation (sin dependencias)
    ↓
Core (→ Foundation)
    ↓
Infrastructure (→ Foundation, Core)
    ↓
Domain (→ Foundation, Core, Infrastructure)
    ↓
Presentation (→ Foundation, Core, Domain)
    ↓
Features (→ todos)
```

### Características de Cada Módulo

| Módulo | LOC Aprox. | Reusabilidad | Acoplamiento | Complejidad |
|--------|-----------|--------------|--------------|-------------|
| **Foundation** | ~500 | ⭐⭐⭐⭐⭐ | Ninguno | Baja |
| **Core/Logger** | ~800 | ⭐⭐⭐⭐⭐ | Foundation | Media |
| **Core/Models** | ~2000 | ⭐⭐⭐⭐ | Foundation | Media |
| **Core/Utilities** | ~300 | ⭐⭐⭐⭐⭐ | Foundation | Baja |
| **Infrastructure/Network** | ~1500 | ⭐⭐⭐⭐⭐ | Core | Alta |
| **Infrastructure/Storage** | ~500 | ⭐⭐⭐⭐ | Core | Media |
| **Infrastructure/Persistence** | ~1200 | ⭐⭐⭐ | Core | Alta |
| **Domain** | ~2500 | ⭐⭐⭐ | Core, Infrastructure | Alta |
| **Presentation** | ~3000 | ⭐⭐ | Domain | Alta |
| **Features** | ~1000 | ⭐ | Todos | Alta |

---

## Estrategias de Separación

### Estrategia 1: Repositorios Independientes (Máxima Separación)

**Ventajas:**
- ✅ Descarga selectiva real
- ✅ Versionado independiente
- ✅ Ownership claro por equipo
- ✅ Ideal para librerías genéricas

**Desventajas:**
- ❌ Más repos que gestionar
- ❌ PRs separados para cambios relacionados
- ❌ Sincronización manual de versiones

**Ideal para:**
- Logger (totalmente genérico)
- Network Client (reutilizable entre apps)
- Utilities (helpers universales)

---

### Estrategia 2: Monorepo con Múltiples Products (Compilación Selectiva)

**Ventajas:**
- ✅ Un solo repo, fácil de mantener
- ✅ Compilación selectiva (solo lo que usas)
- ✅ PRs unificados
- ✅ Sincronización automática

**Desventajas:**
- ⚠️ Descarga todo el código (pero no compila todo)
- ⚠️ Versionado conjunto

**Ideal para:**
- Módulos relacionados (Core con sus submodulos)
- Módulos que cambian juntos frecuentemente
- Código específico del dominio EduGo

---

### Estrategia 3: Híbrida (Recomendada)

**Repositorios independientes para:**
- Librerías genéricas/reutilizables (Foundation, Logger, Network)

**Monorepo con products para:**
- Código específico del dominio (Core/Models, Domain, Presentation)

---

## Propuestas de Modularización

### 📦 Propuesta A: Separación Máxima (7 repos independientes)

```
Repos independientes:
├── edugo-foundation           (100% genérico)
├── edugo-logger              (100% genérico) 
├── edugo-network-client      (95% genérico)
├── edugo-utilities           (100% genérico)
├── edugo-storage             (90% genérico)
├── edugo-core-models         (80% específico EduGo)
└── edugo-domain-business     (100% específico EduGo)
```

**Cuándo usar cada uno:**

```swift
// App solo para reportes (sin UI)
dependencies: [
    .package(url: "github.com/edugo/edugo-logger", from: "1.0.0"),
    .package(url: "github.com/edugo/edugo-network-client", from: "2.0.0"),
    .package(url: "github.com/edugo/edugo-core-models", from: "1.0.0")
]

// App completa móvil
dependencies: [
    .package(url: "github.com/edugo/edugo-foundation", from: "1.0.0"),
    .package(url: "github.com/edugo/edugo-logger", from: "1.0.0"),
    .package(url: "github.com/edugo/edugo-network-client", from: "2.0.0"),
    .package(url: "github.com/edugo/edugo-core-models", from: "1.0.0"),
    .package(url: "github.com/edugo/edugo-domain-business", from: "1.0.0")
]
```

**Pros:**
- ✅ Máxima flexibilidad
- ✅ Versiones independientes
- ✅ Logger puede usarse en otros proyectos sin EduGo

**Contras:**
- ❌ 7 repos que mantener
- ❌ Complejidad en versionado

---

### 📦 Propuesta B: Modularización Híbrida (3 repos + 1 monorepo) ⭐ RECOMENDADA

```
Repos independientes (genéricos):
├── edugo-foundation-kit/
│   └── Package.swift
│       ├── .library(name: "EduFoundation")
│
├── edugo-infrastructure-kit/
│   └── Package.swift
│       ├── .library(name: "EduLogger")        # Selectable
│       ├── .library(name: "EduNetwork")       # Selectable
│       ├── .library(name: "EduStorage")       # Selectable
│       ├── .library(name: "EduUtilities")     # Selectable
│       └── .library(name: "InfraKit")         # Todo junto
│
└── edugo-business-core/  (Monorepo específico EduGo)
    └── Package.swift
        ├── .library(name: "EduModels")        # Selectable
        ├── .library(name: "EduDomain")        # Selectable
        ├── .library(name: "EduPresentation")  # Selectable
        └── .library(name: "EduCore")          # Todo junto
```

**Ejemplo de uso:**

```swift
// Backend Service (solo networking + logger)
dependencies: [
    .package(url: "github.com/edugo/edugo-foundation-kit", from: "1.0.0"),
    .package(url: "github.com/edugo/edugo-infrastructure-kit", from: "2.0.0")
],
targets: [
    .target(
        name: "BackendService",
        dependencies: [
            .product(name: "EduLogger", package: "edugo-infrastructure-kit"),
            .product(name: "EduNetwork", package: "edugo-infrastructure-kit")
            // ✅ Solo compila Logger y Network
            // ❌ NO compila Storage ni Utilities
        ]
    )
]

// App Móvil (completa)
dependencies: [
    .package(url: "github.com/edugo/edugo-foundation-kit", from: "1.0.0"),
    .package(url: "github.com/edugo/edugo-infrastructure-kit", from: "2.0.0"),
    .package(url: "github.com/edugo/edugo-business-core", from: "3.0.0")
],
targets: [
    .target(
        name: "MobileApp",
        dependencies: [
            .product(name: "EduFoundation", package: "edugo-foundation-kit"),
            .product(name: "InfraKit", package: "edugo-infrastructure-kit"),  // Todo
            .product(name: "EduCore", package: "edugo-business-core")         // Todo
        ]
    )
]
```

**Pros:**
- ✅ Balance perfecto: 3 repos manejables
- ✅ Infraestructura genérica separada
- ✅ Compilación selectiva donde importa
- ✅ Lógica de negocio unificada

**Contras:**
- ⚠️ Descarga código completo de `edugo-business-core` (pero no compila todo)

---

### 📦 Propuesta C: Todo en un Monorepo con Products Selectivos (1 repo)

```
edugo-modules-monorepo/
└── Package.swift
    ├── .library(name: "EduFoundation")
    ├── .library(name: "EduLogger")
    ├── .library(name: "EduNetwork")
    ├── .library(name: "EduStorage")
    ├── .library(name: "EduUtilities")
    ├── .library(name: "EduModels")
    ├── .library(name: "EduDomain")
    ├── .library(name: "EduPresentation")
    └── .library(name: "EduGoAll")  # Todo junto
```

**Ejemplo de uso:**

```swift
// Backend Service
dependencies: [
    .package(url: "github.com/edugo/edugo-modules-monorepo", from: "1.0.0")
],
targets: [
    .target(
        name: "Service",
        dependencies: [
            .product(name: "EduLogger", package: "edugo-modules-monorepo"),
            .product(name: "EduNetwork", package: "edugo-modules-monorepo")
            // ✅ Solo compila esos 2 modules
        ]
    )
]
```

**Pros:**
- ✅ Un solo repo, súper simple
- ✅ Compilación selectiva
- ✅ PRs unificados
- ✅ Sin problemas de sincronización

**Contras:**
- ❌ Descarga TODO el código siempre
- ❌ Versionado único para todo

---

## Implementación Recomendada

### 🎯 Opción Híbrida (Propuesta B)

#### Repo 1: `edugo-foundation-kit`

**Propósito:** Tipos base, errores, protocolos fundamentales

**Contenido:**
```
Sources/
└── EduFoundation/
    ├── Domain/
    │   └── Entity.swift
    ├── Errors/
    │   ├── DomainError.swift
    │   ├── UseCaseError.swift
    │   └── RepositoryError.swift
    └── Protocols/
        └── UserContextProtocol.swift
```

**Package.swift:**
```swift
let package = Package(
    name: "EduFoundationKit",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "EduFoundation", targets: ["EduFoundation"])
    ],
    targets: [
        .target(name: "EduFoundation", path: "Sources/EduFoundation")
    ]
)
```

**Versionado:** Semantic versioning estricto (raramente cambia)

---

#### Repo 2: `edugo-infrastructure-kit`

**Propósito:** Componentes técnicos genéricos reutilizables

**Contenido:**
```
Sources/
├── Logger/           # Sistema de logging
├── Network/          # HTTP Client genérico
├── Storage/          # UserDefaults/Keychain wrappers
└── Utilities/        # Helpers, Serializers
```

**Package.swift:**
```swift
let package = Package(
    name: "EduInfrastructureKit",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        // Products selectivos
        .library(name: "EduLogger", targets: ["EduLogger"]),
        .library(name: "EduNetwork", targets: ["EduNetwork"]),
        .library(name: "EduStorage", targets: ["EduStorage"]),
        .library(name: "EduUtilities", targets: ["EduUtilities"]),
        
        // Product "all-in-one"
        .library(name: "InfraKit", targets: [
            "EduLogger", "EduNetwork", "EduStorage", "EduUtilities"
        ])
    ],
    dependencies: [
        .package(url: "github.com/edugo/edugo-foundation-kit", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "EduLogger",
            dependencies: [
                .product(name: "EduFoundation", package: "edugo-foundation-kit")
            ],
            path: "Sources/Logger"
        ),
        .target(
            name: "EduNetwork",
            dependencies: [
                .product(name: "EduFoundation", package: "edugo-foundation-kit"),
                "EduLogger"  // Dependency interna
            ],
            path: "Sources/Network"
        ),
        .target(
            name: "EduStorage",
            dependencies: [
                .product(name: "EduFoundation", package: "edugo-foundation-kit")
            ],
            path: "Sources/Storage"
        ),
        .target(
            name: "EduUtilities",
            dependencies: [
                .product(name: "EduFoundation", package: "edugo-foundation-kit")
            ],
            path: "Sources/Utilities"
        )
    ]
)
```

**Casos de uso:**

```swift
// App que solo necesita Logger
dependencies: [
    .product(name: "EduLogger", package: "edugo-infrastructure-kit")
]

// App que necesita Network + Logger
dependencies: [
    .product(name: "EduNetwork", package: "edugo-infrastructure-kit")
    // EduLogger se incluye automáticamente (dependency interna)
]

// App que usa todo
dependencies: [
    .product(name: "InfraKit", package: "edugo-infrastructure-kit")
]
```

---

#### Repo 3: `edugo-business-core`

**Propósito:** Lógica de negocio específica de EduGo (Models, Domain, Presentation)

**Contenido:**
```
Sources/
├── Models/           # DTOs, Mappers, Domain models
├── Domain/           # UseCases, CQRS, Services
└── Presentation/     # ViewModels, Components
```

**Package.swift:**
```swift
let package = Package(
    name: "EduBusinessCore",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        // Products selectivos
        .library(name: "EduModels", targets: ["EduModels"]),
        .library(name: "EduDomain", targets: ["EduDomain"]),
        .library(name: "EduPresentation", targets: ["EduPresentation"]),
        
        // Product completo
        .library(name: "EduCore", targets: [
            "EduModels", "EduDomain", "EduPresentation"
        ])
    ],
    dependencies: [
        .package(url: "github.com/edugo/edugo-foundation-kit", from: "1.0.0"),
        .package(url: "github.com/edugo/edugo-infrastructure-kit", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "EduModels",
            dependencies: [
                .product(name: "EduFoundation", package: "edugo-foundation-kit"),
                .product(name: "EduUtilities", package: "edugo-infrastructure-kit")
            ],
            path: "Sources/Models"
        ),
        .target(
            name: "EduDomain",
            dependencies: [
                .product(name: "EduFoundation", package: "edugo-foundation-kit"),
                .product(name: "EduNetwork", package: "edugo-infrastructure-kit"),
                "EduModels"
            ],
            path: "Sources/Domain"
        ),
        .target(
            name: "EduPresentation",
            dependencies: [
                "EduModels",
                "EduDomain"
            ],
            path: "Sources/Presentation"
        )
    ]
)
```

---

### Uso en Proyectos Consumidores

#### Caso 1: Servicio Backend (sin UI)

```swift
// Package.swift del backend
let package = Package(
    name: "EduGoBackend",
    dependencies: [
        .package(url: "https://github.com/edugo/edugo-foundation-kit", from: "1.0.0"),
        .package(url: "https://github.com/edugo/edugo-infrastructure-kit", from: "2.0.0"),
        .package(url: "https://github.com/edugo/edugo-business-core", from: "3.0.0")
    ],
    targets: [
        .executableTarget(
            name: "EduGoBackend",
            dependencies: [
                .product(name: "EduLogger", package: "edugo-infrastructure-kit"),
                .product(name: "EduNetwork", package: "edugo-infrastructure-kit"),
                .product(name: "EduModels", package: "edugo-business-core"),
                .product(name: "EduDomain", package: "edugo-business-core")
                // ✅ NO incluye EduPresentation (ViewModels, UI)
            ]
        )
    ]
)
```

**Resultado:**
- ⬇️ Descarga: Foundation + Infrastructure completo + Business Core completo
- 🔨 Compila: Solo Logger, Network, Models, Domain
- ❌ NO compila: Storage, Utilities, Presentation

---

#### Caso 2: App Móvil Completa

```swift
// Package.swift de la app iOS
let package = Package(
    name: "EduGoMobile",
    dependencies: [
        .package(url: "https://github.com/edugo/edugo-foundation-kit", from: "1.0.0"),
        .package(url: "https://github.com/edugo/edugo-infrastructure-kit", from: "2.0.0"),
        .package(url: "https://github.com/edugo/edugo-business-core", from: "3.0.0")
    ],
    targets: [
        .target(
            name: "EduGoMobile",
            dependencies: [
                .product(name: "EduFoundation", package: "edugo-foundation-kit"),
                .product(name: "InfraKit", package: "edugo-infrastructure-kit"),  // TODO
                .product(name: "EduCore", package: "edugo-business-core")         // TODO
            ]
        )
    ]
)
```

**Resultado:**
- ⬇️ Descarga: TODO
- 🔨 Compila: TODO
- ✅ App completa funcional

---

#### Caso 3: Widget de iOS (UI mínima)

```swift
// Widget Extension
dependencies: [
    .product(name: "EduFoundation", package: "edugo-foundation-kit"),
    .product(name: "EduStorage", package: "edugo-infrastructure-kit"),  // Solo storage
    .product(name: "EduModels", package: "edugo-business-core")         // Solo models
    // ✅ NO incluye Network, Domain, Presentation completa
]
```

---

## Roadmap de Migración

### Fase 1: Preparación (Semana 1)

**Objetivos:**
- [ ] Análisis de dependencias circulares
- [ ] Documentar APIs públicas de cada módulo
- [ ] Identificar código duplicado
- [ ] Crear branches de desarrollo

**Acciones:**
```bash
# Crear estructura de repos
mkdir -p ~/repos/edugo-foundation-kit
mkdir -p ~/repos/edugo-infrastructure-kit
mkdir -p ~/repos/edugo-business-core

# Copiar código base
cp -r Packages/Foundation ~/repos/edugo-foundation-kit/
```

---

### Fase 2: Extraer Foundation (Semana 2)

**Objetivos:**
- [ ] Crear repo `edugo-foundation-kit`
- [ ] Publicar versión 1.0.0
- [ ] Probar desde proyecto externo

**Acciones:**
```bash
cd ~/repos/edugo-foundation-kit
git init
git add .
git commit -m "feat: initial foundation kit"
git tag 1.0.0
git push origin main --tags
```

**Validación:**
```swift
// En proyecto de prueba
.package(url: "https://github.com/edugo/edugo-foundation-kit", from: "1.0.0")
```

---

### Fase 3: Extraer Infrastructure (Semana 3-4)

**Objetivos:**
- [ ] Crear repo `edugo-infrastructure-kit`
- [ ] Configurar múltiples products (Logger, Network, Storage, Utilities)
- [ ] Actualizar dependencias a Foundation 1.0.0
- [ ] Publicar versión 2.0.0

**Package.swift:**
```swift
dependencies: [
    .package(url: "https://github.com/edugo/edugo-foundation-kit", from: "1.0.0")
]
```

---

### Fase 4: Consolidar Business Core (Semana 5-6)

**Objetivos:**
- [ ] Crear repo `edugo-business-core`
- [ ] Migrar Models, Domain, Presentation
- [ ] Configurar products selectivos
- [ ] Publicar versión 3.0.0

**Dependencias:**
```swift
dependencies: [
    .package(url: "https://github.com/edugo/edugo-foundation-kit", from: "1.0.0"),
    .package(url: "https://github.com/edugo/edugo-infrastructure-kit", from: "2.0.0")
]
```

---

### Fase 5: Migrar Proyectos Consumidores (Semana 7-8)

**Objetivos:**
- [ ] Actualizar `edugo-api-administracion`
- [ ] Actualizar `edugo-api-mobile`
- [ ] Actualizar otras apps
- [ ] Validar compilación selectiva

**Ejemplo de migración:**
```swift
// Antes
.package(path: "../EduGoModules")

// Después
.package(url: "https://github.com/edugo/edugo-foundation-kit", from: "1.0.0"),
.package(url: "https://github.com/edugo/edugo-infrastructure-kit", from: "2.0.0"),
.package(url: "https://github.com/edugo/edugo-business-core", from: "3.0.0")
```

---

### Fase 6: CI/CD (Semana 9)

**Objetivos:**
- [ ] Configurar GitHub Actions para cada repo
- [ ] Automatizar tests
- [ ] Automatizar releases con semantic versioning
- [ ] Configurar badges de status

**.github/workflows/release.yml:**
```yaml
name: Release
on:
  push:
    tags:
      - '*'
jobs:
  release:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Swift Build
        run: swift build
      - name: Swift Test
        run: swift test
      - name: Create Release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ github.ref }}
```

---

## Versionado Semántico

### edugo-foundation-kit

**v1.0.0** - Base estable
- Cambios raramente (solo bugs o nuevos protocolos fundamentales)
- MAJOR version solo para breaking changes

### edugo-infrastructure-kit

**v2.0.0** - Infraestructura técnica
- MINOR version para nuevas features (ej: nuevo interceptor)
- PATCH version para bugfixes

### edugo-business-core

**v3.0.0** - Lógica de negocio
- Cambios frecuentes (nuevos UseCases, ViewModels)
- MINOR version para nuevas features
- MAJOR version para cambios de arquitectura

---

## Publicación (JitPack vs GitHub Packages)

### Opción A: JitPack (Recomendada - Más Fácil)

**Ventajas:**
- ✅ Sin configuración de Maven
- ✅ Compilación automática
- ✅ Sin autenticación para repos públicos

**Uso:**
```swift
// settings.gradle.kts (si usas con Kotlin también)
maven { url = uri("https://jitpack.io") }

// Package.swift (Swift SPM usa directamente GitHub)
.package(url: "https://github.com/edugo/edugo-foundation-kit", from: "1.0.0")
```

### Opción B: GitHub Packages (Más Profesional)

**Ventajas:**
- ✅ Integración oficial con GitHub
- ✅ Soporte para privados
- ✅ Control de acceso

**Requiere:**
- Personal Access Token
- Configuración de credenciales

---

## Ejemplo de Uso Final

### Backend Service

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/edugo/edugo-infrastructure-kit", from: "2.0.0"),
    .package(url: "https://github.com/edugo/edugo-business-core", from: "3.0.0")
],
targets: [
    .target(
        name: "BackendService",
        dependencies: [
            .product(name: "EduLogger", package: "edugo-infrastructure-kit"),
            .product(name: "EduNetwork", package: "edugo-infrastructure-kit"),
            .product(name: "EduDomain", package: "edugo-business-core")
        ]
    )
]
```

**Resultado:**
- ⬇️ Descarga: ~4MB (Foundation + Infrastructure + Business Core)
- 🔨 Compila: Logger + Network + Models + Domain
- 🚫 NO compila: Storage, Utilities, Presentation

---

### App Móvil

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/edugo/edugo-foundation-kit", from: "1.0.0"),
    .package(url: "https://github.com/edugo/edugo-infrastructure-kit", from: "2.0.0"),
    .package(url: "https://github.com/edugo/edugo-business-core", from: "3.0.0")
],
targets: [
    .target(
        name: "EduGoMobile",
        dependencies: [
            .product(name: "EduFoundation", package: "edugo-foundation-kit"),
            .product(name: "InfraKit", package: "edugo-infrastructure-kit"),
            .product(name: "EduCore", package: "edugo-business-core")
        ]
    )
]
```

**Resultado:**
- ⬇️ Descarga: ~6MB (todo)
- 🔨 Compila: TODO (app completa)

---

## Conclusión

### Recomendación Final: **Propuesta B (Híbrida)**

**3 Repositorios:**
1. `edugo-foundation-kit` - Base universal
2. `edugo-infrastructure-kit` - Infraestructura técnica (con 4 products selectivos)
3. `edugo-business-core` - Lógica de negocio (con 3 products selectivos)

**Beneficios:**
- ✅ Balance perfecto entre simplicidad y flexibilidad
- ✅ Compilación selectiva donde importa
- ✅ Descarga selectiva de infraestructura genérica
- ✅ 3 repos manejables (no 7)
- ✅ Reutilización fácil entre proyectos

**Próximos pasos:**
1. Aprobar esta propuesta
2. Ejecutar Fase 1 del Roadmap
3. Crear repos en GitHub
4. Iniciar migración gradual

---

**Autor:** Claude Code  
**Revisor:** [Tu nombre]  
**Estado:** En revisión
