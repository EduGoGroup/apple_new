# Paso 1: Foundation Toolkit SDK

**Prioridad:** Primera (sin dependencias, base para otros SDKs)
**Dificultad:** Baja
**Archivos fuente:** ~6
**Tests existentes:** 7 archivos en el proyecto original

---

## 1. Crear el proyecto

```bash
mkdir -p FoundationToolkit
cd FoundationToolkit
swift package init --name FoundationToolkit --type library
```

## 2. Configurar Package.swift

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "FoundationToolkit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "FoundationToolkit", targets: ["FoundationToolkit"])
    ],
    targets: [
        .target(
            name: "FoundationToolkit",
            path: "Sources/FoundationToolkit"
        ),
        .testTarget(
            name: "FoundationToolkitTests",
            dependencies: ["FoundationToolkit"],
            path: "Tests/FoundationToolkitTests"
        )
    ]
)
```

## 3. Copiar archivos fuente

Desde el proyecto original, copiar estos archivos a `Sources/FoundationToolkit/`:

### Desde `Packages/Foundation/Sources/EduFoundation/`

| Archivo origen | Destino | Modificaciones |
|---|---|---|
| `Domain/Entity.swift` | `Entity.swift` | Eliminar comentarios "EduGo" |
| `Protocols/UserContextProtocol.swift` | `UserContextProtocol.swift` | Eliminar comentarios "EduGo" |
| `Errors/DomainError.swift` | `Errors/DomainError.swift` | Ninguna (ya es generico) |
| `Errors/RepositoryError.swift` | `Errors/RepositoryError.swift` | Ninguna |
| `Errors/UseCaseError.swift` | `Errors/UseCaseError.swift` | Ninguna |

### Desde `Packages/Core/Sources/Utilities/`

| Archivo origen | Destino | Modificaciones |
|---|---|---|
| `CodableSerializer.swift` | `CodableSerializer.swift` | Eliminar `import EduFoundation` (no lo necesita, solo usa Foundation) |

### Desde `Packages/Infrastructure/Sources/Storage/`

| Archivo origen | Destino | Modificaciones |
|---|---|---|
| `Storage.swift` | `StorageManager.swift` | Eliminar imports de Edu* si los tiene |

## 4. Verificar imports

Despues de copiar, verificar que **ningun archivo** tenga:
```swift
import EduFoundation  // <- eliminar
import EduCore        // <- eliminar
```

Todos deben tener solo:
```swift
import Foundation
```

## 5. Compilar

```bash
swift build
```

**Si falla:** Revisar que `UseCaseError` referencia `DomainError` y `RepositoryError`. Como todos estan en el mismo modulo ahora, deberia resolver sin problemas.

## 6. Copiar tests

Desde el proyecto original a `Tests/FoundationToolkitTests/`:

| Archivo origen | Destino | Modificaciones |
|---|---|---|
| `Packages/Foundation/Tests/EduFoundationTests/Errors/DomainErrorTests.swift` | `DomainErrorTests.swift` | Cambiar `import EduFoundation` por `import FoundationToolkit` |
| `Packages/Foundation/Tests/EduFoundationTests/Errors/RepositoryErrorTests.swift` | `RepositoryErrorTests.swift` | Idem |
| `Packages/Foundation/Tests/EduFoundationTests/Errors/UseCaseErrorTests.swift` | `UseCaseErrorTests.swift` | Idem |
| `Packages/Foundation/Tests/EduFoundationTests/Domain/EntityTests.swift` | `EntityTests.swift` | Idem |
| `Packages/Core/Tests/CoreTests/Utilities/CodableSerializerTests.swift` | `CodableSerializerTests.swift` | Cambiar `import EduCore` por `import FoundationToolkit` |
| `Packages/Infrastructure/Tests/InfrastructureTests/Storage/StorageTests.swift` | `StorageManagerTests.swift` | Cambiar imports |

## 7. Ejecutar tests

```bash
swift test
```

## 8. Checklist final

- [ ] `swift build` compila sin errores
- [ ] `swift test` pasa todos los tests
- [ ] Ningun archivo tiene `import Edu*`
- [ ] Todos los tipos son `public`
- [ ] README.md basico creado
