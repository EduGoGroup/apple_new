# Server-Driven UI (SDUI) — EduGo Apple

> Documentacion generada desde analisis directo del codigo fuente (marzo 2026).

---

## 1. Vision General

El sistema SDUI permite renderizar pantallas definidas en el backend sin necesidad de actualizar la app. Vive en `Packages/DynamicUI/` como paquete lateral (depende de Foundation, Core y Infrastructure, pero NO de Domain ni Presentation).

---

## 2. Arquitectura SDUI

```
Backend API
    │
    ├─ GET /api/v1/screens/{key} → ScreenDefinition (JSON)
    │
    ├─ GET /api/v1/{resource} → Data (JSON)
    │
    ▼
┌──────────────────────────────────────────────┐
│                EduDynamicUI                   │
│                                               │
│  ScreenLoader ──→ ScreenDefinition            │
│       │              │                        │
│       │         ScreenPattern                 │
│       │              │                        │
│  DataLoader ───→ [String: JSONValue]          │
│       │                                       │
│  Resolvers ────→ UI Slots con datos bindeados │
│       │                                       │
│  Contracts ────→ Eventos de pantalla          │
│       │                                       │
│  Orchestrator ─→ Resultados (navegar, submit) │
└──────────────────────────────────────────────┘
```

---

## 3. ScreenLoader

**Archivo:** `Packages/DynamicUI/Sources/DynamicUI/Loader/ScreenLoader.swift`

Actor que carga y cachea definiciones de pantalla:

```swift
public actor ScreenLoader {
    public func seedFromBundle(screens: [String: ScreenBundleDTO]) async
    public func loadScreen(key: String) async throws -> ScreenDefinition
    public func checkVersion(for key: String) async -> Bool
    public func invalidateCache(key: String)
    public func clearCache()
}
```

### Cache L1 (Memoria)

| Propiedad | Valor |
|-----------|-------|
| Tipo | LRU (Least Recently Used) |
| Capacidad | 20 entries (default) |
| ETag | Soportado (304 revalidation) |
| Seed | Desde sync bundle al login |

### TTL por Patron de Pantalla

| Patron | TTL |
|--------|-----|
| Dashboard | 60s |
| List | 300s (5 min) |
| Form | 3600s (1 hora) |
| Detail | 300s |
| Settings | 3600s |

---

## 4. DataLoader

**Archivo:** `Packages/DynamicUI/Sources/DynamicUI/Loader/DataLoader.swift`

Actor que carga datos de endpoints con soporte offline:

```swift
public actor DataLoader {
    public func loadData(
        endpoint: String,
        config: DataConfig?,
        params: [String: String]?
    ) async throws -> [String: JSONValue]

    public func loadDataWithResult(...) async throws -> DataLoadResult

    public func loadNextPageWithMetadata(...) async throws -> PaginatedResult
}
```

### Dual-API Routing

El prefijo del endpoint determina la API destino:

| Prefijo | Base URL | Ejemplo |
|---------|----------|---------|
| `admin:` | `adminBaseURL` | `admin:/api/v1/schools` → Admin API |
| `mobile:` | `mobileBaseURL` | `mobile:/api/v1/materials` → Mobile API |
| Sin prefijo | `mobileBaseURL` | `/api/v1/data` → Mobile API |

### Cache de Datos

| Propiedad | Valor |
|-----------|-------|
| Tipo | LRU |
| Capacidad | 50 entries (default) |
| Offline | Retorna cache stale cuando no hay red |
| Paginacion | Soporte con totalCount/hasMore |

### Offline Support

1. Request falla por red → busca en cache
2. Cache tiene datos (aunque expirados) → retorna datos stale
3. Mutaciones offline → encoladas en `MutationQueue`
4. Red restaurada → `SyncEngine` procesa cola

---

## 5. Modelos SDUI

**Directorio:** `Packages/DynamicUI/Sources/DynamicUI/Models/`

### ScreenDefinition

Estructura principal que describe una pantalla:

```swift
public struct ScreenDefinition: Codable, Sendable {
    public let key: String
    public let pattern: ScreenPattern
    public let template: ScreenTemplate
    public let zones: [Zone]
    public let navigation: NavigationDefinition?
}
```

