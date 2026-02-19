# Network SDK

**Estado de extraccion:** Casi listo (80% generico, 20% especifico de EduGo)
**Dependencias externas:** Ninguna (solo Foundation de Apple)
**Origen en proyecto:** `Packages/Infrastructure/Sources/Network/`

---

## a) Que hace este SDK

Cliente HTTP completo con interceptores, reintentos automaticos y autenticacion basada en tokens. Proporciona:

- **NetworkClient**: Cliente HTTP async/await con soporte GET/POST/PUT/DELETE/PATCH, upload y download
- **Sistema de interceptores**: Chain of Responsibility para modificar requests (logging, auth, retry)
- **Autenticacion automatica**: Inyeccion de Bearer token con refresh automatico y retry en 401
- **Politicas de retry**: Exponential backoff, linear, fixed delay - todas configurables
- **Tipos de respuesta genericos**: `APIResponse<T>`, `PaginatedResponse<T>`, `EmptyResponse`
- **Builder pattern**: Configuracion fluida del cliente

### Uso tipico por el consumidor

```swift
// 1. Crear cliente con interceptores
let client = NetworkClientBuilder()
    .withLogging(level: .debug)
    .withAuthentication(tokenProvider: miTokenProvider)
    .withRetry(policy: .standard)
    .build()

// 2. Hacer requests tipados
let usuarios: [UsuarioDTO] = try await client.get("https://api.miapp.com/usuarios")

// 3. POST con body
let nuevo: UsuarioDTO = try await client.post("https://api.miapp.com/usuarios", body: crearRequest)
```

---

## b) Compila como proyecto independiente?

**Casi.** Tiene una dependencia en `EduCore.CodableSerializer` que debe resolverse:

- `CodableSerializer.dtoSerializer` se usa para encoding/decoding JSON
- Solucion: incluir `CodableSerializer` dentro del SDK, o usar `JSONEncoder/JSONDecoder` estandar

Fuera de eso, solo usa `Foundation` (URLSession, Codable).

---

## c) Dependencias si se extrae

| Dependencia | Tipo | Notas |
|---|---|---|
| Foundation | Sistema Apple | URLSession, Codable, etc. |
| os (condicional) | Sistema Apple | Solo para LoggingInterceptor |
| CodableSerializer | Interna (extraer) | Actualmente en EduCore, copiar al SDK |

---

## d) Que se fusionaria con este SDK

**`CodableSerializer`** (actualmente en `Packages/Core/Sources/Utilities/`) deberia fusionarse dentro de este SDK o crearse como dependencia compartida.

Opcionalmente, **`StorageManager`** (Keychain wrapper) podria ir en el mismo SDK si se quiere un paquete de "infraestructura de red + almacenamiento seguro", ya que tokens se guardan en Keychain. Pero no es obligatorio.

---

## e) Interfaces publicas (contrato del SDK)

### Protocolos

```swift
public protocol NetworkClientProtocol: Sendable {
    func get<T: Decodable>(_ url: String, headers: [String: String]?) async throws -> T
    func post<T: Decodable, B: Encodable>(_ url: String, body: B?, headers: [String: String]?) async throws -> T
    func put<T: Decodable, B: Encodable>(_ url: String, body: B?, headers: [String: String]?) async throws -> T
    func delete(_ url: String, headers: [String: String]?) async throws
    func patch<T: Decodable, B: Encodable>(_ url: String, body: B?, headers: [String: String]?) async throws -> T
}

public protocol RequestInterceptor: Sendable {
    func intercept(_ request: URLRequest) async throws -> URLRequest
    func shouldRetry(_ error: Error, attempt: Int) async -> Bool
}

public protocol TokenProvider: Sendable {
    func getToken() async throws -> String
    func refreshToken() async throws -> String
}

public protocol RetryPolicy: Sendable {
    var maxRetries: Int { get }
    func delay(for attempt: Int) -> TimeInterval
    func shouldRetry(for error: Error) -> Bool
}
```

### Tipos principales

| Tipo | Rol |
|---|---|
| `NetworkClient` | Implementacion base del cliente HTTP |
| `InterceptableNetworkClient` | Cliente con cadena de interceptores |
| `NetworkClientBuilder` | Builder fluido para configurar el cliente |
| `HTTPRequest` | Builder de requests HTTP |
| `NetworkError` | Enum completo de errores de red |
| `AuthenticationInterceptor` | Interceptor de auth con token refresh |
| `LoggingInterceptor` | Interceptor de logging configurable |
| `RetryInterceptor` | Interceptor de reintentos |
| `ExponentialBackoffRetryPolicy` | Presets: aggressive, conservative, standard |
| `LinearBackoffRetryPolicy` | Backoff lineal |
| `FixedDelayRetryPolicy` | Delay fijo |
| `APIResponse<T>` | Wrapper generico con metadata |
| `PaginatedResponse<T>` | Respuestas paginadas |
| `EmptyResponse` | Para endpoints sin cuerpo |

---

## f) Que necesita personalizar el consumidor

### Implementar obligatoriamente

1. **`TokenProvider`**: Como obtener y refrescar tokens de autenticacion
```swift
actor MiTokenProvider: TokenProvider {
    func getToken() async throws -> String { /* leer del keychain */ }
    func refreshToken() async throws -> String { /* llamar endpoint refresh */ }
}
```

2. **Sus propios DTOs**: Structs `Codable` para las respuestas de su API
3. **Sus propios repositorios**: Clases que usen el `NetworkClient` para llamar sus endpoints

### Que se lleva tal cual vs que adapta

| Componente | Se lleva tal cual? | Adaptacion necesaria |
|---|---|---|
| NetworkClient + Protocol | Si | - |
| InterceptableNetworkClient | Si | - |
| NetworkClientBuilder | Si | - |
| HTTPRequest | Si | - |
| NetworkError | Si | - |
| AuthenticationInterceptor | Si | Proveer TokenProvider |
| LoggingInterceptor | Si | - |
| RetryPolicy (todas) | Si | - |
| APIResponse, PaginatedResponse | Si | - |
| MaterialsRepository | **No** | Especifico de EduGo |
| ProgressRepository | **No** | Especifico de EduGo |
| StatsRepository | **No** | Especifico de EduGo |
| Todos los DTOs (Material, Progress, Stats) | **No** | Especificos de EduGo |
| JSONValue | Si | Utilidad generica |

### Archivos a excluir del SDK

```
Network/
  Repositories/     <- TODO: especifico de EduGo (eliminar)
    MaterialsRepository.swift
    ProgressRepository.swift
    StatsRepository.swift
  DTOs/             <- TODO: especifico de EduGo (eliminar)
    MaterialDTO.swift
    ProgressDTO.swift
    StatsDTO.swift
```

### Cambios necesarios para portabilidad

1. **Eliminar repositorios y DTOs de EduGo**: Son implementaciones de negocio, no SDK
2. **Incluir CodableSerializer**: Copiar de Core/Utilities o reemplazar por JSONEncoder/JSONDecoder inline
3. **Opcional**: Remover dependencia condicional de `os.Logger` en `LoggingInterceptor` (o dejarlo, es del sistema)
