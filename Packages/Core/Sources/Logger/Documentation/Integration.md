# Guía de Integración del Logger

**Fecha**: 27 de enero de 2026  
**Versión**: 1.0

---

## 1. Integrar Logger en un Módulo Nuevo

Esta guía te ayudará a integrar el sistema de logging en cualquier módulo nuevo de EduGo.

### Paso 1: Agregar Dependencia

En el `Package.swift` de tu módulo, agrega Logger como dependencia:

```swift
// TIER-X-MyModule/Package.swift
let package = Package(
    name: "MyModule",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "MyModule", targets: ["MyModule"])
    ],
    dependencies: [
        // Agregar Logger
        .package(path: "../../TIER-1-Core/Logger")
    ],
    targets: [
        .target(
            name: "MyModule",
            dependencies: [
                // Agregar como dependencia del target
                .product(name: "Logger", package: "Logger")
            ]
        )
    ]
)
```

### Paso 2: Definir Categorías del Módulo

Crea un archivo para las categorías de logging:

```swift
// Sources/MyModule/Logging/MyModuleCategory.swift
import Logger

/// Categorías de logging para MyModule.
public enum MyModuleCategory: String, LogCategory {
    case initialization = "com.edugo.tier3.mymodule.init"
    case operation = "com.edugo.tier3.mymodule.operation"
    case error = "com.edugo.tier3.mymodule.error"
    case performance = "com.edugo.tier3.mymodule.performance"
}
```

**Convención**:
- Formato: `com.edugo.tier<N>.<module>.<subcomponent>`
- Usar tier correcto (0-4)
- Minúsculas, sin camelCase
- Jerarquía clara

### Paso 3: Registrar Categorías

Crea una extensión para registro fácil:

```swift
// Sources/MyModule/Logging/MyModuleLogging.swift
import Logger

public extension LoggerRegistry {
    /// Registra todas las categorías de MyModule.
    @discardableResult
    func registerMyModuleCategories() async -> Int {
        await register(categories: [
            MyModuleCategory.initialization,
            MyModuleCategory.operation,
            MyModuleCategory.error,
            MyModuleCategory.performance
        ])
    }
}
```

### Paso 4: Usar en tus Clases/Actors

```swift
// Sources/MyModule/MyManager.swift
import Logger

public actor MyManager {
    // Obtener logger del registry
    private let logger: OSLoggerAdapter
    
    public init() async {
        self.logger = await LoggerRegistry.shared.logger(
            for: MyModuleCategory.initialization
        )
        await logger.info("MyManager initialized")
    }
    
    public func performOperation() async throws {
        await logger.debug("Starting operation", category: MyModuleCategory.operation)
        
        do {
            // ... tu lógica
            await logger.info("Operation completed successfully")
        } catch {
            await logger.error("Operation failed: \(error)", category: MyModuleCategory.error)
            throw error
        }
    }
}
```

### Paso 5: Inicializar en App

```swift
// En tu app principal
@main
struct EduGoApp: App {
    init() {
        Task {
            await setupLogging()
        }
    }
    
    private func setupLogging() async {
        // Configurar sistema
        await LoggerConfigurator.shared.configureFromEnvironment()
        
        // Registrar categorías estándar
        await LoggerRegistry.shared.registerAllStandardCategories()
        
        // Registrar categorías de tu módulo
        await LoggerRegistry.shared.registerMyModuleCategories()
    }
}
```

---

## 2. Patrones de Integración por Tier

### TIER-0: Foundation

**No necesita logging activo** (solo definir errores).

```swift
// TIER-0 solo define estructuras
public enum DomainError: Error {
    case invalidOperation
}

// El logging lo hacen los tiers superiores que usan estas estructuras
```

### TIER-1: Core

**Logging interno del sistema**.

