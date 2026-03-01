# Spec: Paginacion Infinita con Prefetch

> Cargar la siguiente pagina anticipadamente cuando el usuario se acerca al final de la lista visible.

## Contexto

El sistema actual usa paginacion offset-based con un patron "Load More": un `ProgressView` al final de la lista dispara `loadNextPage()` cuando es visible. Esto causa un delay perceptible (300-1500ms) cada vez que el usuario llega al final.

## Analisis del Codigo Actual

### DataLoader

**`Packages/DynamicUI/Sources/DynamicUI/Loader/DataLoader.swift`:**
- `loadNextPage(endpoint:config:currentOffset:)` (lineas 128-136) — Recibe offset del caller
- `buildRequest()` (lineas 191-209) — Construye HTTP con `limit` y `offset` params
- Cache: clave = endpoint + params, eviccion por timestamp (no LRU real para datos)
- `maxCacheSize` default 50 entries

### ListPatternRenderer

**`Apps/DemoApp/Sources/Renderers/ListPatternRenderer.swift`:**
- Lineas 89-95: `ProgressView` con `onAppear` al final de la lista
- NO hay threshold de prefetch
- NO hay scroll position tracking
- Usa `ForEach(Array(filteredItems.enumerated()), id: \.offset)`

### DynamicScreenViewModel

**`Apps/DemoApp/Sources/ViewModels/DynamicScreenViewModel.swift`:**
- `currentOffset: Int` (linea 31) — Gestionado por ViewModel
- `loadNextPage()` (lineas 111-136):
  - Guard `!loadingMore` para evitar duplicados
  - Incrementa offset por pageSize
  - `hasMore`: heuristic `newItems.count >= pageSize`
- `loadData()` (lineas 90-109) — Reset offset a 0

### DataState

**`Packages/DynamicUI/Sources/DynamicUI/Models/ScreenState.swift:46-52`:**
```swift
enum DataState: Sendable {
    case idle, loading
    case success(items: [[String: JSONValue]], hasMore: Bool, loadingMore: Bool)
    case error(String)
}
```

### PaginationConfig

**`Packages/DynamicUI/Sources/DynamicUI/Models/DataConfig.swift`:**
- `pageSize: Int?` (default 20)
- `limitParam: String?`, `offsetParam: String?`
- `type: String?` — No usado

### Problemas identificados

1. **No prefetch** — Espera a que ProgressView sea visible
2. **hasMore heuristic** — `items.count >= pageSize` falla si ultima pagina tiene exactamente pageSize items
3. **Search no resetea offset** — Bug: paginacion despues de search usa offset incorrecto
4. **No extrae metadata del servidor** — `totalCount`, `hasNextPage` ignorados

## Diseno Tecnico

### 1. PrefetchCoordinator

**Ubicacion:** `Packages/DynamicUI/Sources/DynamicUI/Loader/PrefetchCoordinator.swift`

```swift
public actor PrefetchCoordinator {

    public struct PrefetchConfig: Sendable {
        public let prefetchThreshold: Int  // Items antes del final para disparar prefetch
        public let maxConcurrentPrefetches: Int  // Max prefetches simultaneos

        public static let `default` = PrefetchConfig(
            prefetchThreshold: 5,
            maxConcurrentPrefetches: 1
        )
    }

    private let config: PrefetchConfig
    private var prefetchTask: Task<Void, Never>?
    private var isPrefetching: Bool = false
    private var prefetchedData: [[String: JSONValue]]?  // Datos pre-cargados

    public init(config: PrefetchConfig = .default) {
        self.config = config
    }

    /// Evalua si debe disparar prefetch basado en posicion del item visible
    public func evaluatePrefetch(
        visibleIndex: Int,
        totalItems: Int,
        hasMore: Bool,
        loadAction: @Sendable @escaping () async throws -> [[String: JSONValue]]
    ) {
        let remainingItems = totalItems - visibleIndex - 1

        guard hasMore,
              !isPrefetching,
              prefetchedData == nil,
              remainingItems <= config.prefetchThreshold else { return }

        isPrefetching = true
        prefetchTask = Task {
            do {
                let newItems = try await loadAction()
                self.prefetchedData = newItems
            } catch {
                // Prefetch fallo silenciosamente — se reintentara
            }
            self.isPrefetching = false
        }
    }

    /// Consume datos pre-cargados (retorna nil si no hay)
    public func consumePrefetchedData() -> [[String: JSONValue]]? {
        let data = prefetchedData
        prefetchedData = nil
        return data
    }

    /// Cancela prefetch en vuelo (ej: al cambiar de pantalla)
    public func cancelPrefetch() {
        prefetchTask?.cancel()
        prefetchTask = nil
        isPrefetching = false
        prefetchedData = nil
    }

    /// Estado actual
    public func isPrefetchInProgress() -> Bool {
        isPrefetching
    }
}
```

### 2. Modificar DataLoader

**Archivo:** `Packages/DynamicUI/Sources/DynamicUI/Loader/DataLoader.swift`

Agregar extraccion de metadata del servidor:

