# Problemas de Calidad de Codigo

## CAL-01: CRITICAL - NetworkClientBuilder @unchecked Sendable con estado mutable

**Archivo**: `Packages/Infrastructure/Sources/Network/Interceptors/InterceptableNetworkClient.swift:404-464`

**Descripcion**: `NetworkClientBuilder` es `final class` con estado mutable (`interceptors`, `retryPolicy`, `maxRetryTimeout`, `configuration`) marcado `@unchecked Sendable`. Si se comparte entre tasks antes de `build()`, data races ocurriran.

**Recomendacion**: Hacerlo `actor`, o remover `@unchecked Sendable` (los builders se usan en contexto unico), o convertir a `struct` con mutating methods.

---

## CAL-02: CRITICAL - DesignSystemSDK usa NotificationCenter.default.addObserver (prohibido)

**Archivos**:
- `modulos/DesignSystemSDK/Sources/DesignSystemSDK/Accessibility/Preferences/AccessibilityPreferences.swift:101-144`
- `modulos/DesignSystemSDK/Sources/DesignSystemSDK/Accessibility/Contrast/HighContrastSupport.swift:199`
- `modulos/DesignSystemSDK/Sources/DesignSystemSDK/Accessibility/Motion/ReducedMotionSupport.swift:136`

**Recomendacion**: Reemplazar con `@Environment` de SwiftUI o `AsyncStream`.

---

## CAL-03: HIGH - InterceptableNetworkClient.init muta URLSessionConfiguration pasada

**Archivo**: `Packages/Infrastructure/Sources/Network/Interceptors/InterceptableNetworkClient.swift:81-88`

**Descripcion**: `URLSessionConfiguration` es reference type. Mutar el parametro modifica el original del caller silenciosamente.

**Fix**: `let config = configuration.copy() as! URLSessionConfiguration`

---

## CAL-04: HIGH - StatePublisher.stream: problema de consumidor unico

**Archivos**:
- `modulos/CQRSKit/Sources/CQRSKit/StateManagement/Core/StatePublisher.swift:50-59`
- `Packages/Infrastructure/Sources/Network/Connectivity/NetworkObserver.swift:45-54`

**Descripcion**: `AsyncStream` solo puede ser iterado por UN consumidor. Si `stream` se accede multiples veces, solo un consumidor recibe cada valor.

---

## CAL-05: HIGH - StoredAuthToken sin tracking de expiracion

**Archivo**: `Packages/Infrastructure/Sources/Network/DTOs/AuthDTO.swift:84-100`

**Descripcion**: `expiresIn` es duracion (segundos), pero no hay `issuedAt: Date`. Al restaurar desde storage, es imposible saber si el token esta expirado.

**Fix**: Agregar `issuedAt: Date` para calcular `expirationDate = issuedAt + expiresIn`.

---

## CAL-06: MEDIUM - force_cast para EmptyResponse

**Archivos**: `Network.swift:188` (Infrastructure y NetworkSDK)

`return EmptyResponse() as! T` - guardado por `T.self == EmptyResponse.self` pero force cast es code smell.

---

## CAL-07: MEDIUM - PersistenceContainerProvider.perform closure sin @Sendable

**Archivo**: `Packages/Infrastructure/Sources/Persistence/Container/PersistenceContainerProvider.swift:106-119`

---

## CAL-08: MEDIUM - StorageManager usa JSONEncoder/Decoder default (sin ISO8601)

**Archivo**: `Packages/Infrastructure/Sources/Storage/Storage.swift:17-28`

Si almacena DTOs con `Date`, usara format Double en vez de ISO8601.

---

## CAL-09: MEDIUM - UseCaseError sin conformancia Equatable

**Archivo**: `Packages/Foundation/Sources/EduFoundation/Errors/UseCaseError.swift`

DomainError y RepositoryError tienen Equatable, pero UseCaseError no. Rompe simetria.

---

## CAL-10: LOW - DynamicJSONValue typealias no usado

**Archivo**: `Packages/DynamicUI/Sources/DynamicUI/Loader/DataLoader.swift:7`

Codigo muerto: `public typealias DynamicJSONValue = EduModels.JSONValue` nunca se usa.

---

## CAL-11: LOW - describeDecodingError metodo muerto

**Archivos**: `Network.swift:488-501` (Infrastructure y NetworkSDK)

Metodo nunca llamado.

---

## CAL-12: LOW - NetworkClient.shared singleton con 0 interceptors

**Archivo**: `Packages/Infrastructure/Sources/Network/Network.swift:40-43`

Puede confundir a desarrolladores. El patron correcto es `ServiceContainer`.

---

## CAL-13: LOW - PaginatedResponse/APIResponse sin CodingKeys snake_case

**Archivo**: `Packages/Infrastructure/Sources/Network/NetworkClientProtocol.swift:217-248`

`totalCount`, `pageSize` no decodificarian correctamente si el backend envia `total_count`.

---

## CAL-14: LOW - RepositoryError Equatable manual (sintetizable)

**Archivo**: `Packages/Foundation/Sources/EduFoundation/Errors/RepositoryError.swift`

Todos los associated values son String (Equatable). El compilador puede sintetizar.

---

## CAL-15: LOW - Archivos placeholder EduFoundation.swift y EduCore.swift

Solo contienen `version = "1.0.0"`. Inofensivos.
