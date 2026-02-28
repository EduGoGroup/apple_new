# Fase C — Resiliencia: Error Boundaries por Zona + Parallel Serialization

**Complejidad**: Media
**Archivos estimados**: ~8
**Prerequisitos**: Ninguno (independiente de Fase A y B)

---

## C1: Error Boundaries por Zona SDUI

**Origen**: KMP PR #15 — Error boundaries por zona SDUI con validación defensiva

**Qué hace**: Envolver cada zona en un boundary que captura errores de rendering, muestra un placeholder inline con opción de retry, y evita que una zona con error tumbe toda la pantalla.

### Problema actual

En apple_new, el `ErrorBoundary` existe solo a nivel de pantalla completa. Si un slot o zona falla al renderizar (datos malformados, tipo inesperado, etc.), la pantalla entera muestra error. En KMP, se implementó aislamiento por zona.

### Diseño en Swift/SwiftUI

#### ZoneErrorBoundary ViewModifier

```swift
struct ZoneErrorBoundary: ViewModifier {
    let zoneName: String
    @State private var hasError = false
    @State private var errorMessage: String?
    @State private var retryCount = 0

    func body(content: Content) -> some View {
        if hasError {
            // Placeholder inline con retry
            ZoneErrorPlaceholder(
                zoneName: zoneName,
                message: errorMessage,
                onRetry: { retryCount += 1; hasError = false }
            )
        } else {
            content
                .id(retryCount) // Force re-render on retry
        }
    }
}
```

#### Pre-validación de datos de zona

Antes de renderizar una zona, validar integridad de datos:
- Zona tiene slots válidos
- Slots tienen tipos de control conocidos
- Datos de binding resolvibles

Si la validación falla, el boundary muestra placeholder en vez de intentar renderizar.

#### Funciones defensivas en resolvers

Envolver accesos a datos JSON en SlotBindingResolver y PlaceholderResolver con do-catch:
- `resolveSlotValue()` → retorna fallback en caso de error
- `evaluateCondition()` → retorna `true` por defecto en caso de error
- `resolveFieldFromJSON()` → retorna `.null` en caso de error

### Pasos

1. **Crear `ZoneErrorBoundary`** (`Packages/Presentation/Sources/Components/ErrorHandling/ZoneErrorBoundary.swift`):
   - ViewModifier que captura errores de rendering
   - Placeholder inline con nombre de zona, mensaje de error, botón retry
   - `retryCount` como `.id()` para forzar re-render
   - Logging del error via Logger

2. **Crear `ZoneErrorPlaceholder`** (`Packages/Presentation/Sources/Components/ErrorHandling/ZoneErrorPlaceholder.swift`):
   - Vista compacta: icono de warning + "Error en zona {name}" + botón Reintentar
   - Estilo Liquid Glass subtle, no intrusivo

3. **Agregar pre-validación en `ZoneRenderer`** (`Apps/DemoApp/Sources/Renderers/ZoneRenderer.swift`):
   - `static func validateZone(_ zone: Zone, data: JSONValue?) -> String?`
   - Retorna nil si válida, mensaje de error si no
   - Envolver rendering de cada zona con `.modifier(ZoneErrorBoundary(zoneName:))`

4. **Hacer SlotBindingResolver defensivo** (`Packages/DynamicUI/Sources/DynamicUI/Resolver/SlotBindingResolver.swift`):
   - Envolver `resolve()` en do-catch, retornar fallback string en error
   - Log de warning cuando hay error de resolución

5. **Hacer PlaceholderResolver defensivo** (`Packages/DynamicUI/Sources/DynamicUI/Resolver/PlaceholderResolver.swift`):
   - Envolver resolución de tokens en do-catch
   - Si un token no se resuelve, dejarlo como está (no crash)

6. **Tests**:
   - Test que zona con datos malformados muestra placeholder (no crash)
   - Test que retry re-renderiza la zona
   - Test que otras zonas siguen funcionando cuando una falla
   - Test que SlotBindingResolver retorna fallback en error

