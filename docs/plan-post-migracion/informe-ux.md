# Informe UX — Mejoras Post-Migracion

## 1. Optimistic UI

### Estado actual

El flujo actual de CRUD es **API-first**: el usuario ejecuta una accion, se envia al servidor, y solo se actualiza la UI cuando el servidor confirma.

**Archivos relevantes:**
- `Apps/DemoApp/Sources/ViewModels/DynamicScreenViewModel.swift` (lineas 140-160) — `executeEvent()` envia al servidor y espera respuesta
- `Packages/Domain/Sources/Services/DynamicUI/EventOrchestrator.swift` (lineas 181-253) — `executeWrite()` hace HTTP request directo
- `Apps/DemoApp/Sources/Renderers/FormPatternRenderer.swift` (lineas 66-77) — Save handler llama `viewModel.executeEvent()`
- `Apps/DemoApp/Sources/Renderers/ListPatternRenderer.swift` (lineas 83-86) — Select item handler

**Excepcion:** Delete ya tiene un patron semi-optimistic:
- `EventOrchestrator.executeWrite()` retorna `.pendingDelete` (linea 192-200)
- `DynamicScreenViewModel.schedulePendingDelete()` (linea 365) remueve item de UI inmediatamente
- Toast con undo por 5 segundos, luego ejecuta DELETE real
- Si falla, refresh completo restaura el estado

**MutationQueue** (`Packages/Domain/Sources/Services/Offline/MutationQueue.swift`):
- Actor con max 50 mutations, deduplicacion por endpoint+method
- Estados: pending -> syncing -> completed/failed/conflicted
- Persistencia en UserDefaults con JSON
- Solo se usa como fallback cuando el API call directo falla y hay modo offline

### Problema/oportunidad

- Crear/editar items muestra spinner mientras espera servidor (300-1500ms de latencia percibida)
- En conexiones lentas o modo offline, la UI queda bloqueada hasta que responde o falla
- El patron de delete con undo demuestra que el patron optimistic ya es viable

### Solucion propuesta

Ver [spec-optimistic-ui.md](spec-optimistic-ui.md) para diseno tecnico detallado.

### Plan de trabajo

1. Crear `OptimisticUpdateManager` (actor) en `Packages/Domain/`
2. Modificar `EventOrchestrator.executeWrite()` para retornar optimistic result
3. Modificar `DynamicScreenViewModel` para aplicar updates locales inmediatos
4. Agregar indicador visual "pendiente de confirmacion" en renderers
5. Implementar rollback en caso de fallo del servidor
6. Tests unitarios para todos los escenarios

**Complejidad:** ALTA — Afecta 4+ archivos, requiere nuevo actor, modifica flujo critico

### Tests requeridos

- Confirmacion exitosa: UI no cambia despues de confirmar
- Rollback exitoso: UI revierte cuando servidor rechaza
- Conflicto 409: UI muestra error y revierte
- Timeout: rollback automatico tras timeout configurable
- Offline: mutation se encola, UI muestra optimistic
- Multiples updates simultaneos: no se pisan

### Dependencias

Ninguna — puede implementarse independientemente.

---

## 2. Breadcrumb Navigation

### Estado actual

**Componente existente parcial:**
- `Packages/Presentation/Sources/Components/Navigation/EduBreadcrumbs.swift`
  - `EduBreadcrumbs` — Solo macOS (lineas 31-95), max 7 niveles, chevron separador
  - `EduBreadcrumbCoordinator` — `@Observable` manager con push/pop/clear (lineas 148-185)
  - `EduPlatformBreadcrumbs` — Wrapper adaptativo: macOS=breadcrumbs, iOS=solo titulo (lineas 245-272)
  - `EduBreadcrumbBuilder` — Builder pattern fluido (lineas 102-142)

**Navegacion actual:**
- `Packages/Presentation/Sources/Navigation/AppCoordinator.swift` — `@Observable`, `NavigationPath`, `Screen` enum
  - `navigate(to:)` push, `goBack()` pop, `popToRoot()` clear
  - No expone historial para breadcrumbs (solo `navigationPath.count`)
- `Apps/DemoApp/Sources/Screens/DynamicScreenView.swift` — Carga pantalla via ScreenLoader + PatternRouter
- `DynamicScreenViewModel` navega via callbacks `onNavigate?(screenKey, params)` — sin tracking centralizado

**Toolbar dinamico:**
- `Packages/Presentation/Sources/Components/Navigation/EduDynamicToolbar.swift`
  - Modos: hidden, list (titulo+create+search), form (cancel+titulo+save), detail (back+titulo+menu), titleOnly
  - No tiene zona para breadcrumbs

### Problema/oportunidad

