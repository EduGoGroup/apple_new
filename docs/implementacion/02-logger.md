# Paso 2: Logger SDK

**Prioridad:** Segunda (sin dependencias, otros SDKs podrian usarlo)
**Dificultad:** Baja
**Archivos fuente:** 12
**Tests existentes:** Completos (LoggerTests.swift + MockLogger + TestHelpers)

---

## 1. Crear el proyecto

```bash
mkdir -p LoggerSDK
cd LoggerSDK
swift package init --name LoggerSDK --type library
```

## 2. Configurar Package.swift

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "LoggerSDK",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "LoggerSDK", targets: ["LoggerSDK"])
    ],
    targets: [
        .target(
            name: "LoggerSDK",
            path: "Sources/LoggerSDK"
        ),
        .testTarget(
            name: "LoggerSDKTests",
            dependencies: ["LoggerSDK"],
            path: "Tests/LoggerSDKTests"
        )
    ]
)
```

## 3. Copiar archivos fuente

Desde `Packages/Core/Sources/Logger/` copiar todo a `Sources/LoggerSDK/`:

| Archivo origen | Destino | Modificaciones |
|---|---|---|
| `Core/LoggerProtocol.swift` | `Core/LoggerProtocol.swift` | Ninguna |
| `Core/LogLevel.swift` | `Core/LogLevel.swift` | Ninguna |
| `Core/LogCategory.swift` | `Core/LogCategory.swift` | Ninguna |
| `Core/LogConfiguration.swift` | `Core/LogConfiguration.swift` | Ninguna |
| `Adapters/OSLoggerAdapter.swift` | `Adapters/OSLoggerAdapter.swift` | Ninguna |
| `Adapters/Logger.swift` | `Adapters/Logger.swift` | Cambiar subsystem `"com.edugo.apple"` -> parametrizable |
| `Factory/OSLoggerFactory.swift` | `Factory/OSLoggerFactory.swift` | Ninguna |
| `Registry/LoggerRegistry.swift` | `Registry/LoggerRegistry.swift` | Ninguna |
| `Configuration/LoggerConfigurator.swift` | `Configuration/LoggerConfigurator.swift` | Ninguna |
| `Configuration/EnvironmentConfiguration.swift` | `Configuration/EnvironmentConfiguration.swift` | Ninguna |

### Archivos a EXCLUIR (especificos de EduGo)

| Archivo | Razon |
|---|---|
| `Categories/StandardLogCategory.swift` | Categorias predefinidas de EduGo (TIER0, Logger, Models) |
| `Categories/LogCategoryExtensions.swift` | Usa convenciones "com.edugo" hardcoded |

**Opcion alternativa:** Si quieres mantener `LogCategoryExtensions.swift`, cambiar el prefijo `"com.edugo"` por uno configurable. El `CategoryBuilder` tiene `"com"`, `"edugo"` hardcoded en `build()`.

## 4. Modificaciones necesarias

### 4.1 Parametrizar subsystem en `Logger.swift`

Buscar:
```swift
private static let defaultSubsystem = "com.edugo.apple"
```
Cambiar a:
```swift
public static var defaultSubsystem = "com.app"  // configurable por el consumidor
```

### 4.2 Parametrizar CategoryBuilder (si se incluye)

En `LogCategoryExtensions.swift`, buscar:
```swift
var parts = ["com", "edugo", "tier\(tier)", module]
```
Hacerlo configurable:
```swift
public struct CategoryBuilder: Sendable {
    public static var baseComponents: [String] = ["com", "app"]
    // ...
    public func build() -> String {
        var parts = Self.baseComponents + ["tier\(tier)", module]
        // ...
    }
}
```

## 5. Compilar

```bash
swift build
```

No deberia haber problemas. Los unicos imports son `Foundation` y `OSLog`.

## 6. Copiar tests

Desde `Packages/Core/Tests/CoreTests/Logger/` a `Tests/LoggerSDKTests/`:

| Archivo origen | Destino | Modificaciones |
|---|---|---|
| `LoggerTests.swift` | `LoggerTests.swift` | Cambiar `import EduCore` por `import LoggerSDK`. Eliminar tests de `StandardLogCategory` si se excluyo |
| `Mocks/MockLogger.swift` | `Mocks/MockLogger.swift` | Cambiar import |
| `Helpers/TestHelpers.swift` | `Helpers/TestHelpers.swift` | Cambiar import |

## 7. Ejecutar tests

```bash
swift test
```

## 8. Checklist final

- [ ] `swift build` compila sin errores
- [ ] `swift test` pasa todos los tests
- [ ] Subsystem ya no dice "com.edugo"
- [ ] No hay imports de `EduCore` ni `EduFoundation`
- [ ] README.md basico creado
