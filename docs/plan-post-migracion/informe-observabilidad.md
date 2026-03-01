# Informe Observabilidad — Mejoras Post-Migracion

## 1. Crash Reporting (MetricKit / OSLog)

### Estado actual

- `Packages/Core/Sources/Logger/Logger.swift` (lineas 1-31)
  - `Logger` actor con OSLog basico
  - Metodos: `info()`, `debug()`, `error()`, `warning()`
  - Subsystem: `com.edugo.apple`, category: `default`
  - Solo logging local — no se transmite a ningun backend

- `Packages/Domain/Sources/CQRS/Observability/MetricCollector.swift` (lineas 25-65)
  - `OSLogMetricCollector` actor implementa `MetricCollector` protocol
  - Declara `signpostLog: OSLog` pero NUNCA lo usa
  - `recordLatency()` solo hace `logger.debug()` — no usa `os_signpost`
  - No hay integracion con MetricKit

### Problema/oportunidad

- Crashes en produccion son invisibles (solo logs locales)
- No hay historial de crashes ni stack traces remotos
- `os_signpost` declarado pero no utilizado — no se puede perfilar con Instruments
- MetricKit disponible en iOS 13+ permite crash reports sin dependencias externas

### Solucion propuesta

**`CrashReporter` (actor) con MetricKit**

```swift
import MetricKit

actor CrashReporter: MXMetricManagerSubscriber {
    func didReceive(_ payloads: [MXMetricPayload]) {
        // Procesar metricas de rendimiento
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        // Procesar crash reports, disk writes, hangs
        for payload in payloads {
            // Persistir localmente + enviar a backend cuando haya conectividad
        }
    }
}
```

**Archivos a crear:**
- `Packages/Features/Sources/Observability/CrashReporter.swift`
- `Packages/Features/Sources/Observability/DiagnosticPayloadDTO.swift`

**Archivos a modificar:**
- `Packages/Domain/Sources/CQRS/Observability/MetricCollector.swift` — Implementar os_signpost real
- `Apps/DemoApp/Sources/Services/ServiceContainer.swift` — Registrar CrashReporter

### Plan de trabajo

1. Crear `CrashReporter` actor que implemente `MXMetricManagerSubscriber`
2. Registrar con `MXMetricManager.shared.add(subscriber:)`
3. Persistir payloads localmente (para envio diferido)
4. Implementar envio batch a backend analytics
5. Corregir `OSLogMetricCollector` para usar `os_signpost` real
6. Integrar signposts en puntos criticos: screen load, data fetch, auth refresh
7. Tests unitarios

**Complejidad:** MEDIA

### Tests requeridos

- Subscriber se registra correctamente en MXMetricManager
- Payload se persiste localmente
- Envio batch funciona con network client
- os_signpost se emite correctamente (verificable en Instruments)

### Dependencias

- Backend debe tener endpoint para recibir diagnostic payloads

---

## 2. Metricas de Cache Hit Rate

### Estado actual

- `Packages/DynamicUI/Sources/DynamicUI/Loader/ScreenLoader.swift` (lineas 154-210)
  - Log `[EduGo.Cache.Screen] L1 HIT: {key}` y `REMOTE: {key}` via osLogger.debug
  - NO contabiliza hits ni misses
  - NO expone tasa de aciertos

- `Packages/DynamicUI/Sources/DynamicUI/Loader/DataLoader.swift` (lineas 92-126)
  - Log `[EduGo.Cache.Data] STALE (offline): {key}` via osLogger.debug
  - Misma situacion — solo logs, sin contadores

### Problema/oportunidad

- Imposible medir efectividad del cache
- No se puede optimizar `maxCacheSize` o TTLs basado en datos reales
- No se detectan pantallas lentas (siempre miss) o pantallas que deberian tener TTL mas largo

### Solucion propuesta

**`CacheMetrics` struct agregado a cada Loader**

```swift
public struct CacheMetrics: Sendable {
    public private(set) var hitCount: Int = 0
    public private(set) var missCount: Int = 0
    public private(set) var staleHitCount: Int = 0
    public private(set) var evictionCount: Int = 0

    public var totalRequests: Int { hitCount + missCount }
    public var hitRate: Double {
        totalRequests > 0 ? Double(hitCount) / Double(totalRequests) : 0
    }

    mutating func recordHit() { hitCount += 1 }
    mutating func recordMiss() { missCount += 1 }
    mutating func recordStaleHit() { staleHitCount += 1 }
    mutating func recordEviction() { evictionCount += 1 }
}
```

**Archivos a crear:**
- `Packages/DynamicUI/Sources/DynamicUI/Loader/CacheMetrics.swift`

**Archivos a modificar:**
- `Packages/DynamicUI/Sources/DynamicUI/Loader/ScreenLoader.swift` — Agregar `var metrics: CacheMetrics`
- `Packages/DynamicUI/Sources/DynamicUI/Loader/DataLoader.swift` — Agregar `var metrics: CacheMetrics`

### Plan de trabajo

1. Crear `CacheMetrics` struct
2. Agregar propiedad `metrics` a `ScreenLoader` y `DataLoader`
3. Incrementar contadores en cada hit/miss/eviction
4. Exponer via `getMetrics()` async en cada loader
5. Opcional: agregar a analytics batch para backend
6. Tests unitarios

**Complejidad:** BAJA — Solo contadores, sin cambio de flujo

### Tests requeridos

- Hit incrementa hitCount
- Miss incrementa missCount
- hitRate calcula correctamente
- Reset de metricas funciona
- Metricas son thread-safe (actor)

### Dependencias

