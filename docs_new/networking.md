# Networking y Resiliencia — EduGo Apple

> Documentacion generada desde analisis directo del codigo fuente (marzo 2026).

---

## 1. Vision General

El modulo de networking (`EduNetwork`) esta en `Packages/Infrastructure/Sources/Network/`. Toda la capa de red esta construida con **actors** para thread-safety y usa **async/await** exclusivamente.

---

## 2. NetworkClient

**Archivo:** `Packages/Infrastructure/Sources/Network/NetworkClient.swift`

Actor principal para operaciones HTTP:

```swift
public actor NetworkClient: NetworkClientProtocol {
    public func request<T: Decodable & Sendable>(_ request: HTTPRequest) async throws -> T
    public func requestData(_ request: HTTPRequest) async throws -> Data
    public func upload(_ request: HTTPRequest) async throws -> UploadResponse
    public func download(_ request: HTTPRequest) async throws -> Data
}
```

| Propiedad | Valor |
|-----------|-------|
| Tipo | `actor` (thread-safe) |
| Timeout request | 30s |
| Timeout resource | 60s |
| URLSession | `waitsForConnectivity: true` |
| Serializacion | `CodableSerializer.dtoSerializer` |
| Headers globales | Bearer token, Content-Type |

### Dos instancias en ServiceContainer

```
plainNetworkClient ────────→ AuthService (login, refresh, sin interceptors)
authenticatedNetworkClient ─→ Todo lo demas (con AuthenticationInterceptor)
```

---

## 3. HTTPRequest — Builder Pattern

**Archivo:** `HTTPRequest.swift`

Struct inmutable con API fluida:

```swift
let request = HTTPRequest(baseURL: config.iamBaseURL)
    .path("/api/v1/auth/login")
    .method(.post)
    .jsonBody(LoginRequestDTO(email: email, password: password))
    .header("Accept", "application/json")
    .timeout(30)
```

**Metodos HTTP:** GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS

**Helpers:**
- `.queryParam(key, value)` / `.queryParams([:])`
- `.jsonBody(data)` / `.jsonBody(json)`
- `.bearerToken(token)`
- `.basicAuth(username:password:)`

---

## 4. Sistema de Interceptores

**Directorio:** `Packages/Infrastructure/Sources/Network/Interceptors/`

### RequestInterceptor Protocol

```swift
public protocol RequestInterceptor: Sendable {
    func adapt(_ request: URLRequest, context: RequestContext) async throws -> URLRequest
    func retry(_ request: URLRequest, dueTo error: Error, context: RequestContext) async -> RetryDecision
    func didReceive(response: HTTPURLResponse, data: Data, for request: URLRequest, context: RequestContext) async
}
```

**RetryDecision:**
- `.doNotRetry`
- `.retryAfter(TimeInterval)`
- `.retryImmediately`
- `.retryWithRequest(URLRequest)` — permite modificar el request antes de reintentar

**InterceptorChain:** Compone multiples interceptores con fan-out.

### AuthenticationInterceptor

**Archivo:** `AuthenticationInterceptor.swift`

```swift
public actor AuthenticationInterceptor: RequestInterceptor {
    // Inyecta Bearer token en cada request
    // Refresca token si esta cerca de expirar
    // Reintenta en 401 con token nuevo
    // Excluye paths: login, register, refresh
    // Shared refresh task para evitar refreshes concurrentes
}
```

**Protocolos requeridos:**
- `TokenProvider` — obtener/refrescar/verificar expiracion de token
- `SessionExpiredHandler` — notificar cuando refresh falla

**Implementaciones de conveniencia:**
- `SimpleTokenProvider` — para testing
- `StaticTokenProvider` — token fijo
- `.standard(tokenProvider:sessionExpiredHandler:)` — factory con paths excluidos comunes

### RetryInterceptor

**Archivo:** `RetryPolicy.swift`

3 estrategias de retry:

| Estrategia | Formula | Presets |
|-----------|---------|---------|
| `ExponentialBackoffRetryPolicy` | `min(baseDelay * 2^(attempt-1) + jitter, maxDelay)` | `.standard`, `.aggressive`, `.conservative`, `.none` |
| `LinearBackoffRetryPolicy` | `baseDelay * attempt` | - |
| `FixedDelayRetryPolicy` | `delay` constante | - |

