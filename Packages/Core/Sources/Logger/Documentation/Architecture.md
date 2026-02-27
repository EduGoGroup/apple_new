# Arquitectura del Sistema de Logging - EduGo

**Fecha**: 27 de enero de 2026  
**Versión**: 1.0  
**Swift**: 6.2 (Strict Concurrency)

---

## 1. Visión General

El sistema de logging de EduGo está diseñado como una capa de abstracción sobre `os.Logger` de Apple, proporcionando una API consistente, type-safe y concurrency-aware para todos los módulos de la aplicación.

### Objetivos de Diseño

1. **Abstracción**: Protocolo `LoggerProtocol` permite cambiar implementaciones sin afectar código cliente
2. **Type Safety**: Uso de enums y protocolos para categorías y niveles
3. **Concurrency**: Total compatibilidad con Swift 6.2 Strict Concurrency
4. **Performance**: Cero overhead cuando logging está deshabilitado
5. **Configurabilidad**: Soporte para configuración por entorno y categoría
6. **Observabilidad**: Integración con herramientas del sistema (Console.app, Instruments)

---

## 2. Componentes Principales

### 2.1 LoggerProtocol

**Ubicación**: `Sources/Logger/Protocols/LoggerProtocol.swift`

Protocolo base que define la interfaz de logging. Todos los adaptadores (OSLoggerAdapter, etc.) implementan este protocolo.

```swift
public protocol LoggerProtocol: Sendable {
    func debug(_ message: String, category: LogCategory?, file: String, function: String, line: Int) async
    func info(_ message: String, category: LogCategory?, file: String, function: Int) async
    func warning(_ message: String, category: LogCategory?, file: String, function: String, line: Int) async
    func error(_ message: String, category: LogCategory?, file: String, function: String, line: Int) async
}
```

**Decisiones de Diseño**:

- **Async**: Todos los métodos son `async` para permitir implementaciones que requieren I/O (logging remoto, archivos, etc.)
- **Sendable**: Garantiza thread-safety en Swift 6
- **Metadata**: Parámetros `file`, `function`, `line` capturados automáticamente con `#file`, `#function`, `#line`
- **Extension con defaults**: Parámetros opcionales para simplicidad de uso

### 2.2 LogLevel

**Ubicación**: `Sources/Logger/Models/LogLevel.swift`

Enum que representa los niveles de severidad, con soporte para comparación.

```swift
public enum LogLevel: String, Sendable, Comparable, CaseIterable {
    case debug    // Severidad: 0
    case info     // Severidad: 1
    case warning  // Severidad: 2
    case error    // Severidad: 3
}
```

**Decisiones de Diseño**:

- **Comparable**: Permite expresiones como `level >= .warning`
- **CaseIterable**: Útil para UI de configuración
- **String RawValue**: Serialización sencilla para configuración persistente
- **Propiedades adicionales**: `displayName`, `emoji` para debugging

**Mapeo a os.Logger**:

| LogLevel  | os.Logger  |
|-----------|------------|
| `.debug`  | `.debug`   |
| `.info`   | `.info`    |
| `.warning`| `.notice`* |
| `.error`  | `.error`   |

\* `os.Logger` no tiene `.warning`, usamos `.notice` que es el nivel más cercano.

### 2.3 LogCategory

**Ubicación**: `Sources/Logger/Models/LogCategory.swift`

Protocolo para categorización de logs por módulo/funcionalidad.

```swift
public protocol LogCategory: Sendable {
    var identifier: String { get }
    var displayName: String { get }
}
```

**Convenciones**:

- Usar reverse-domain notation: `com.edugo.<module>.<submodule>`
- Implementar como enums con RawValue String
- La extension proporciona implementación por defecto de `displayName`

**Categorías Predefinidas** (TIER-0/TIER-1):

```swift
public enum SystemLogCategory: String, LogCategory {
    case commonError = "com.edugo.common.error"
    case logger = "com.edugo.logger.system"
    case network = "com.edugo.network"
    // ...
}
```

### 2.4 LogConfiguration

**Ubicación**: `Sources/Logger/Models/LogConfiguration.swift`

Struct inmutable que define la configuración global del logging.

```swift
public struct LogConfiguration: Sendable {
    let globalLevel: LogLevel
    let isEnabled: Bool
    let environment: Environment
    let subsystem: String
    let categoryOverrides: [String: LogLevel]
    let includeMetadata: Bool
}
```

**Funcionalidad**:

- **Nivel global**: Filtro mínimo para todos los logs
- **Overrides por categoría**: Permite debug granular (`auth` en `.debug`, resto en `.info`)
- **Detección de entorno**: Automática vía `#if DEBUG` y variable `EDUGO_ENVIRONMENT`
- **Presets**: `.development`, `.staging`, `.production`, `.testing`

**Resolución de Nivel**:

```
Para un log con (level, category):
  1. Si !isEnabled → no registrar
  2. Si existe override para category → usar ese nivel
  3. Si no → usar globalLevel
  4. Registrar si level >= nivel_efectivo
```