Ninguna.

---

## 3. Analytics de User Flows

### Estado actual

- `Packages/Features/Sources/Analytics/Analytics.swift` (lineas 1-47)
  - `AnalyticsManager` actor existe y funciona
  - `track(event:)` guarda en array en memoria
  - Comentario: "In production, this would send to analytics backend" (linea 29)
  - `AnalyticsEvent`: name, properties (`[String: String]`), timestamp
  - NO hay transmision a backend
  - NO hay tracking de sesiones
  - NO hay tracking de user flows (funnels)

### Problema/oportunidad

- Eventos se pierden al cerrar la app (solo in-memory)
- No hay visibilidad del comportamiento de usuarios en produccion
- No se puede medir adopcion de features, tiempo en pantalla, tasa de completado de formularios
- No hay datos para priorizar mejoras

### Solucion propuesta

**Extender `AnalyticsManager` con:**
1. **Persistencia local** de eventos (batch en UserDefaults o archivo JSON)
2. **Transmision batch** al backend (cada 30 eventos o 5 minutos)
3. **Session tracking** con session ID y duracion
4. **Screen flow tracking** automatico (que pantallas visita el usuario, en que orden)
5. **Funnel primitives** (start funnel, complete step, abandon)

**Archivos a crear:**
- `Packages/Features/Sources/Analytics/AnalyticsStore.swift` — Persistencia local
- `Packages/Features/Sources/Analytics/SessionTracker.swift` — Session management
- `Packages/Features/Sources/Analytics/FlowTracker.swift` — User flow analysis

**Archivos a modificar:**
- `Packages/Features/Sources/Analytics/Analytics.swift` — Agregar batch transmision y persistencia
- `Apps/DemoApp/Sources/ViewModels/DynamicScreenViewModel.swift` — Auto-track screen views
- `Apps/DemoApp/Sources/Services/ServiceContainer.swift` — Inyectar analytics

### Plan de trabajo

1. Implementar `AnalyticsStore` para persistencia local
2. Agregar batch transmission en `AnalyticsManager` (30 eventos o 5 min)
3. Crear `SessionTracker` con session ID, start/end
4. Auto-track screen views en `DynamicScreenViewModel.loadScreen()`
5. Agregar tracking de acciones CRUD (create, update, delete)
6. Crear endpoint backend para recibir batch de eventos
7. Tests unitarios

**Complejidad:** ALTA — Nuevo subsistema con persistencia, transmision, y auto-tracking

### Tests requeridos

- Eventos se persisten localmente
- Batch se transmite cuando alcanza threshold
- Session ID se genera al iniciar app
- Screen view se trackea automaticamente
- Eventos offline se envian al reconectar
- Buffer no crece indefinidamente (max 1000 eventos locales)

### Dependencias

- Backend debe tener endpoint para recibir batch de analytics

---

## 4. Performance Monitoring (Signposts)

### Estado actual

- `Packages/Domain/Sources/CQRS/Observability/MetricCollector.swift` (lineas 25-65)
  - `signpostLog: OSLog` declarado en linea 32 pero NUNCA usado
  - `recordLatency()` usa `logger.debug()` en vez de `os_signpost`
  - No hay signposts en ScreenLoader, DataLoader, ni NetworkClient

### Problema/oportunidad

- No se puede perfilar la app con Xcode Instruments (no hay signposts)
- Latencia de screen loads, data fetches, y auth refreshes no es medible
- La infraestructura ya existe (signpostLog declarado) pero no se usa

### Solucion propuesta

**Activar signposts en puntos criticos:**

```swift
import os.signpost

// En MetricCollector
let signpostID = OSSignpostID(log: signpostLog)
os_signpost(.begin, log: signpostLog, name: "ScreenLoad", signpostID: signpostID, "%{public}@", screenKey)
// ... operacion ...
os_signpost(.end, log: signpostLog, name: "ScreenLoad", signpostID: signpostID)
```

**Puntos de instrumentacion:**
1. `ScreenLoader.loadScreen()` — Tiempo de carga de definicion de pantalla
2. `DataLoader.loadData()` — Tiempo de carga de datos
3. `NetworkClient.send()` — Tiempo de cada HTTP request
4. `AuthService.refreshToken()` — Tiempo de refresh de JWT
5. `EventOrchestrator.execute()` — Tiempo de procesamiento de eventos

**Archivos a modificar:**
- `Packages/Domain/Sources/CQRS/Observability/MetricCollector.swift` — Usar os_signpost real
- `Packages/DynamicUI/Sources/DynamicUI/Loader/ScreenLoader.swift` — Agregar signpost
- `Packages/DynamicUI/Sources/DynamicUI/Loader/DataLoader.swift` — Agregar signpost
- `Packages/Infrastructure/Sources/Network/Interceptors/InterceptableNetworkClient.swift` — Agregar signpost

### Plan de trabajo

1. Corregir `OSLogMetricCollector.recordLatency()` para usar `os_signpost`
2. Agregar signpost begin/end en `ScreenLoader.loadScreen()`
3. Agregar signpost begin/end en `DataLoader.loadData()`
4. Agregar signpost begin/end en `InterceptableNetworkClient.send()`
5. Verificar visibilidad en Xcode Instruments > Points of Interest
6. Tests unitarios

**Complejidad:** BAJA — Solo agregar llamadas os_signpost en metodos existentes

### Tests requeridos

- os_signpost no lanza error
- signpostLog se inicializa correctamente
- Signpost IDs son unicos por operacion
- Latencia se registra correctamente

### Dependencias

Ninguna — os.signpost es framework nativo.