**Errores retriable:** timeout, networkFailure, rateLimited, serverError (5xx)
**HTTP 429:** Soporta header `Retry-After`

### LoggingInterceptor

**Archivo:** `LoggingInterceptor.swift`

| Nivel | Comportamiento |
|-------|---------------|
| `none` | Sin logs |
| `error` | Solo errores |
| `info` | Request method+URL + response status |
| `debug` | + headers + body truncado |
| `verbose` | Todo sin truncar |

- Redaccion de headers sensibles (Authorization, X-API-Key, Cookie)
- Truncado de body (default 1KB)
- Integracion con `os.Logger`
- Presets: `.debug`, `.production`, `.verbose`

### InterceptableNetworkClient

Builder fluido para configuracion:

```swift
let client = NetworkClientBuilder()
    .addInterceptor(authInterceptor)
    .withLogging(level: .info)
    .withRetry(policy: .standard)
    .maxRetryTimeout(60)
    .build()
```

---

## 5. Patrones de Resiliencia

**Directorio:** `Packages/Infrastructure/Sources/Network/Resilience/`

### CircuitBreaker

**Archivo:** `CircuitBreaker.swift`

```swift
public actor CircuitBreaker {
    public func execute<T>(_ operation: () async throws -> T) async throws -> T
}
```

| Estado | Comportamiento |
|--------|---------------|
| `closed` | Normal — ejecuta operaciones |
| `open` | Rechaza — lanza `CircuitBreakerOpenError` |
| `halfOpen` | Prueba — permite N intentos para decidir |

**Presets:**

| Preset | Failure Threshold | Reset Timeout | Half-Open Max |
|--------|-------------------|---------------|---------------|
| `.default` | 5 fallos | 30s | 3 |
| `.aggressive` | 3 fallos | 15s | 1 |
| `.conservative` | 10 fallos | 60s | 5 |

Ignora `CancellationError` (no cuenta como fallo).

### RateLimiter

**Archivo:** `RateLimiter.swift`

Token bucket con sliding window:

```swift
public actor RateLimiter {
    public func acquire() async    // Espera si necesario
    public func tryAcquire() -> Bool  // Non-blocking
    public var availableRequests: Int { get }
}
```

**Presets:**

| Preset | Requests | Window |
|--------|----------|--------|
| `.standard` | 60 | 1 minuto |
| `.conservative` | 30 | 1 minuto |
| `.aggressive` | 120 | 1 minuto |

---

## 6. NetworkError

```swift
public enum NetworkError: Error, LocalizedError, Sendable {
    case invalidURL
    case noData
    case decodingError(Error)
    case serverError(statusCode: Int, data: Data?)
    case networkFailure(Error)
    case cancelled
    case timeout
    case sslError
    case unauthorized     // 401
    case forbidden        // 403
    case notFound         // 404
    case rateLimited      // 429
}
```

**Factories:**
- `NetworkError.from(statusCode:)` — mapea HTTP status a caso especifico
- `NetworkError.from(urlError:)` — mapea URLError a caso especifico

**Helpers:** `isSuccessStatusCode()`, `isClientError()`, `isServerError()`

---

## 7. NetworkObserver

**Archivos:** `NetworkStatus.swift`, `NetworkObserver.swift`

Monitoreo de conectividad para modo offline:

```swift
public actor NetworkObserver {
    public var isOnline: Bool { get }
    public var statusStream: AsyncStream<NetworkStatus> { get }
}
```

Usa `NWPathMonitor` de Apple para detectar WiFi/Cellular/Sin conexion.

---

## 8. DTOs de Red

| DTO | Proposito |
|-----|-----------|
| `AuthDTO` | Login/auth responses con ActiveContext |
| `MaterialDTO` | Representaciones de materiales |
| `ProgressDTO` | Tracking de progreso de upload/sync |
| `StatsDTO` | Datos de estadisticas/metricas |

Todos los DTOs usan `CodingKeys` explicitas con mapeo snake_case.

---

*Generado: marzo 2026 | Basado en analisis directo del codigo fuente*
