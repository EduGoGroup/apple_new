# Informe Performance — Mejoras Post-Migracion

## 1. Paginacion Infinita con Prefetch

### Estado actual

**DataLoader** (`Packages/DynamicUI/Sources/DynamicUI/Loader/DataLoader.swift`):
- `loadNextPage(endpoint:config:currentOffset:)` (lineas 128-136) — Recibe offset explicito del caller
- `buildRequest()` (lineas 191-209) — Agrega `limit` y `offset` como query params
- Cache por pagina: cada offset genera clave de cache diferente
- Offline: retorna cache stale si disponible, sin distincion de pagina

**ListPatternRenderer** (`Apps/DemoApp/Sources/Renderers/ListPatternRenderer.swift`):
- Lineas 89-95: `ProgressView` al final de la lista con `onAppear` que llama `viewModel.loadNextPage()`
- NO hay threshold de prefetch — espera a que ProgressView sea visible
- NO hay tracking de posicion de scroll

**DynamicScreenViewModel** (`Apps/DemoApp/Sources/ViewModels/DynamicScreenViewModel.swift`):
- `currentOffset: Int` (linea 31) — Manejado por ViewModel, incrementa por `pageSize`
- `loadNextPage()` (lineas 111-136):
  - Guard contra carga duplicada (`!loadingMore`)
  - Incrementa offset, llama DataLoader, agrega items
  - `hasMore` heuristic: `newItems.count >= pageSize`
- `loadData()` (lineas 90-109) — Reset offset a 0 en refresh

**DataConfig.PaginationConfig** (`Packages/DynamicUI/Sources/DynamicUI/Models/DataConfig.swift`):
- `pageSize: Int?` (default 20)
- `limitParam: String?`, `offsetParam: String?`, `pageParam: String?`
- `type: String?` — Declarado pero no usado (planeado para cursor/page)

**DataState** (`Packages/DynamicUI/Sources/DynamicUI/Models/ScreenState.swift`, lineas 46-52):
```swift
enum DataState: Sendable {
    case idle, loading
    case success(items: [[String: JSONValue]], hasMore: Bool, loadingMore: Bool)
    case error(String)
}
```

### Problema/oportunidad

| Problema | Impacto |
|----------|---------|
| No hay prefetch | Usuario ve spinner al final de cada pagina (300-1500ms delay) |
| `hasMore` heuristic | Si ultima pagina tiene exactamente `pageSize` items, pide pagina vacia innecesariamente |
| Cache per-page | Eviccion de pagina 1 cuando carga pagina 5 pierde datos ya vistos |
| Search no resetea offset | Paginacion despues de search usa offset incorrecto |
| No extrae metadata del servidor | `totalCount`, `totalPages`, `hasNextPage` ignorados |

### Solucion propuesta

Ver [spec-paginacion-prefetch.md](spec-paginacion-prefetch.md) para diseno tecnico detallado.

### Plan de trabajo

1. Crear `PrefetchCoordinator` en DynamicUI
2. Modificar `DataLoader` para soportar prefetch
3. Modificar `ListPatternRenderer` para detectar proximidad al final
4. Extraer metadata de paginacion del servidor (`totalCount`, `hasNextPage`)
5. Integrar con cache LRU y modo offline
6. Tests unitarios

**Complejidad:** MEDIA

### Tests requeridos

- Prefetch se dispara al acercarse al final (threshold configurable)
- No duplica requests si prefetch ya esta en vuelo
- Funciona offline con datos cacheados
- Search resetea paginacion correctamente
- `hasMore` usa metadata del servidor cuando esta disponible
- Cache consolida paginas (no evicta paginas intermedias)

### Dependencias

Ninguna.

---

## 2. Imagenes SVG / Optimizadas

### Estado actual

- `Apps/DemoApp/Sources/Renderers/Controls/DisplayControl.swift` (lineas 104-132)
  - `ImageControl` usa `AsyncImage` estandar de SwiftUI
  - NO hay cache de imagenes entre sesiones (solo cache HTTP de URLSession)
  - NO hay soporte SVG
  - NO hay optimizacion de tamano (resize, quality)
  - Error handling basico: placeholder `Image(systemName: "photo")` en fallo

- Iconos usan SF Symbols (sistema) — funcionan bien

### Problema/oportunidad

- AsyncImage no cachea entre sesiones de la app
- Imagenes se re-descargan cada vez que se abre la app
- No hay soporte para SVG (formato comun en dashboards y logos)
- No hay lazy loading inteligente (solo carga cuando view aparece)
- No hay resize a tamano necesario (descarga imagen full y escala en cliente)

### Solucion propuesta

**`ImageLoader` (actor) — Cache de imagenes nativo**

```swift
actor ImageLoader {
    private var memoryCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024  // 50MB
        return cache
    }()
    private var diskCachePath: URL

    func loadImage(url: URL, targetSize: CGSize? = nil) async throws -> UIImage {
        // 1. Check memory cache
        // 2. Check disk cache
        // 3. Download
        // 4. Resize if targetSize provided
        // 5. Cache in memory + disk
    }
}
```

**SVG Support (sin dependencias externas):**
- iOS 26/macOS 26 tienen soporte SVG nativo en `UIImage(data:)` para SVGs simples
- Para SVGs complejos, usar `WKWebView` render + snapshot (no ideal)
- Alternativa: convertir SVGs a PDF assets en build time

**Archivos a crear:**
- `Packages/Infrastructure/Sources/Storage/ImageLoader.swift` — Cache de imagenes
- `Packages/Presentation/Sources/Components/Media/CachedImage.swift` — View wrapper

**Archivos a modificar:**
- `Apps/DemoApp/Sources/Renderers/Controls/DisplayControl.swift` — Usar CachedImage en vez de AsyncImage

### Plan de trabajo

1. Crear `ImageLoader` actor con cache en memoria + disco
2. Implementar resize en descarga (para no almacenar imagenes oversized)
3. Crear `CachedImage` View como reemplazo de AsyncImage
4. Evaluar soporte SVG nativo de iOS 26 (puede ser suficiente)
5. Integrar en `DisplayControl.ImageControl`
6. Tests unitarios

**Complejidad:** MEDIA

### Tests requeridos

- Imagen se cachea en memoria despues de primer descarga
- Cache de disco persiste entre sesiones
- Imagen corrupta muestra placeholder
- targetSize resize funciona correctamente
- Cache memory limit se respeta (100 items, 50MB)
- Cache disk se limpia cuando supera limite

### Dependencias

- Evaluar soporte SVG nativo de iOS 26 antes de implementar solucion custom.
