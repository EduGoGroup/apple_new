# Category Guide

Guia completa para crear y usar categorias de logging.

## Overview

Las categorias permiten organizar y filtrar logs por modulo o funcionalidad.

## Convencion de Naming

### Formato

```
com.edugo.tier<N>.<module>.<subcomponent>
```

### Ejemplos

- `com.edugo.tier0.common.error`
- `com.edugo.tier1.logger.registry`
- `com.edugo.tier2.auth.login`
- `com.edugo.tier3.courses.enrollment`

## Crear Categorias

### Opcion 1: Enum (Recomendado)

```swift
import Logger

public enum AuthCategory: String, LogCategory {
    case login = "com.edugo.tier2.auth.login"
    case logout = "com.edugo.tier2.auth.logout"
    case token = "com.edugo.tier2.auth.token"
}
```

### Opcion 2: CategoryBuilder

```swift
let categoryId = StandardLogCategory.tier2("auth")
    .component("login")
    .build()
// Resultado: "com.edugo.tier2.auth.login"
```

### Opcion 3: DynamicLogCategory

```swift
let dynamic = DynamicLogCategory(
    identifier: "com.edugo.tier2.auth.login",
    displayName: "Auth Login"
)
```

## Categorias Predefinidas

### TIER-0 (Foundation)

```swift
StandardLogCategory.TIER0.entity
StandardLogCategory.TIER0.repository
StandardLogCategory.TIER0.useCase
StandardLogCategory.TIER0.error
```

### TIER-1 (Core)

```swift
StandardLogCategory.Logger.system
StandardLogCategory.Logger.registry
StandardLogCategory.Logger.configuration
```

### Sistema

```swift
SystemLogCategory.system
SystemLogCategory.network
SystemLogCategory.database
SystemLogCategory.performance
```

## Registrar Categorias

### Individual

```swift
await LoggerRegistry.shared.register(category: AuthCategory.login)
```

### Multiples

```swift
await LoggerRegistry.shared.register(categories: [
    AuthCategory.login,
    AuthCategory.logout,
    AuthCategory.token
])
```

### Todas las Standard

```swift
await LoggerRegistry.shared.registerAllStandardCategories()
```

## Filtrado

### Por Tier

```swift
let tier1Categories = categories.filterByTier(1)
```

### Por Modulo

```swift
let authCategories = categories.filterByModule("auth")
```

### Detectar Tier

```swift
let category = AuthCategory.login
print(category.tier)       // 2
print(category.moduleName) // "auth"
```

## Validacion

```swift
let category = AuthCategory.login
print(category.isValidIdentifier)  // true

if !category.validationErrors.isEmpty {
    print("Errors: \(category.validationErrors)")
}
```

## Ejemplo Completo

```swift
import Logger

// 1. Definir categorias del modulo
public enum NetworkCategory: String, LogCategory {
    case request = "com.edugo.tier2.network.request"
    case response = "com.edugo.tier2.network.response"
    case error = "com.edugo.tier2.network.error"
    
    public static var all: [NetworkCategory] {
        [.request, .response, .error]
    }
}

// 2. Extension para registro facil
public extension LoggerRegistry {
    func registerNetworkCategories() async -> Int {
        await register(categories: NetworkCategory.all)
    }
}

// 3. Uso en el modulo
public actor NetworkManager {
    private let logger: OSLoggerAdapter
    
    public init() async {
        await LoggerRegistry.shared.registerNetworkCategories()
        self.logger = await LoggerRegistry.shared.logger(for: NetworkCategory.request)
    }
    
    public func fetch(url: URL) async throws -> Data {
        await logger.info("Fetching: \(url.absoluteString)", category: NetworkCategory.request)
        
        let data = try await URLSession.shared.data(from: url).0
        
        await logger.info("Response: \(data.count) bytes", category: NetworkCategory.response)
        
        return data
    }
}
```