```swift
/// Resultado de carga con metadata de paginacion
public struct PaginatedResult: Sendable {
    public let items: [[String: JSONValue]]
    public let totalCount: Int?
    public let hasNextPage: Bool
    public let currentOffset: Int
}

/// loadNextPage mejorado que extrae metadata
public func loadNextPageWithMetadata(
    endpoint: String,
    config: DataConfig?,
    currentOffset: Int
) async throws -> PaginatedResult {
    let raw = try await loadNextPage(endpoint: endpoint, config: config, currentOffset: currentOffset)
    let items = extractItems(from: raw)
    let pageSize = config?.pagination?.pageSize ?? 20

    // Extraer metadata del servidor si disponible
    let totalCount = extractTotalCount(from: raw)
    let serverHasMore = extractHasMore(from: raw)

    // Usar metadata del servidor si disponible, si no, heuristic
    let hasNextPage = serverHasMore ?? (items.count >= pageSize)

    return PaginatedResult(
        items: items,
        totalCount: totalCount,
        hasNextPage: hasNextPage,
        currentOffset: currentOffset
    )
}

/// Extrae totalCount del response
private func extractTotalCount(from raw: [String: JSONValue]) -> Int? {
    // Buscar en campos comunes: total, totalCount, total_count, meta.total
    for key in ["total", "totalCount", "total_count", "count"] {
        if case .integer(let count) = raw[key] { return count }
    }
    // Buscar en meta object
    if case .object(let meta) = raw["meta"],
       case .integer(let total) = meta["total"] {
        return total
    }
    return nil
}

/// Extrae hasMore/hasNextPage del response
private func extractHasMore(from raw: [String: JSONValue]) -> Bool? {
    for key in ["hasMore", "has_more", "hasNextPage", "has_next_page"] {
        if case .bool(let value) = raw[key] { return value }
    }
    if case .object(let meta) = raw["meta"],
       case .bool(let hasMore) = meta["has_more"] {
        return hasMore
    }
    return nil
}
```

### 3. Modificar ListPatternRenderer

**Archivo:** `Apps/DemoApp/Sources/Renderers/ListPatternRenderer.swift`

Reemplazar el patron ProgressView+onAppear por prefetch basado en proximidad:

```swift
@ViewBuilder
private func listContent(
    items: [[String: JSONValue]],
    hasMore: Bool,
    loadingMore: Bool
) -> some View {
    List {
        if let searchable = ... {
            searchSection
        }

        ForEach(Array(filteredItems.enumerated()), id: \.offset) { index, item in
            itemRow(item: item)
                .onTapGesture {
                    Task {
                        await viewModel.executeEvent(.selectItem, selectedItem: item)
                    }
                }
                .onAppear {
                    // Prefetch: evaluar si estamos cerca del final
                    viewModel.evaluatePrefetch(visibleIndex: index, totalItems: filteredItems.count)
                }
        }

        // Skeleton items al final mientras carga
        if loadingMore {
            ForEach(0..<3, id: \.self) { _ in
                skeletonRow
            }
        }
    }
    .listStyle(.plain)
}

@ViewBuilder
private var skeletonRow: some View {
    HStack {
        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
            .fill(.quaternary)
            .frame(width: 40, height: 40)
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                .fill(.quaternary)
                .frame(height: 14)
                .frame(maxWidth: 200)
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                .fill(.quaternary)
                .frame(height: 12)
                .frame(maxWidth: 140)
        }
    }
    .padding(.vertical, DesignTokens.Spacing.small)
    .redacted(reason: .placeholder)
}
```

### 4. Modificar DynamicScreenViewModel

**Archivo:** `Apps/DemoApp/Sources/ViewModels/DynamicScreenViewModel.swift`

```swift
// Nueva propiedad
private var prefetchCoordinator: PrefetchCoordinator?

// Inicializar en init o loadScreen
func setupPrefetch() {
    prefetchCoordinator = PrefetchCoordinator()
}

// Metodo llamado desde ListPatternRenderer.onAppear
func evaluatePrefetch(visibleIndex: Int, totalItems: Int) {
    guard case .success(_, let hasMore, let loadingMore) = dataState,
          hasMore, !loadingMore else { return }

    Task {
        await prefetchCoordinator?.evaluatePrefetch(
            visibleIndex: visibleIndex,
            totalItems: totalItems,
            hasMore: hasMore,
            loadAction: { [weak self] in
                guard let self else { return [] }
                return try await self.performPrefetch()
            }
        )
    }
}

// Ejecuta la carga de la siguiente pagina
private func performPrefetch() async throws -> [[String: JSONValue]] {
    guard case .ready(let screen) = screenState,
          let endpoint = screen.dataEndpoint else { return [] }

    let pageSize = screen.dataConfig?.pagination?.pageSize ?? 20
    let nextOffset = currentOffset + pageSize

    let result = try await dataLoader.loadNextPageWithMetadata(
        endpoint: endpoint,
        config: screen.dataConfig,
        currentOffset: nextOffset
    )
    return result.items
}

// loadNextPage mejorado — consume prefetch si disponible
func loadNextPage() async {
    guard case .success(let items, let hasMore, let loadingMore) = dataState,
          hasMore, !loadingMore else { return }
    guard case .ready(let screen) = screenState,
          let endpoint = screen.dataEndpoint else { return }

    dataState = .success(items: items, hasMore: hasMore, loadingMore: true)
    let pageSize = screen.dataConfig?.pagination?.pageSize ?? 20
    currentOffset += pageSize

    do {
        // Intentar consumir datos pre-cargados
        if let prefetched = await prefetchCoordinator?.consumePrefetchedData() {
            let newHasMore = prefetched.count >= pageSize
            dataState = .success(items: items + prefetched, hasMore: newHasMore, loadingMore: false)
            return
        }

        // Si no hay prefetch, cargar normalmente
        let result = try await dataLoader.loadNextPageWithMetadata(
            endpoint: endpoint,
            config: screen.dataConfig,
            currentOffset: currentOffset
        )
        dataState = .success(
            items: items + result.items,
            hasMore: result.hasNextPage,
            loadingMore: false
        )
    } catch {
        dataState = .success(items: items, hasMore: false, loadingMore: false)
    }
}

// Fix: resetear offset en search
func executeSearch(query: String) async {
    searchQuery = query
    currentOffset = 0  // Reset pagination on search
    await prefetchCoordinator?.cancelPrefetch()
    await executeEvent(.search)
}
```

