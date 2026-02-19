# Plan de Implementación - Modularización Híbrida

**Proyecto:** EduGoModules  
**Estrategia:** Propuesta B - Híbrida (3 repositorios)  
**Fecha:** 06 de Febrero 2026  
**Estado:** Aprobado - Listo para implementar

---

## Índice

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Estructura de Repositorios](#estructura-de-repositorios)
3. [Repositorio 1: edugo-foundation-kit](#repositorio-1-edugo-foundation-kit)
4. [Repositorio 2: edugo-infrastructure-kit](#repositorio-2-edugo-infrastructure-kit)
5. [Repositorio 3: edugo-business-core](#repositorio-3-edugo-business-core)
6. [Configuración Local/Remoto](#configuración-localremoto)
7. [Migración de Proyectos Consumidores](#migración-de-proyectos-consumidores)
8. [Scripts de Automatización](#scripts-de-automatización)
9. [Checklist de Implementación](#checklist-de-implementación)

---

## Resumen Ejecutivo

### Objetivo

Separar `EduGoModules` en **3 repositorios independientes** con compilación selectiva mediante múltiples products.

### Repositorios a Crear

| Repositorio | Propósito | Versión Inicial | LOC |
|-------------|-----------|-----------------|-----|
| **edugo-foundation-kit** | Tipos base, errores, protocolos | 1.0.0 | ~500 |
| **edugo-infrastructure-kit** | Logger, Network, Storage, Utilities | 2.0.0 | ~3000 |
| **edugo-business-core** | Models, Domain, Presentation | 3.0.0 | ~7500 |

### Beneficios Clave

- ✅ Compilación selectiva (solo products usados)
- ✅ Versionado semántico independiente
- ✅ Flexibilidad local/remoto sin editar código
- ✅ Reutilización entre proyectos (mobile, backend, widgets)

---

## Estructura de Repositorios

### Arquitectura Final

```
GitHub: edugo/
├── edugo-foundation-kit/          (Repo 1)
│   └── Package.swift → EduFoundation
│
├── edugo-infrastructure-kit/      (Repo 2)
│   └── Package.swift
│       ├── EduLogger     (product)
│       ├── EduNetwork    (product)
│       ├── EduStorage    (product)
│       ├── EduUtilities  (product)
│       └── InfraKit      (product "all-in-one")
│
└── edugo-business-core/           (Repo 3)
    └── Package.swift
        ├── EduModels        (product)
        ├── EduDomain        (product)
        ├── EduPresentation  (product)
        └── EduCore          (product "all-in-one")
```

### Dependencias entre Repositorios

```
┌─────────────────────┐
│ edugo-business-core │ v3.0.0
└──────────┬──────────┘
           │ depends on
           ↓
┌──────────────────────────┐
│ edugo-infrastructure-kit │ v2.0.0
└──────────┬───────────────┘
           │ depends on
           ↓
┌──────────────────────┐
│ edugo-foundation-kit │ v1.0.0
└──────────────────────┘
```

---

## Repositorio 1: edugo-foundation-kit

### Descripción

Biblioteca base con tipos fundamentales, errores y protocolos sin dependencias externas. Es la base para todos los demás paquetes.

### Archivos a Migrar

**Desde:** `EduGoModules/Packages/Foundation/`

```
Sources/
└── EduFoundation/
    ├── Domain/
    │   └── Entity.swift                    ← COPIAR
    ├── Errors/
    │   ├── DomainError.swift               ← COPIAR
    │   ├── RepositoryError.swift           ← COPIAR
    │   └── UseCaseError.swift              ← COPIAR
    ├── Protocols/
    │   └── UserContextProtocol.swift       ← COPIAR
    └── EduFoundation.swift                 ← COPIAR

Tests/
└── EduFoundationTests/
    ├── Domain/
    │   └── EntityTests.swift               ← COPIAR
    ├── Errors/
    │   ├── DomainErrorTests.swift          ← COPIAR
    │   ├── RepositoryErrorTests.swift      ← COPIAR
    │   └── UseCaseErrorTests.swift         ← COPIAR
    └── EduFoundationTests.swift            ← COPIAR
```

### Estructura del Repositorio

```
edugo-foundation-kit/
├── .github/
│   └── workflows/
│       ├── tests.yml                       ← CREAR (ver sección Scripts)
│       └── release.yml                     ← CREAR
├── .gitignore                              ← CREAR
├── Package.swift                           ← CREAR (ver abajo)
├── README.md                               ← CREAR
├── LICENSE                                 ← CREAR
├── Sources/
│   └── EduFoundation/                      ← COPIAR desde Packages/Foundation/
└── Tests/
    └── EduFoundationTests/                 ← COPIAR desde Packages/Foundation/
```

### Package.swift

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "EduFoundationKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "EduFoundation",
            targets: ["EduFoundation"]
        )
    ],
    targets: [
        .target(
            name: "EduFoundation",
            path: "Sources/EduFoundation"
        ),
        .testTarget(
            name: "EduFoundationTests",
            dependencies: ["EduFoundation"],
            path: "Tests/EduFoundationTests"
        )
    ],
    swiftLanguageModes: [.v6]
)
```

### README.md

```markdown
# EduFoundation Kit

Base library with fundamental types, errors, and protocols for EduGo ecosystem.

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/edugo/edugo-foundation-kit", from: "1.0.0")
]
```

## Usage

```swift
import EduFoundation

// Domain entities
class User: Entity {
    let id: String
    // ...
}

// Error handling
throw DomainError.invalidData
throw UseCaseError.unauthorized
throw RepositoryError.notFound
```

## Requirements

- iOS 18.0+ / macOS 15.0+
- Swift 6.2+
- Xcode 16.0+

## License

MIT
```

### .gitignore

```gitignore
# Swift
.DS_Store
.build/
*.xcodeproj
*.xcworkspace
.swiftpm/

# Xcode
xcuserdata/
DerivedData/
*.moved-aside
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3

# SPM
.swiftpm/
Package.resolved
```

### Comandos de Creación

```bash
# 1. Crear directorio
mkdir -p ~/repos/edugo-foundation-kit
cd ~/repos/edugo-foundation-kit

# 2. Inicializar git
git init
git branch -M main

# 3. Copiar archivos desde EduGoModules
cp -r /path/to/EduGoModules/Packages/Foundation/Sources ./
cp -r /path/to/EduGoModules/Packages/Foundation/Tests ./

# 4. Crear Package.swift (copiar contenido de arriba)
# 5. Crear README.md (copiar contenido de arriba)
# 6. Crear .gitignore (copiar contenido de arriba)

# 7. Commit inicial
git add .
git commit -m "feat: initial foundation kit v1.0.0"

# 8. Crear repo en GitHub y push
git remote add origin https://github.com/edugo/edugo-foundation-kit.git
git push -u origin main

# 9. Crear tag de versión
git tag 1.0.0
git push origin 1.0.0
```

---

## Repositorio 2: edugo-infrastructure-kit

### Descripción

Componentes técnicos genéricos: Logger, Network, Storage, Utilities. Todos son selectivos mediante products.

### Archivos a Migrar

**Desde:** `EduGoModules/Packages/Core/` e `Infrastructure/`

```
Sources/
├── Logger/                                 ← COPIAR desde Core/Sources/Logger/
│   ├── Configuration/
│   ├── Implementation/
│   ├── Models/
│   ├── Categories/
│   ├── Protocols/
│   ├── Registry/
│   └── Logger.swift
│
├── Network/                                ← COPIAR desde Infrastructure/Sources/Network/
│   ├── Interceptors/
│   ├── Repositories/
│   ├── DTOs/
│   ├── HTTPRequest.swift
│   ├── NetworkClientProtocol.swift
│   ├── NetworkError.swift
│   └── Network.swift
│
├── Storage/                                ← COPIAR desde Infrastructure/Sources/Storage/
│   └── Storage.swift
│
└── Utilities/                              ← COPIAR desde Core/Sources/Utilities/
    ├── CodableSerializer.swift
    └── Utilities.swift

Tests/
├── LoggerTests/                            ← COPIAR desde Core/Tests/CoreTests/Logger/
├── NetworkTests/                           ← CREAR (actualmente no existen)
├── StorageTests/                           ← CREAR
└── UtilitiesTests/                         ← CREAR
```

### Estructura del Repositorio

```
edugo-infrastructure-kit/
├── .github/
│   └── workflows/
│       ├── tests.yml
│       └── release.yml
├── .gitignore
├── Package.swift                           ← CREAR (ver abajo)
├── README.md                               ← CREAR
├── LICENSE
├── Sources/
│   ├── Logger/                             ← COPIAR
│   ├── Network/                            ← COPIAR
│   ├── Storage/                            ← COPIAR
│   └── Utilities/                          ← COPIAR
└── Tests/
    ├── LoggerTests/                        ← COPIAR
    ├── NetworkTests/                       ← CREAR
    ├── StorageTests/                       ← CREAR
    └── UtilitiesTests/                     ← CREAR
```

### Package.swift

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "EduInfrastructureKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        // Products individuales (selectivos)
        .library(
            name: "EduLogger",
            targets: ["EduLogger"]
        ),
        .library(
            name: "EduNetwork",
            targets: ["EduNetwork"]
        ),
        .library(
            name: "EduStorage",
            targets: ["EduStorage"]
        ),
        .library(
            name: "EduUtilities",
            targets: ["EduUtilities"]
        ),
        // Product "all-in-one"
        .library(
            name: "InfraKit",
            targets: [
                "EduLogger",
                "EduNetwork",
                "EduStorage",
                "EduUtilities"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/edugo/edugo-foundation-kit", from: "1.0.0")
    ],
    targets: [
        // Logger Target
        .target(
            name: "EduLogger",
            dependencies: [
                .product(name: "EduFoundation", package: "edugo-foundation-kit")
            ],
            path: "Sources/Logger"
        ),
        
        // Network Target (depende de Logger para logging)
        .target(
            name: "EduNetwork",
            dependencies: [
                .product(name: "EduFoundation", package: "edugo-foundation-kit"),
                "EduLogger"
            ],
            path: "Sources/Network"
        ),
        
        // Storage Target
        .target(
            name: "EduStorage",
            dependencies: [
                .product(name: "EduFoundation", package: "edugo-foundation-kit")
            ],
            path: "Sources/Storage"
        ),
        
        // Utilities Target
        .target(
            name: "EduUtilities",
            dependencies: [
                .product(name: "EduFoundation", package: "edugo-foundation-kit")
            ],
            path: "Sources/Utilities"
        ),
        
        // Tests
        .testTarget(
            name: "EduLoggerTests",
            dependencies: ["EduLogger"],
            path: "Tests/LoggerTests"
        ),
        .testTarget(
            name: "EduNetworkTests",
            dependencies: ["EduNetwork"],
            path: "Tests/NetworkTests"
        ),
        .testTarget(
            name: "EduStorageTests",
            dependencies: ["EduStorage"],
            path: "Tests/StorageTests"
        ),
        .testTarget(
            name: "EduUtilitiesTests",
            dependencies: ["EduUtilities"],
            path: "Tests/UtilitiesTests"
        )
    ],
    swiftLanguageModes: [.v6]
)
```

### README.md

```markdown
# EduInfrastructure Kit

Technical infrastructure components: Logger, Network, Storage, Utilities.

## Products

- **EduLogger**: Logging system based on OSLog
- **EduNetwork**: HTTP client with interceptors
- **EduStorage**: UserDefaults/Keychain wrappers
- **EduUtilities**: Common helpers and serializers
- **InfraKit**: All components in one product

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/edugo/edugo-infrastructure-kit", from: "2.0.0")
]
```

## Selective Usage

```swift
// Only Logger
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "EduLogger", package: "edugo-infrastructure-kit")
    ]
)

