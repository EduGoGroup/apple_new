# Foundation Toolkit SDK

**Estado de extraccion:** Listo (100% generico)
**Dependencias externas:** Ninguna (solo Foundation de Apple)
**Origen en proyecto:** `Packages/Foundation/Sources/` y `Packages/Core/Sources/Utilities/` y `Packages/Infrastructure/Sources/Storage/`

---

## a) Que hace este SDK

Coleccion de tipos base, protocolos y utilidades fundamentales para cualquier proyecto con arquitectura limpia. Proporciona:

### Protocolos base
- **Entity**: Protocolo base DDD que combina `Identifiable + Equatable + Sendable` con `id: UUID`, `createdAt`, `updatedAt`
- **UserContextProtocol**: Abstraccion para contexto de usuario autenticado (evita dependencias circulares)

### Jerarquia de errores por capa
- **RepositoryError**: Errores de capa de persistencia (fetchFailed, saveFailed, deleteFailed, connectionError, serializationError)
- **DomainError**: Errores de capa de dominio (validationFailed, businessRuleViolated, invalidOperation, entityNotFound)
- **UseCaseError**: Errores de capa de aplicacion con wrapping de errores inferiores (preconditionFailed, unauthorized, domainError, repositoryError, executionFailed, timeout)

### Utilidades
- **CodableSerializer**: Actor thread-safe para serialization JSON con configuraciones predefinidas (default, prettyPrinted, dtoCompatible) y estrategias ISO8601/snake_case
- **StorageManager**: Actor para persistencia local con API generica `Codable` (Keychain/UserDefaults)

### Uso tipico por el consumidor

```swift
// === Entity Protocol ===
struct MiEntidad: Entity {
    let id: UUID
    let createdAt: Date
    let updatedAt: Date
    let nombre: String
}

// === Errores tipados por capa ===
func obtenerUsuario(id: UUID) async throws -> Usuario {
    do {
        return try await repositorio.fetch(id: id)
    } catch let error as RepositoryError {
        throw UseCaseError.repositoryError(error)
    }
}

// === Serialization ===
let json = try await CodableSerializer.shared.encodeToString(miObjeto, prettyPrinted: true)
let decoded = try await CodableSerializer.shared.decode(MiTipo.self, from: jsonData)

// === Storage ===
try await StorageManager.shared.save(miToken, forKey: "auth_token")
let token = try await StorageManager.shared.retrieve(String.self, forKey: "auth_token")
```

---

## b) Compila como proyecto independiente?

**Si.** Todos los componentes solo dependen de `Foundation`:
- `Entity` - solo Foundation
- Errores (Repository, Domain, UseCase) - solo Foundation
- `UserContextProtocol` - solo Foundation
- `CodableSerializer` - solo Foundation (JSONEncoder/JSONDecoder)
- `StorageManager` - solo Foundation (UserDefaults, JSONEncoder/JSONDecoder)

---

## c) Dependencias si se extrae

| Dependencia | Tipo | Notas |
|---|---|---|
| Foundation | Sistema Apple | Unico requerimiento |

---

## d) Que se fusionaria con este SDK

Estos componentes actualmente estan dispersos en 3 paquetes diferentes:

| Componente | Ubicacion actual | Razon de fusion |
|---|---|---|
| Entity, UserContextProtocol | Packages/Foundation | Protocolos base |
| RepositoryError, DomainError, UseCaseError | Packages/Foundation | Errores por capa |
| CodableSerializer | Packages/Core/Utilities | Utilidad generica sin dependencias |
| StorageManager | Packages/Infrastructure/Storage | Utilidad generica sin dependencias |

Fusionarlos en un solo SDK "Foundation Toolkit" tiene sentido porque:
- Son todos TIER-0 (sin dependencias internas)
- Son las "piezas base" que cualquier proyecto necesita
- Juntos forman la capa de cimientos sobre la que se construye todo

---

## e) Interfaces publicas (contrato del SDK)

### Protocolos

```swift
public protocol Entity: Identifiable, Equatable, Sendable where ID == UUID {
    var id: UUID { get }
    var createdAt: Date { get }
    var updatedAt: Date { get }
}

public protocol UserContextProtocol: Sendable {
    var currentUserId: UUID? { get async }
    var isAuthenticated: Bool { get async }
    var currentUserEmail: String? { get async }
}
```

### Errores

```swift
public enum RepositoryError: Error, LocalizedError, Sendable {
    case fetchFailed(reason: String)
    case saveFailed(reason: String)
    case deleteFailed(reason: String)
    case connectionError(reason: String)
    case serializationError(type: String)
    case dataInconsistency(description: String)
}

public enum DomainError: Error, LocalizedError, Sendable, Equatable {
    case validationFailed(field: String, reason: String)
    case businessRuleViolated(rule: String)
    case invalidOperation(operation: String)
    case entityNotFound(type: String, id: String)
}

public enum UseCaseError: Error, LocalizedError, Sendable {
    case preconditionFailed(description: String)
    case unauthorized(action: String)
    case domainError(DomainError)
    case repositoryError(RepositoryError)
    case executionFailed(reason: String)
    case timeout
    var underlyingDomainError: DomainError? { get }
    var underlyingRepositoryError: RepositoryError? { get }
}
```

### Utilidades

```swift
public actor CodableSerializer {
    public static let shared: CodableSerializer
    public static let dtoSerializer: CodableSerializer
    public func encode<T: Encodable>(_ value: T, prettyPrinted: Bool) async throws -> Data
    public func encodeToString<T: Encodable>(_ value: T, prettyPrinted: Bool) async throws -> String
    public func decode<T: Decodable>(_ type: T.Type, from data: Data) async throws -> T
    public func decode<T: Decodable>(_ type: T.Type, from string: String) async throws -> T
    public init(configuration: SerializerConfiguration)
}

public actor StorageManager {
    public static let shared: StorageManager
    public func save<T: Encodable>(_ value: T, forKey key: String) throws
    public func retrieve<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T?
    public func remove(forKey key: String)
}
```

---

## f) Que necesita personalizar el consumidor

### Minimo (0 configuracion)

Todo funciona out-of-the-box. Los errores son genericos, los protocolos son estables, las utilidades tienen defaults razonables.

### Personalizaciones opcionales

1. **CodableSerializer**: Crear configuraciones custom con estrategias de encoding propias
2. **Errores**: Los mensajes estan en espanol (`LocalizedError`). Si se quiere i18n, localizar los `errorDescription`
3. **Entity**: Si no se quiere `UUID` como ID, se puede crear un protocolo similar con otro tipo

### Que se lleva tal cual vs que adapta

| Componente | Se lleva tal cual? | Adaptacion necesaria |
|---|---|---|
| Entity | Si | - |
| UserContextProtocol | Si | - |
| RepositoryError | Si | Opcional: traducir mensajes |
| DomainError | Si | Opcional: traducir mensajes |
| UseCaseError | Si | Opcional: traducir mensajes |
| CodableSerializer | Si | - |
| StorageManager | Si | - |

### Cambios necesarios para portabilidad

1. **Nada obligatorio**: Todo es generico y funcional
2. **Opcional**: Traducir mensajes de error de espanol a ingles (o hacerlos configurables)
3. **Opcional**: Eliminar referencia a "EduGo" en comentarios/copyright
