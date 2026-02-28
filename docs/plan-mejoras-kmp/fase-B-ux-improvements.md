# Fase B — UX: Skeleton Views + Undo Delete

**Complejidad**: Media
**Archivos estimados**: ~15
**Prerequisitos**: Fase A (i18n strings para mensajes del undo toast)

---

## B1: Skeleton Views por Patrón

**Origen**: KMP PR #19 — UX1 Skeleton Loading

**Qué hace**: Crear skeleton views específicos por patrón de pantalla (List, Form) que reemplacen `ProgressView()` o `EduLoadingStateView()` genéricos. Dashboard ya tiene skeleton propio.

### Estado actual
- `DashboardPatternRenderer` ✅ ya tiene `dashboardSkeleton` con `EduSkeletonLoader`
- `ListPatternRenderer` ❌ usa `EduLoadingStateView()` genérico
- `FormPatternRenderer` ❌ no tiene loading state explícito
- `DetailPatternRenderer` ❌ usa loading state genérico
- `EduSkeletonLoader` ✅ ya existe en Presentation con shapes y shimmer animation

### Nuevas Skeleton Views

#### ListSkeletonView
```
┌─────────────────────────────────┐
│  ○  ████████████████  ▸         │  ← Avatar circle + text lines + chevron
│     ████████████                │
├─────────────────────────────────┤
│  ○  ████████████████  ▸         │
│     ████████████                │
├─────────────────────────────────┤
│  ○  ████████████████  ▸         │
│     ████████████                │
├─────────────────────────────────┤
│  ○  ████████████████  ▸         │
│     ████████████                │
├─────────────────────────────────┤
│  ○  ████████████████  ▸         │
│     ████████████                │
└─────────────────────────────────┘
```
- 5 rows con shimmer
- Cada row: circle (48pt) + 2 text lines (ancho 80% y 60%) + chevron placeholder
- Usar `EduSkeletonLoader` existente
- **Sin padding interno** — el contenedor padre maneja el padding (fix de PR #19)

#### FormSkeletonView
```
┌─────────────────────────────────┐
│  ████████                       │  ← Label skeleton (30% width)
│  ┌─────────────────────────┐    │  ← Input skeleton (full width, 44pt)
│  └─────────────────────────┘    │
│                                 │
│  ████████                       │
│  ┌─────────────────────────┐    │
│  └─────────────────────────┘    │
│                                 │
│  ████████                       │
│  ┌─────────────────────────┐    │
│  └─────────────────────────┘    │
└─────────────────────────────────┘
```
- 3 field groups con shimmer
- Cada grupo: label (30% width, 14pt height) + input (100% width, 44pt height)
- **Sin padding interno** — el contenedor padre maneja el padding (fix de PR #19)

#### DetailSkeletonView
```
┌─────────────────────────────────┐
│  ████████████████████████       │  ← Title (80% width, 20pt)
│  ████████████████                │  ← Subtitle (60% width, 14pt)
│  ─────────────────────────────  │  ← Divider
│  ████████                       │  ← Label
│  ████████████████████████████   │  ← Value (100%)
│                                 │
│  ████████                       │
│  ████████████████████████████   │
│                                 │
│  ████████                       │
│  ████████████████████████████   │
└─────────────────────────────────┘
```
- Header (title + subtitle) + 3 detail rows

### Pasos

1. **Crear `ListSkeletonView`** (`Packages/Presentation/Sources/Components/Loading/ListSkeletonView.swift`):
   - 5 repeticiones de row skeleton
   - Usar `EduSkeletonLoader(shape:)` para cada elemento
   - Shimmer animado

2. **Crear `FormSkeletonView`** (`Packages/Presentation/Sources/Components/Loading/FormSkeletonView.swift`):
   - 3 field groups
   - Label + input skeleton por grupo

3. **Crear `DetailSkeletonView`** (`Packages/Presentation/Sources/Components/Loading/DetailSkeletonView.swift`):
   - Header + 3 detail rows

4. **Integrar en renderers**:
   - `ListPatternRenderer` → reemplazar `EduLoadingStateView()` con `ListSkeletonView()`
   - `FormPatternRenderer` → agregar loading state con `FormSkeletonView()`
   - `DetailPatternRenderer` → reemplazar loading con `DetailSkeletonView()`

5. **Tests**:
   - Snapshot test o test de instantiation para cada skeleton view

### Archivos afectados
- `Packages/Presentation/Sources/Components/Loading/ListSkeletonView.swift` (nuevo)
- `Packages/Presentation/Sources/Components/Loading/FormSkeletonView.swift` (nuevo)
- `Packages/Presentation/Sources/Components/Loading/DetailSkeletonView.swift` (nuevo)
- `Apps/DemoApp/Sources/Renderers/ListPatternRenderer.swift`
- `Apps/DemoApp/Sources/Renderers/FormPatternRenderer.swift`
- `Apps/DemoApp/Sources/Renderers/DetailPatternRenderer.swift`

---

## B2: Undo DELETE con Toast

**Origen**: KMP PR #17/#18 — Undoable Delete + Event Bus

**Qué hace**: Cuando el usuario elimina un elemento, en vez de ejecutar el DELETE inmediatamente (tras confirmación), se muestra un toast con botón "Deshacer" y se retrasa el DELETE real 5 segundos. Si el usuario presiona "Deshacer", la eliminación se cancela.

### Diseño en Swift

#### Nuevo EventResult case

```swift
// En EventResult.swift
public enum EventResult: Sendable {
    // ... cases existentes ...
    case pendingDelete(
        screenKey: String,
        itemId: String,
        endpoint: String,
        method: String = "DELETE"
    )
}
```

#### Flujo

```
Usuario toca "Eliminar"
  → confirmationDialog (ya existe)
    → EventOrchestrator retorna .pendingDelete (en vez de ejecutar DELETE)
      → ViewModel agenda Task con delay de 5s
      → UI muestra toast con "Elemento eliminado" + botón "Deshacer"
        → Si "Deshacer": cancela el Task → restaura elemento
        → Si timeout (5s): ejecuta DELETE real via NetworkClient
          → Emite evento al EventBus para que listas se recarguen
```

### Pasos

1. **Agregar `pendingDelete` a `EventResult`** (`Packages/Domain/Sources/Services/DynamicUI/EventResult.swift`):
   - Nuevo case con screenKey, itemId, endpoint, method

2. **Modificar `EventOrchestrator.executeWrite()`** (`Packages/Domain/Sources/Services/DynamicUI/EventOrchestrator.swift`):
   - Cuando el evento es `.delete`, en vez de ejecutar el HTTP DELETE:
   - Retornar `.pendingDelete(screenKey:, itemId:, endpoint:, method:)`
   - La ejecución real se delega al ViewModel

3. **Agregar lógica de pending delete al ViewModel** (en DemoApp, ViewModel que maneja eventos):
   - Propiedad: `pendingDelete: PendingDeleteInfo?` (screenKey, itemId, endpoint, task handle)
   - `schedulePendingDelete()`: crea Task con `Task.sleep(for: .seconds(5))` + execute DELETE
   - `cancelPendingDelete()`: cancela el Task, limpia pendingDelete
   - `executePendingDelete()`: ejecuta HTTP DELETE, emite evento al EventBus

4. **Extender `EduToast` con acción** (`Packages/Presentation/Sources/Components/Feedback/EduToast.swift`):
   - Agregar soporte para toast con botón de acción (undo)
   - `ToastManager.showUndoable(message:, onUndo:, duration:)`
   - El toast muestra mensaje + botón "Deshacer"
   - Auto-dismiss después de duration (5s)

5. **Integrar en renderers**:
   - Cuando EventResult es `.pendingDelete`, mostrar toast undoable
   - El botón "Deshacer" llama `cancelPendingDelete()`

6. **i18n strings** (depende de Fase A):
   - `EduStrings.Action.undo = "Deshacer"`
   - `EduStrings.Messages.itemDeleted = "Elemento eliminado"`

7. **Tests**:
   - Test EventOrchestrator retorna `.pendingDelete` para `.delete` event
   - Test que cancel antes de 5s no ejecuta DELETE
   - Test que timeout ejecuta DELETE

### Archivos afectados
- `Packages/Domain/Sources/Services/DynamicUI/EventResult.swift`
- `Packages/Domain/Sources/Services/DynamicUI/EventOrchestrator.swift`
- `Packages/Presentation/Sources/Components/Feedback/EduToast.swift`
- `Packages/Presentation/Sources/i18n/EduStrings.swift`
- `Apps/DemoApp/Sources/Renderers/DetailPatternRenderer.swift`
- `Apps/DemoApp/Sources/Renderers/ListPatternRenderer.swift`
- `Packages/Domain/Tests/DomainTests/Services/DynamicUI/EventOrchestratorTests.swift`

---

## Verificación de Fase

```bash
make build
cd Packages/Presentation && swift test
cd Packages/Domain && swift test
make run
```

**Criterio de éxito**:
- Skeleton views visibles al cargar pantallas List, Form, Detail
- Al eliminar un elemento: toast con "Deshacer" aparece, botón funcional
- Si se presiona "Deshacer" antes de 5s → elemento NO se elimina
- Si pasan 5s → DELETE se ejecuta y lista se recarga
- 0 warnings, todos tests pasan