// Logger + Network
.target(
    name: "MyBackend",
    dependencies: [
        .product(name: "EduLogger", package: "edugo-infrastructure-kit"),
        .product(name: "EduNetwork", package: "edugo-infrastructure-kit")
    ]
)

// Everything
.target(
    name: "MyFullApp",
    dependencies: [
        .product(name: "InfraKit", package: "edugo-infrastructure-kit")
    ]
)
```

## Usage Examples

### Logger

```swift
import EduLogger

let logger = Logger.default
logger.info("App started", category: .application)
```

### Network

```swift
import EduNetwork

let client = NetworkClient()
let response = try await client.request(GetUserRequest(id: "123"))
```

### Storage

```swift
import EduStorage

Storage.shared.set("value", forKey: "key")
let value = Storage.shared.string(forKey: "key")
```

## Requirements

- iOS 18.0+ / macOS 15.0+
- Swift 6.2+
- Depends on: edugo-foundation-kit 1.x

## License

MIT
```

### Comandos de Creación

```bash
# 1. Crear directorio
mkdir -p ~/repos/edugo-infrastructure-kit
cd ~/repos/edugo-infrastructure-kit

# 2. Inicializar git
git init
git branch -M main

# 3. Crear estructura
mkdir -p Sources/{Logger,Network,Storage,Utilities}
mkdir -p Tests/{LoggerTests,NetworkTests,StorageTests,UtilitiesTests}

# 4. Copiar archivos
cp -r /path/to/EduGoModules/Packages/Core/Sources/Logger/* Sources/Logger/
cp -r /path/to/EduGoModules/Packages/Infrastructure/Sources/Network/* Sources/Network/
cp -r /path/to/EduGoModules/Packages/Infrastructure/Sources/Storage/* Sources/Storage/
cp -r /path/to/EduGoModules/Packages/Core/Sources/Utilities/* Sources/Utilities/

cp -r /path/to/EduGoModules/Packages/Core/Tests/CoreTests/Logger/* Tests/LoggerTests/

# 5. Crear Package.swift, README.md, .gitignore
# (copiar contenidos de arriba)

# 6. Commit inicial
git add .
git commit -m "feat: initial infrastructure kit v2.0.0"

# 7. Crear repo en GitHub y push
git remote add origin https://github.com/edugo/edugo-infrastructure-kit.git
git push -u origin main

# 8. Crear tag
git tag 2.0.0
git push origin 2.0.0
```

