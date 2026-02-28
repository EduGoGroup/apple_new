# Errores Logicos y de Implementacion

## EL-01: MEDIUM - CircuitBreaker cuenta CancellationError como falla

**Archivo**: `Packages/Infrastructure/Sources/Network/Resilience/CircuitBreaker.swift:106-109`

**Descripcion**: Todo error (incluyendo `CancellationError`) cuenta como falla del circuit breaker. Una task cancelada NO deberia abrir el circuito.

**Fix**:
```swift
} catch {
    if !(error is CancellationError) {
        recordFailure()
    }
    throw error
}
```

---

## EL-02: MEDIUM - Unknown ControlType/ScreenPattern causa fallo total de decodificacion

**Archivos**:
- `Packages/DynamicUI/Sources/DynamicUI/Models/ControlType.swift`
- `Packages/DynamicUI/Sources/DynamicUI/Models/ScreenPattern.swift`
- `Packages/DynamicUI/Sources/DynamicUI/Models/ActionDefinition.swift` (ActionTrigger, ActionType)

**Descripcion**: Todos son enums cerrados. Si el backend agrega un nuevo tipo, el cliente falla en decodificar toda la pantalla. Una actualizacion del backend rompe clientes no actualizados.

**Ver solucion**: [Resiliencia DynamicUI](../soluciones/resiliencia-dynamicui.md)

---

## EL-03: MEDIUM - AuthenticationInterceptor: race condition en refresh concurrente

**Archivo**: `Packages/Infrastructure/Sources/Network/Interceptors/AuthenticationInterceptor.swift:186-197`

**Descripcion**: `refreshTask = nil` se ejecuta inmediatamente despues del primer refresh. Si otro request llega justo despues del `await` y antes de que se setee nil, empezara un NUEVO refresh innecesario. Multiples refreshes en rapida sucesion.

---

## EL-04: MEDIUM - URL concatenation puede generar doble slash

**Archivos**:
- `Packages/DynamicUI/Sources/DynamicUI/Loader/DataLoader.swift:168`
- `Packages/DynamicUI/Sources/DynamicUI/Loader/ScreenLoader.swift:168,228`

**Descripcion**: `baseURL + path` sin sanitizacion. Si baseURL termina en `/` y path empieza con `/`, resulta en `https://api.test//api/v1/...`.

---

## EL-05: LOW - 304 Not Modified con cache eviccionado causa error

**Archivo**: `Packages/DynamicUI/Sources/DynamicUI/Loader/ScreenLoader.swift:178-193`

**Descripcion**: Si el servidor devuelve 304 pero el cache fue eviccionado (LRU), `memoryCache[key]` es nil. El codigo intenta parsear el body vacio del 304 como ScreenDefinition, causando error de decodificacion.

**Impacto**: Race condition improbable. ETag se limpia con la eviccion.

---

## EL-06: LOW - safeReplace en PlaceholderResolver: falso positivo en log

**Archivo**: `Packages/DynamicUI/Sources/DynamicUI/Resolvers/PlaceholderResolver.swift:97-104`

Si `replacement` es identico al `token`, se loggea un error falso.

---

## EL-07: LOW - RateLimiter.availableRequests no limpia timestamps internos

**Archivo**: `Packages/Infrastructure/Sources/Network/Resilience/RateLimiter.swift:71-76`

Computed property crea copia local y limpia la copia, no los timestamps reales. Funcionalmente correcto ya que los reales se limpian en `acquire()`/`tryAcquire()`.
