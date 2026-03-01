# Spec: Optimistic UI

> Patron: accion -> UI update inmediato -> confirmar con server -> rollback si falla

## Contexto

El flujo actual de escritura es API-first:
1. Usuario toca "Guardar" en formulario
2. UI muestra spinner
3. HTTP POST/PUT al servidor
4. Servidor responde (300-1500ms)
5. UI se actualiza con respuesta

El patron optimistic invierte pasos 2-4: la UI se actualiza inmediatamente y el servidor confirma asincronamente.

## Analisis del Codigo Actual

### Flujo de escritura actual

```
FormPatternRenderer.save()                              [UI Layer]
  -> viewModel.executeEvent(.saveNew / .saveExisting)   [ViewModel]
    -> orchestrator.execute(event, context)              [Domain]
      -> executeWrite()                                  [Domain]
        -> networkClient.send(request)                   [Infrastructure]
          <- HTTP Response                               [Server]
        <- EventResult.success / .error                  [Domain]
      <- result                                          [Domain]
    -> handleResult(result)                              [ViewModel]
      -> dataState = .success(updatedItems)              [ViewModel]
  <- UI reflects change                                  [UI Layer]
```

**Archivos:**
- `Apps/DemoApp/Sources/Renderers/FormPatternRenderer.swift:66-77` — Save handler
- `Apps/DemoApp/Sources/ViewModels/DynamicScreenViewModel.swift:140-160` — executeEvent
- `Packages/Domain/Sources/Services/DynamicUI/EventOrchestrator.swift:181-253` — executeWrite
- `Packages/Domain/Sources/Services/Offline/MutationQueue.swift:65-80` — enqueue (solo offline)

### Patron de delete existente (referencia)

El delete ya usa un patron semi-optimistic que sirve de referencia:
1. `EventOrchestrator.executeWrite()` retorna `.pendingDelete` (no ejecuta DELETE aun)
2. `DynamicScreenViewModel.schedulePendingDelete()` remueve item de UI inmediatamente
3. Toast con "Deshacer" por 5 segundos
4. Si no se deshace: ejecuta HTTP DELETE real
5. Si falla: `refresh()` restaura estado

## Diseno Tecnico

### 1. OptimisticUpdateManager (actor)

**Ubicacion:** `Packages/Domain/Sources/Services/DynamicUI/OptimisticUpdateManager.swift`

```swift
public actor OptimisticUpdateManager {

    /// Snapshot del estado antes del update optimistic
    public struct PendingUpdate: Sendable, Identifiable {
        public let id: String  // UUID
        public let screenKey: String
        public let event: ScreenEvent  // .saveNew, .saveExisting, .delete
        public let previousItems: [[String: JSONValue]]  // Estado anterior para rollback
        public let optimisticItems: [[String: JSONValue]]  // Estado optimista
        public let fieldValues: [String: String]  // Valores del formulario
        public let createdAt: Date
        public let timeoutSeconds: TimeInterval  // Default 30s
        public var status: PendingUpdateStatus
    }

    public enum PendingUpdateStatus: Sendable {
        case pending       // Esperando confirmacion del server
        case confirmed     // Server confirmo
        case rolledBack    // Server rechazo, UI revertida
        case timedOut      // Timeout sin respuesta
    }

    private var pendingUpdates: [String: PendingUpdate] = [:]

    // Stream para notificar cambios de estado a la UI
    private let statusContinuation: AsyncStream<(updateId: String, status: PendingUpdateStatus)>.Continuation
    public let statusStream: AsyncStream<(updateId: String, status: PendingUpdateStatus)>

    /// Registra un update optimistic antes de enviar al servidor
    public func registerOptimisticUpdate(
        screenKey: String,
        event: ScreenEvent,
        previousItems: [[String: JSONValue]],
        optimisticItems: [[String: JSONValue]],
        fieldValues: [String: String],
        timeoutSeconds: TimeInterval = 30
    ) -> String  // Retorna updateId

    /// Confirma que el servidor acepto el update
    public func confirmUpdate(id: String, serverItems: [[String: JSONValue]]?)

    /// Marca como fallido y retorna los items anteriores para rollback
    public func rollbackUpdate(id: String) -> [[String: JSONValue]]?

    /// Retorna items anteriores para un update pendiente (para rollback manual)
    public func previousItems(for id: String) -> [[String: JSONValue]]?

    /// Verifica si hay updates pendientes para una pantalla
    public func hasPendingUpdates(for screenKey: String) -> Bool

    /// Limpia updates expirados
    public func cleanupExpired()
}
```

### 2. Modificar EventOrchestrator

**Archivo:** `Packages/Domain/Sources/Services/DynamicUI/EventOrchestrator.swift`

Agregar nuevo caso a `EventResult`:

```swift
// En EventResult.swift
case optimisticSuccess(
    updateId: String,
    message: String = "",
    optimisticData: JSONValue? = nil
)
```

Modificar `executeWrite()` para retornar resultado optimistic antes de confirmar:

```swift
// Nuevo flujo en executeWrite():
// 1. Validar permisos (igual que antes)
// 2. Construir request body (igual que antes)
// 3. Retornar .optimisticSuccess con updateId
// 4. Enviar request al server en background
// 5. Si confirma: notificar via OptimisticUpdateManager.confirmUpdate()
// 6. Si falla: notificar via OptimisticUpdateManager.rollbackUpdate()
```

### 3. Modificar DynamicScreenViewModel

**Archivo:** `Apps/DemoApp/Sources/ViewModels/DynamicScreenViewModel.swift`

