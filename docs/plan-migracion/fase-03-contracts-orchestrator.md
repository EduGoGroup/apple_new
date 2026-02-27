# Fase 3: ScreenContracts + EventOrchestrator

## Objetivo
Implementar el sistema de contratos de pantalla (ScreenContract) que define la lógica de negocio para cada tipo de pantalla, y el EventOrchestrator que ejecuta eventos con verificación de permisos y resolución de endpoints.

## Dependencias
- **Fase 0** (Auth + Sync)
- **Fase 1** (Menu + Navegación)

## Contexto KMP (referencia)

### ScreenContracts en KMP
- Interface `ScreenContract` define: `screenKey`, `resource`, `endpointFor(event)`, `permissionFor(event)`, `dataConfig()`, `customEventHandlers()`
- 30+ implementaciones: Login, Dashboard (7 por rol), CRUD (Schools, Users, Units, Subjects, Materials, Assessments, Roles, Permissions, Memberships, Guardian)
- `BaseCrudContract` provee CRUD genérico que se especializa por recurso
- Registrados en DI (equivalente: registry/diccionario)

### EventOrchestrator en KMP
- `ScreenEvent`: LOAD_DATA, SAVE_NEW, SAVE_EXISTING, DELETE, SEARCH, SELECT_ITEM, REFRESH, LOAD_MORE, CREATE
- Flujo: verificar permiso → encontrar contract → resolver endpoint → ejecutar → retornar EventResult
- `EventResult`: Success, NavigateTo, Error, PermissionDenied, Logout, Cancelled, NoOp, SubmitTo

---

## Pasos de Implementación

### Paso 3.1: ScreenEvent + EventResult

**Paquete**: `Packages/Domain/Sources/`

**Archivos a crear:**
- `Services/DynamicUI/ScreenEvent.swift`
- `Services/DynamicUI/EventResult.swift`
- `Services/DynamicUI/EventContext.swift`

**Requisitos:**
```swift
enum ScreenEvent: String, Sendable {
    case loadData
    case saveNew
    case saveExisting
    case delete
    case search
    case selectItem
    case refresh
    case loadMore
    case create
}

enum EventResult: Sendable {
    case success(message: String = "", data: JSONValue? = nil)
    case navigateTo(screenKey: String, params: [String: String] = [:])
    case error(message: String, canRetry: Bool = false)
    case permissionDenied
    case logout
    case cancelled
    case noOp
    case submitTo(endpoint: String, method: String, fieldValues: [String: JSONValue])
}

struct EventContext: Sendable {
    let screenKey: String
    let userContext: UserContext
    let selectedItem: [String: JSONValue]?
    let fieldValues: [String: String]
    let searchQuery: String?
    let paginationOffset: Int
}
```

**Verificar:** `cd Packages/Domain && swift test`

---

### Paso 3.2: ScreenContract protocol + BaseCrudContract

**Paquete**: `Packages/Domain/Sources/`

**Archivos a crear:**
- `Services/DynamicUI/Contracts/ScreenContract.swift`
- `Services/DynamicUI/Contracts/BaseCrudContract.swift`

**Requisitos:**
```swift
protocol ScreenContract: Sendable {
    var screenKey: String { get }
    var resource: String { get }

    func endpointFor(event: ScreenEvent, context: EventContext) -> String?
    func permissionFor(event: ScreenEvent) -> String?
    func dataConfig() -> DataConfig?
    func customEventHandler(for eventId: String) -> ((EventContext) async -> EventResult)?
}

// Extensión con defaults
extension ScreenContract {
    func dataConfig() -> DataConfig? { nil }
    func customEventHandler(for eventId: String) -> ((EventContext) async -> EventResult)? { nil }
}
```

- `BaseCrudContract` implementa el patrón genérico CRUD:
  ```swift
  struct BaseCrudContract: ScreenContract {
      let screenKey: String
      let resource: String
      let apiPrefix: String  // "admin:" o "mobile:"
      let basePath: String   // "/api/v1/schools"

      func endpointFor(event: ScreenEvent, context: EventContext) -> String? {
          switch event {
          case .loadData, .refresh: return "\(apiPrefix)\(basePath)"
          case .loadMore: return "\(apiPrefix)\(basePath)"  // con offset
          case .search: return "\(apiPrefix)\(basePath)?search=\(context.searchQuery ?? "")"
          case .saveNew: return "\(apiPrefix)\(basePath)"
          case .saveExisting:
              guard let id = context.selectedItem?["id"]?.stringValue else { return nil }
              return "\(apiPrefix)\(basePath)/\(id)"
          case .delete:
              guard let id = context.selectedItem?["id"]?.stringValue else { return nil }
              return "\(apiPrefix)\(basePath)/\(id)"
          case .selectItem: return nil  // handled by navigation
          case .create: return nil  // navigate to form
          }
      }

      func permissionFor(event: ScreenEvent) -> String? {
          switch event {
          case .loadData, .refresh, .loadMore, .search, .selectItem: return "\(resource):read"
          case .saveNew, .create: return "\(resource):create"
          case .saveExisting: return "\(resource):update"
          case .delete: return "\(resource):delete"
          }
      }
  }
  ```

