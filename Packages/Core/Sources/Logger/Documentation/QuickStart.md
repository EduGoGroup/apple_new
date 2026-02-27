# Logger - Guía de Inicio Rápido

**Fecha**: 27 de enero de 2026  
**Versión**: 1.0  
**Módulo**: TIER-1-Core/Logger

---

## 1. Configuración Inicial

### Opción A: Configuración Automática (Recomendada)

```swift
import Logger

// En tu AppDelegate o @main
@main
struct EduGoApp: App {
    init() {
        Task {
            // Configura automáticamente desde environment variables
            await LoggerConfigurator.shared.configureFromEnvironment()
            
            // O usa un preset si no hay variables de entorno
            await LoggerConfigurator.shared.configureDevelopment()
        }
    }
}
```

### Opción B: Configuración Manual

```swift
// Development
await LoggerConfigurator.shared.configureDevelopment()

// Production
await LoggerConfigurator.shared.configureProduction()

// Staging
await LoggerConfigurator.shared.configureStaging()

// Testing (logging deshabilitado)
await LoggerConfigurator.shared.configureTesting()
```

---

## 2. Uso Básico

### Crear un Logger

```swift
import Logger

actor AuthManager {
    // Opción 1: Usar factory
    private let logger = OSLoggerFactory.development()
    
    // Opción 2: Obtener del registry
    private let logger: OSLoggerAdapter
    
    init() {
        self.logger = await LoggerRegistry.shared.logger(
            for: SystemLogCategory.system
        )
    }
}
```

### Registrar Mensajes

```swift
// Niveles disponibles
await logger.debug("Información detallada para debugging")
await logger.info("Evento informativo normal")
await logger.warning("Situación anómala pero no crítica")
await logger.error("Error que afecta funcionalidad")

// Con categoría
await logger.info("Usuario autenticado", category: SystemLogCategory.system)

// Metadata se captura automáticamente (#file, #function, #line)
```

---

## 3. Categorías

### Usar Categorías Predefinidas

```swift
// Categorías del sistema (TIER-0 y TIER-1)
SystemLogCategory.commonError
SystemLogCategory.logger
SystemLogCategory.network
SystemLogCategory.database
SystemLogCategory.system

// Ejemplo
await logger.error("Error de conexión", category: SystemLogCategory.network)
```

### Crear Categorías Personalizadas

```swift
// Para tu módulo
enum AuthCategory: String, LogCategory {
    case login = "com.edugo.auth.login"
    case logout = "com.edugo.auth.logout"
    case token = "com.edugo.auth.token"
}

// Registrar (opcional pero recomendado)
await LoggerRegistry.shared.register(category: AuthCategory.login)

// Usar
await logger.info("Login exitoso", category: AuthCategory.login)
```

---

## 4. Variables de Entorno

### Variables Soportadas

| Variable | Valores | Default | Descripción |
|----------|---------|---------|-------------|
| `EDUGO_LOG_LEVEL` | debug, info, warning, error | debug/warning | Nivel mínimo |
| `EDUGO_LOG_ENABLED` | true, false, 1, 0 | true | Habilitar logging |
| `EDUGO_LOG_METADATA` | true, false | true/false | Incluir origen |
| `EDUGO_ENVIRONMENT` | development, staging, production | auto | Environment |
| `EDUGO_LOG_SUBSYSTEM` | string | com.edugo.apple | Subsystem ID |

### Configurar en Xcode

1. **Product → Scheme → Edit Scheme**
2. **Run → Arguments → Environment Variables**
3. Agregar variables:
   ```
   EDUGO_LOG_LEVEL = debug
   EDUGO_LOG_ENABLED = true
   EDUGO_ENVIRONMENT = development
   ```

### Configurar en Terminal

```bash
export EDUGO_LOG_LEVEL=debug
export EDUGO_ENVIRONMENT=development
./MyApp
```

---

## 5. Configuración Dinámica (Runtime)

### Cambiar Nivel Global

```swift
// Durante ejecución de la app
await LoggerConfigurator.shared.setGlobalLevel(.debug)
```

### Configurar Categoría Específica

```swift
// Solo auth en debug, resto según global
await LoggerConfigurator.shared.setLevel(.debug, for: AuthCategory.login)

// Resetear a default global
await LoggerConfigurator.shared.resetCategory(AuthCategory.login)
```

### Habilitar/Deshabilitar

```swift
// Deshabilitar completamente
await LoggerConfigurator.shared.setEnabled(false)

// Habilitar
await LoggerConfigurator.shared.setEnabled(true)
```

### Metadata

```swift
// Incluir archivo, función, línea (útil en development)
await LoggerConfigurator.shared.setIncludeMetadata(true)

// Deshabilitar para performance (production)
await LoggerConfigurator.shared.setIncludeMetadata(false)
```

---

## 6. Patrones Comunes

### Pattern 1: Logger por Módulo

```swift
// En cada módulo, definir categorías
enum NetworkCategory: String, LogCategory {
    case request = "com.edugo.network.request"
    case response = "com.edugo.network.response"
    case error = "com.edugo.network.error"
}

// Registrar al inicio
await LoggerRegistry.shared.register(categories: [
    NetworkCategory.request,
    NetworkCategory.response,
    NetworkCategory.error
])

// Usar en el módulo
actor NetworkManager {
    private let logger: OSLoggerAdapter
    
    init() {
        self.logger = await LoggerRegistry.shared.logger(
            for: NetworkCategory.request
        )
    }
    
    func makeRequest() async {
        await logger.info("Starting request")
        // ...
    }
}
```

