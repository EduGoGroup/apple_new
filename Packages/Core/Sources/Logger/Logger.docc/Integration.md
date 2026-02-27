# Integration

Integra el sistema de logging en tus modulos EduGo.

## Overview

Esta guia explica como integrar el modulo Logger en nuevos modulos del proyecto.

## Agregar Dependencia

En tu `Package.swift`:

```swift
dependencies: [
    .package(path: "../TIER-1-Core/Logger")
]
```

En tu target:

```swift
.target(
    name: "TuModulo",
    dependencies: [
        .product(name: "Logger", package: "Logger")
    ]
)
```

## Definir Categorias

Crea un enum con las categorias de tu modulo:

```swift
import Logger

public enum AuthCategory: String, LogCategory {
    case login = "com.edugo.tier2.auth.login"
    case logout = "com.edugo.tier2.auth.logout"
    case token = "com.edugo.tier2.auth.token"
    
    // Conveniencia para registro
    public static var allCategories: [AuthCategory] {
        [.login, .logout, .token]
    }
}
```

### Convencion de Naming

Formato: `com.edugo.tier<N>.<module>.<subcomponent>`

Ejemplos:
- `com.edugo.tier0.common.error`
- `com.edugo.tier1.logger.registry`
- `com.edugo.tier2.auth.login`

## Usar en tu Modulo

### Patron Recomendado

```swift
import Logger

public actor AuthManager {
    private let logger: OSLoggerAdapter
    
    public init() async {
        // Registrar categorias (solo una vez)
        await LoggerRegistry.shared.register(categories: AuthCategory.allCategories)
        
        // Obtener logger
        self.logger = await LoggerRegistry.shared.logger(for: AuthCategory.login)
    }
    
    public func login(email: String) async throws -> User {
        await logger.info("Attempting login")
        
        do {
            let user = try await performLogin(email: email)
            await logger.info("Login successful")
            return user
        } catch {
            await logger.error("Login failed: \(error.localizedDescription)")
            throw error
        }
    }
}
```

## Testing

Usa ``MockLogger`` para verificar logging en tests:

```swift
import Testing
@testable import Logger
@testable import YourModule

@Suite
struct AuthManagerTests {
    @Test
    func loginLogsSuccess() async {
        let mockLogger = MockLogger()
        let manager = AuthManager(logger: mockLogger)
        
        _ = try? await manager.login(email: "test@example.com")
        
        #expect(await mockLogger.contains(level: .info, messageContaining: "successful"))
    }
}
```

## Siguiente Paso

Consulta <doc:BestPractices> para aprender que y como loggear correctamente.