### Archivos afectados
- `Packages/Presentation/Sources/Components/ErrorHandling/ZoneErrorBoundary.swift` (nuevo)
- `Packages/Presentation/Sources/Components/ErrorHandling/ZoneErrorPlaceholder.swift` (nuevo)
- `Apps/DemoApp/Sources/Renderers/ZoneRenderer.swift`
- `Packages/DynamicUI/Sources/DynamicUI/Resolver/SlotBindingResolver.swift`
- `Packages/DynamicUI/Sources/DynamicUI/Resolver/PlaceholderResolver.swift`
- `Packages/DynamicUI/Tests/DynamicUITests/Resolver/SlotBindingResolverTests.swift`

---

## C2: Parallel Serialization en LocalSyncStore y ScreenLoader

**Origen**: KMP PR #13/#14 — Optimize bundle load and save with parallel screen serialization

**Qué hace**: Paralelizar la serialización/deserialización de pantallas en `LocalSyncStore` y `ScreenLoader.seedFromBundle()` usando `withTaskGroup`, reduciendo tiempos de carga para bundles grandes (21+ pantallas).

### Problema actual

- `LocalSyncStore.save()` serializa el bundle completo en una sola operación secuencial
- `ScreenLoader.seedFromBundle()` itera secuencialmente por cada pantalla para encode/decode
- Con 21+ pantallas, esto puede tomar tiempo significativo

### Diseño en Swift

#### ScreenLoader.seedFromBundle() paralelo

```swift
func seedFromBundle(_ screens: [ScreenDefinition]) async {
    await withTaskGroup(of: (String, CacheEntry)?.self) { group in
        for screen in screens {
            group.addTask {
                // Encode/decode en parallel
                let entry = CacheEntry(screen: screen, timestamp: Date(), etag: nil)
                return (screen.screenKey, entry)
            }
        }
        for await result in group {
            if let (key, entry) = result {
                cache[key] = entry
            }
        }
    }
}
```

#### LocalSyncStore — Targeted bucket update paralelo

Para `updateBucket()`, cuando se procesan múltiples buckets cambiados en deltaSync, se puede paralelizar la deserialización:

```swift
// En SyncService.deltaSync()
await withTaskGroup(of: Void.self) { group in
    for (bucketName, bucketData) in response.changed {
        group.addTask {
            try await localStore.updateBucket(name: bucketName, data: bucketData.data, hash: bucketData.hash)
        }
    }
}
```

### Pasos

1. **Paralelizar `ScreenLoader.seedFromBundle()`** (`Packages/DynamicUI/Sources/DynamicUI/Loader/ScreenLoader.swift`):
   - Reemplazar loop secuencial con `withTaskGroup`
   - Cada screen se procesa en un child task
   - Resultados se recolectan y almacenan en cache

2. **Paralelizar bucket updates en `SyncService.deltaSync()`** (`Packages/Domain/Sources/Services/Sync/SyncService.swift`):
   - El loop `for (bucketName, bucketData) in response.changed` → `withTaskGroup`
   - Cada bucket se actualiza en parallel
   - Nota: `LocalSyncStore` es actor, así que las llamadas ya son thread-safe

3. **Tests**:
   - Test de performance: seedFromBundle con 20 screens mide tiempo
   - Test funcional: seedFromBundle produce mismo resultado que secuencial
   - Test que deltaSync con múltiples buckets los aplica todos correctamente

### Archivos afectados
- `Packages/DynamicUI/Sources/DynamicUI/Loader/ScreenLoader.swift`
- `Packages/Domain/Sources/Services/Sync/SyncService.swift`
- `Packages/DynamicUI/Tests/DynamicUITests/Loader/ScreenLoaderTests.swift`

---

## Verificación de Fase

```bash
make build
cd Packages/DynamicUI && swift test
cd Packages/Domain && swift test
make run
```

**Criterio de éxito**:
- Zona con datos malformados muestra placeholder inline (no crash de pantalla)
- Retry en zona con error re-renderiza correctamente
- Otras zonas no afectadas por error en una zona hermana
- seedFromBundle procesa screens en paralelo (verificar con logs de timing)
- 0 warnings, todos tests pasan