### Pattern 2: Debug Granular en Production

```swift
// Setup inicial: production logging
await LoggerConfigurator.shared.configureProduction()

// Solo para debuggear un módulo específico
await LoggerConfigurator.shared.setLevel(.debug, for: AuthCategory.login)

// Resto de módulos siguen en .warning (production default)
```

### Pattern 3: Testing

```swift
class MyTests: XCTestCase {
    override func setUp() async throws {
        // Silenciar logs en tests
        await LoggerConfigurator.shared.configureTesting()
    }
    
    func testSomething() async {
        // Los logs no aparecerán en output de tests
    }
}
```

---

## 7. Factory Patterns

### Crear Loggers con Factory

```swift
// Preset simple
let devLogger = OSLoggerFactory.development()
let prodLogger = OSLoggerFactory.production()

// Con overrides
let logger = OSLoggerFactory.development(
    categoryOverrides: [
        "com.edugo.network": .error,
        "com.edugo.auth": .debug
    ]
)

// Builder pattern (configuración compleja)
let logger = OSLoggerFactory.builder()
    .globalLevel(.info)
    .environment(.production)
    .override(level: .debug, for: AuthCategory.login)
    .override(level: .error, for: SystemLogCategory.network)
    .includeMetadata(false)
    .build()
```

---

## 8. Visualización de Logs

### Console.app (macOS)

1. Abrir **Console.app**
2. Filtrar por subsystem: `subsystem:com.edugo.apple`
3. O por categoría: `category:com.edugo.auth.login`

### Xcode Debug Console

Los logs aparecen automáticamente en la consola de Xcode cuando ejecutas la app.

### Instruments

1. **Product → Profile**
2. Seleccionar **os_signpost** o **Logging**
3. Los logs se integran con el unified logging system

---

## 9. Mejores Prácticas

### ✅ DO

- Usar categorías específicas por módulo
- Configurar desde environment variables en development
- Usar `.warning` o superior en production
- Deshabilitar metadata en production para performance
- Registrar categorías al inicio de la app

### ❌ DON'T

- No loggear contraseñas, tokens, o PII
- No usar `print()`, usa el logger
- No crear loggers en cada llamada, reutilizar instancias
- No usar `.debug` en production
- No loggear en hot paths sin verificar nivel primero

---

## 10. Ejemplo Completo

```swift
import SwiftUI
import Logger

@main
struct EduGoApp: App {
    init() {
        setupLogging()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func setupLogging() {
        Task {
            // 1. Configurar desde environment
            let configured = await LoggerConfigurator.shared.configureFromEnvironment()
            
            if !configured {
                // 2. Fallback a preset según build
                #if DEBUG
                await LoggerConfigurator.shared.configureDevelopment()
                #else
                await LoggerConfigurator.shared.configureProduction()
                #endif
            }
            
            // 3. Registrar categorías del sistema
            await LoggerRegistry.shared.registerSystemCategories()
            
            // 4. Configuración específica (opcional)
            #if DEBUG
            await LoggerConfigurator.shared.setLevel(.debug, for: SystemLogCategory.logger)
            #endif
            
            // 5. Log inicial
            let logger = await LoggerRegistry.shared.logger()
            await logger.info("App initialized with logging configured")
        }
    }
}

// En tus módulos
actor AuthManager {
    private let logger: OSLoggerAdapter
    
    init() async {
        self.logger = await LoggerRegistry.shared.logger(
            for: SystemLogCategory.system
        )
        await logger.info("AuthManager initialized")
    }
    
    func login(email: String, password: String) async throws -> User {
        await logger.info("Login attempt for email")
        
        do {
            let user = try await performLogin(email: email, password: password)
            await logger.info("Login successful")
            return user
        } catch {
            await logger.error("Login failed: \(error.localizedDescription)")
            throw error
        }
    }
}
```

---

## 11. Troubleshooting

### No veo logs en Console.app

- Verifica que el subsystem sea correcto: `com.edugo.apple`
- Verifica que logging esté enabled
- Verifica que el nivel del mensaje sea >= nivel configurado

### Logs no aparecen en Xcode

- Verifica que logging esté enabled
- Verifica que el nivel sea correcto
- Recuerda que `.debug` solo se loggea en DEBUG builds por default

### Performance issues

- Deshabilita metadata en production: `setIncludeMetadata(false)`
- Aumenta el nivel mínimo: `setGlobalLevel(.warning)`
- No loggees en hot paths o loops intensivos

---

## 12. Referencia Rápida

```swift
// Setup
await LoggerConfigurator.shared.configureFromEnvironment()
await LoggerRegistry.shared.registerSystemCategories()

// Crear logger
let logger = await LoggerRegistry.shared.logger(for: category)

// Loggear
await logger.debug("message")
await logger.info("message", category: myCategory)
await logger.warning("message")
await logger.error("message")

// Runtime config
await LoggerConfigurator.shared.setGlobalLevel(.debug)
await LoggerConfigurator.shared.setLevel(.debug, for: category)
await LoggerConfigurator.shared.setEnabled(false)

// Variables de entorno
EDUGO_LOG_LEVEL=debug
EDUGO_LOG_ENABLED=true
EDUGO_ENVIRONMENT=development
```

---

**Nota**: Esta guía cubre lo implementado hasta la tarea 5 del sprint de logging. Se expandirá en tareas futuras con más ejemplos y mejores prácticas.
