# Guía de Categorías de Logging

**Fecha**: 27 de enero de 2026  
**Versión**: 1.0

---

## 1. Convención de Naming

### Formato Estándar

Todas las categorías siguen el formato:

```
com.edugo.tier<N>.<module>.<subcomponent>
```

**Componentes**:
- `com.edugo` - Prefijo fijo del proyecto
- `tier<N>` - Número de tier (0-4)
- `<module>` - Nombre del módulo en minúsculas
- `<subcomponent>` - Subcomponente opcional (puede ser múltiple)

**Ejemplos**:
```
com.edugo.tier0.common.entity
com.edugo.tier1.logger.registry
com.edugo.tier2.network.request.http
com.edugo.tier3.auth.login
```

### Reglas

1. **Minúsculas**: Todo en minúsculas, sin camelCase
2. **Sin espacios**: Usar punto `.` como separador
3. **Descriptivo**: Usar nombres claros y específicos
4. **Jerárquico**: De general a específico (módulo → subcomponente)

---

## 2. Categorías Predefinidas

### TIER-0: Foundation (EduGoCommon)

```swift
// Entity
StandardLogCategory.TIER0.entity                 // General entity operations
StandardLogCategory.TIER0.entityEquality         // Equality checks
StandardLogCategory.TIER0.entityIdentity         // Identity operations

// Repository
StandardLogCategory.TIER0.repository             // General repository
StandardLogCategory.TIER0.repositoryFetch        // Fetch operations
StandardLogCategory.TIER0.repositoryCreate       // Create operations
StandardLogCategory.TIER0.repositoryUpdate       // Update operations
StandardLogCategory.TIER0.repositoryDelete       // Delete operations

// UseCase
StandardLogCategory.TIER0.useCase                // General use case
StandardLogCategory.TIER0.useCaseExecution       // Execution tracking
StandardLogCategory.TIER0.useCaseValidation      // Validation logic

// Error
StandardLogCategory.TIER0.error                  // General errors
StandardLogCategory.TIER0.domainError            // Domain errors
StandardLogCategory.TIER0.repositoryError        // Repository errors
StandardLogCategory.TIER0.useCaseError           // Use case errors

// System
StandardLogCategory.TIER0.system                 // System operations
StandardLogCategory.TIER0.lifecycle              // Lifecycle events
```

### TIER-1: Core (Logger, Models)

```swift
// Logger Module
StandardLogCategory.Logger.system                // General logger system
StandardLogCategory.Logger.adapter               // OSLoggerAdapter
StandardLogCategory.Logger.factory               // Factory operations
StandardLogCategory.Logger.registry              // Registry operations
StandardLogCategory.Logger.registryCache         // Cache management
StandardLogCategory.Logger.configuration         // Configuration
StandardLogCategory.Logger.configurator          // Configurator
StandardLogCategory.Logger.environment           // Environment config
StandardLogCategory.Logger.category              // Category management
StandardLogCategory.Logger.performance           // Performance tracking

// Models Module
StandardLogCategory.Models.user                  // User models
StandardLogCategory.Models.userProfile           // User profile
StandardLogCategory.Models.userPreferences       // User preferences
StandardLogCategory.Models.model                 // General models
StandardLogCategory.Models.modelValidation       // Validation
StandardLogCategory.Models.modelSerialization    // Serialization
StandardLogCategory.Models.relationships         // Relationships
```

### System Categories (Legacy/General)

```swift
SystemLogCategory.system                         // General system
SystemLogCategory.performance                    // Performance
SystemLogCategory.network                        // Network operations
SystemLogCategory.database                       // Database operations
```

---

## 3. Crear Categorías Personalizadas

### Método 1: Enum con RawValue

```swift
// Para tu módulo
enum AuthCategory: String, LogCategory {
    case login = "com.edugo.tier3.auth.login"
    case logout = "com.edugo.tier3.auth.logout"
    case token = "com.edugo.tier3.auth.token"
    case session = "com.edugo.tier3.auth.session"
    case passwordReset = "com.edugo.tier3.auth.password.reset"
}

// Usar
await logger.info("Login successful", category: AuthCategory.login)
```

### Método 2: CategoryBuilder