**Verificar:** `cd Packages/Domain && swift test`

---

### Paso 3.3: Contratos específicos — Auth + Dashboard

**Paquete**: `Packages/Domain/Sources/`

**Archivos a crear:**
- `Services/DynamicUI/Contracts/Auth/LoginContract.swift`
- `Services/DynamicUI/Contracts/Auth/SettingsContract.swift`
- `Services/DynamicUI/Contracts/Dashboard/BaseDashboardContract.swift`
- `Services/DynamicUI/Contracts/Dashboard/DashboardSuperadminContract.swift`
- `Services/DynamicUI/Contracts/Dashboard/DashboardSchoolAdminContract.swift`
- `Services/DynamicUI/Contracts/Dashboard/DashboardTeacherContract.swift`
- `Services/DynamicUI/Contracts/Dashboard/DashboardStudentContract.swift`
- `Services/DynamicUI/Contracts/Dashboard/DashboardGuardianContract.swift`

**Requisitos:**
- `LoginContract`:
  - screenKey: `"login"`
  - customEventHandler `"submit-login"`: llama `AuthService.login(email, password)` → EventResult
  - No requiere permisos

- `SettingsContract`:
  - screenKey: `"settings"`
  - customEventHandler para `"change-theme"`, `"logout"`, `"change-language"`

- `BaseDashboardContract`:
  - Patrón genérico para dashboards con `endpointFor(.loadData)` → endpoint de stats
  - Cada subcontrato define su endpoint y permisos específicos

- Dashboards por rol usan endpoints como:
  - superadmin: `admin:/api/v1/stats/global`
  - school_admin: `admin:/api/v1/stats/global` (filtered by school)
  - teacher: `mobile:/api/v1/stats/global`
  - student: `mobile:/api/v1/stats/global`
  - guardian: `mobile:/api/v1/stats/global`

**Verificar:** `cd Packages/Domain && swift test`

---

### Paso 3.4: Contratos específicos — CRUD Resources

**Paquete**: `Packages/Domain/Sources/`

**Archivos a crear:**
- `Services/DynamicUI/Contracts/CRUD/SchoolsListContract.swift`
- `Services/DynamicUI/Contracts/CRUD/SchoolCrudContract.swift`
- `Services/DynamicUI/Contracts/CRUD/UsersListContract.swift`
- `Services/DynamicUI/Contracts/CRUD/UserCrudContract.swift`
- `Services/DynamicUI/Contracts/CRUD/UnitsListContract.swift`
- `Services/DynamicUI/Contracts/CRUD/UnitCrudContract.swift`
- `Services/DynamicUI/Contracts/CRUD/SubjectsListContract.swift`
- `Services/DynamicUI/Contracts/CRUD/SubjectCrudContract.swift`
- `Services/DynamicUI/Contracts/CRUD/MembershipsListContract.swift`
- `Services/DynamicUI/Contracts/CRUD/MembershipCrudContract.swift`
- `Services/DynamicUI/Contracts/CRUD/MaterialsListContract.swift`
- `Services/DynamicUI/Contracts/CRUD/MaterialCrudContract.swift`
- `Services/DynamicUI/Contracts/CRUD/AssessmentsListContract.swift`
- `Services/DynamicUI/Contracts/CRUD/RolesListContract.swift`
- `Services/DynamicUI/Contracts/CRUD/PermissionsListContract.swift`
- `Services/DynamicUI/Contracts/CRUD/GuardianContract.swift`

**Requisitos:**
- Cada contrato usa `BaseCrudContract` internamente o lo extiende:
  ```swift
  // Ejemplo:
  struct SchoolsListContract: ScreenContract {
      let screenKey = "schools:list"
      let resource = "schools"
      private let crud = BaseCrudContract(
          screenKey: "schools:list",
          resource: "schools",
          apiPrefix: "admin:",
          basePath: "/api/v1/schools"
      )
      // Delega a crud para la mayoría...
      // Agrega lógica especial si necesario
  }
  ```

- Mapeo de endpoints por recurso (del backend):
  | Recurso | API Prefix | Base Path |
  |---------|-----------|-----------|
  | schools | admin: | /api/v1/schools |
  | users | admin: | /api/v1/users |
  | units | admin: | /api/v1/units |
  | subjects | admin: | /api/v1/subjects |
  | memberships | admin: | /api/v1/memberships |
  | materials | mobile: | /api/v1/materials |
  | assessments | mobile: | /api/v1/materials/{id}/assessment |
  | roles | iam: | /api/v1/roles |
  | permissions | iam: | /api/v1/permissions |
  | guardian | admin: | /api/v1/guardian-relations |

