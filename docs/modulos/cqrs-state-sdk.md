# CQRS + StateManagement SDK

**Estado de extraccion:** Listo la parte framework (70% generico, 30% implementaciones EduGo)
**Dependencias externas:** Ninguna (solo Foundation de Apple)
**Origen en proyecto:** `Packages/Domain/Sources/CQRS/` y `Packages/Domain/Sources/StateManagement/`

---

## a) Que hace este SDK

Framework de arquitectura CQRS (Command Query Responsibility Segregation) con sistema de estado reactivo. Proporciona:

### CQRS Core
- **Command/Query**: Protocolos genericos con associated types y validacion
- **CommandHandler/QueryHandler**: Protocolos para implementar handlers
- **CommandResult<T>**: Wrapper con metadata, eventos de dominio y estado (success/failure)
- **Mediator**: Actor central para dispatch type-safe de commands y queries
- **MediatorRegistry**: Registry con type-erasure para almacenar handlers
- **EventBus**: Actor pub/sub para eventos de dominio con TaskGroup paralelo
- **DomainEvent**: Protocolo base para eventos con metadata
- **CQRSMetrics**: Observabilidad con metricas de ejecucion

### State Management
- **StatePublisher<State>**: Actor generico con AsyncStream
- **BufferedStatePublisher<State>**: Con estrategias de buffering pluggables
- **StateStream<State>**: Wrapper sobre AsyncSequence
- **Operadores reactivos**: Map, Filter, CombineLatest (2 y 3 streams), Merge, Scan
- **Estrategias de buffering**: Unbounded, Bounded, Dropping

### Uso tipico por el consumidor

```swift
// === CQRS ===

// 1. Definir Commands propios
struct CrearPedidoCommand: Command {
    typealias Result = Pedido
    let items: [ItemPedido]
    func validate() throws { /* validacion */ }
}

// 2. Implementar handlers
actor CrearPedidoHandler: CommandHandler {
    typealias CommandType = CrearPedidoCommand
    func handle(_ command: CrearPedidoCommand) async throws -> CommandResult<Pedido> { ... }
}

// 3. Registrar en Mediator
let mediator = Mediator(loggingEnabled: true)
try await mediator.registerCommandHandler(CrearPedidoHandler())

// 4. Ejecutar
let result = try await mediator.execute(CrearPedidoCommand(items: items))

// === StateManagement ===

// 5. Publicar estados reactivos
let publisher = StatePublisher<EstadoCarga>()
await publisher.send(.cargando(progress: 0.5))

// 6. Consumir con operadores
let viewModelStream = publisher.stream.map { estado in
    MiViewModel(from: estado)
}

for await viewModel in viewModelStream {
    actualizarUI(viewModel)
}
```

---

## b) Compila como proyecto independiente?

**La parte framework: Si.** Los protocolos y tipos core no importan ningun modulo EduGo:
- `Command`, `Query`, `CommandHandler`, `QueryHandler` - cero dependencias
- `Mediator`, `MediatorRegistry`, `EventBus` - cero dependencias
- `StatePublisher`, `BufferedStatePublisher`, `StateStream` - cero dependencias
- Todos los operadores y estrategias de buffering - cero dependencias

**Las implementaciones: No.** Commands, Queries, Events y StateMachines concretos dependen de `EduCore` (User, Material, Assessment, etc.)

---

## c) Dependencias si se extrae

### Framework generico (el SDK):

| Dependencia | Tipo | Notas |
|---|---|---|
| Foundation | Sistema Apple | Unico requerimiento |

### Implementaciones concretas (NO van en el SDK):

| Dependencia | Tipo | Notas |
|---|---|---|
| EduCore | Interna proyecto | Entidades de dominio |
| EduFoundation | Interna proyecto | Validadores, errores |
| EduInfrastructure | Interna proyecto | Repositorios (usado por UseCases) |

---

## d) Que se fusionaria con este SDK

Los dos subsistemas (CQRS y StateManagement) **deberian ir juntos** en un solo SDK porque:
1. Los `CommandHandler` publican estados via `StatePublisher`
2. Los `CommandResult` incluyen `events` que se envian al `EventBus`
3. Comparten el patron de actor-based async/await

Opcionalmente, los **protocolos base de UseCase** (`UseCase`, `SimpleUseCase`, `CommandUseCase`) podrian incluirse ya que son genericos.