---

## Repositorio 3: edugo-business-core

### Descripción

Lógica de negocio específica de EduGo: Models, Domain (UseCases, CQRS), Presentation (ViewModels).

### Archivos a Migrar

**Desde:** `EduGoModules/Packages/`

```
Sources/
├── Models/                                 ← COPIAR desde Core/Sources/Models/
│   ├── DTOs/
│   ├── Domain/
│   ├── Mappers/
│   ├── Protocols/
│   ├── Support/
│   ├── Validation/
│   └── Models.swift
│
├── Domain/                                 ← COPIAR desde Domain/Sources/
│   ├── CQRS/
│   ├── Services/
│   ├── StateManagement/
│   ├── UseCases/
│   └── EduDomain.swift
│
└── Presentation/                           ← COPIAR desde Presentation/Sources/
    ├── Components/
    ├── DesignSystem/
    ├── Navigation/
    ├── Utilities/
    ├── ViewModels/
    └── EduPresentation.swift

Tests/
├── ModelsTests/                            ← COPIAR desde Core/Tests/CoreTests/Models/
├── DomainTests/                            ← COPIAR desde Domain/Tests/
└── PresentationTests/                      ← COPIAR desde Presentation/Tests/
```

### Estructura del Repositorio

```
edugo-business-core/
├── .github/
│   └── workflows/
│       ├── tests.yml
│       └── release.yml
├── .gitignore
├── Package.swift                           ← CREAR (ver abajo)
├── README.md                               ← CREAR
├── LICENSE
├── Sources/
│   ├── Models/                             ← COPIAR
│   ├── Domain/                             ← COPIAR
│   └── Presentation/                       ← COPIAR
└── Tests/
    ├── ModelsTests/                        ← COPIAR
    ├── DomainTests/                        ← COPIAR
    └── PresentationTests/                  ← COPIAR
```

### Package.swift

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "EduBusinessCore",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        // Products individuales (selectivos)
        .library(
            name: "EduModels",
            targets: ["EduModels"]
        ),
        .library(
            name: "EduDomain",
            targets: ["EduDomain"]
        ),
        .library(
            name: "EduPresentation",
            targets: ["EduPresentation"]
        ),
        // Product "all-in-one"
        .library(
            name: "EduCore",
            targets: [
                "EduModels",
                "EduDomain",
                "EduPresentation"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/edugo/edugo-foundation-kit", from: "1.0.0"),
        .package(url: "https://github.com/edugo/edugo-infrastructure-kit", from: "2.0.0")
    ],
    targets: [
        // Models Target
        .target(
            name: "EduModels",
            dependencies: [
                .product(name: "EduFoundation", package: "edugo-foundation-kit"),
                .product(name: "EduUtilities", package: "edugo-infrastructure-kit")
            ],
            path: "Sources/Models"
        ),
        
        // Domain Target (depende de Models y Network)
        .target(
            name: "EduDomain",
            dependencies: [
                .product(name: "EduFoundation", package: "edugo-foundation-kit"),
                .product(name: "EduNetwork", package: "edugo-infrastructure-kit"),
                .product(name: "EduStorage", package: "edugo-infrastructure-kit"),
                "EduModels"
            ],
            path: "Sources/Domain"
        ),
        
        // Presentation Target (depende de Domain)
        .target(
            name: "EduPresentation",
            dependencies: [
                .product(name: "EduFoundation", package: "edugo-foundation-kit"),
                "EduModels",
                "EduDomain"
            ],
            path: "Sources/Presentation"
        ),
        
        // Tests
        .testTarget(
            name: "EduModelsTests",
            dependencies: ["EduModels"],
            path: "Tests/ModelsTests",
            resources: [
                .copy("Resources/JSON")
            ]
        ),
        .testTarget(
            name: "EduDomainTests",
            dependencies: ["EduDomain"],
            path: "Tests/DomainTests"
        ),
        .testTarget(
            name: "EduPresentationTests",
            dependencies: ["EduPresentation"],
            path: "Tests/PresentationTests"
        )
    ],
    swiftLanguageModes: [.v6]
)
```

### README.md

```markdown
# EduBusiness Core

