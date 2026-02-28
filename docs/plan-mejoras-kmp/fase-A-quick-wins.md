# Fase A — Quick Wins: Cache Logging + i18n + Cache Clear

**Complejidad**: Baja
**Archivos estimados**: ~10
**Prerequisitos**: Ninguno

---

## A1: Cache Hit/Miss Logging en ScreenLoader y DataLoader

**Origen**: KMP PR #19 — OB3 Cache logging

**Qué hace**: Agregar logging de operaciones de cache (HIT/MISS/STALE/REMOTE) en los loaders para observabilidad del desarrollador.

**Taxonomía de mensajes** (mantener consistencia con KMP):

| Mensaje | Significado |
|---------|-------------|
| `L1 HIT: <key>` | Encontrado en cache de memoria (fresco) |
| `STALE (offline): <key>` | Cache obsoleto devuelto porque está offline |
| `STALE FALLBACK: <key>` | Network falló, fallback a cache obsoleto |
| `REMOTE: <key>` | Yendo a network |
| `MISS: <key>` | Sin cache, sin éxito de network |
| `MISS (offline): <key>` | Offline sin datos en cache |

### Pasos

1. **Modificar `ScreenLoader` actor** (`Packages/DynamicUI/Sources/DynamicUI/Loader/ScreenLoader.swift`):
   - Agregar propiedad `private let logger: Logger?` al actor
   - Actualizar `init()` para recibir `logger: Logger? = nil`
   - En `loadScreen()`:
     - Antes de return de cache hit → `logger?.debug("[EduGo.Cache.Screen] L1 HIT: \(screenKey)")`
     - Antes de return de 304 Not Modified → `logger?.debug("[EduGo.Cache.Screen] L1 HIT (revalidated): \(screenKey)")`
     - Antes de fetch remoto → `logger?.debug("[EduGo.Cache.Screen] REMOTE: \(screenKey)")`
     - En catch con cache fallback → `logger?.debug("[EduGo.Cache.Screen] STALE FALLBACK: \(screenKey)")`
     - En catch sin cache → `logger?.debug("[EduGo.Cache.Screen] MISS: \(screenKey)")`

2. **Modificar `DataLoader` actor** (`Packages/DynamicUI/Sources/DynamicUI/Loader/DataLoader.swift`):
   - Misma estrategia: agregar `logger: Logger?`
   - Tag: `[EduGo.Cache.Data]`
   - Logging en los puntos de decisión de cache

3. **Actualizar `ServiceContainer`** (`Apps/DemoApp/Sources/Services/ServiceContainer.swift`):
   - Pasar instancia de Logger al crear ScreenLoader y DataLoader

4. **Tests**:
   - Test que verifica que ScreenLoader loguea L1 HIT al re-solicitar screen cacheada
   - Test que verifica REMOTE al solicitar screen nueva
   - Test que verifica MISS cuando no hay cache ni network

### Archivos afectados
- `Packages/DynamicUI/Sources/DynamicUI/Loader/ScreenLoader.swift`
- `Packages/DynamicUI/Sources/DynamicUI/Loader/DataLoader.swift`
- `Apps/DemoApp/Sources/Services/ServiceContainer.swift`
- `Packages/DynamicUI/Tests/DynamicUITests/Loader/ScreenLoaderTests.swift`
- `Packages/DynamicUI/Tests/DynamicUITests/Loader/DataLoaderTests.swift`

---

## A2: i18n — Reemplazar Strings Hardcoded

**Origen**: KMP PR #19 — i18n Fase 1

**Qué hace**: Reemplazar strings en español hardcodeados con referencias a `EduStrings` o `String(localized:)`.

### Strings a migrar

| String Hardcoded | Ubicación | Key Propuesta |
|---|---|---|
| `"Sin conexión"` | EduConnectivityBanner.swift:38 | `EduStrings.Connectivity.offline` (ya existe) |
| `"Sincronizado"` | EduConnectivityBanner.swift:46 | `EduStrings.Connectivity.synced` (ya existe) |
| `"Sincronizando..."` | EduConnectivityBanner.swift:73 | `EduStrings.Connectivity.syncing` (ya existe) |
| `"Seleccionar escuela"` | SchoolSelectionScreen.swift:46 | `EduStrings.Navigation.selectSchool` (ya existe) |
| `"Cerrar"` | SchoolSelectionScreen.swift:52 | `EduStrings.Action.close` (crear) |
| `"Sin escuela"` | SchoolSelectionScreen.swift:72 | `EduStrings.Navigation.noSchool` (crear) |
| `"Cancelar"` | FormPatternRenderer.swift:43 | `EduStrings.Action.cancel` (ya existe) |
| `"Guardar"` | FormPatternRenderer.swift:46 | `EduStrings.Action.save` (ya existe) |

