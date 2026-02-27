# Troubleshooting Guide

Esta guía te ayudará a diagnosticar y resolver problemas comunes al usar el sistema de logging de EduGo.

---

## 1. Los Logs No Aparecen

### Síntoma
Los logs no se muestran en Console.app o en la consola de Xcode.

### Diagnóstico

**Paso 1: Verificar que el logging está habilitado**
```swift
let configurator = LoggerConfigurator.shared
let isEnabled = await configurator.isEnabled()
print("Logging enabled: \(isEnabled)")
```

**Paso 2: Verificar el nivel global de logging**
```swift
let level = await configurator.globalLevel()
print("Global level: \(level)")
```

**Paso 3: Verificar la configuración actual**
```swift
let logger = await LoggerRegistry.shared.logger()
// En modo DEBUG, imprime la configuración internamente
await logger.info("Test log", category: StandardLogCategory.Logger.system)
```

### Soluciones

**Problema: Logging deshabilitado**
```swift
// Solución: Habilitar logging
await LoggerConfigurator.shared.setEnabled(true)
```

**Problema: Nivel muy restrictivo**
```swift
// Si estás usando .debug pero el nivel global es .error
await LoggerConfigurator.shared.setGlobalLevel(.debug)
```

**Problema: Variables de entorno incorrectas**
```bash
# Verificar variables de entorno
echo $EDUGO_LOG_ENABLED    # Debería ser "true" o "1"
echo $EDUGO_LOG_LEVEL      # Debería ser "debug", "info", "warning", o "error"
```

---

## 2. Configuración de Entorno No Funciona

### Síntoma
Las variables de entorno `EDUGO_LOG_*` no tienen efecto.

### Diagnóstico

**Verificar que la configuración desde entorno fue llamada:**
```swift
let success = await LoggerConfigurator.shared.configureFromEnvironment()
print("Environment configuration loaded: \(success)")
```

### Soluciones

**Problema: No se llamó `configureFromEnvironment()`**
```swift
// Solución: Llamar en el inicio de la app
@main
struct MyApp: App {
    init() {
        Task {
            await LoggerConfigurator.shared.configureFromEnvironment()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**Problema: Variables de entorno no definidas correctamente**

En Xcode:
1. Product → Scheme → Edit Scheme
2. Run → Arguments → Environment Variables
3. Añadir: `EDUGO_LOG_LEVEL = debug`
4. Añadir: `EDUGO_LOG_ENABLED = true`

En terminal (testing):
```bash
export EDUGO_LOG_LEVEL=debug
export EDUGO_LOG_ENABLED=true
swift test
```

**Problema: Formato incorrecto**
```bash
# ❌ INCORRECTO
EDUGO_LOG_ENABLED=TRUE    # Debe ser minúsculas
EDUGO_LOG_LEVEL=Debug     # Debe ser minúsculas

# ✅ CORRECTO
EDUGO_LOG_ENABLED=true
EDUGO_LOG_LEVEL=debug
```

---

## 3. Logs en Console.app

### Cómo Ver Logs en Console.app

**Paso 1: Abrir Console.app**
- Ubicación: `/Applications/Utilities/Console.app`
- O usa Spotlight: `Cmd+Space` → "Console"

**Paso 2: Filtrar por subsystem**
1. En el campo de búsqueda, escribe: `subsystem:com.edugo`
2. O filtra por categoría específica: `category:com.edugo.tier1.logger.system`

**Paso 3: Ajustar nivel de detalle**
- Menú: Action → Include Info Messages
- Menú: Action → Include Debug Messages

### Filtros Útiles

**Ver todos los logs de EduGo:**
```
subsystem:com.edugo
```

**Ver logs de un tier específico:**
```
category:com.edugo.tier0.*
```

**Ver logs de un módulo específico:**
```
category:com.edugo.tier1.logger.*
```

**Ver solo errores:**
```
subsystem:com.edugo level:error
```

**Combinar filtros:**
```
subsystem:com.edugo level:error OR level:warning
```

---

## 4. Performance: Logging Muy Lento

### Síntoma
La aplicación se vuelve lenta al usar logging intensivo.

### Diagnóstico

**Identificar hotspots:**
```swift
// ❌ PROBLEMA: Logging en loop sin condición
for item in items { // 10000 items
    await logger.debug("Processing \(item)", category: category)
}
```

### Soluciones

**Solución 1: Usar conditional logging**
```swift
// ✅ MEJOR: Condicional
#if DEBUG
for item in items {
    await logger.debug("Processing \(item)", category: category)
}
#endif
```

**Solución 2: Reducir frecuencia**
```swift
// ✅ MEJOR: Log cada N items
for (index, item) in items.enumerated() {
    if index % 100 == 0 {
        await logger.debug("Processed \(index) items", category: category)
    }
}
```

**Solución 3: Usar nivel apropiado**
```swift
// ❌ PROBLEMA: debug en producción
await logger.debug("Processing item", category: category)