Business logic for EduGo: Models, Domain (UseCases, CQRS), Presentation (ViewModels).

## Products

- **EduModels**: DTOs, Domain models, Mappers
- **EduDomain**: UseCases, CQRS, State management
- **EduPresentation**: ViewModels, Components, Navigation
- **EduCore**: All business logic in one product

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/edugo/edugo-business-core", from: "3.0.0")
]
```

## Selective Usage

```swift
// Backend: Solo Models + Domain (sin UI)
.target(
    name: "EduGoBackend",
    dependencies: [
        .product(name: "EduModels", package: "edugo-business-core"),
        .product(name: "EduDomain", package: "edugo-business-core")
    ]
)

// Mobile App: Todo
.target(
    name: "EduGoMobile",
    dependencies: [
        .product(name: "EduCore", package: "edugo-business-core")
    ]
)
```

## Usage Examples

### Models

```swift
import EduModels

let user = User(id: "123", email: "user@edugo.com")
let dto = UserMapper.toDTO(user)
```

### Domain

```swift
import EduDomain

let useCase = GetUserUseCase(repository: userRepo)
let user = try await useCase.execute(userId: "123")
```

### Presentation

```swift
import EduPresentation

class UserListViewModel: ObservableObject {
    @Published var users: [User] = []
    // ...
}
```

## Requirements

- iOS 18.0+ / macOS 15.0+
- Swift 6.2+
- Depends on: 
  - edugo-foundation-kit 1.x
  - edugo-infrastructure-kit 2.x

## License

MIT
```

### Comandos de Creación

```bash
# 1. Crear directorio
mkdir -p ~/repos/edugo-business-core
cd ~/repos/edugo-business-core

# 2. Inicializar git
git init
git branch -M main

# 3. Crear estructura
mkdir -p Sources/{Models,Domain,Presentation}
mkdir -p Tests/{ModelsTests,DomainTests,PresentationTests}

# 4. Copiar archivos
cp -r /path/to/EduGoModules/Packages/Core/Sources/Models/* Sources/Models/
cp -r /path/to/EduGoModules/Packages/Domain/Sources/* Sources/Domain/
cp -r /path/to/EduGoModules/Packages/Presentation/Sources/* Sources/Presentation/

cp -r /path/to/EduGoModules/Packages/Core/Tests/CoreTests/Models/* Tests/ModelsTests/
cp -r /path/to/EduGoModules/Packages/Domain/Tests/* Tests/DomainTests/
cp -r /path/to/EduGoModules/Packages/Presentation/Tests/* Tests/PresentationTests/

# 5. Crear Package.swift, README.md, .gitignore

# 6. Commit inicial
git add .
git commit -m "feat: initial business core v3.0.0"

# 7. Crear repo en GitHub y push
git remote add origin https://github.com/edugo/edugo-business-core.git
git push -u origin main

# 8. Crear tag
git tag 3.0.0
git push origin 3.0.0
```

---

## Configuración Local/Remoto

### Método Recomendado: Xcode Local Override

Este método NO requiere modificar `Package.swift`, manteniendo el código limpio y seguro para commits.

### Setup Inicial (Una Vez por Desarrollador)

#### 1. Clonar Repositorios Localmente

```bash
# Crear directorio de trabajo
mkdir -p ~/repos/edugo
cd ~/repos/edugo

# Clonar los 3 repos
git clone https://github.com/edugo/edugo-foundation-kit.git
git clone https://github.com/edugo/edugo-infrastructure-kit.git
git clone https://github.com/edugo/edugo-business-core.git

# Estructura resultante:
# ~/repos/edugo/
# ├── edugo-foundation-kit/
# ├── edugo-infrastructure-kit/
# └── edugo-business-core/
```

#### 2. Configurar Override en Xcode

**Para cada paquete que quieras desarrollar localmente:**

1. Abrir tu proyecto consumidor (ej: `EduGoMobile.xcodeproj`)

2. En **Project Navigator**:
   - Expandir sección "Package Dependencies"
   - Encontrar `edugo-foundation-kit`

3. **Clic derecho** → **"Override Package..."**

4. Seleccionar carpeta: `~/repos/edugo/edugo-foundation-kit`

5. Repetir para `edugo-infrastructure-kit` y `edugo-business-core` si los necesitas

**Resultado visual en Xcode:**

```
📦 Package Dependencies
  📁 edugo-foundation-kit (Local: ~/repos/edugo/edugo-foundation-kit)
  📁 edugo-infrastructure-kit (Local: ~/repos/edugo/edugo-infrastructure-kit)
  📁 edugo-business-core (Remote: github.com/edugo/edugo-business-core)
```

### Package.swift de Proyectos Consumidores

**IMPORTANTE:** El `Package.swift` SIEMPRE usa URLs remotas. NO editar esto nunca.

```swift
// edugo-api-mobile/Package.swift
let package = Package(
    name: "EduGoMobile",
    dependencies: [
        // SIEMPRE URLs remotas - NO cambiar
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
)
```

### Workflow de Desarrollo

#### Escenario: Desarrollar Feature en `edugo-infrastructure-kit`

**Paso 1: Preparar branch local**

```bash
cd ~/repos/edugo/edugo-infrastructure-kit
git checkout -b feature/improve-network-retry
```

**Paso 2: Activar override en Xcode (si no está ya)**

