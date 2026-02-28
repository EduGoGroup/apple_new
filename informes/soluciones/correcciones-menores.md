# Correcciones Menores (Fase 2 - Automatizables)

Estas correcciones son seguras de aplicar automaticamente ya que no cambian logica de negocio, no afectan APIs publicas significativamente, y son cambios localizados.

---

## Lista de Correcciones

### 1. Eliminar typealias DynamicJSONValue no usado
**Archivo**: `Packages/DynamicUI/Sources/DynamicUI/Loader/DataLoader.swift:7`
**Cambio**: Eliminar `public typealias DynamicJSONValue = EduModels.JSONValue`

### 2. Eliminar metodo describeDecodingError muerto
**Archivos**:
- `Packages/Infrastructure/Sources/Network/Network.swift:488-501`
- `modulos/NetworkSDK/Sources/NetworkSDK/Network.swift:488-501`
**Cambio**: Eliminar el metodo no utilizado

### 3. Optimizar DateFormatter en PlaceholderResolver
**Archivo**: `Packages/DynamicUI/Sources/DynamicUI/Resolvers/PlaceholderResolver.swift:76`
**Cambio**: Cambiar a `private static let dateFormatter`

### 4. Eliminar duplicacion TTL en ScreenLoader
**Archivo**: `Packages/DynamicUI/Sources/DynamicUI/Loader/ScreenLoader.swift:122-134`
**Cambio**: Instance method delega al static: `Self.effectiveTTLStatic(for: pattern, defaultTTL: defaultTTL)`

### 5. Agregar Equatable a UseCaseError
**Archivo**: `Packages/Foundation/Sources/EduFoundation/Errors/UseCaseError.swift`
**Cambio**: Agregar extension con Equatable conformance

### 6. Simplificar RepositoryError Equatable (sintetizable)
**Archivo**: `Packages/Foundation/Sources/EduFoundation/Errors/RepositoryError.swift`
**Cambio**: Eliminar extension manual de Equatable, dejar que el compilador sintetice

### 7. Fix CircuitBreaker: no contar CancellationError como falla
**Archivo**: `Packages/Infrastructure/Sources/Network/Resilience/CircuitBreaker.swift:106-109`
**Cambio**: Agregar `if !(error is CancellationError)` antes de `recordFailure()`

### 8. Agregar issuedAt a StoredAuthToken
**Archivo**: `Packages/Infrastructure/Sources/Network/DTOs/AuthDTO.swift:84-100`
**Cambio**: Agregar `public let issuedAt: Date` con default `Date()` y computed `isExpired`

### 9. Agregar CodingKeys snake_case a PaginatedResponse
**Archivo**: `Packages/Infrastructure/Sources/Network/NetworkClientProtocol.swift:217-248`
**Cambio**: Agregar CodingKeys enum con snake_case mapping

### 10. Fix make test para ejecutar por paquete
**Archivo**: `Makefile`
**Cambio**: Loop por cada paquete en Packages/

### 11. Eliminar tests cosmeticos placeholder
**Archivos**:
- `Packages/Domain/Tests/DomainTests/DomainTests.swift`
- `Packages/Presentation/Tests/PresentationTests/PresentationTests.swift`
- `Packages/Features/Tests/FeaturesTests/FeaturesTests.swift`
**Cambio**: Reemplazar `#expect(true)` con tests que validen algo real, o eliminar si estan cubiertos por otros tests

---

## Criterios de Aplicacion

- Solo se aplican correcciones que NO cambian logica de negocio
- NO se tocan proyectos compartidos (backend, shared, infraestructura)
- Se valida compilacion con `make build` despues de cada grupo de cambios
- Se valida que tests pasen despues de los cambios
- NO se hace commit