### 5. Interaccion con Cache LRU

El prefetch se integra con el cache existente de DataLoader:
- Datos prefetched se cachean automaticamente (misma clave endpoint+offset)
- Si el usuario no llega a la siguiente pagina, los datos quedan en cache para uso futuro
- Si el cache se llena, la eviccion normal aplica

### 6. Interaccion con Modo Offline

```
ONLINE:
  User scrolls list
  -> visibleIndex cerca del final (threshold 5)
  -> PrefetchCoordinator: start prefetch
  -> DataLoader: HTTP GET page N+1
  -> Datos llegan antes de que user llegue al final
  -> User llega al final: datos disponibles inmediatamente (0ms)

OFFLINE:
  -> PrefetchCoordinator: start prefetch
  -> DataLoader: detecta isOnline=false
  -> Retorna cache stale si disponible
  -> Si no hay cache: prefetch falla silenciosamente
  -> User llega al final: sin datos nuevos, hasMore=false
```

### 7. Flujo Completo

```
Pagina 1 cargada (20 items)
  User ve items 1-10

User scrolls a item 15 (5 items antes del final)
  -> onAppear(index: 14)
  -> evaluatePrefetch(visibleIndex: 14, totalItems: 20)
  -> remainingItems = 20 - 14 - 1 = 5 <= threshold(5)
  -> PrefetchCoordinator dispara loadAction()
  -> DataLoader: GET /api/v1/items?limit=20&offset=20
  -> Respuesta llega en background

User scrolls a item 20 (final)
  -> loadNextPage()
  -> consumePrefetchedData() retorna items pre-cargados
  -> dataState actualizado con items 1-40 inmediatamente (0ms delay)
  -> PrefetchCoordinator listo para siguiente ciclo

User scrolls a item 35 (5 antes del nuevo final)
  -> Mismo ciclo: prefetch de pagina 3
```

## Archivos a Crear

| Archivo | Paquete | Descripcion |
|---------|---------|-------------|
| `PrefetchCoordinator.swift` | DynamicUI | Actor que coordina prefetch |

## Archivos a Modificar

| Archivo | Cambio |
|---------|--------|
| `Packages/DynamicUI/Sources/DynamicUI/Loader/DataLoader.swift` | Agregar `loadNextPageWithMetadata()`, extractores de metadata |
| `Apps/DemoApp/Sources/Renderers/ListPatternRenderer.swift` | Prefetch via onAppear, skeleton rows |
| `Apps/DemoApp/Sources/ViewModels/DynamicScreenViewModel.swift` | PrefetchCoordinator, consumo de prefetch, search fix |

## Tests Requeridos

| Test | Descripcion |
|------|-------------|
| `testPrefetchTriggersAtThreshold` | Prefetch se dispara cuando remainingItems <= threshold |
| `testPrefetchDoesNotDuplicate` | No dispara prefetch si ya hay uno en vuelo |
| `testConsumedPrefetchReturnsData` | consumePrefetchedData retorna datos pre-cargados |
| `testConsumedPrefetchClearsBuffer` | Despues de consumir, buffer queda nil |
| `testCancelStopsPrefetch` | cancelPrefetch detiene task en vuelo |
| `testSearchResetsOffset` | Search resetea currentOffset a 0 |
| `testExtractTotalCount` | Extrae totalCount de diferentes formatos de API |
| `testExtractHasMore` | Extrae hasMore de diferentes formatos de API |
| `testOfflinePrefetchFailsSilently` | Sin red, prefetch falla sin error |
| `testSkeletonRowsDuringLoad` | Skeleton items se muestran durante carga |

## Estimacion

- **Complejidad:** MEDIA
- **Archivos nuevos:** 1
- **Archivos modificados:** 3
- **Tests nuevos:** 10+
