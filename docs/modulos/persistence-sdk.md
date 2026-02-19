# Persistence SDK

**Estado de extraccion:** Parcial (60% generico, 40% especifico de EduGo)
**Dependencias externas:** SwiftData (framework Apple)
**Origen en proyecto:** `Packages/Infrastructure/Sources/Persistence/`

---

## a) Que hace este SDK

Framework de persistencia local sobre SwiftData con gestion de contenedores, migraciones y utilidades de concurrencia. Proporciona:

- **PersistenceContainerProvider**: Actor thread-safe que gestiona `ModelContainer` con soporte in-memory/persistent
- **Sistema de migraciones**: Framework con `SchemaVersions` y soporte para lightweight/custom migrations
- **Utilidades de concurrencia**:
  - `CancellationHandler`: Operaciones con timeout configurable
  - `TaskGroupCoordinator<T>`: Coordinacion de operaciones batch con task groups
  - `BatchResult<T>`: Resultados de operaciones batch con exitos/fallos
  - Funciones globales: `withTimeout`, `withCancellableTaskGroup`
- **Patron de repositorio**: Patron consistente para crear repositorios actor-based con cache local

### Uso tipico por el consumidor

```swift
// 1. Definir sus propios @Model
@Model class MiEntidadModel {
    var id: UUID
    var nombre: String
    // ...
}

// 2. Configurar el provider
let schema = Schema([MiEntidadModel.self])
try await PersistenceContainerProvider.shared.configure(
    with: .init(storageType: .persistent(miURL)),
    schema: schema
)

// 3. Operar con el contexto
try await PersistenceContainerProvider.shared.perform { context in
    let descriptor = FetchDescriptor<MiEntidadModel>()
    return try context.fetch(descriptor)
}

// 4. Usar utilidades de concurrencia
let coordinator = TaskGroupCoordinator<MiResultado>()
let results = try await coordinator.execute(items: misItems) { item in
    try await procesarItem(item)
}
```

---

## b) Compila como proyecto independiente?

**No directamente.** Tiene dependencias que resolver:

- `import EduCore`: Usado por repositorios para tipos de dominio (User, Document, Material, etc.)
- `import EduFoundation`: Usado para `RepositoryError`, `DomainError`, `Logger`
- `@_exported import SwiftData`: Re-exporta SwiftData (filtra hacia consumidores)

**Solucion**: Extraer solo la capa generica (Provider + Migration + Concurrency), dejar repositorios y modelos en el proyecto EduGo.

---

## c) Dependencias si se extrae

### Solo la parte generica del SDK:

| Dependencia | Tipo | Notas |
|---|---|---|
| Foundation | Sistema Apple | Siempre disponible |
| SwiftData | Framework Apple | iOS 17+ / macOS 14+ |

### Los repositorios especificos (NO van en el SDK):

| Dependencia | Tipo | Notas |
|---|---|---|
| EduCore | Interna proyecto | Entidades de dominio |
| EduFoundation | Interna proyecto | Tipos de error |

---

## d) Que se fusionaria con este SDK

**`StorageManager`** (Keychain wrapper, actualmente en `Infrastructure/Sources/Storage/`) podria fusionarse aqui para tener un SDK unificado de "persistencia" que cubra:
- SwiftData (datos estructurados)
- Keychain (datos sensibles)
- UserDefaults (preferencias simples)

---

## e) Interfaces publicas (contrato del SDK)

### Container y configuracion

```swift
public actor PersistenceContainerProvider {
    public static let shared: PersistenceContainerProvider
    public func configure(with config: LocalPersistenceConfiguration, schema: Schema) throws
    public func perform<T: Sendable>(_ operation: @Sendable (ModelContext) throws -> T) throws -> T
    public func reset()
    public var isInitialized: Bool { get }
}

public struct LocalPersistenceConfiguration: Sendable {
    public enum StorageType { case inMemory, persistent(URL) }
    public let storageType: StorageType
}
```

### Concurrencia

```swift
public actor CancellationHandler {
    public func execute<T>(timeout: Duration, operation: () async throws -> T) async throws -> T
}

public actor TaskGroupCoordinator<T: Sendable> {
    public func execute<Input>(items: [Input], operation: (Input) async throws -> T) async throws -> BatchResult<T>
}

public struct BatchResult<T: Sendable> {
    public let successes: [T]
    public let failures: [(index: Int, error: Error)]
}

public struct TaskGroupConfiguration: Sendable {
    public let timeout: Duration?
    public let cancelOnFirstError: Bool
    public let maxConcurrency: Int?
}
```

---

## f) Que necesita personalizar el consumidor

### Implementar obligatoriamente

1. **Sus propios `@Model`**: Tipos SwiftData para sus entidades
2. **Su `Schema`**: Con sus modelos
3. **Su `MigrationPlan`**: Si necesita migraciones entre versiones
4. **Sus repositorios**: Actors que usen `PersistenceContainerProvider.shared.perform`

### Que se lleva tal cual vs que adapta

| Componente | Se lleva tal cual? | Adaptacion necesaria |
|---|---|---|
| PersistenceContainerProvider | Si | - |
| LocalPersistenceConfiguration | Si | - |
| CancellationHandler | Si | - |
| TaskGroupCoordinator | Si | - |
| BatchResult, TaskGroupConfig | Si | - |
| withTimeout, withCancellableTaskGroup | Si | - |
| SchemaVersions (V1, V2) | **No** | Esquemas especificos de EduGo |
| LocalPersistenceMigrationPlan | **No** | Plan de migracion especifico |
| UserModel, DocumentModel, etc. | **No** | 6 modelos especificos de EduGo |
| LocalUserRepository, etc. | **No** | 6 repositorios especificos |
| *PersistenceMapper (todos) | **No** | 6 mappers especificos |

### Archivos a excluir del SDK

```
Persistence/
  Models/          <- TODO: especifico de EduGo
  Repositories/    <- TODO: especifico de EduGo
  Mappers/         <- TODO: especifico de EduGo
  Migration/       <- TODO: parcial - el framework es generico, las versiones son de EduGo
```

### Cambios necesarios para portabilidad

1. **Extraer solo**: ContainerProvider, Configuration, Concurrency utilities
2. **Eliminar `@_exported import SwiftData`**: Que el consumidor importe SwiftData explicitamente
3. **Remover referencia a `RepositoryError`**: De Foundation, usar errores propios del SDK o generico
4. **Documentar patron de repositorio**: Como ejemplo para que el consumidor replique
