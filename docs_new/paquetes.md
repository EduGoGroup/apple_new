# Paquetes SPM — EduGo Apple

> Documentacion generada desde analisis directo del codigo fuente (marzo 2026).

---

## 1. EduFoundation (Tier 0)

**Ruta:** `Packages/Foundation/`
**Product:** `EduFoundation`
**Dependencias:** Ninguna

Tipos base y protocolos de error que todas las capas superiores utilizan.

### Errores por Capa

```swift
// DomainError — errores de logica de negocio
public enum DomainError: Error, LocalizedError, Sendable, Equatable {
    case validationFailed(String)
    case businessRuleViolated(String)
    case invalidOperation(String)
    case entityNotFound(String)
}

// RepositoryError — errores de acceso a datos
public enum RepositoryError: Error, LocalizedError, Sendable, Equatable {
    case fetchFailed(String)
    case saveFailed(String)
    case deleteFailed(String)
    case connectionError(String)
    case serializationError(String)
    case dataInconsistency(String)
}

// UseCaseError — envuelve domain/repo + errores propios
public enum UseCaseError: Error, LocalizedError, Sendable, Equatable {
    case preconditionFailed(String)
    case unauthorized(String)
    case timeout(String)
    // + wrapping de DomainError y RepositoryError
}
```

### Protocolos

```swift
public protocol UserContextProtocol: Sendable {
    var currentUserId: UUID? { get async }
    var isAuthenticated: Bool { get async }
    var currentUserEmail: String? { get async }
}
```

### Otros

- `AppEnvironment` — enum `.development`, `.staging`, `.production` con deteccion automatica

---

## 2. EduCore (Tier 1)

**Ruta:** `Packages/Core/`
**Products:** `EduCore` (umbrella), `EduModels`, `EduLogger`, `EduUtilities`
**Dependencias:** Foundation

4 submodulos que `EduCore` reexporta via `@_exported import`.

### EduModels

50+ archivos organizados en:

| Carpeta | Contenido | Ejemplos |
|---------|-----------|----------|
| `DTOs/` | 24 Data Transfer Objects | `LoginRequestDTO`, `LoginResponseDTO`, `SyncBundleResponseDTO`, `MenuItemDTO`, `ScreenBundleDTO` |
| `Domain/` | 11 entidades de dominio | `User`, `School`, `Material`, `AuthToken`, `AuthContext`, `Permission`, `Role` |
| `Mappers/` | 8 mappers bidireccionales | `UserMapper`, `SchoolMapper`, `MaterialMapper` (DTO ↔ Domain) |
| `Protocols/` | 7 protocolos de repositorio | `UserRepositoryProtocol`, `SchoolRepositoryProtocol`, `MaterialRepositoryProtocol` |
| `Validation/` | Validadores | `EmailValidator`, `DocumentValidator`, `DomainValidation` |
| `Support/` | `JSONValue` | Enum Codable+Sendable+Hashable para JSON dinamico |

**JSONValue** — unica fuente de verdad en `EduModels`:

```swift
public enum JSONValue: Codable, Sendable, Hashable {
    case string(String)
    case integer(Int)    // Nota: .integer, NO .int
    case double(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null
}
```

### EduLogger

Logger profesional con categorias y niveles:

```swift
public protocol LoggerProtocol: Sendable {
    func debug(_ message: String, category: LogCategory?, ...) async
    func info(_ message: String, category: LogCategory?, ...) async
    func warning(_ message: String, category: LogCategory?, ...) async
    func error(_ message: String, category: LogCategory?, ...) async
}

public actor Logger {
    public static let shared = Logger()
    // Implementacion con os.Logger de Apple
}
```

- Adapters: `OSLoggerAdapter`, `OSLoggerFactory`
- Categorias: `LogCategory` enum por subsistema
- Configuracion: `LoggerConfigurator`, `EnvironmentConfiguration`
- Registry: `LoggerRegistry` para multiples instancias

### EduUtilities

Utilidades compartidas (extensiones, helpers, formatters).

---

## 3. EduInfrastructure (Tier 2)

**Ruta:** `Packages/Infrastructure/`
**Products:** `EduInfrastructure` (umbrella), `EduNetwork`, `EduStorage`, `EduPersistence`
**Dependencias:** Foundation, Core

### EduNetwork

Ver documento dedicado: [networking.md](networking.md)

### EduStorage

| Componente | Tipo | Descripcion |
|-----------|------|-------------|
| `StorageManager` | `actor` | UserDefaults wrapper con serializacion JSON |
| `KeychainManager` | `actor` | Credenciales seguras via Security framework |

**KeychainManager:**

```swift
public actor KeychainManager {
    public func save<T: Codable>(_ item: T, forKey key: String, accessibility: KeychainAccessibility) throws
    public func retrieve<T: Codable>(forKey key: String) throws -> T?
    public func delete(forKey key: String) throws
    public func exists(forKey key: String) throws -> Bool
    public func deleteAll() throws
}
```

Opciones de accesibilidad: `.whenUnlockedThisDeviceOnly` (default), `.afterFirstUnlockThisDeviceOnly`, `.whenUnlocked`.

### EduPersistence

