# Mejores Prácticas de Logging

**Fecha**: 27 de enero de 2026  
**Versión**: 1.0

---

## 1. Qué Loguear

### ✅ SÍ Loguear

**Eventos del Sistema**
```swift
// Inicio/fin de operaciones importantes
await logger.info("Sync started")
await logger.info("Sync completed: 150 items")

// Cambios de estado
await logger.info("User logged in")
await logger.info("App entered background")

// Milestone de procesos largos
await logger.debug("Processing batch 5/10")
```

**Errores y Excepciones**
```swift
// Errores con contexto
do {
    try await operation()
} catch {
    await logger.error("Operation failed: \(error.localizedDescription)")
}

// Warnings de situaciones anómalas
if data.isEmpty {
    await logger.warning("Received empty data from server")
}
```

**Performance Metrics**
```swift
let start = Date()
try await heavyOperation()
let duration = Date().timeIntervalSince(start)

if duration > 1.0 {
    await logger.warning("Operation took \(duration)s (threshold: 1s)")
}
```

### ❌ NO Loguear

**Información Sensible**
```swift
// ❌ MAL
await logger.info("Password: \(password)")
await logger.info("Credit card: \(cardNumber)")
await logger.info("API key: \(apiKey)")

// ✅ BIEN
await logger.info("Authentication attempt")
await logger.info("Payment processed successfully")
await logger.info("API call authenticated")
```

**PII (Personally Identifiable Information)**
```swift
// ❌ MAL
await logger.info("User email: \(email)")
await logger.info("User address: \(address)")

// ✅ BIEN
await logger.info("User registered: \(userId)")
await logger.info("Profile updated")
```

**Datos Excesivos**
```swift
// ❌ MAL
await logger.debug("Full response: \(hugeJsonString)")

// ✅ BIEN
await logger.debug("Response received: \(responseCode) (\(byteCount) bytes)")
```

---

## 2. Niveles de Log Apropiados

### Debug (.debug)

**Cuándo usar**:
- Información detallada para debugging
- Valores de variables importantes
- Flujo de ejecución interno
- Solo en development

```swift
await logger.debug("Fetching user with ID: \(userId)")
await logger.debug("Cache hit for key: \(cacheKey)")
await logger.debug("Validation passed: \(validationResult)")
```

**NO usar en production** (alto volumen, puede afectar performance).

### Info (.info)

**Cuándo usar**:
- Eventos informativos importantes
- Confirmación de operaciones exitosas
- Cambios de estado
- Aceptable en production

```swift
await logger.info("User logged in")
await logger.info("Sync completed successfully")
await logger.info("Configuration loaded")
```

**Regla**: Si un usuario te pregunta "¿qué está haciendo la app?", la respuesta debería estar en los logs info.

### Warning (.warning)

**Cuándo usar**:
- Situaciones anómalas pero recuperables
- Datos inesperados
- Fallbacks automáticos
- Deprecation warnings

```swift
await logger.warning("API returned partial data, using cached")
await logger.warning("Request took 5s (expected < 2s)")
await logger.warning("Using deprecated method")
```

**Regla**: Algo que eventualmente necesita atención pero no impide funcionalidad.

### Error (.error)

**Cuándo usar**:
- Errores que afectan funcionalidad
- Excepciones capturadas
- Fallas de operaciones
- Requiere investigación

```swift
await logger.error("Failed to save user: \(error)")
await logger.error("Network request failed: \(statusCode)")
await logger.error("Database connection lost")
```

**Regla**: Si algo falló y el usuario lo va a notar, es un error.

---

## 3. Mensajes Efectivos

### Estructura Recomendada

**Formato**: `[Acción] [Resultado/Estado] [Contexto relevante]`

```swift
// ✅ BIEN
await logger.info("User login successful")
await logger.error("Database query failed: timeout after 30s")
await logger.warning("Cache miss for user:123, fetching from network")

// ❌ MAL
await logger.info("Done")
await logger.error("Error")
await logger.debug("Here")
```

### Mensajes Específicos

```swift
// ❌ Genérico
await logger.error("Operation failed")

// ✅ Específico
await logger.error("Failed to save user profile: disk full")

// ❌ Sin contexto
await logger.info("Processing")

// ✅ Con contexto
await logger.info("Processing payment for order #1234")
```

### Incluir Valores Relevantes

```swift
// ✅ Con valores
await logger.info("Sync completed: \(itemCount) items in \(duration)s")
await logger.warning("Retry attempt \(attempt)/\(maxRetries)")
await logger.error("Invalid response: expected 200, got \(statusCode)")
```