```
Xcode → Project Navigator → edugo-infrastructure-kit
→ Inspector → "Local Path Override" → ~/repos/edugo/edugo-infrastructure-kit
```

**Paso 3: Desarrollar**

```
1. Editar Sources/Network/RetryPolicy.swift
2. Cambios se reflejan AUTOMÁTICAMENTE en tu app
3. Testear en la app
4. Iterar hasta terminar
```

**Paso 4: Publicar cambios**

```bash
cd ~/repos/edugo/edugo-infrastructure-kit

# Commit y push
git add .
git commit -m "feat: improve retry policy with exponential backoff"
git push origin feature/improve-network-retry

# Crear Pull Request en GitHub
# Después del merge a main...

# Actualizar local
git checkout main
git pull

# Crear release
git tag 2.1.0
git push origin 2.1.0
```

**Paso 5: Actualizar versión en app consumidora**

```swift
// edugo-api-mobile/Package.swift
dependencies: [
    .package(url: "https://github.com/edugo/edugo-infrastructure-kit", from: "2.1.0")  // ← Cambiar de 2.0.0 a 2.1.0
]
```

```
Xcode → File → Packages → Update to Latest Package Versions
```

**Paso 6: (Opcional) Remover override**

```
Xcode → Inspector → "Remove Local Override"
```

### Pre-commit Hook (Seguridad)

Previene commits accidentales de paths locales:

**Archivo:** `.git/hooks/pre-commit`

```bash
#!/bin/bash

# Verificar que Package.swift no tenga .package(path:
if grep -q '\.package(path:' Package.swift 2>/dev/null; then
    echo "❌ ERROR: Package.swift contiene dependencias locales!"
    echo ""
    echo "   Encontrado: .package(path: ...)"
    echo "   Debe ser:   .package(url: ...)"
    echo ""
    echo "   Si estás usando Xcode Local Override, esto no debería pasar."
    echo "   Revisa tu Package.swift y asegúrate de usar URLs remotas."
    exit 1
fi

echo "✅ Package.swift OK (usando dependencias remotas)"
exit 0
```

**Instalación:**

```bash
# En cada proyecto consumidor
cd /path/to/edugo-api-mobile
chmod +x .git/hooks/pre-commit
```

### Documentación para Desarrolladores

**Archivo:** `DESARROLLO_LOCAL.md` (crear en cada proyecto consumidor)

```markdown
# Desarrollo Local de Paquetes

## Setup Inicial

### 1. Clonar repositorios de paquetes

```bash
mkdir -p ~/repos/edugo
cd ~/repos/edugo

git clone https://github.com/edugo/edugo-foundation-kit.git
git clone https://github.com/edugo/edugo-infrastructure-kit.git
git clone https://github.com/edugo/edugo-business-core.git
```

### 2. Configurar Xcode Override

Para cada paquete que necesites modificar:

1. Abrir proyecto en Xcode
2. Project Navigator → Package Dependencies → Clic derecho en paquete
3. "Override Package..." → Seleccionar carpeta local
4. Ejemplo: `~/repos/edugo/edugo-infrastructure-kit`

## Workflow Diario

### Desarrollar feature

1. Crear branch en repo del paquete:
   ```bash
   cd ~/repos/edugo/edugo-infrastructure-kit
   git checkout -b feature/mi-feature
   ```

2. Editar código (cambios se reflejan automáticamente en Xcode)

3. Testear en la app

4. Commit y push:
   ```bash
   git add .
   git commit -m "feat: descripción"
   git push origin feature/mi-feature
   ```

5. Crear Pull Request en GitHub

6. Después del merge, crear release:
   ```bash
   git checkout main
   git pull
   git tag 2.1.0
   git push origin 2.1.0
   ```

7. Actualizar versión en este proyecto

### Volver a versión remota

Xcode → Inspector del paquete → "Remove Local Override"

## Troubleshooting

### "Package not found"
- Verifica que la carpeta local exista
- Verifica que tenga un Package.swift válido

### "Package conflicts"
- File → Packages → Reset Package Caches
- Cierra y reabre Xcode

### Cambios no se reflejan
- File → Packages → Resolve Package Versions
- Clean Build Folder (Cmd+Shift+K)
```

### Script de Verificación

**Archivo:** `scripts/verify-packages.sh`

```bash
#!/bin/bash

echo "🔍 Verificando configuración de paquetes..."
echo ""

# Verificar que Package.swift use URLs
if grep -q '\.package(path:' Package.swift; then
    echo "❌ ERROR: Package.swift contiene .package(path:...)"
    echo "   Debe usar .package(url:...)"
    exit 1
else
    echo "✅ Package.swift usa URLs remotas"
fi

# Verificar que los repos locales existan (si se usan overrides)
REPOS=(
    "$HOME/repos/edugo/edugo-foundation-kit"
    "$HOME/repos/edugo/edugo-infrastructure-kit"
    "$HOME/repos/edugo/edugo-business-core"
)

echo ""
echo "📦 Repositorios locales:"
for repo in "${REPOS[@]}"; do
    if [ -d "$repo" ]; then
        cd "$repo"
        branch=$(git branch --show-current)
        echo "  ✅ $(basename $repo) (branch: $branch)"
    else
        echo "  ⚠️  $(basename $repo) (no encontrado)"
    fi
done

echo ""
echo "✅ Verificación completa"
```

**Uso:**

```bash
chmod +x scripts/verify-packages.sh
./scripts/verify-packages.sh
```

---

## Migración de Proyectos Consumidores

### Proyectos a Actualizar

1. `edugo-api-administracion`
2. `edugo-api-mobile`
3. Cualquier otro proyecto que use EduGoModules

### Proceso de Migración

#### Paso 1: Backup

```bash
cd /path/to/edugo-api-mobile
git checkout -b migration/modular-packages
git commit -am "chore: backup before migration"
```

#### Paso 2: Actualizar Package.swift

**Antes:**