### ScreenPattern

Tipos de pantalla soportados:

| Patron | Descripcion |
|--------|-------------|
| `dashboard` | Panel principal con widgets |
| `list` | Lista con busqueda y filtros |
| `form` | Formulario con campos dinamicos |
| `detail` | Vista de detalle de un recurso |
| `settings` | Configuracion con toggles |
| `login` | Pantalla de autenticacion |

### Zone

Regiones dentro de una pantalla:

```swift
public struct Zone: Codable, Sendable {
    public let id: String
    public let type: String
    public let slots: [Slot]
    public let dataConfig: DataConfig?
}
```

### ControlType

24+ tipos de control para campos de formulario:

- Text, TextField, TextArea
- Select, MultiSelect, RemoteSelect
- Switch, Checkbox, Radio
- DatePicker, TimePicker
- Number, Slider
- Image, File
- Button, Link
- etc.

### DataConfig

Configuracion de endpoint para una zona:

```swift
public struct DataConfig: Codable, Sendable {
    public let endpoint: String      // "admin:/api/v1/schools"
    public let method: String?       // GET, POST, etc.
    public let fieldMapping: [String: String]?  // API field → template field
}
```

---

## 6. Resolvers

### SlotBindingResolver

Resuelve bindings de datos a slots de UI:

```
slot.bind = "title"  →  data["title"]  →  "Matematicas"
```

### PlaceholderResolver

Resuelve placeholders en templates:

```
"{user.name}"     → nombre del usuario actual
"{context.school}" → nombre de la escuela activa
"{item.title}"    → campo del item actual
"{date.now}"      → fecha actual formateada
```

### FieldMapper

Mapea campos de API a campos genericos del template:

```json
{
  "fieldMapping": {
    "full_name": "title",
    "description": "subtitle",
    "created_at": "date"
  }
}
```

---

## 7. Contracts y Orchestrator

### ContractRegistry

Registro de contratos por tipo de pantalla:

```swift
public final class ContractRegistry {
    public func registerDefaults()
    public func contract(for screenKey: String) -> ScreenContract?
}
```

### EventOrchestrator

Enruta eventos de pantalla al handler correspondiente:

```swift
public final class EventOrchestrator {
    public func handle(event: ScreenEvent, context: EventContext) async -> EventResult
}
```

### ScreenEvent

Eventos que puede emitir una pantalla:
- Tap en item de lista
- Submit de formulario
- Tap en boton de accion
- Navegacion (back, create)
- Refresh / pull-to-refresh

### EventResult

Resultados posibles:
- `Success` — operacion exitosa
- `NavigateTo(screenKey)` — navegar a otra pantalla
- `Error(message)` — mostrar error
- `SubmitTo(endpoint, method, fields)` — enviar datos al backend

---

## 8. PrefetchCoordinator

Coordina precarga paralela de pantallas y datos:

```swift
public actor PrefetchCoordinator {
    // Task group coordination
    // Parallel resource loading
}
```

Optimiza la experiencia cargando pantallas probables en background.

---

## 9. Flujo Completo

```
1. Login exitoso
   │
2. fullSync() → SyncBundle
   │  (menu, screens, permissions, contexts)
   │
3. screenLoader.seedFromBundle(screens)
   │  (pre-carga definiciones en cache)
   │
4. Usuario navega a pantalla (ej: "schools-list")
   │
5. ScreenLoader.loadScreen("schools-list")
   │  ├─ Cache hit → retorna ScreenDefinition
   │  └─ Cache miss → GET /api/v1/screens/schools-list
   │
6. DataLoader.loadData(endpoint: "admin:/api/v1/schools")
   │  ├─ Online → fetch + cache
   │  └─ Offline → retorna cache stale
   │
7. Resolvers procesan bindings + placeholders
   │
8. SwiftUI renderiza la pantalla
   │
9. Usuario interactua → ScreenEvent
   │
10. EventOrchestrator → EventResult
    ├─ NavigateTo → navegar
    └─ SubmitTo → DataLoader.loadData(POST/PUT)
```

---

*Generado: marzo 2026 | Basado en analisis directo del codigo fuente*