```swift
public actor CoreManager {
    private let logger: OSLoggerAdapter
    
    init() async {
        self.logger = await LoggerRegistry.shared.logger(
            for: StandardLogCategory.Logger.system
        )
    }
    
    func internalOperation() async {
        await logger.debug("Internal operation", 
            category: StandardLogCategory.Logger.performance)
    }
}
```

### TIER-2: Infrastructure

**Logging de operaciones I/O**.

```swift
public actor NetworkManager {
    private let logger: OSLoggerAdapter
    
    init() async {
        self.logger = await LoggerRegistry.shared.logger(
            for: NetworkCategory.system
        )
    }
    
    func makeRequest() async throws {
        await logger.info("Request started", category: NetworkCategory.request)
        
        // Medir performance
        let start = Date()
        defer {
            let duration = Date().timeIntervalSince(start)
            Task {
                await logger.debug("Request took \(duration)s",
                    category: NetworkCategory.performance)
            }
        }
        
        // ... request logic
    }
}
```

### TIER-3: Domain

**Logging de lógica de negocio**.

```swift
public actor AuthManager {
    private let logger: OSLoggerAdapter
    
    init() async {
        self.logger = await LoggerRegistry.shared.logger(
            for: AuthCategory.system
        )
    }
    
    func login(email: String, password: String) async throws -> User {
        await logger.info("Login attempt", category: AuthCategory.login)
        
        do {
            let user = try await authenticate(email: email, password: password)
            await logger.info("Login successful for user: \(user.id)")
            return user
        } catch {
            await logger.error("Login failed: \(error.localizedDescription)")
            throw error
        }
    }
}
```

### TIER-4: Features

**Logging de interacciones de usuario**.

```swift
public actor AnalyticsManager {
    private let logger: OSLoggerAdapter
    
    init() async {
        self.logger = await LoggerRegistry.shared.logger(
            for: AnalyticsCategory.events
        )
    }
    
    func trackEvent(_ event: String) async {
        await logger.info("Event tracked: \(event)", 
            category: AnalyticsCategory.tracking)
    }
}
```

---

## 3. Inyección de Dependencias

### Patrón 1: Dependency Injection (Recomendado)

```swift
public actor MyManager {
    private let logger: OSLoggerAdapter
    
    // Logger inyectado en el inicializador
    public init(logger: OSLoggerAdapter) {
        self.logger = logger
    }
}

// Uso
let logger = await LoggerRegistry.shared.logger(for: MyCategory.system)
let manager = MyManager(logger: logger)
```

**Ventajas**:
- Testeable (puedes inyectar MockLogger)
- Explícito
- Flexible

### Patrón 2: Factory Method

```swift
public actor MyManager {
    private let logger: OSLoggerAdapter
    
    private init(logger: OSLoggerAdapter) {
        self.logger = logger
    }
    
    public static func create() async -> MyManager {
        let logger = await LoggerRegistry.shared.logger(
            for: MyCategory.system
        )
        return MyManager(logger: logger)
    }
}

// Uso
let manager = await MyManager.create()
```

### Patrón 3: Lazy Initialization

```swift
public actor MyManager {
    private var _logger: OSLoggerAdapter?
    
    private var logger: OSLoggerAdapter {
        get async {
            if let logger = _logger {
                return logger
            }
            let logger = await LoggerRegistry.shared.logger(
                for: MyCategory.system
            )
            _logger = logger
            return logger
        }
    }
    
    func operation() async {
        await (await logger).info("Operation")
    }
}
```

---

## 4. Testing con MockLogger

### Setup en Tests