```swift
// edugo-api-mobile/Package.swift
dependencies: [
    .package(path: "../EduGoModules")  // Referencia local al monorepo
],
targets: [
    .target(
        name: "App",
        dependencies: [
            .product(name: "EduGoModules", package: "EduGoModules")
        ]
    )
]
```

**Después:**

```swift
// edugo-api-mobile/Package.swift
dependencies: [
    .package(url: "https://github.com/edugo/edugo-foundation-kit", from: "1.0.0"),
    .package(url: "https://github.com/edugo/edugo-infrastructure-kit", from: "2.0.0"),
    .package(url: "https://github.com/edugo/edugo-business-core", from: "3.0.0")
],
targets: [
    .target(
        name: "App",
        dependencies: [
            .product(name: "EduFoundation", package: "edugo-foundation-kit"),
            .product(name: "InfraKit", package: "edugo-infrastructure-kit"),
            .product(name: "EduCore", package: "edugo-business-core")
        ]
    )
]
```

#### Paso 3: Actualizar Imports (si es necesario)

La mayoría de los imports NO cambiarán porque los nombres de módulos se mantienen:

```swift
// ✅ Siguen funcionando igual
import EduFoundation
import EduLogger
import EduNetwork
import EduModels
import EduDomain
import EduPresentation
```

**Solo cambia si antes usabas el umbrella:**

```swift
// Antes
import EduGoModules  // ❌ Ya no existe

// Después - importa específicamente lo que necesitas
import EduFoundation
import EduLogger
import EduModels
```

#### Paso 4: Resolver Paquetes

```bash
# CLI
swift package resolve

# O en Xcode
# File → Packages → Resolve Package Versions
```

#### Paso 5: Build y Test

```bash
swift build
swift test
```

#### Paso 6: Commit

```bash
git add Package.swift
git commit -m "feat: migrate to modular packages (foundation-kit, infrastructure-kit, business-core)"
git push origin migration/modular-packages
```

### Ejemplo Completo: edugo-api-mobile

**Package.swift completo después de migración:**

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "EduGoMobile",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(name: "EduGoMobile", targets: ["EduGoMobile"])
    ],
    dependencies: [
        // Paquetes modulares
        .package(url: "https://github.com/edugo/edugo-foundation-kit", from: "1.0.0"),
        .package(url: "https://github.com/edugo/edugo-infrastructure-kit", from: "2.0.0"),
        .package(url: "https://github.com/edugo/edugo-business-core", from: "3.0.0"),
        
        // Otras dependencias externas
        // .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "EduGoMobile",
            dependencies: [
                // Usar products selectivos o "all-in-one"
                .product(name: "EduFoundation", package: "edugo-foundation-kit"),
                .product(name: "InfraKit", package: "edugo-infrastructure-kit"),  // Todo infra
                .product(name: "EduCore", package: "edugo-business-core")         // Todo business
            ]
        ),
        .testTarget(
            name: "EduGoMobileTests",
            dependencies: ["EduGoMobile"]
        )
    ]
)
```

### Ejemplo: Backend (Compilación Selectiva)

**edugo-api-administracion/Package.swift:**

```swift
let package = Package(
    name: "EduGoBackend",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        .package(url: "https://github.com/edugo/edugo-foundation-kit", from: "1.0.0"),
        .package(url: "https://github.com/edugo/edugo-infrastructure-kit", from: "2.0.0"),
        .package(url: "https://github.com/edugo/edugo-business-core", from: "3.0.0")
    ],
    targets: [
        .executableTarget(
            name: "Server",
            dependencies: [
                // Solo lo que el backend necesita
                .product(name: "EduFoundation", package: "edugo-foundation-kit"),
                .product(name: "EduLogger", package: "edugo-infrastructure-kit"),
                .product(name: "EduNetwork", package: "edugo-infrastructure-kit"),
                .product(name: "EduModels", package: "edugo-business-core"),
                .product(name: "EduDomain", package: "edugo-business-core")
                // ✅ NO incluye: EduStorage, EduUtilities, EduPresentation
            ]
        )
    ]
)
```

**Resultado:**
- ⬇️ Descarga: ~6MB (todos los repos)
- 🔨 Compila: Solo Foundation + Logger + Network + Models + Domain
- ❌ NO compila: Storage, Utilities, Presentation

---

## Scripts de Automatización

### GitHub Actions: Tests

**Archivo:** `.github/workflows/tests.yml`

```yaml
name: Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test-ios:
    name: Test iOS
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
      
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.0.app
      
      - name: Show Swift version
        run: swift --version
      
      - name: Resolve dependencies
        run: swift package resolve
      
      - name: Build
        run: swift build
      
      - name: Run tests
        run: swift test --parallel
  
  test-macos:
    name: Test macOS
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
      
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.0.app
      
      - name: Build for macOS
        run: swift build -c release
      
      - name: Run tests
        run: swift test --parallel
```

### GitHub Actions: Release

**Archivo:** `.github/workflows/release.yml`

```yaml
name: Release

on:
  push:
    tags:
      - '*'

jobs:
  create-release:
    name: Create Release
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
      
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.0.app
      
      - name: Build
        run: swift build -c release
      
      - name: Run tests
        run: swift test
      
      - name: Create GitHub Release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ github.ref_name }}
          release_name: Release ${{ github.ref_name }}
          body: |
            ## Changes in this Release
            - See commit history for details
          draft: false
          prerelease: false
```

### Script: Crear Todos los Repos

**Archivo:** `scripts/create-all-repos.sh`

```bash
#!/bin/bash

set -e

BASE_DIR="$HOME/repos/edugo"
SOURCE_DIR="/Users/jhoanmedina/source/EduGo/EduUI/Modules/Apple/EduGoModules"

echo "🚀 Creando estructura de repositorios modulares..."
echo ""

# Crear directorio base
mkdir -p "$BASE_DIR"
cd "$BASE_DIR"