---

## 3. Flujo de Logging

### 3.1 Proceso de Registro de un Log

```
1. Cliente llama: await logger.info("mensaje", category: .auth)
   
2. LoggerProtocol (default implementation)
   ↓ Captura metadata (#file, #function, #line)
   
3. Implementación concreta (ej: OSLoggerAdapter)
   ↓ Consulta LogConfiguration
   ↓ shouldLog(level: .info, category: .auth)?
   
4. Si NO → return (early exit, cero overhead)
   Si SÍ → continuar
   
5. Obtener os.Logger para la categoría
   ↓ LoggerRegistry.logger(for: category)
   
6. Formatear mensaje (incluir metadata si config.includeMetadata)
   
7. Llamar os.Logger.info("\(formatted_message)")
   
8. OS registra en unified logging system
```

### 3.2 Performance

**Optimizaciones**:

1. **Early exit**: Si logging deshabilitado o nivel insuficiente, return inmediato
2. **Lazy evaluation**: String interpolation solo si se va a registrar
3. **Logger caching**: `LoggerRegistry` mantiene cache de `os.Logger` por categoría
4. **Sendable**: No hay contención de locks gracias a tipos Sendable

**Overhead Estimado**:

- Logging deshabilitado: **~1-2 ns** (comparación booleana)
- Logging habilitado: **~100-500 ns** (dependiendo de metadata y categoría)

---

## 4. Integración con os.Logger

### 4.1 Ventajas de os.Logger

- **Performance**: Extremadamente rápido, diseñado por Apple para logging intensivo
- **Herramientas**: Integración nativa con Console.app, Instruments, Xcode
- **Persistencia**: Logs almacenados en unified logging system del OS
- **Privacy**: Soporte automático para redacción de datos sensibles

### 4.2 Arquitectura de Adaptador

```
                    ┌─────────────────────┐
                    │  LoggerProtocol     │
                    │   (abstracción)     │
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
    ┌─────────▼──────┐  ┌──────▼──────┐  ┌────▼─────────┐
    │ OSLoggerAdapter│  │FileLogger   │  │RemoteLogger  │
    │  (os.Logger)   │  │  (Future)   │  │  (Future)    │
    └────────────────┘  └─────────────┘  └──────────────┘
```

**OSLoggerAdapter** (próxima tarea):

- Implementa `LoggerProtocol`
- Mantiene `LogConfiguration`
- Usa `LoggerRegistry` para gestionar instancias de `os.Logger`
- Mapea `LogLevel` → niveles de `os.Logger`

---

## 5. Configuración por Entorno

### 5.1 Detección Automática

```swift
#if DEBUG
    environment = .development
#else
    // Leer EDUGO_ENVIRONMENT
    environment = ProcessInfo.processInfo.environment["EDUGO_ENVIRONMENT"]
        .flatMap(Environment.init) ?? .production
#endif
```

### 5.2 Configuraciones Recomendadas

| Entorno     | Global Level | Metadata | Use Case                           |
|-------------|--------------|----------|------------------------------------|
| Development | `.debug`     | ✅ Sí    | Debugging local, tracing completo  |
| Staging     | `.info`      | ✅ Sí    | Testing en servidor, diagnostics   |
| Production  | `.warning`   | ❌ No    | Solo problemas, performance óptimo |
| Testing     | `.error`     | ❌ No    | Tests unitarios, silenciar output  |

### 5.3 Overrides Dinámicos

```swift
// En development, debug granular para Auth
let config = LogConfiguration.development
    .withOverride(level: .debug, for: "com.edugo.auth.login")
    .withOverride(level: .error, for: "com.edugo.network")

// Resultado:
// - Auth.login → .debug
// - Network → .error
// - Resto → .debug (global)
```

---

## 6. Uso en Módulos

### 6.1 Definir Categorías por Módulo

```swift
// TIER-3-Domain/Auth/Sources/Auth/Logging/AuthCategory.swift
public enum AuthCategory: String, LogCategory {
    case login = "com.edugo.auth.login"
    case logout = "com.edugo.auth.logout"
    case token = "com.edugo.auth.token"
    case session = "com.edugo.auth.session"
}
```

### 6.2 Inyectar Logger

```swift
// AuthManager.swift
public actor AuthManager {
    private let logger: LoggerProtocol
    
    public init(logger: LoggerProtocol) {
        self.logger = logger
    }
    
    public func login(email: String, password: String) async throws {
        await logger.info("Login attempt", category: AuthCategory.login)
        
        // ... lógica de login
        
        await logger.info("Login successful", category: AuthCategory.login)
    }
}
```

### 6.3 Configuración en Main

```swift
// App entry point
@main
struct EduGoApp: App {
    init() {
        // Configurar logging
        let config = LogConfiguration.production
            .withOverride(level: .debug, for: "com.edugo.auth")
        
        let logger = OSLoggerAdapter(configuration: config)
        LoggerRegistry.shared.configure(with: config)
        
        // Inyectar en managers
        self.authManager = AuthManager(logger: logger)
    }
}
```