### Strings adicionales (del fix commit de PR #19)

Estas strings se agregaron en el commit de corrección y también deben incluirse:

| Key Propuesta | Valor Default | Uso |
|---|---|---|
| `EduStrings.Form.fieldRequired` | `"Este campo es obligatorio"` | Validación de formularios |
| `EduStrings.Form.fixErrors` | `"Corrige los campos marcados"` | Mensaje toast cuando hay errores |
| `EduStrings.Select.loading` | `"Cargando..."` | RemoteSelectField placeholder |
| `EduStrings.Select.loadError` | `"Error al cargar opciones"` | RemoteSelectField error state |

### Pasos

1. **Agregar keys faltantes a `EduStrings`** (`Packages/Presentation/Sources/i18n/EduStrings.swift`):
   - `Action.close = String(localized: "action.close", defaultValue: "Cerrar")`
   - `Navigation.noSchool = String(localized: "nav.noSchool", defaultValue: "Sin escuela")`
   - `Form.fieldRequired = String(localized: "form.fieldRequired", defaultValue: "Este campo es obligatorio")`
   - `Form.fixErrors = String(localized: "form.fixErrors", defaultValue: "Corrige los campos marcados")`
   - `Select.loading = String(localized: "select.loading", defaultValue: "Cargando...")`
   - `Select.loadError = String(localized: "select.loadError", defaultValue: "Error al cargar opciones")`

2. **Reemplazar hardcoded strings**:
   - `EduConnectivityBanner.swift` → usar `EduStrings.Connectivity.*`
   - `SchoolSelectionScreen.swift` → usar `EduStrings.Navigation.*` y `EduStrings.Action.*`
   - `FormPatternRenderer.swift` → usar `EduStrings.Action.*` y `EduStrings.Form.*` para mensajes de validación

3. **Tests**: Verificar que las vistas compilan y strings se resuelven correctamente

### Archivos afectados
- `Packages/Presentation/Sources/i18n/EduStrings.swift`
- `Packages/Presentation/Sources/Components/Feedback/EduConnectivityBanner.swift`
- `Apps/DemoApp/Sources/Screens/SchoolSelectionScreen.swift`
- `Apps/DemoApp/Sources/Renderers/FormPatternRenderer.swift`

---

## A3: Cache Clearing al Cambiar de Escuela

**Origen**: KMP PR #14 — School Selection improvements

**Qué hace**: Limpiar caches de ScreenLoader y DataLoader cuando el usuario cambia de contexto escolar, evitando que datos de la escuela anterior se sirvan de cache.

### Problema actual

En `MainScreen.switchContext()`, se hace fullSync pero NO se limpian los caches:
```swift
// Actual (sin cache clearing)
try await container.authService.switchContext(context)
let bundle = try await container.syncService.fullSync()
```

Esto puede servir pantallas/datos de la escuela anterior desde cache.

### Pasos

1. **Modificar `MainScreen.switchContext()`** (`Apps/DemoApp/Sources/Screens/MainScreen.swift`):
   - Antes del fullSync, agregar:
     ```swift
     await container.screenLoader.clearCache()
     await container.dataLoader.clearCache()
     ```
   - Esto asegura que después del cambio de contexto, todas las pantallas se cargan fresh

2. **Verificar** que los métodos `clearCache()` existen en ambos loaders (ya confirmado)

3. **Tests**: No se requieren tests nuevos — es una llamada directa a métodos existentes

### Archivos afectados
- `Apps/DemoApp/Sources/Screens/MainScreen.swift`

---

## Verificación de Fase

```bash
# Compilar
make build

# Tests DynamicUI (cache logging)
cd Packages/DynamicUI && swift test

# Tests Presentation (i18n)
cd Packages/Presentation && swift test

# Build DemoApp
make run
```

**Criterio de éxito**:
- 0 warnings de deprecación
- Todos los tests pasan
- Logs de cache visibles en consola al navegar por pantallas
- No hay strings hardcoded en español en ConnectivityBanner ni SchoolSelectionScreen
- Al cambiar de escuela, las pantallas se recargan (no sirve cache viejo)
