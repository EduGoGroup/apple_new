# Fase 2: Offline-First — NetworkObserver + MutationQueue + SyncEngine

## Objetivo
Implementar el sistema offline-first completo: detección de conectividad, cola de mutaciones para escrituras offline, y motor de sincronización con resolución de conflictos.

## Dependencias
- **Fase 0** completada (Auth + Sync Bundle)

## Contexto KMP (referencia)

### NetworkObserver en KMP
- Android: `ConnectivityManager` callback
- iOS: `NWPathMonitor` (lo que necesitamos)
- Desktop: HTTP polling cada 30s
- WasmJS: `navigator.onLine`

### MutationQueue en KMP
- Máximo 50 mutaciones pendientes
- Persistida en storage
- Deduplicación por endpoint + method + entityId
- Estados: PENDING → SYNCING → removed | FAILED | CONFLICTED

### SyncEngine en KMP
- Procesa cola al reconectar
- Exponential backoff: 1s, 2s, 4s
- ConflictResolver: last-write-wins, skip para entidades eliminadas
- Después de sync → invalidar cache de screens recientes → reload pantalla actual

---

## Pasos de Implementación

### Paso 2.1: NetworkObserver nativo (NWPathMonitor)

**Paquete**: `Packages/Infrastructure/Sources/Network/`

**Archivos a crear:**
- `Connectivity/NetworkObserver.swift`
- `Connectivity/NetworkStatus.swift`

**Requisitos:**
- `NetworkStatus`:
  ```swift
  enum NetworkStatus: Sendable {
      case available
      case unavailable
      case losing  // conexión degradándose
  }
  ```

- `actor NetworkObserver`:
  - Usa `NWPathMonitor` de `Network` framework (nativo Apple)
  - `var status: NetworkStatus` — estado actual
  - `var isOnline: Bool` — computed convenience
  - `var statusStream: AsyncStream<NetworkStatus>` — para observar cambios reactivamente
  - `start()` / `stop()` — lifecycle
  - Manejar correctamente el `DispatchQueue` del monitor sin `nonisolated`:
    - Crear un `Task` interno que reciba updates via continuation
    - El callback de NWPathMonitor envía al actor vía `Task { await self.updateStatus(...) }`
  - Logging de cambios de estado

**Nota**: No usar `nonisolated` para el callback de NWPathMonitor. En su lugar:
```swift
actor NetworkObserver {
    private var monitor: NWPathMonitor?
    private var monitorQueue = DispatchQueue(label: "network-observer")

    func start() {
        let monitor = NWPathMonitor()
        self.monitor = monitor
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            Task {
                await self.handlePathUpdate(path)
            }
        }
        monitor.start(queue: monitorQueue)
    }

    private func handlePathUpdate(_ path: NWPath) {
        // Actualizar status dentro del actor
    }
}
```

**Verificar:** `cd Packages/Infrastructure && swift test`

---

### Paso 2.2: MutationQueue persistente

**Paquete**: `Packages/Domain/Sources/`

**Archivos a crear:**
- `Services/Offline/PendingMutation.swift`
- `Services/Offline/MutationStatus.swift`
- `Services/Offline/MutationQueue.swift`

**Requisitos:**
- `PendingMutation`:
  ```swift
  struct PendingMutation: Codable, Sendable, Identifiable {
      let id: String  // UUID
      let endpoint: String
      let method: String  // POST, PUT, DELETE
      let body: JSONValue
      let createdAt: Date
      var retryCount: Int
      let maxRetries: Int  // default 3
      var status: MutationStatus
      let entityUpdatedAt: String?  // para conflict resolution
  }
  ```

- `MutationStatus`:
  ```swift
  enum MutationStatus: String, Codable, Sendable {
      case pending
      case syncing
      case failed
      case conflicted
  }
  ```

- `actor MutationQueue`:
  - `var pendingCount: Int` — número de mutaciones pendientes
  - `var pendingCountStream: AsyncStream<Int>` — observable
  - `func enqueue(_ mutation: PendingMutation)` — añadir mutación
  - `func dequeue() -> PendingMutation?` — obtener siguiente pendiente
  - `func markSyncing(id: String)` — marcar como sincronizando
  - `func markCompleted(id: String)` — remover de la cola
  - `func markFailed(id: String)` — marcar como fallido
  - `func markConflicted(id: String)` — marcar como conflicto
  - `func incrementRetry(id: String) -> Bool` — incrementar retry, retorna false si maxRetries alcanzado
  - `func allPending() -> [PendingMutation]` — obtener todas las pendientes
  - `func clear()` — limpiar cola
  - **Máximo 50 mutaciones** — si se excede, rechazar con error
  - **Deduplicación**: si ya existe una mutación con mismo endpoint + method + body → reemplazar la anterior
  - **Persistencia**: guardar/restaurar desde storage al inicio/fin

**Verificar:** `cd Packages/Domain && swift test`

---

### Paso 2.3: ConflictResolver

**Paquete**: `Packages/Domain/Sources/`

**Archivos a crear:**
- `Services/Offline/ConflictResolver.swift`
- `Services/Offline/ConflictResolution.swift`

**Requisitos:**
- `ConflictResolution`:
  ```swift
  enum ConflictResolution: Sendable {
      case applyLocal    // la mutación local gana
      case skipSilently  // ignorar (entidad eliminada en server)
      case retry         // reintentar más tarde
      case fail          // marcar como fallido permanentemente
  }
  ```