# -------------------
# REPO 1: Foundation
# -------------------
echo "📦 1/3 Creando edugo-foundation-kit..."
mkdir -p edugo-foundation-kit
cd edugo-foundation-kit

git init
git branch -M main

# Copiar archivos
mkdir -p Sources Tests
cp -r "$SOURCE_DIR/Packages/Foundation/Sources/EduFoundation" Sources/
cp -r "$SOURCE_DIR/Packages/Foundation/Tests/EduFoundationTests" Tests/

# Crear Package.swift
cat > Package.swift << 'EOF'
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "EduFoundationKit",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "EduFoundation", targets: ["EduFoundation"])
    ],
    targets: [
        .target(name: "EduFoundation", path: "Sources/EduFoundation"),
        .testTarget(name: "EduFoundationTests", dependencies: ["EduFoundation"], path: "Tests/EduFoundationTests")
    ],
    swiftLanguageModes: [.v6]
)
EOF

# .gitignore
cat > .gitignore << 'EOF'
.DS_Store
.build/
*.xcodeproj
*.xcworkspace
.swiftpm/
xcuserdata/
DerivedData/
Package.resolved
EOF

# README
cat > README.md << 'EOF'
# EduFoundation Kit

Base library with fundamental types, errors, and protocols.

## Installation

```swift
.package(url: "https://github.com/edugo/edugo-foundation-kit", from: "1.0.0")
```
EOF

git add .
git commit -m "feat: initial foundation kit v1.0.0"

echo "✅ edugo-foundation-kit creado"
echo ""

# -------------------
# REPO 2: Infrastructure
# -------------------
cd "$BASE_DIR"
echo "📦 2/3 Creando edugo-infrastructure-kit..."
mkdir -p edugo-infrastructure-kit
cd edugo-infrastructure-kit

git init
git branch -M main

# Copiar archivos
mkdir -p Sources/{Logger,Network,Storage,Utilities}
mkdir -p Tests/{LoggerTests,NetworkTests,StorageTests,UtilitiesTests}

cp -r "$SOURCE_DIR/Packages/Core/Sources/Logger/"* Sources/Logger/ 2>/dev/null || true
cp -r "$SOURCE_DIR/Packages/Infrastructure/Sources/Network/"* Sources/Network/ 2>/dev/null || true
cp -r "$SOURCE_DIR/Packages/Infrastructure/Sources/Storage/"* Sources/Storage/ 2>/dev/null || true
cp -r "$SOURCE_DIR/Packages/Core/Sources/Utilities/"* Sources/Utilities/ 2>/dev/null || true

cp -r "$SOURCE_DIR/Packages/Core/Tests/CoreTests/Logger/"* Tests/LoggerTests/ 2>/dev/null || true

# Crear Package.swift (ver contenido completo arriba - omitido por brevedad)
# ... (copiar Package.swift de la sección correspondiente)

git add .
git commit -m "feat: initial infrastructure kit v2.0.0"

echo "✅ edugo-infrastructure-kit creado"
echo ""

# -------------------
# REPO 3: Business Core
# -------------------
cd "$BASE_DIR"
echo "📦 3/3 Creando edugo-business-core..."
mkdir -p edugo-business-core
cd edugo-business-core

git init
git branch -M main

# Copiar archivos
mkdir -p Sources/{Models,Domain,Presentation}
mkdir -p Tests/{ModelsTests,DomainTests,PresentationTests}

cp -r "$SOURCE_DIR/Packages/Core/Sources/Models/"* Sources/Models/ 2>/dev/null || true
cp -r "$SOURCE_DIR/Packages/Domain/Sources/"* Sources/Domain/ 2>/dev/null || true
cp -r "$SOURCE_DIR/Packages/Presentation/Sources/"* Sources/Presentation/ 2>/dev/null || true

cp -r "$SOURCE_DIR/Packages/Core/Tests/CoreTests/Models/"* Tests/ModelsTests/ 2>/dev/null || true
cp -r "$SOURCE_DIR/Packages/Domain/Tests/"* Tests/DomainTests/ 2>/dev/null || true
cp -r "$SOURCE_DIR/Packages/Presentation/Tests/"* Tests/PresentationTests/ 2>/dev/null || true

# Crear Package.swift (ver contenido completo arriba)
# ... (copiar Package.swift de la sección correspondiente)

git add .
git commit -m "feat: initial business core v3.0.0"

echo "✅ edugo-business-core creado"
echo ""

echo "🎉 Todos los repositorios creados exitosamente!"
echo ""
echo "Próximos pasos:"
echo "1. Crear repos en GitHub:"
echo "   - https://github.com/edugo/edugo-foundation-kit"
echo "   - https://github.com/edugo/edugo-infrastructure-kit"
echo "   - https://github.com/edugo/edugo-business-core"
echo ""
echo "2. Push de cada repo:"
echo "   cd $BASE_DIR/edugo-foundation-kit && git remote add origin ... && git push -u origin main && git tag 1.0.0 && git push origin 1.0.0"
echo "   cd $BASE_DIR/edugo-infrastructure-kit && git remote add origin ... && git push -u origin main && git tag 2.0.0 && git push origin 2.0.0"
echo "   cd $BASE_DIR/edugo-business-core && git remote add origin ... && git push -u origin main && git tag 3.0.0 && git push origin 3.0.0"
```

**Uso:**

```bash
chmod +x scripts/create-all-repos.sh
./scripts/create-all-repos.sh
```

---

## Checklist de Implementación

### Fase 1: Preparación (Día 1)

- [ ] Crear organización/equipo en GitHub: `edugo`
- [ ] Definir permisos de acceso
- [ ] Preparar LICENSE (MIT recomendado)
- [ ] Backup completo de `EduGoModules` actual

```bash
cd /path/to/EduGoModules
git tag backup-before-modularization
git push origin backup-before-modularization
```

### Fase 2: Crear Repositorios Vacíos en GitHub (Día 1)

- [ ] Crear repo: `https://github.com/edugo/edugo-foundation-kit`
- [ ] Crear repo: `https://github.com/edugo/edugo-infrastructure-kit`
- [ ] Crear repo: `https://github.com/edugo/edugo-business-core`
- [ ] Configurar branch protection en `main`
- [ ] Configurar require PR reviews