```swift
import Testing
@testable import MyModule
@testable import Logger

@Suite("MyManager Tests")
struct MyManagerTests {
    
    @Test("Manager logs initialization")
    func testInitLogging() async {
        // Crear mock
        let mockLogger = MockLogger()
        
        // Inyectar en tu clase
        let manager = MyManager(logger: mockLogger)
        
        // Verificar logs
        let count = await mockLogger.count
        #expect(count > 0)
        
        let hasInitLog = await mockLogger.containsMessage(
            level: .info,
            containing: "initialized"
        )
        #expect(hasInitLog)
    }
    
    @Test("Manager logs errors correctly")
    func testErrorLogging() async {
        let mockLogger = MockLogger()
        let manager = MyManager(logger: mockLogger)
        
        // Forzar error
        do {
            try await manager.operationThatFails()
        } catch {
            // Expected
        }
        
        // Verificar que se logueó el error
        let errorEntries = await mockLogger.entries(level: .error)
        #expect(errorEntries.count == 1)
        #expect(errorEntries[0].message.contains("failed"))
    }
}
```

---

## 5. Configuración por Módulo

### Debug Granular

```swift
// En desarrollo, solo debug tu módulo
@main
struct EduGoApp: App {
    init() {
        Task {
            await LoggerConfigurator.shared.configureProduction()
            
            // Override solo para tu módulo
            await LoggerConfigurator.shared.setLevel(.debug,
                for: MyModuleCategory.operation)
        }
    }
}
```

### Configuración Dinámica

```swift
// Cambiar nivel en runtime (útil para debugging)
public actor MyManager {
    func enableDebugMode() async {
        await LoggerConfigurator.shared.setLevel(.debug,
            for: MyModuleCategory.operation)
    }
    
    func disableDebugMode() async {
        await LoggerConfigurator.shared.resetCategory(
            MyModuleCategory.operation)
    }
}
```

---

## 6. Migration Checklist

Usa este checklist al integrar logging en un módulo existente:

- [ ] Agregar dependencia de Logger en Package.swift
- [ ] Crear archivo de categorías (MyModuleCategory.swift)
- [ ] Definir 3-5 categorías principales
- [ ] Crear extensión de LoggerRegistry para registro
- [ ] Actualizar inicializadores para aceptar logger
- [ ] Agregar logging en operaciones críticas
- [ ] Agregar logging en error paths
- [ ] Crear MockLogger tests
- [ ] Registrar categorías en app initialization
- [ ] Documentar categorías en README del módulo
- [ ] Verificar que compila sin warnings
- [ ] Verificar que tests pasan

---

## 7. Ejemplos Completos

### Módulo Simple (CRUD)

```swift
// UserService.swift
import Logger

public actor UserService {
    private let logger: OSLoggerAdapter
    
    public init(logger: OSLoggerAdapter) {
        self.logger = logger
    }
    
    public func createUser(_ user: User) async throws {
        await logger.info("Creating user", category: UserCategory.create)
        
        // Validación
        guard user.email.contains("@") else {
            await logger.warning("Invalid email format")
            throw UserError.invalidEmail
        }
        
        // Crear
        do {
            try await repository.save(user)
            await logger.info("User created successfully: \(user.id)")
        } catch {
            await logger.error("Failed to create user: \(error)")
            throw error
        }
    }
}
```

### Módulo con Performance Tracking

```swift
// DataSyncManager.swift
import Logger

public actor DataSyncManager {
    private let logger: OSLoggerAdapter
    
    func syncData() async throws {
        await logger.info("Sync started", category: SyncCategory.operation)
        
        let startTime = Date()
        var itemCount = 0
        
        defer {
            let duration = Date().timeIntervalSince(startTime)
            Task {
                await logger.info(
                    "Sync completed: \(itemCount) items in \(duration)s",
                    category: SyncCategory.performance
                )
            }
        }
        
        // Sync logic
        itemCount = try await performSync()
    }
}
```

---

## 8. Recursos Adicionales

- **QuickStart.md**: Guía de inicio rápido
- **CategoryGuide.md**: Guía completa de categorías
- **Architecture.md**: Documentación de arquitectura
- **BestPractices.md**: Mejores prácticas de logging
- **Troubleshooting.md**: Solución de problemas comunes

---

**Última actualización**: 27 de enero de 2026