**Verificar:** `cd Packages/Domain && swift test`

---

### Paso 3.5: ContractRegistry

**Paquete**: `Packages/Domain/Sources/`

**Archivos a crear:**
- `Services/DynamicUI/ContractRegistry.swift`

**Requisitos:**
- `@MainActor final class ContractRegistry`:
  - Diccionario `[String: any ScreenContract]` — screenKey → contract
  - `func register(_ contract: any ScreenContract)` — registrar
  - `func contract(for screenKey: String) -> (any ScreenContract)?` — buscar
  - `func registerDefaults()` — registra todos los contratos por defecto
  - Se inicializa en `ServiceContainer`

- Todos los contratos de paso 3.3 y 3.4 se registran en `registerDefaults()`

**Verificar:** `cd Packages/Domain && swift test`

---

### Paso 3.6: EventOrchestrator

**Paquete**: `Packages/Domain/Sources/`

**Archivos a crear:**
- `Services/DynamicUI/EventOrchestrator.swift`

**Requisitos:**
- `actor EventOrchestrator`:
  - Depende de: `ContractRegistry`, `NetworkClientProtocol`, `MutationQueue?`, `UserContext`

  - `func execute(event: ScreenEvent, context: EventContext) async -> EventResult`:
    1. Buscar contract para `context.screenKey` en registry
    2. Si no existe → `EventResult.error("No contract for screen")`
    3. Verificar permiso: `contract.permissionFor(event)` → `context.userContext.hasPermission()`
    4. Si no tiene permiso → `EventResult.permissionDenied`
    5. Resolver endpoint: `contract.endpointFor(event, context)`
    6. Si el evento tiene un `customEventHandler` → ejecutar y retornar
    7. Si es lectura (loadData, refresh, search, loadMore):
       - Fetch desde API vía `DataLoader`
       - Retornar `EventResult.success(data:)`
    8. Si es escritura (saveNew, saveExisting, delete):
       - Si online → enviar al API
       - Si offline → enqueue en `MutationQueue`
       - Retornar `EventResult.success(message: "Guardado")`
    9. Si es selectItem → determinar navegación desde contract/screen config
    10. Si es create → navegar al formulario correspondiente

  - `func executeCustom(eventId: String, context: EventContext) async -> EventResult`:
    - Para eventos personalizados (como "submit-login", "change-theme")
    - Busca el handler en el contract

**Verificar:** `cd Packages/Domain && swift test`

---

### Paso 3.7: DynamicScreenViewModel actualizado

**Paquete**: `Apps/DemoApp/`

**Archivos a modificar:**
- `ViewModels/DynamicScreenViewModel.swift`

**Requisitos:**
- Integrar `EventOrchestrator` en el ViewModel:
  - `func executeEvent(_ event: ScreenEvent)` → delega al orchestrator
  - `func executeCustomEvent(_ eventId: String)` → para acciones de botones
  - Manejar `EventResult`:
    - `.success` → actualizar datos en pantalla
    - `.navigateTo` → navegar a otra pantalla
    - `.error` → mostrar error en UI
    - `.permissionDenied` → mostrar alerta
    - `.submitTo` → enviar formulario
  - Estado del formulario: `fieldValues: [String: String]`, `fieldErrors: [String: String]`
  - `func updateField(key: String, value: String)` → actualizar valor de campo
  - `func validateField(key: String)` → validar campo individual

**Verificar:** `make build`

---

### Paso 3.8: Tests de Fase 3

**Archivos a crear:**
- `Packages/Domain/Tests/Services/DynamicUI/BaseCrudContractTests.swift`
- `Packages/Domain/Tests/Services/DynamicUI/ContractRegistryTests.swift`
- `Packages/Domain/Tests/Services/DynamicUI/EventOrchestratorTests.swift`
- `Packages/Domain/Tests/Services/DynamicUI/ScreenEventTests.swift`

**Requisitos mínimos:**
- BaseCrudContract genera endpoints correctos para cada evento
- BaseCrudContract genera permisos correctos
- ContractRegistry encuentra contratos por screenKey
- EventOrchestrator verifica permisos antes de ejecutar
- EventOrchestrator maneja caso sin contrato
- EventOrchestrator delega a customEventHandler si existe
- EventOrchestrator maneja errores de red correctamente

---

## Criterios de Completitud

- [ ] 30+ ScreenContracts registrados y funcionales
- [ ] BaseCrudContract genera endpoints/permisos para CRUD genérico
- [ ] EventOrchestrator ejecuta eventos con verificación de permisos
- [ ] Eventos custom (login, theme, logout) funcionan
- [ ] DynamicScreenViewModel integrado con orchestrator
- [ ] Formularios mantienen estado de campos
- [ ] `make build` sin errores
- [ ] `make test` sin fallos
- [ ] Zero warnings de deprecación