---

## e) Interfaces publicas (contrato del SDK)

### CQRS Protocolos

```swift
public protocol Command: Sendable {
    associatedtype Result: Sendable
    func validate() throws
}

public protocol Query: Sendable {
    associatedtype Result: Sendable
}

public protocol CommandHandler: Actor {
    associatedtype CommandType: Command
    func handle(_ command: CommandType) async throws -> CommandResult<CommandType.Result>
}

public protocol QueryHandler: Actor {
    associatedtype QueryType: Query
    func handle(_ query: QueryType) async throws -> QueryType.Result
}

public protocol DomainEvent: Sendable {
    var eventId: UUID { get }
    var occurredAt: Date { get }
    var metadata: [String: String] { get }
}

public protocol EventSubscriber: Actor {
    associatedtype EventType: DomainEvent
    func handle(_ event: EventType) async
}
```

### CQRS Tipos

```swift
public struct CommandResult<T: Sendable> {
    public let isSuccess: Bool
    public func getValue() -> T?
    public func getError() -> Error?
    public let events: [String]  // nombres de eventos publicados
}

public actor Mediator {
    public func execute<C: Command>(_ command: C) async throws -> CommandResult<C.Result>
    public func send<Q: Query>(_ query: Q) async throws -> Q.Result
    public func registerCommandHandler<H: CommandHandler>(_ handler: H) async throws
    public func registerQueryHandler<H: QueryHandler>(_ handler: H) async throws
}

public actor EventBus {
    public func publish<E: DomainEvent>(_ event: E) async
    public func subscribe<S: EventSubscriber>(_ subscriber: S) async
}
```

### StateManagement Tipos

```swift
public protocol AsyncState: Sendable, Equatable {}

public actor StatePublisher<State: AsyncState> {
    public var stream: StateStream<State> { get }
    public func send(_ state: State) async
    public func finish() async
}

public struct StateStream<State: AsyncState>: AsyncSequence {
    public func map<Output>(_ transform: (State) -> Output) -> StateMap<...>
    public func filter(_ predicate: (State) -> Bool) -> StateFilter<...>
}

public func combineLatest<A, B>(_ a: StateStream<A>, _ b: StateStream<B>) -> ...
```

---

## f) Que necesita personalizar el consumidor

### Implementar obligatoriamente

1. **Sus propios Commands**: Structs que conformen `Command` con sus tipos
2. **Sus propios Queries**: Structs que conformen `Query`
3. **Sus propios Handlers**: Actors que implementen la logica de negocio
4. **Sus propios Events**: Structs que conformen `DomainEvent`
5. **Sus propios States**: Enums que conformen `AsyncState`

### Que se lleva tal cual vs que adapta

| Componente | Se lleva tal cual? | Adaptacion necesaria |
|---|---|---|
| Command, Query protocols | Si | - |
| CommandHandler, QueryHandler | Si | - |
| CommandResult | Si | - |
| Mediator, MediatorRegistry | Si | - |
| EventBus, DomainEvent | Si | - |
| StatePublisher, StateStream | Si | - |
| Operadores (Map, Filter, etc.) | Si | - |
| BufferingStrategies | Si | - |
| CQRSMetrics | Si | - |
| LoginCommand, UploadMaterialCommand, etc. | **No** | Commands de EduGo |
| GetUserContextQuery, ListMaterialsQuery, etc. | **No** | Queries de EduGo |
| LoginSuccessEvent, MaterialUploadedEvent, etc. | **No** | Events de EduGo |
| UploadStateMachine, AssessmentStateMachine, etc. | **No** | StateMachines de EduGo |
| Todos los UseCases concretos | **No** | Logica de negocio de EduGo |
| SystemRole, Permission, RoleManager | **No** | Sistema de roles de EduGo |

### Cambios necesarios para portabilidad

1. **Extraer solo los directorios core**: `CQRS/Core/`, `CQRS/Mediator/`, `CQRS/Events/` (protocolos), `StateManagement/Core/`, `StateManagement/Operators/`, `StateManagement/Buffering/`
2. **Excluir**: `CQRS/Commands/`, `CQRS/Queries/`, `CQRS/Events/Subscribers/`, `CQRS/ReadModels/`, `StateManagement/StateMachines/`, `UseCases/`, `Services/`
3. **Sin cambios de codigo**: Los componentes framework ya son 100% genericos