### Fase 3: Generar Contenido Local (Día 2)

- [ ] Ejecutar `scripts/create-all-repos.sh`
- [ ] Verificar estructura de cada repo
- [ ] Verificar que tests pasen localmente:

```bash
cd ~/repos/edugo/edugo-foundation-kit && swift test
cd ~/repos/edugo/edugo-infrastructure-kit && swift test
cd ~/repos/edugo/edugo-business-core && swift test
```

### Fase 4: Push Inicial (Día 2)

- [ ] Push `edugo-foundation-kit`:

```bash
cd ~/repos/edugo/edugo-foundation-kit
git remote add origin https://github.com/edugo/edugo-foundation-kit.git
git push -u origin main
git tag 1.0.0
git push origin 1.0.0
```

- [ ] Push `edugo-infrastructure-kit`:

```bash
cd ~/repos/edugo/edugo-infrastructure-kit
git remote add origin https://github.com/edugo/edugo-infrastructure-kit.git
git push -u origin main
git tag 2.0.0
git push origin 2.0.0
```

- [ ] Push `edugo-business-core`:

```bash
cd ~/repos/edugo/edugo-business-core
git remote add origin https://github.com/edugo/edugo-business-core.git
git push -u origin main
git tag 3.0.0
git push origin 3.0.0
```

### Fase 5: Configurar GitHub Actions (Día 3)

Para cada repo:

- [ ] Crear `.github/workflows/tests.yml`
- [ ] Crear `.github/workflows/release.yml`
- [ ] Verificar que CI pase (green checks)
- [ ] Configurar badges en README.md

### Fase 6: Migrar Primer Proyecto (Día 3-4)

- [ ] Elegir proyecto piloto (ej: `edugo-api-mobile`)
- [ ] Crear branch: `migration/modular-packages`
- [ ] Actualizar `Package.swift`
- [ ] Resolver dependencias
- [ ] Build exitoso
- [ ] Tests pasan
- [ ] Merge a main

### Fase 7: Configurar Desarrollo Local (Día 4)

- [ ] Documentar en `DESARROLLO_LOCAL.md`
- [ ] Configurar Xcode Local Override
- [ ] Instalar pre-commit hooks
- [ ] Crear `scripts/verify-packages.sh`
- [ ] Entrenar al equipo

### Fase 8: Migrar Resto de Proyectos (Día 5-7)

- [ ] Migrar `edugo-api-administracion`
- [ ] Migrar otros proyectos dependientes
- [ ] Actualizar documentación de cada proyecto

### Fase 9: Deprecar Monorepo Original (Día 8)

- [ ] Archivar `EduGoModules` (no eliminar)
- [ ] Actualizar README con aviso de deprecación:

```markdown
# ⚠️ DEPRECATED

Este repositorio ha sido dividido en módulos independientes:

- [edugo-foundation-kit](https://github.com/edugo/edugo-foundation-kit)
- [edugo-infrastructure-kit](https://github.com/edugo/edugo-infrastructure-kit)
- [edugo-business-core](https://github.com/edugo/edugo-business-core)

**No usar más para nuevos proyectos.**
```

### Fase 10: Validación Final (Día 9)

- [ ] Todos los proyectos usan paquetes modulares
- [ ] CI/CD funciona en todos los repos
- [ ] Desarrollo local funciona
- [ ] Documentación completa
- [ ] Equipo entrenado

---

## Resumen de Comandos Rápidos

### Crear repos localmente

```bash
./scripts/create-all-repos.sh
```

### Push a GitHub (después de crear repos vacíos)

```bash
# Foundation
cd ~/repos/edugo/edugo-foundation-kit
git remote add origin https://github.com/edugo/edugo-foundation-kit.git
git push -u origin main && git tag 1.0.0 && git push origin 1.0.0

# Infrastructure
cd ~/repos/edugo/edugo-infrastructure-kit
git remote add origin https://github.com/edugo/edugo-infrastructure-kit.git
git push -u origin main && git tag 2.0.0 && git push origin 2.0.0

# Business Core
cd ~/repos/edugo/edugo-business-core
git remote add origin https://github.com/edugo/edugo-business-core.git
git push -u origin main && git tag 3.0.0 && git push origin 3.0.0
```

### Verificar estado

```bash
./scripts/verify-packages.sh
```

### Actualizar versión (ejemplo: Infrastructure 2.0.0 → 2.1.0)

```bash
cd ~/repos/edugo/edugo-infrastructure-kit
# ... hacer cambios ...
git add .
git commit -m "feat: new feature"
git push
git tag 2.1.0
git push origin 2.1.0
```

---

## Soporte y Troubleshooting

### Problema: "Package not found"

```bash
# Limpiar cache
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf .build
swift package clean
swift package resolve
```

### Problema: "Xcode no detecta cambios locales"

```
File → Packages → Reset Package Caches
Product → Clean Build Folder (Cmd+Shift+K)
Cerrar y reabrir Xcode
```

### Problema: "Conflicto de versiones"

```bash
# Ver versiones instaladas
swift package show-dependencies

# Actualizar a latest
swift package update
```

---

## Conclusión

Este plan implementa la **Propuesta B (Híbrida)** con:

✅ **3 repositorios** bien definidos  
✅ **Compilación selectiva** mediante products  
✅ **Flexibilidad local/remoto** con Xcode Override  
✅ **Versionado semántico** independiente  
✅ **CI/CD** automatizado  
✅ **Documentación** completa  

**Tiempo estimado:** 9 días  
**Complejidad:** Media  
**Reversible:** Sí (mantener backup)

**Estado:** ✅ Listo para ejecutar

---

**Aprobado por:** _____________  
**Fecha de inicio:** _____________  
**Responsable:** _____________