// ✅ MEJOR: Usa info/warning solo cuando sea necesario
await logger.info("Processing batch complete", category: category)
```

**Solución 4: Desactivar metadata**
```swift
// Desactivar metadata en producción
export EDUGO_LOG_METADATA=false
```

**Solución 5: Deshabilitar logging en hot paths**
```swift
// En código crítico de performance
#if DEBUG
await logger.debug("Hot path executed", category: category)
#endif
```

---

## 5. Problemas de Concurrencia

### Síntoma
Warnings de concurrencia o crashes relacionados con actores.

### Diagnóstico

**Verificar el uso correcto de async/await:**
```swift
// ❌ PROBLEMA: Acceder sin await
let logger = LoggerRegistry.shared.logger() // Error de compilación

// ✅ CORRECTO: Usar await
let logger = await LoggerRegistry.shared.logger()
```

### Soluciones

**Problema: "Expression is 'async' but is not marked with 'await'"**
```swift
// ❌ PROBLEMA
func doSomething() {
    logger.info("Message", category: category)
}

// ✅ SOLUCIÓN 1: Función async
func doSomething() async {
    await logger.info("Message", category: category)
}

// ✅ SOLUCIÓN 2: Task wrapper
func doSomething() {
    Task {
        await logger.info("Message", category: category)
    }
}
```

**Problema: "Actor-isolated property cannot be referenced"**
```swift
// ❌ PROBLEMA
let count = logger.cachedLoggerCount

// ✅ SOLUCIÓN
let count = await logger.cachedLoggerCount
```

**Problema: Deadlock en tests**
```swift
// ❌ PROBLEMA: Tests en paralelo con singleton
@Suite struct MyTests {
    @Test func testLogger() async { }
}

// ✅ SOLUCIÓN: Serializar tests con singleton
@Suite("My Tests", .serialized)
struct MyTests {
    @Test func testLogger() async { }
}
```

---

## 6. Integración con Módulos

### Síntoma
Errores al integrar Logger en un módulo nuevo.

### Diagnóstico

**Verificar dependencias en Package.swift:**
```swift
.target(
    name: "MyModule",
    dependencies: [
        .product(name: "Logger", package: "Logger"),  // ✅ Necesario
    ]
)
```

### Soluciones

**Problema: "No such module 'Logger'"**
```swift
// 1. Verificar Package.swift del módulo
// 2. Agregar dependencia:
.target(
    name: "MyModule",
    dependencies: [
        .product(name: "Logger", package: "Logger"),
    ]
)

// 3. Resolver dependencias:
// File → Packages → Resolve Package Versions
```

**Problema: "Cannot find type 'LoggerProtocol' in scope"**
```swift
// Asegúrate de importar Logger
import Logger  // ✅ Necesario

actor MyRepository: LoggerProtocol {
    // ...
}
```

**Problema: Dependencia circular**
```swift
// ❌ PROBLEMA: Logger depende de MyModule y MyModule depende de Logger
// Esto no debería pasar si Logger está en TIER-1

// ✅ SOLUCIÓN: Verificar la arquitectura de tiers
// Logger (TIER-1) solo puede depender de TIER-0
// Otros módulos pueden depender de Logger
```

---

## 7. Tests Fallando

### Síntoma
Tests del módulo Logger o tests que usan Logger fallan.

### Diagnóstico

**Verificar el uso de MockLogger:**
```swift
// ✅ Usar MockLogger en tests
let mockLogger = MockLogger()

await mockLogger.info("Test message", category: nil)

let hasLog = await mockLogger.contains(
    level: .info,
    message: "Test message",
    category: nil
)
#expect(hasLog)
```

### Soluciones

**Problema: Tests intermitentes con LoggerRegistry**
```swift
// ❌ PROBLEMA: Tests en paralelo
@Suite struct RegistryTests {
    @Test func test1() async { }
}

// ✅ SOLUCIÓN: Serializar
@Suite("Registry Tests", .serialized)
struct RegistryTests {
    @Test func test1() async { }
}
```

**Problema: MockLogger no captura logs**
```swift
// ❌ PROBLEMA: Olvidar await
mockLogger.info("Message", category: nil)  // Sin await

