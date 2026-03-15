# Concurrencia Swift 6.2 — EduGo Apple

> Documentacion generada desde analisis directo del codigo fuente (marzo 2026).

---

## 1. Principios No Negociables

El proyecto usa **Swift 6.2 Strict Concurrency Mode**. Estas reglas son absolutas y no admiten excepciones:

| Regla | Estado |
|-------|--------|
| `nonisolated` | **PROHIBIDO** — nunca como workaround |
| `nonisolated(unsafe)` | **PROHIBIDO** |
| `@Published` | **PROHIBIDO** — usar `@Observable` |
| `@ObservableObject` | **PROHIBIDO** — usar `@Observable` |
| `@EnvironmentObject` | **PROHIBIDO** — usar `@Environment` |
| Combine framework | **PROHIBIDO** — usar AsyncSequence/AsyncStream |
| NotificationCenter | **PROHIBIDO** — usar EventBus propio |
| DispatchQueue/GCD | **PROHIBIDO** — usar async/await |
| `synchronized` | **PROHIBIDO** — usar actor |

---

## 2. Patrones Correctos

### Actors para Estado Compartido

Todas las abstracciones concurrentes son actors:

```swift
// Correcto: NetworkClient es un actor
public actor NetworkClient: NetworkClientProtocol {
    public func request<T: Decodable & Sendable>(_ request: HTTPRequest) async throws -> T
}

// Correcto: ScreenLoader es un actor
public actor ScreenLoader {
    public func loadScreen(key: String) async throws -> ScreenDefinition
}

// Correcto: CircuitBreaker es un actor
public actor CircuitBreaker {
    public func execute<T>(_ operation: () async throws -> T) async throws -> T
}
```

**Actors implementados:** `NetworkClient`, `ScreenLoader`, `DataLoader`, `CircuitBreaker`, `RateLimiter`, `StorageManager`, `KeychainManager`, `StatePublisher`, `PersistenceContainerProvider`, `NetworkObserver`

### @MainActor para UI

ViewModels y ServiceContainer estan en `@MainActor`:

```swift
@MainActor @Observable
public final class LoginViewModel {
    public var email: String = ""
    public var isLoading: Bool = false

    public func login() async { ... }
}

@MainActor @Observable
final class ServiceContainer {
    // Todos los servicios inicializados aqui
}
```

### @Observable en Lugar de @Published

```swift
// PROHIBIDO
class OldViewModel: ObservableObject {
    @Published var data: [Item] = []
}

// CORRECTO
@MainActor @Observable
final class NewViewModel {
    var data: [Item] = []
}
```

### AsyncSequence/AsyncStream en Lugar de Combine

```swift
// PROHIBIDO
import Combine
let cancellable = publisher.sink { ... }

// CORRECTO
for await state in statePublisher.stream {
    // Reaccionar a cambios de estado
}
```

### StatePublisher para Estado Reactivo

```swift
public actor StatePublisher<State: AsyncState> {
    public var currentState: State?
    public var stream: StateStream<State> { get }

    public func send(_ state: State)
    public func sendIfChanged(_ state: State) -> Bool
    public func finish()
}

// Consumo desde SwiftUI
.task {
    for await state in viewModel.stateStream {
        handleState(state)
    }
}
```

---

## 3. Alternativas a nonisolated

`nonisolated` esta prohibido. Alternativas correctas:

| Situacion | Solucion |
|-----------|----------|
| Metodo que no accede a estado del actor | `static func` |
| `let` almacenada que callers necesitan sin await | Pasar valor en constructor, caller lo retiene directamente |
| Conformancia a protocolo no-isolated | `@preconcurrency` en protocolo o redesign |
| Computed property sin estado | `static` computed property |

```swift
// PROHIBIDO
public actor MyActor {
    nonisolated func helper() -> Bool { ... }
}

// CORRECTO
public actor MyActor {
    static func helper() -> Bool { ... }
}
```

---

## 4. Sendable Everywhere

Todos los tipos que cruzan boundaries de actor deben ser `Sendable`:

```swift
// Errores: Sendable
public enum DomainError: Error, Sendable { ... }
public enum NetworkError: Error, Sendable { ... }

// DTOs: Sendable
public struct LoginRequestDTO: Codable, Sendable { ... }

// Protocolos: Sendable
public protocol Command: Sendable { ... }
public protocol Query: Sendable { ... }

// Handlers: Actor + Sendable
public protocol CommandHandler: Actor, Sendable { ... }
```

---

## 5. Patron de Concurrencia por Capa

| Capa | Patron Principal | Ejemplo |
|------|-----------------|---------|
| Foundation | Structs Sendable | `DomainError`, `AppEnvironment` |
| Core | Structs Sendable + Actor Logger | `LoginRequestDTO`, `Logger` |
| Infrastructure | Actors | `NetworkClient`, `KeychainManager`, `StorageManager` |
| DynamicUI | Actors | `ScreenLoader`, `DataLoader` |
| Domain | Actors + AsyncSequence | `StatePublisher`, `CommandHandler` |
| Presentation | @MainActor @Observable | `LoginViewModel`, `AppCoordinator` |
| App | @MainActor | `ServiceContainer`, `DemoApp` |

---

## 6. Testing con Concurrencia

```swift
@Suite("NetworkClient Tests")
struct NetworkClientTests {
    @Test("Request exitoso")
    func requestSuccess() async throws {
        let client = NetworkClient()
        let result: LoginResponseDTO = try await client.request(
            HTTPRequest(baseURL: mockURL).path("/login").method(.post)
        )
        #expect(result.token != nil)
    }
}
```

Los tests usan `async` naturalmente ya que los actors requieren `await`.

---

## 7. Verificacion de Compliance

El proyecto verifica automaticamente:

| Verificacion | Resultado |
|-------------|-----------|
| 0 usos de `nonisolated` | PASS |
| 0 usos de `nonisolated(unsafe)` | PASS |
| 0 usos de `@Published`/`@ObservableObject`/`@EnvironmentObject` | PASS |
| `@MainActor` en todos los ViewModels | PASS (9/9) |
| `@Observable` usado correctamente | PASS |
| 0 imports de Combine | PASS |
| 0 usos de DispatchQueue/GCD | PASS (1 excepcion justificada: NWPathMonitor API) |
| 0 warnings de deprecacion | PASS |

---

*Generado: marzo 2026 | Basado en analisis directo del codigo fuente*