---

## 7. Extensibilidad Futura

### 7.1 Adaptadores Adicionales

**FileLoggerAdapter**:
- Para logging persistente local
- Rotación de archivos
- Exportación de logs

**RemoteLoggerAdapter**:
- Envío a servidor centralizado
- Analytics y crash reporting
- Aggregation cross-device

**CompositeLogger**:
- Combina múltiples adaptadores
- Routing condicional (ej: errores → remote, debug → OS)

### 7.2 Filtros y Transformers

```swift
public protocol LogFilter: Sendable {
    func shouldLog(_ message: String, level: LogLevel, category: LogCategory?) -> Bool
}

public protocol LogTransformer: Sendable {
    func transform(_ message: String, level: LogLevel, category: LogCategory?) -> String
}
```

### 7.3 Observabilidad Avanzada

- **Metrics**: Conteo de logs por nivel/categoría
- **Sampling**: Registrar solo N% de logs debug en production
- **Alerting**: Notificaciones cuando rate de errores excede threshold

---

## 8. Testing

### 8.1 MockLogger

```swift
public final class MockLogger: LoggerProtocol, @unchecked Sendable {
    private let logs = Mutex<[LogEntry]>([])
    
    public func debug(_ message: String, category: LogCategory?, ...) async {
        logs.withLock { $0.append(LogEntry(level: .debug, message: message)) }
    }
    
    // Aserciones
    public func assertLogged(level: LogLevel, containing: String) {
        let found = logs.withLock { $0.contains { $0.level == level && $0.message.contains(containing) } }
        XCTAssertTrue(found, "Expected log not found")
    }
}
```

### 8.2 Verificación de Logs en Tests

```swift
func testLoginLogsCorrectly() async throws {
    let mockLogger = MockLogger()
    let auth = AuthManager(logger: mockLogger)
    
    try await auth.login(email: "test@edugo.com", password: "pass")
    
    mockLogger.assertLogged(level: .info, containing: "Login attempt")
    mockLogger.assertLogged(level: .info, containing: "Login successful")
}
```

---

## 9. Consideraciones de Seguridad

### 9.1 Datos Sensibles

**NO registrar**:
- Contraseñas, tokens de autenticación
- Datos personales identificables (PII)
- Información financiera

**Estrategias**:

```swift
// ❌ MAL
await logger.info("Token: \(authToken)")

// ✅ BIEN
await logger.info("Token received: \(authToken.prefix(4))...")

// ✅ MEJOR (con privacy de os.Logger)
await logger.info("Token received", category: .auth)
```

### 9.2 os.Logger Privacy

```swift
// os.Logger redacta automáticamente en Console.app (no en código)
osLogger.info("User email: \(email, privacy: .private)")
osLogger.info("User ID: \(userId, privacy: .public)")
```

**Plan**: Próximas tareas añadirán soporte para privacy annotations en `LoggerProtocol`.

---

## 10. Dependencias

### 10.1 Módulos del Proyecto

- **TIER-0/EduGoCommon**: Ninguna (Logger es TIER-1)
- **Foundation**: Import requerido para tipos base
- **os**: Para `os.Logger` en `OSLoggerAdapter`

### 10.2 Package.swift

```swift
.target(
    name: "Logger",
    dependencies: [],
    swiftSettings: [
        .enableExperimentalFeature("StrictConcurrency")
    ]
)
```

**No hay dependencias de otros módulos EduGo**, Logger es completamente autocontenido.

---

## 11. Roadmap

### Fase 1: Foundation ✅ (Esta tarea)
- [x] `LoggerProtocol`
- [x] `LogLevel`
- [x] `LogCategory`
- [x] `LogConfiguration`
- [x] Documentación de arquitectura

### Fase 2: Implementación (Próximas tareas)
- [ ] `OSLoggerAdapter` con os.Logger
- [ ] `LoggerRegistry` para gestión de categorías
- [ ] Configuración dinámica y environment-aware
- [ ] Categorías predefinidas para TIER 0-1

### Fase 3: Testing & Docs
- [ ] Suite completa de tests unitarios
- [ ] Tests de integración con os.Logger
- [ ] Documentación de API pública
- [ ] Guía de integración para módulos

### Fase 4: Advanced Features (Futuro)
- [ ] Privacy annotations support
- [ ] Filtros y transformers
- [ ] Metrics y observability
- [ ] Adaptadores adicionales (File, Remote)

---

## 12. Referencias

- **Swift Concurrency**: [Swift.org - Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- **os.Logger**: [Apple Docs - Logging](https://developer.apple.com/documentation/os/logging)
- **Unified Logging**: [WWDC 2016 - Session 721](https://developer.apple.com/videos/play/wwdc2016/721/)
- **Swift 6 Migration**: [Swift Evolution - SE-0337](https://github.com/apple/swift-evolution/blob/main/proposals/0337-support-incremental-migration-to-concurrency-checking.md)

---

**Autor**: EduGo Team  
**Última actualización**: 27 de enero de 2026