```swift
// Nuevo metodo para manejar optimistic updates
func handleOptimisticResult(_ result: EventResult) {
    switch result {
    case .optimisticSuccess(let updateId, let message, let data):
        // 1. Aplicar cambio optimistic inmediatamente
        applyOptimisticUpdate(updateId: updateId, data: data)

        // 2. Mostrar indicador sutil "guardando..."
        pendingOptimisticIds.insert(updateId)

        // 3. Observar confirmacion/rollback
        observeUpdateStatus(updateId: updateId)

    default:
        handleResult(result)  // Flujo actual
    }
}

private func applyOptimisticUpdate(updateId: String, data: JSONValue?) {
    guard case .success(var items, let hasMore, _) = dataState else { return }

    // Para saveNew: agregar item al inicio de la lista
    // Para saveExisting: reemplazar item existente
    // Para delete: remover item

    dataState = .success(items: updatedItems, hasMore: hasMore, loadingMore: false)
}

private func observeUpdateStatus(updateId: String) {
    Task {
        for await (id, status) in optimisticManager.statusStream {
            guard id == updateId else { continue }
            switch status {
            case .confirmed:
                pendingOptimisticIds.remove(id)
                // Opcionalmente actualizar con datos reales del servidor
            case .rolledBack:
                pendingOptimisticIds.remove(id)
                rollbackOptimistic(updateId: id)
                toastManager?.show(.error("No se pudo guardar. Cambios revertidos."))
            case .timedOut:
                pendingOptimisticIds.remove(id)
                // Timeout no revierte automaticamente — marca como incierto
                toastManager?.show(.warning("No se confirmo el guardado. Verifica la conexion."))
            default:
                break
            }
        }
    }
}

private func rollbackOptimistic(updateId: String) {
    Task {
        if let previousItems = await optimisticManager.previousItems(for: updateId) {
            let hasMore = /* calcular */ false
            dataState = .success(items: previousItems, hasMore: hasMore, loadingMore: false)
        }
    }
}
```

### 4. Indicador Visual de Estado Pendiente

**En renderers:** Agregar indicador sutil cuando un item tiene update pendiente.

```swift
// En ListPatternRenderer — cada row
HStack {
    itemRow(item: item)
    if viewModel.isPendingOptimistic(item: item) {
        Image(systemName: "arrow.trianglehead.2.clockwise")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .symbolEffect(.rotate, isActive: true)
    }
}
```

**En FormPatternRenderer — boton save:**
```swift
Button(action: save) {
    if viewModel.isSaving {
        ProgressView()
    } else {
        Text(isEditing ? EduStrings.save : EduStrings.create)
    }
}
// Despues de save exitoso (optimistic), navegar back inmediatamente
// No esperar confirmacion del servidor
```

### 5. Integracion con MutationQueue (Offline)

Cuando no hay conectividad:
1. `OptimisticUpdateManager` registra el update
2. `MutationQueue` encola la mutation
3. UI muestra estado optimistic
4. Cuando hay conectividad, `SyncEngine` procesa la mutation
5. Si confirma: `OptimisticUpdateManager.confirmUpdate()`
6. Si falla: `OptimisticUpdateManager.rollbackUpdate()`

### 6. Flujo Completo

```
ONLINE:
  User taps Save
  -> ViewModel: snapshot current items (previousItems)
  -> ViewModel: apply optimistic change (show new item in list)
  -> ViewModel: show "saving..." indicator
  -> EventOrchestrator: send HTTP request (background)
  -> Server responds:
     Success -> OptimisticUpdateManager.confirmUpdate()
              -> ViewModel: remove "saving..." indicator
              -> Optional: merge server data (IDs, timestamps)
     Failure -> OptimisticUpdateManager.rollbackUpdate()
              -> ViewModel: revert to previousItems
              -> ViewModel: show error toast

OFFLINE:
  User taps Save
  -> ViewModel: snapshot + apply optimistic
  -> EventOrchestrator: enqueue mutation (offline fallback)
  -> MutationQueue persists mutation
  -> UI shows optimistic state + offline indicator
  -> When online: SyncEngine processes mutation
     -> Confirm/rollback same as online
```

## Archivos a Crear

| Archivo | Paquete | Descripcion |
|---------|---------|-------------|
| `OptimisticUpdateManager.swift` | Domain | Actor que gestiona updates pendientes |

## Archivos a Modificar

| Archivo | Cambio |
|---------|--------|
| `Packages/Domain/Sources/Services/DynamicUI/EventResult.swift` | Agregar caso `.optimisticSuccess` |
| `Packages/Domain/Sources/Services/DynamicUI/EventOrchestrator.swift` | Retornar optimistic result, confirmar/rollback en background |
| `Apps/DemoApp/Sources/ViewModels/DynamicScreenViewModel.swift` | Handle optimistic updates, rollback, observar status |
| `Apps/DemoApp/Sources/Renderers/ListPatternRenderer.swift` | Indicador visual de pending |
| `Apps/DemoApp/Sources/Renderers/FormPatternRenderer.swift` | Navegacion inmediata post-save |

## Tests Requeridos

| Test | Descripcion |
|------|-------------|
| `testOptimisticCreateAppearsInList` | Crear item aparece inmediatamente en lista |
| `testServerConfirmationRemovesPending` | Confirmacion del server limpia estado pendiente |
| `testRollbackRevertsToOriginal` | Fallo del server revierte a items originales |
| `testConflict409TriggersRollback` | Error 409 dispara rollback |
| `testTimeoutShowsWarning` | Timeout muestra warning sin revertir |
| `testOfflineEnqueuesMutation` | Sin red, mutation se encola |
| `testMultipleOptimisticUpdatesCoexist` | Multiples updates no se pisan |
| `testPendingUpdateIndicatorShows` | Indicador visual aparece para items pendientes |

## Estimacion

- **Complejidad:** ALTA
- **Archivos nuevos:** 1
- **Archivos modificados:** 5
- **Tests nuevos:** 8+