### Consistencia

```swift
// Establecer un estilo y mantenerlo
await logger.info("User login started")
await logger.info("User login completed")
await logger.info("User logout started")
await logger.info("User logout completed")
```

---

## 4. Categorías Efectivas

### Granularidad Apropiada

**Demasiado genérico**:
```swift
// ❌ Todo en una categoría
enum AppCategory: String, LogCategory {
    case general = "com.edugo.app"
}
```

**Demasiado específico**:
```swift
// ❌ Una categoría por método
enum UserCategory: String, LogCategory {
    case getUserById = "com.edugo.user.get.by.id"
    case getUserByEmail = "com.edugo.user.get.by.email"
    // 50 categorías más...
}
```

**Balance correcto**:
```swift
// ✅ Por feature/operación
enum UserCategory: String, LogCategory {
    case authentication = "com.edugo.tier3.user.auth"
    case profile = "com.edugo.tier3.user.profile"
    case preferences = "com.edugo.tier3.user.preferences"
}
```

### Jerarquía Clara

```swift
// Organización lógica
enum NetworkCategory: String, LogCategory {
    // General
    case system = "com.edugo.tier2.network"
    
    // Por tipo de operación
    case request = "com.edugo.tier2.network.request"
    case response = "com.edugo.tier2.network.response"
    
    // Por aspecto específico
    case error = "com.edugo.tier2.network.error"
    case retry = "com.edugo.tier2.network.retry"
    case performance = "com.edugo.tier2.network.performance"
}
```

---

## 5. Performance

### Logging Condicional

```swift
// ❌ Logging incondicional costoso
await logger.debug("Heavy computation result: \(expensiveOperation())")

// ✅ Evaluar solo si es necesario
if await logger.shouldLog(level: .debug, for: category) {
    let result = expensiveOperation()
    await logger.debug("Result: \(result)")
}
```

### Avoid Logging en Hot Paths

```swift
// ❌ Logging en loop intensivo
for item in millionsOfItems {
    await logger.debug("Processing item: \(item.id)")
    process(item)
}

// ✅ Logging por lotes
let batchSize = 1000
for (index, item) in millionsOfItems.enumerated() {
    if index % batchSize == 0 {
        await logger.debug("Processed \(index) items")
    }
    process(item)
}
```

### String Interpolation Eficiente

```swift
// ❌ Interpolación costosa siempre
await logger.debug("User data: \(user.expensiveDescription)")

// ✅ Lazy evaluation
await logger.debug("User data: \(user.id)") // Solo ID
```

### Metadata Solo en Development

```swift
// En production, deshabilitar metadata
#if DEBUG
await LoggerConfigurator.shared.setIncludeMetadata(true)
#else
await LoggerConfigurator.shared.setIncludeMetadata(false)
#endif
```

---

## 6. Error Handling

### Logging con Contexto

```swift
func fetchUser(id: UUID) async throws -> User {
    await logger.debug("Fetching user: \(id)")
    
    do {
        let user = try await repository.fetch(id: id)
        await logger.info("User fetched successfully: \(id)")
        return user
    } catch let error as DatabaseError {
        await logger.error("Database error fetching user \(id): \(error)")
        throw UserError.databaseFailure(underlying: error)
    } catch {
        await logger.error("Unknown error fetching user \(id): \(error)")
        throw UserError.unknown(error)
    }
}
```

### No Log and Throw

```swift
// ❌ MAL - Logging duplicado
func operation() async throws {
    do {
        try await dangerousOperation()
    } catch {
        await logger.error("Operation failed: \(error)")
        throw error // Se logueará otra vez arriba
    }
}

// ✅ BIEN - Log en un solo lugar
func operation() async throws {
    try await dangerousOperation()
    // El caller es responsable de loguear si necesita
}
```

### Niveles Apropiados por Tipo de Error

```swift
do {
    try await operation()
} catch ValidationError.invalidInput {
    // Usuario error - warning
    await logger.warning("Invalid input provided")
} catch NetworkError.timeout {
    // Recuperable - warning
    await logger.warning("Network timeout, retrying...")
} catch {
    // Fatal - error
    await logger.error("Critical failure: \(error)")
}
```

---

## 7. Testing

### Siempre Usa MockLogger en Tests

```swift
@Test("Operation logs correctly")
func testLogging() async {
    let mock = MockLogger()
    let manager = MyManager(logger: mock)
    
    await manager.operation()
    
    // Verificar logs
    await expectLog(in: mock, level: .info, message: "Operation started")
    await expectLog(in: mock, level: .info, message: "Operation completed")
}
```