// ✅ SOLUCIÓN: Usar await
await mockLogger.info("Message", category: nil)
```

**Problema: Tests dependen del orden**
```swift
// ❌ PROBLEMA: Estado compartido
static let logger = MockLogger()

// ✅ SOLUCIÓN: Logger por test
@Test func testSomething() async {
    let logger = MockLogger()
    // usar logger
}
```

---

## 8. Categorías No Reconocidas

### Síntoma
Warning o error al usar una categoría custom.

### Diagnóstico

**Verificar formato de categoría:**
```swift
// ✅ Formato correcto
let category = DynamicLogCategory("com.edugo.tier2.mymodule.component")

// ❌ Formato incorrecto
let category = DynamicLogCategory("myCategory")  // Sin namespace
```

### Soluciones

**Problema: Categoría no sigue naming convention**
```swift
// ❌ PROBLEMA
enum MyCategory: String, LogCategory {
    case something = "myapp.feature"  // Naming incorrecto
}

// ✅ SOLUCIÓN
enum MyCategory: String, LogCategory {
    case something = "com.edugo.tier3.mymodule.feature"
}
```

**Problema: Categoría no registrada**
```swift
// Registrar categoría en LoggerRegistry (opcional pero recomendado)
await LoggerRegistry.shared.registerCategory(MyCategory.something)
```

---

## 9. Preguntas Frecuentes (FAQ)

### ¿Por qué mis logs de `.debug` no aparecen en producción?

Por diseño. El preset `.production` tiene nivel mínimo `.info`:
```swift
public static let production = LogConfiguration(
    globalLevel: .info,  // ← .debug está filtrado
    isEnabled: true,
    environment: .production,
    // ...
)
```

**Solución:** Usa `.info` para logs que quieres en producción.

---

### ¿Cómo ver logs de un dispositivo físico?

1. Conecta el dispositivo al Mac
2. Abre Console.app
3. Selecciona tu dispositivo en la barra lateral
4. Filtra por `subsystem:com.edugo`

---

### ¿Puedo cambiar el nivel de logging sin recompilar?

**En simulador/dispositivo durante desarrollo:**
```swift
// Runtime configuration
await LoggerConfigurator.shared.setGlobalLevel(.debug)
```

**En producción:**
No directamente. Considera usar remote config (future feature) o feature flags.

---

### ¿Logger funciona en extensiones (widgets, notificaciones)?

Sí, pero considera:
1. Extensiones tienen límites de memoria más estrictos
2. Usa nivel `.warning` o `.error` por defecto
3. Desactiva metadata para reducir overhead

```swift
// En extensión
let config = LogConfiguration(
    globalLevel: .warning,  // Más restrictivo
    isEnabled: true,
    environment: .production,
    subsystem: "com.edugo.widget",
    categoryOverrides: [:],
    includeMetadata: false  // Reducir overhead
)
```

---

### ¿Cómo debug el propio Logger?

Logger tiene auto-logging en DEBUG:
```swift
// Logger imprime su configuración al inicializar
// Busca logs con categoría: com.edugo.tier1.logger.system
```

O usa MockLogger en tests para inspeccionar comportamiento:
```swift
let mock = MockLogger()
await mock.info("Test", category: nil)
let entries = await mock.entries
print(entries)  // Inspeccionar directamente
```

---

### ¿Los logs afectan el tamaño del binario?

Mínimamente. Los strings de logs se incluyen en el binario, pero:
- `os.Logger` es muy eficiente
- En Release builds, el compilador puede optimizar logs no alcanzables
- Usa `#if DEBUG` para logs de desarrollo

---

### ¿Cómo integrar con crash reporting (Crashlytics, Sentry)?

Crea un custom logger que implemente `LoggerProtocol`:
```swift
public actor CrashlyticsLogger: LoggerProtocol {
    public func error(_ message: String, category: LogCategory?, file: String, function: String, line: Int) async {
        // Log a os.Logger
        await osLogger.error(message, category: category, file: file, function: function, line: line)
        
        // También enviar a Crashlytics
        Crashlytics.crashlytics().log("\(function): \(message)")
    }
    
    // Implementar otros métodos...
}
```

---

## 10. Herramientas de Diagnóstico

### Script de Diagnóstico Rápido

Crea este archivo `diagnose-logger.swift` para debug rápido:

```swift
import Logger

@main
struct DiagnoseLogger {
    static func main() async {
        print("=== Logger Diagnostic Tool ===\n")
        
        // 1. Configuración desde entorno
        let envSuccess = await LoggerConfigurator.shared.configureFromEnvironment()
        print("1. Environment config loaded: \(envSuccess)")
        
        // 2. Estado actual
        let isEnabled = await LoggerConfigurator.shared.isEnabled()
        let level = await LoggerConfigurator.shared.globalLevel()
        print("2. Logging enabled: \(isEnabled)")
        print("   Global level: \(level)")
        
        // 3. Variables de entorno
        print("\n3. Environment variables:")
        print("   EDUGO_LOG_ENABLED: \(ProcessInfo.processInfo.environment["EDUGO_LOG_ENABLED"] ?? "not set")")
        print("   EDUGO_LOG_LEVEL: \(ProcessInfo.processInfo.environment["EDUGO_LOG_LEVEL"] ?? "not set")")
        print("   EDUGO_LOG_METADATA: \(ProcessInfo.processInfo.environment["EDUGO_LOG_METADATA"] ?? "not set")")
        print("   EDUGO_ENVIRONMENT: \(ProcessInfo.processInfo.environment["EDUGO_ENVIRONMENT"] ?? "not set")")
        
        // 4. Test de logging
        print("\n4. Testing logger:")
        let logger = await LoggerRegistry.shared.logger()
        await logger.debug("Test DEBUG message", category: StandardLogCategory.Logger.system)
        await logger.info("Test INFO message", category: StandardLogCategory.Logger.system)
        await logger.warning("Test WARNING message", category: StandardLogCategory.Logger.system)
        await logger.error("Test ERROR message", category: StandardLogCategory.Logger.system)
        
        print("\n5. Check Console.app with filter:")
        print("   subsystem:com.edugo category:com.edugo.tier1.logger.system")
        print("\n=== Diagnostic complete ===")
    }
}
```

Ejecutar:
```bash
cd TIER-1-Core/Logger
swift run diagnose-logger
```

---

## 11. Checklist de Troubleshooting

Usa este checklist cuando encuentres problemas:

- [ ] ¿Importé el módulo `Logger`?
- [ ] ¿Llamé `configureFromEnvironment()` al inicio?
- [ ] ¿Verifiqué que logging está habilitado?
- [ ] ¿El nivel global permite mi log level?
- [ ] ¿Las variables de entorno están en minúsculas?
- [ ] ¿Estoy usando `await` correctamente?
- [ ] ¿La categoría sigue la naming convention?
- [ ] ¿Revisé Console.app con el filtro correcto?
- [ ] ¿Mis tests usan `.serialized` si modifican estado compartido?
- [ ] ¿Estoy usando MockLogger en tests en lugar de OSLoggerAdapter?

---

## 12. Obtener Ayuda

Si después de seguir esta guía sigues teniendo problemas:

1. **Revisa la documentación:**
   - `QuickStart.md` - Guía de inicio rápido
   - `Architecture.md` - Arquitectura del sistema
   - `Integration.md` - Guía de integración
   - `BestPractices.md` - Mejores prácticas
   - `CategoryGuide.md` - Guía de categorías

2. **Habilita debug logging del Logger:**
   ```swift
   // En DEBUG, Logger auto-loggea su configuración
   #if DEBUG
   await LoggerConfigurator.shared.setGlobalLevel(.debug)
   #endif
   ```

3. **Usa MockLogger para inspeccionar:**
   ```swift
   let mock = MockLogger()
   // ... usa el logger
   let entries = await mock.entries
   print(entries)  // Ver qué se está loggeando realmente
   ```

4. **Contacta al equipo de EduGo Platform** con:
   - Descripción del problema
   - Output del script de diagnóstico
   - Versión de Swift/Xcode
   - Logs de Console.app (si aplica)

---

## Resumen

**Top 3 problemas más comunes:**

1. **Logs no aparecen** → Verificar que logging está enabled y nivel global es apropiado
2. **Variables de entorno ignoradas** → Llamar `configureFromEnvironment()` al inicio
3. **Errores de concurrencia** → Usar `await` con todos los métodos de logger

**Comandos útiles:**
```bash
# Ver variables de entorno
env | grep EDUGO_LOG

# Ejecutar con logging debug
EDUGO_LOG_LEVEL=debug swift test

# Ver logs en tiempo real
log stream --predicate 'subsystem == "com.edugo"'
```

**Recuerda:** Logger está diseñado para ser silencioso y eficiente. Si no ves logs, generalmente es porque están siendo filtrados correctamente según el nivel configurado.