```swift
// Construcción dinámica
let requestCategory = CategoryBuilder(tier: 2, module: "network")
    .component("request")
    .component("http")
    .build()

// O usando shortcuts
let requestCategory2 = StandardLogCategory.tier2("network")
    .component("request")
    .component("http")
    .build()

// Resultado: "com.edugo.tier2.network.request.http"
```

### Método 3: DynamicLogCategory

```swift
// Para categorías runtime
let customCategory = DynamicLogCategory(
    identifier: "com.edugo.tier3.custom.feature",
    displayName: "Custom Feature"
)

await logger.debug("Custom log", category: customCategory)
```

---

## 4. Organización por Módulo

### Estructura Recomendada

```
MyModule/
├── Sources/
│   └── MyModule/
│       ├── MyModule.swift
│       └── Logging/
│           ├── MyModuleCategory.swift    // Definir categorías
│           └── MyModuleLogging.swift     // Extensions y helpers
```

### Ejemplo Completo

```swift
// TIER-3-Domain/Auth/Sources/Auth/Logging/AuthCategory.swift

public enum AuthCategory: String, LogCategory {
    // Login flow
    case login = "com.edugo.tier3.auth.login"
    case loginAttempt = "com.edugo.tier3.auth.login.attempt"
    case loginSuccess = "com.edugo.tier3.auth.login.success"
    case loginFailure = "com.edugo.tier3.auth.login.failure"
    
    // Logout flow
    case logout = "com.edugo.tier3.auth.logout"
    
    // Token management
    case token = "com.edugo.tier3.auth.token"
    case tokenRefresh = "com.edugo.tier3.auth.token.refresh"
    case tokenExpiry = "com.edugo.tier3.auth.token.expiry"
    
    // Session
    case session = "com.edugo.tier3.auth.session"
    case sessionCreate = "com.edugo.tier3.auth.session.create"
    case sessionDestroy = "com.edugo.tier3.auth.session.destroy"
}

// Helpers
public extension AuthCategory {
    static var loginCategories: [AuthCategory] {
        [.login, .loginAttempt, .loginSuccess, .loginFailure]
    }
    
    static var tokenCategories: [AuthCategory] {
        [.token, .tokenRefresh, .tokenExpiry]
    }
}

// Registration helper
public extension LoggerRegistry {
    @discardableResult
    func registerAuthCategories() async -> Int {
        await register(categories: [
            AuthCategory.login,
            AuthCategory.logout,
            AuthCategory.token,
            AuthCategory.session
        ])
    }
}
```

---

## 5. Mejores Prácticas

### ✅ DO

```swift
// Específico y descriptivo
StandardLogCategory.TIER0.repositoryFetch

// Jerarquía clara
AuthCategory.loginSuccess

// Agrupación lógica
enum NetworkCategory: String, LogCategory {
    case request = "com.edugo.tier2.network.request"
    case response = "com.edugo.tier2.network.response"
    case error = "com.edugo.tier2.network.error"
}
```

### ❌ DON'T

```swift
// ❌ Demasiado genérico
case general = "com.edugo.general"

// ❌ CamelCase
case userLogin = "com.edugo.tier3.auth.UserLogin"

// ❌ Sin tier
case something = "com.edugo.auth.something"

// ❌ Demasiado profundo
case tooDeep = "com.edugo.tier3.auth.login.user.check.validation.step1"
```

### Niveles de Granularidad

| Nivel | Cuándo Usar | Ejemplo |
|-------|-------------|---------|
| **Módulo** | Logs generales del módulo | `com.edugo.tier3.auth` |
| **Feature** | Funcionalidad específica | `com.edugo.tier3.auth.login` |
| **Operation** | Operación detallada | `com.edugo.tier3.auth.login.attempt` |

**Regla**: No más de 6 componentes en total.

---

## 6. Registrar Categorías

### Al Inicio de la App

```swift
@main
struct EduGoApp: App {
    init() {
        Task {
            await setupLogging()
        }
    }
    
    private func setupLogging() async {
        // Configurar
        await LoggerConfigurator.shared.configureDevelopment()
        
        // Registrar categorías estándar
        await LoggerRegistry.shared.registerAllStandardCategories()
        
        // Registrar categorías custom
        await LoggerRegistry.shared.registerAuthCategories()
        await LoggerRegistry.shared.registerNetworkCategories()
    }
}
```