### Silenciar Logs en Tests

```swift
@Suite("MyManager Tests")
struct MyManagerTests {
    override func setUp() async throws {
        // Silenciar logs para output limpio
        await LoggerConfigurator.shared.configureTesting()
    }
}
```

---

## 8. Configuration

### Environment-Based

```swift
@main
struct EduGoApp: App {
    init() {
        Task {
            #if DEBUG
            await LoggerConfigurator.shared.configureDevelopment()
            #elseif STAGING
            await LoggerConfigurator.shared.configureStaging()
            #else
            await LoggerConfigurator.shared.configureProduction()
            #endif
        }
    }
}
```

### Feature Flags

```swift
// Debug específico de features
if FeatureFlags.debugAuth {
    await LoggerConfigurator.shared.setLevel(.debug,
        for: AuthCategory.system)
}
```

---

## 9. Security

### Redacción de Datos Sensibles

```swift
// Si DEBES loguear algo sensible
struct SensitiveData {
    let token: String
    
    var redacted: String {
        "\(token.prefix(4))...\(token.suffix(4))"
    }
}

await logger.debug("Token: \(token.redacted)")
```

### Audit Logging

```swift
// Logs de auditoría separados
enum AuditCategory: String, LogCategory {
    case userAction = "com.edugo.audit.user"
    case dataAccess = "com.edugo.audit.data"
}

await logger.info("User \(userId) accessed resource \(resourceId)",
    category: AuditCategory.dataAccess)
```

---

## 10. Code Review Checklist

Usa este checklist al revisar código con logging:

**Contenido**:
- [ ] No contiene contraseñas, tokens o API keys
- [ ] No contiene PII sin redactar
- [ ] Mensajes son claros y específicos
- [ ] Nivel de log es apropiado

**Performance**:
- [ ] No hay logging en hot paths
- [ ] String interpolation no es costosa
- [ ] Logging condicional donde aplique

**Categorías**:
- [ ] Categorías siguen convención de naming
- [ ] Granularidad apropiada
- [ ] Categorías registradas

**Testing**:
- [ ] Tests usan MockLogger
- [ ] Tests verifican logging correcto
- [ ] Tests no dependen de logs para funcionalidad

**Documentación**:
- [ ] Nuevas categorías documentadas
- [ ] Patrones de logging consistentes

---

## 11. Anti-Patterns

### ❌ Logging Como Debugging

```swift
// NO uses logs en lugar de debugger
await logger.debug("Checkpoint 1")
await logger.debug("Checkpoint 2")
await logger.debug("Variable x: \(x)")

// USA breakpoints y debugger
```

### ❌ Logging Excesivo

```swift
// NO loguees todo
await logger.debug("Entering function")
await logger.debug("Initializing variable")
await logger.debug("Calling method A")
await logger.debug("Method A returned")
await logger.debug("Exiting function")

// Loguea solo lo relevante
await logger.debug("Processing started")
await logger.debug("Processing completed: \(result)")
```

### ❌ Logging Como Comments

```swift
// NO uses logs como comentarios
await logger.debug("This is where we validate the user")

// USA comentarios reales
// Validate user permissions
```

### ❌ Logging Sin Categorías

```swift
// NO uses categoría default siempre
await logger.info("Something happened")

// USA categorías específicas
await logger.info("User login successful", category: AuthCategory.login)
```

---

## 12. Métricas y Monitoring

### Logging para Métricas

```swift
// Estructura que facilita parsing
await logger.info("metric:request_duration value:\(duration) endpoint:\(endpoint)")
await logger.info("metric:error_count value:1 type:\(errorType)")
```

### Correlación de Logs

```swift
// Request ID para correlacionar logs relacionados
let requestId = UUID()
await logger.info("Request started: \(requestId)")
// ... operaciones
await logger.info("Request completed: \(requestId)")
```

---

## 13. Resumen de Reglas de Oro

1. **Nunca loguees información sensible**
2. **Usa el nivel correcto** (debug/info/warning/error)
3. **Mensajes claros y específicos**
4. **Categorías apropiadas y consistentes**
5. **Performance matters** - no loguees en hot paths
6. **Testea con MockLogger**
7. **Configura por environment**
8. **Logging no es debugging** - usa debugger
9. **Una sola vez** - no log and throw
10. **Contexto relevante** - incluye valores importantes

---

**Última actualización**: 27 de enero de 2026