SwiftData wrapper con actor container:

```swift
public actor PersistenceContainerProvider {
    public static let shared = PersistenceContainerProvider()
    public func perform<T>(_ operation: (ModelContext) throws -> T) throws -> T
}
```

**Modelos SwiftData:** `UserModel`, `SchoolModel`, `MembershipModel`, `DocumentModel`, `MaterialModel`, `AcademicUnitModel`

**Mappers:** Conversion bidireccional entre modelos SwiftData y entidades de dominio.

**Migraciones:** `LocalPersistenceMigrationPlan` con versionado de schemas.

---

## 4. EduDynamicUI (Tier Lateral)

**Ruta:** `Packages/DynamicUI/`
**Product:** `EduDynamicUI`
**Dependencias:** Foundation, Core (EduModels), Infrastructure (EduNetwork)

Ver documento dedicado: [sdui.md](sdui.md)

---

## 5. EduDomain (Tier 3)

**Ruta:** `Packages/Domain/`
**Product:** `EduDomain`
**Dependencias:** Foundation, Core, Infrastructure, DynamicUI

### State Management

Sistema reactivo basado en `AsyncSequence`:

```swift
public actor StatePublisher<State: AsyncState> {
    public var currentState: State?
    public var stream: StateStream<State> { get }
    public func send(_ state: State)
    public func sendIfChanged(_ state: State) -> Bool
    public func finish()
}
```

**Operadores reactivos:** `StateMap`, `StateFilter`, `StateMerge`, `StateScan`, `StateCombineLatest`

**Buffering:** `UnboundedBuffer`, `BoundedBuffer`, `DroppingBuffer`

### State Machines

| Maquina | Proposito |
|---------|-----------|
| `DashboardStateMachine` | Estados del dashboard principal |
| `AssessmentStateMachine` | Transiciones de evaluaciones |
| `UploadStateMachine` | Progreso de subida de materiales |

### CQRS (Command/Query/Event)

```swift
public protocol Command: Sendable {
    associatedtype Output: Sendable
}

public protocol Query: Sendable {
    associatedtype Result: Sendable
}

public protocol CommandHandler: Actor, Sendable {
    associatedtype Input: Command
    func handle(_ command: Input) async throws -> CommandResult<Input.Output>
}

public protocol QueryHandler: Actor, Sendable {
    associatedtype Input: Query
    func handle(_ query: Input) async throws -> Input.Result
}
```

**CommandResult** envuelve el resultado + eventos de dominio generados:

```swift
public struct CommandResult<T: Sendable> {
    public let isSuccess: Bool
    public let events: [DomainEvent]
}
```

### Use Case Protocols

Abstracciones type-erased para DI:

- `LoginUseCaseProtocol`
- `UploadMaterialUseCaseProtocol`
- `TakeAssessmentUseCaseProtocol`
- `SwitchSchoolContextUseCaseProtocol`
- `SyncProgressUseCaseProtocol`

---

## 6. EduPresentation (Tier 4)

**Ruta:** `Packages/Presentation/`
**Product:** `EduPresentation`
**Dependencias:** Foundation, Core, Domain

### ViewModels

Todos siguen el patron `@MainActor @Observable`:

```swift
@MainActor @Observable
public final class LoginViewModel {
    public var email: String = ""
    public var password: String = ""
    public var isLoading: Bool = false
    public var error: Error?
    public var isAuthenticated: Bool = false

    public func login() async { ... }
    public func validateForm() -> Bool { ... }
}
```

**ViewModels implementados:** `LoginViewModel`, `DashboardViewModel`, `AssessmentViewModel`, `MaterialUploadViewModel`, `MaterialListViewModel`, `UserProfileViewModel`, `ContextSwitchViewModel`, `AuditViewModel`

### Navegacion

Patron Coordinator con `NavigationPath`:

```swift
@MainActor @Observable
public final class AppCoordinator {
    public var navigationPath: NavigationPath
    public var presentedSheet: Screen?
    public var presentedFullScreenCover: Screen?

    public func navigate(to screen: Screen)
    public func presentSheet(_ screen: Screen)
    public func goBack()
    public func popToRoot()
}
```

**Rutas type-safe:**

```swift
public enum Screen: Hashable, Sendable {
    case login, dashboard, materialList, materialUpload
    case materialAssignment(materialId: UUID)
    case assessment(assessmentId: UUID, userId: UUID)
    case userProfile, contextSwitch
    case materialDetail(materialId: UUID)
    case assessmentResults(assessmentId: UUID)
}
```

**Coordinadores por feature:** `AuthCoordinator`, `DashboardCoordinator`, `MaterialsCoordinator`, `AssessmentCoordinator`

**EventBus:** Navegacion automatica en respuesta a eventos de dominio (`LoginSuccessEvent`, `ContextSwitchedEvent`, etc.)

---

## 7. EduFeatures (Tier 5)

**Ruta:** `Packages/Features/`
**Product:** `EduFeatures`
**Dependencias:** Foundation, Core, Infrastructure, Domain, Presentation

Integraciones de alto nivel: AI, analytics. Combina todas las capas para features completas.

---

*Generado: marzo 2026 | Basado en analisis directo del codigo fuente*