- iOS no muestra breadcrumbs (solo titulo de pantalla actual)
- macOS tiene el componente pero no esta conectado a la navegacion real
- No hay tracking automatico del trail de navegacion SDUI
- Usuario no puede saltar a niveles intermedios

### Solucion propuesta

Ver [spec-breadcrumb-navigation.md](spec-breadcrumb-navigation.md) para diseno tecnico detallado.

### Plan de trabajo

1. Extender `EduBreadcrumbCoordinator` para sync con NavigationPath
2. Crear `BreadcrumbTracker` que intercepte navegacion SDUI
3. Adaptar `EduBreadcrumbs` para iOS (horizontal scroll, colapsable)
4. Integrar en `EduDynamicToolbar` como zona de breadcrumbs
5. Conectar con `DynamicScreenView` para auto-tracking
6. Tests unitarios

**Complejidad:** MEDIA — Componente base existe, necesita integracion

### Tests requeridos

- Stack correcto despues de navegacion List -> Detail -> Form
- Tap en breadcrumb intermedio navega correctamente y poda stack
- Stack vacio en root (home/dashboard)
- Max 7 niveles respetado con truncamiento
- Breadcrumbs se limpian al cambiar de seccion (menu lateral)

### Dependencias

Ninguna — puede implementarse independientemente.

---

## 3. Deep-Linking Avanzado (Universal Links)

### Estado actual

- `Apps/DemoApp/Sources/Navigation/DeepLinkHandler.swift` (lineas 1-50)
  - Solo custom scheme: `edugo://screen/{screenKey}?params`
  - `DeepLink` struct con screenKey + params
  - `pendingDeepLink` para links que llegan antes de login

### Problema/oportunidad

- No soporta Universal Links (`https://edugo.app/screen/...`)
- No hay web fallback si la app no esta instalada
- No hay analytics de deep links abiertos
- Requiere configuracion en backend (`apple-app-site-association`)

### Solucion propuesta

1. Crear `apple-app-site-association` en backend para dominio `edugo.app`
2. Extender `DeepLinkHandler` para parsear URLs https:// ademas de edugo://
3. Registrar `applinks` en entitlements de la app
4. Agregar fallback web: si path no es screen conocido, abrir en Safari
5. Tracking de deep links via AnalyticsManager

### Plan de trabajo

1. Configurar `apple-app-site-association` en backend (requiere coordinacion backend)
2. Agregar entitlement `com.apple.developer.associated-domains` al target
3. Extender `DeepLinkHandler.handle(url:)` para soportar https://
4. Agregar validacion de dominio permitido
5. Integrar con analytics
6. Tests unitarios

**Complejidad:** MEDIA — Requiere coordinacion con backend para AASA file

### Tests requeridos

- Parse correcto de URL https://edugo.app/screen/schools-list
- Parse correcto de URL edugo://screen/schools-list (retrocompat)
- Dominio no permitido retorna nil
- Pending link se procesa despues de login
- Parametros se extraen correctamente

### Dependencias

- Backend debe servir `apple-app-site-association` en `/.well-known/`

---

## 4. Undo/Redo en Formularios

### Estado actual

- `modulos/FormsSDK/Sources/FormsSDK/Core/FormState.swift` — `@Observable`, maneja validacion pero NO historial
- `DynamicScreenViewModel.fieldValues: [String: String]` — Binding directo sin snapshots
- Cambios se aplican inmediatamente al campo, no hay stack de deshacer

### Problema/oportunidad

- Usuario no puede deshacer un cambio accidental en formularios largos
- No hay integracion con gestos de undo del sistema (shake, Cmd+Z)
- Formularios SDUI pueden tener 10+ campos — perder trabajo es frustrante

### Solucion propuesta

1. Crear `FormHistoryManager` con stack de snapshots `[String: String]`
2. Grabar snapshot en cada cambio de campo (debounced 500ms)
3. Undo: restaurar snapshot anterior, Redo: avanzar
4. Integrar con `UndoManager` de SwiftUI para gestos nativos
5. Limite de 50 snapshots en historial

### Plan de trabajo

1. Crear `FormHistoryManager` en FormsSDK
2. Integrar con `DynamicScreenViewModel.fieldValues`
3. Agregar botones undo/redo en toolbar de formulario
4. Conectar con UndoManager para Cmd+Z / shake
5. Tests unitarios

**Complejidad:** MEDIA

### Tests requeridos

- Undo restaura campo anterior
- Redo re-aplica cambio deshecho
- Limite de snapshots (50) se respeta
- Undo en formulario vacio no hace nada
- Nuevo cambio despues de undo descarta redo stack

### Dependencias

Ninguna.
