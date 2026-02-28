# Problemas de Rendimiento

## REN-01: MEDIUM - LRU cache de ScreenLoader eviciona por insercion, no por acceso

**Archivo**: `Packages/DynamicUI/Sources/DynamicUI/Loader/ScreenLoader.swift:270-274`

**Descripcion**: La eviccion usa `cachedAt` (timestamp de insercion). Un LRU real deberia actualizar `lastAccessedAt` en cada cache hit. Un item frecuentemente accedido puede ser eviccionado si fue el primero insertado.

Ademas, la eviccion no limpia `bundleVersions` para la clave eviccionada.

**Recomendacion**: Agregar campo `lastAccessedAt` a `CachedScreen` y actualizarlo en hits.

---

## REN-02: MEDIUM - DataLoader cache sin limite de tamano

**Archivo**: `Packages/DynamicUI/Sources/DynamicUI/Loader/DataLoader.swift:31`

**Descripcion**: A diferencia de ScreenLoader (maxCacheSize: 20), DataLoader no tiene limite. El diccionario puede crecer indefinidamente. `invalidateCache(olderThan:)` existe pero no se llama automaticamente.

**Recomendacion**: Agregar `maxCacheSize` o invocar invalidation periodicamente.

---

## REN-03: LOW - AuthContext.permissions usa [String] en vez de Set<String>

**Archivo**: `Packages/Core/Sources/Models/Domain/AuthContext.swift`

`.contains()` es O(n) en arrays. `Set<String>` daria O(1). Negligible con < 50 permisos actuales.

---

## REN-04: LOW - DateFormatter creado por invocacion en PlaceholderResolver

**Archivo**: `Packages/DynamicUI/Sources/DynamicUI/Resolvers/PlaceholderResolver.swift:76`

**Fix**: Usar `private static let dateFormatter`.

---

## REN-05: LOW - DateFormatter creado por invocacion en DocumentMapper

**Archivo**: `Packages/Core/Sources/Models/Mappers/DocumentMapper.swift`

Intencional para concurrency safety. Aceptable.

---

## REN-06: LOW - PlaceholderResolver multiples pasadas de string replacement

**Archivo**: `Packages/DynamicUI/Sources/DynamicUI/Resolvers/PlaceholderResolver.swift:59-92`

Minimo 9 pasadas por invocacion. Insignificante para strings cortos de UI.

---

## REN-07: LOW - seedFromBundle encode/decode roundtrip

**Archivo**: `Packages/DynamicUI/Sources/DynamicUI/Loader/ScreenLoader.swift:69-75`

JSONValue -> Data -> ScreenTemplate roundtrip. Necesario por tipos genericos. Se ejecuta en paralelo con `withTaskGroup`.