- `ConflictResolver`:
  - `static func resolve(mutation: PendingMutation, serverError: NetworkError) -> ConflictResolution`
  - Estrategia:
    - 404 Not Found → `.skipSilently` (entidad eliminada)
    - 409 Conflict → `.applyLocal` (last-write-wins por defecto)
    - 400 Bad Request → `.fail` (datos inválidos)
    - 5xx Server Error → `.retry`
    - Network timeout → `.retry`

**Verificar:** `cd Packages/Domain && swift test`

---

### Paso 2.4: SyncEngine

**Paquete**: `Packages/Domain/Sources/`

**Archivos a crear:**
- `Services/Offline/SyncEngine.swift`

**Requisitos:**
- `actor SyncEngine`:
  - Depende de: `MutationQueue`, `NetworkClientProtocol`, `ConflictResolver`
  - `var syncState: SyncState` — `.idle`, `.syncing(progress: Double)`, `.completed`, `.error(Error)`
  - `var syncStateStream: AsyncStream<SyncState>`
  - `func processQueue() async` — procesa todas las mutaciones pendientes:
    1. Tomar siguiente mutación pendiente
    2. Marcar como `.syncing`
    3. Enviar al servidor
    4. Si éxito → marcar completada, continuar
    5. Si error → `ConflictResolver.resolve()`:
       - `.applyLocal` → reintentar inmediato
       - `.skipSilently` → marcar completada (skip)
       - `.retry` → incrementar retryCount, si no alcanzó max → backoff, si sí → fail
       - `.fail` → marcar como failed
    6. Continuar con siguiente mutación
  - **Exponential backoff**: 1s, 2s, 4s entre reintentos
  - **Cancelación**: soportar `Task` cancellation para detener sync
  - Loggear cada operación (success/fail/skip)

**Verificar:** `cd Packages/Domain && swift test`

---

### Paso 2.5: ConnectivitySyncManager (orquestador)

**Paquete**: `Packages/Domain/Sources/`

**Archivos a crear:**
- `Services/Offline/ConnectivitySyncManager.swift`

**Requisitos:**
- `actor ConnectivitySyncManager`:
  - Observa `NetworkObserver.statusStream`
  - Al detectar `unavailable → available`:
    1. Trigger `SyncEngine.processQueue()` — enviar mutaciones offline
    2. Trigger `SyncService.deltaSync()` — actualizar datos
    3. Invalidar cache de screens visitados recientemente (últimos 5 min)
    4. Notificar a la UI para reload de la pantalla actual
  - Al detectar `available → unavailable`:
    1. Notificar UI (mostrar banner offline)
  - `var isOnline: Bool` — forwarded desde NetworkObserver
  - `var isOnlineStream: AsyncStream<Bool>` — para la UI

**Verificar:** `cd Packages/Domain && swift test`

---

### Paso 2.6: Integrar offline en DataLoader

**Paquete**: `Packages/DynamicUI/`

**Archivos a modificar:**
- `Loader/DataLoader.swift`

**Requisitos:**
- Nuevo parámetro: `isOnline: Bool`
- Estrategia de lectura:
  - Online: fetch from API → cache result → return
  - Offline: return from cache (si existe) → marcar como stale
- Nuevo método: `enqueueOfflineMutation(endpoint: String, method: String, body: JSONValue)` → delega a MutationQueue
- Retorno incluye flag `isStale: Bool`
- Si fetch falla estando online → try cache como fallback

**Verificar:** `cd Packages/DynamicUI && swift test`

---

### Paso 2.7: ConnectivityBanner UI

**Paquete**: `Packages/Presentation/Sources/`

**Archivos a crear:**
- `Components/Feedback/EduConnectivityBanner.swift`

**Requisitos:**
- Banner que aparece en la parte superior/inferior de la pantalla:
  - **Offline**: Fondo rojo/naranja, icono wifi.slash, texto "Sin conexión"
  - **Syncing**: Fondo azul, spinner, texto "Sincronizando..." + count de mutaciones pendientes
  - **Synced**: Fondo verde, checkmark, texto "Sincronizado" → auto-dismiss después de 3s
- Animación de entrada/salida con `.transition(.move(edge: .top))`
- Usa Liquid Glass effect para el fondo
- Recibe: `isOnline: Bool`, `pendingCount: Int`, `syncState: SyncState`

**Verificar:** `make build`

---

### Paso 2.8: Tests de Fase 2

**Archivos a crear:**
- `Packages/Infrastructure/Tests/Network/Connectivity/NetworkObserverTests.swift`
- `Packages/Domain/Tests/Services/Offline/MutationQueueTests.swift`
- `Packages/Domain/Tests/Services/Offline/ConflictResolverTests.swift`
- `Packages/Domain/Tests/Services/Offline/SyncEngineTests.swift`

**Requisitos mínimos:**
- NetworkObserver reporta cambios de estado
- MutationQueue: enqueue, dequeue, persistencia, deduplicación, límite de 50
- ConflictResolver: cada caso de error → resolución correcta
- SyncEngine: procesa cola, maneja conflictos, backoff exponencial

---

## Criterios de Completitud

- [ ] NetworkObserver detecta cambios online/offline con NWPathMonitor
- [ ] MutationQueue persiste mutaciones y soporta deduplicación
- [ ] SyncEngine procesa cola con exponential backoff
- [ ] ConflictResolver maneja 404, 409, 400, 5xx correctamente
- [ ] ConnectivitySyncManager orquesta reconexión (sync mutations + delta sync)
- [ ] DataLoader funciona offline con cache stale
- [ ] ConnectivityBanner muestra estado visual
- [ ] `make build` sin errores
- [ ] `make test` sin fallos
- [ ] Zero warnings de deprecación