### Verificar Registro

```swift
// Verificar si una categoría está registrada
let isRegistered = await LoggerRegistry.shared.isRegistered(
    category: AuthCategory.login
)

// Listar todas las categorías registradas
let categories = await LoggerRegistry.shared.allRegisteredCategories
print("Registered categories: \(categories.count)")
```

---

## 7. Filtrado y Búsqueda

### Por Tier

```swift
let categories: [any LogCategory] = [
    StandardLogCategory.TIER0.entity,
    StandardLogCategory.TIER1.logger,
    AuthCategory.login
]

let tier0Categories = categories.filter { $0.isTier0 }
let tier3Categories = categories.filterByTier(3)
```

### Por Módulo

```swift
let loggerCategories = categories.filterByModule("logger")
let authCategories = categories.filterByModule("auth")
```

### Por Subsistema

```swift
let authRelated = categories.filterBySubsystem("auth")
```

---

## 8. Validación

### Validar Identifier

```swift
let category = DynamicLogCategory(
    identifier: "com.edugo.tier3.auth.login"
)

if category.isValidIdentifier {
    print("✓ Valid category")
} else {
    print("✗ Invalid category")
    print("Errors: \(category.validationErrors)")
}
```

### Errores Comunes

```swift
// ❌ Sin prefijo correcto
"edugo.tier3.auth" → Error: Must start with 'com.edugo.'

// ❌ Sin tier
"com.edugo.auth.login" → Error: Must contain valid tier

// ❌ Tier inválido
"com.edugo.tier9.auth" → Error: Tier must be 0-4

// ❌ Muy corto
"com.edugo.tier3" → Error: Must have at least 4 components
```

---

## 9. Migración de Categorías Legacy

Si tienes categorías antiguas sin el formato tier:

```swift
// Legacy (antes)
enum OldCategory: String, LogCategory {
    case user = "com.edugo.user"
    case auth = "com.edugo.auth"
}

// Nuevo (después)
enum NewCategory: String, LogCategory {
    case user = "com.edugo.tier1.models.user"
    case auth = "com.edugo.tier3.auth.system"
}

// Compatibilidad temporal
extension LoggerRegistry {
    func migrateLegacyCategories() async {
        // Mapear categorías legacy a nuevas
        await setLevel(.debug, for: NewCategory.user)
    }
}
```

---

## 10. Ejemplos por Use Case

### Debugging Específico

```swift
// Solo debug de login, resto en warning
await LoggerConfigurator.shared.setGlobalLevel(.warning)
await LoggerConfigurator.shared.setLevel(.debug, for: AuthCategory.login)
```

### Performance Tracking

```swift
let performanceLogger = await LoggerRegistry.shared.logger(
    for: StandardLogCategory.Logger.performance
)

await performanceLogger.info("Operation started")
// ... operación
await performanceLogger.info("Operation completed: 123ms")
```

### Error Tracking

```swift
let errorLogger = await LoggerRegistry.shared.logger(
    for: StandardLogCategory.TIER0.error
)

do {
    try await someOperation()
} catch {
    await errorLogger.error("Operation failed: \(error)")
}
```

---

## 11. Cheat Sheet

```swift
// Crear categoría para tu módulo
enum MyCategory: String, LogCategory {
    case feature = "com.edugo.tier<N>.<module>.<feature>"
}

// Registrar
await LoggerRegistry.shared.register(category: MyCategory.feature)

// Usar
let logger = await LoggerRegistry.shared.logger(for: MyCategory.feature)
await logger.info("Message")

// Configurar nivel específico
await LoggerConfigurator.shared.setLevel(.debug, for: MyCategory.feature)

// Validar
let isValid = MyCategory.feature.isValidIdentifier
```

---

## 12. Referencias

- **QuickStart.md**: Guía de inicio rápido del logger
- **Architecture.md**: Documentación de arquitectura completa
- **LogCategory.swift**: Protocolo base y SystemLogCategory
- **StandardLogCategory.swift**: Categorías predefinidas TIER 0-1
- **LogCategoryExtensions.swift**: Utilidades y extensiones

---

**Actualizado**: 27 de enero de 2026
