# Paso 3: CQRS + StateManagement SDK

**Prioridad:** Tercera (sin dependencias, framework de arquitectura)
**Dificultad:** Media (seleccionar archivos correctos)
**Archivos fuente:** ~28 (framework generico)
**Tests existentes:** Parciales

---

## 1. Crear el proyecto

```bash
mkdir -p CQRSKit
cd CQRSKit
swift package init --name CQRSKit --type library
```

## 2. Configurar Package.swift

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CQRSKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "CQRSKit", targets: ["CQRSKit"])
    ],
    targets: [
        .target(
            name: "CQRSKit",
            path: "Sources/CQRSKit"
        ),
        .testTarget(
            name: "CQRSKitTests",
            dependencies: ["CQRSKit"],
            path: "Tests/CQRSKitTests"
        )
    ]
)
```

## 3. Copiar archivos fuente - CQRS

Desde `Packages/Domain/Sources/CQRS/` copiar **solo el framework generico**:

### SI copiar (generico)

| Archivo origen | Destino |
|---|---|
| `Core/Command.swift` | `CQRS/Command.swift` |
| `Core/Query.swift` | `CQRS/Query.swift` |
| `Core/CommandHandler.swift` | `CQRS/CommandHandler.swift` |
| `Core/QueryHandler.swift` | `CQRS/QueryHandler.swift` |
| `Core/CommandResult.swift` | `CQRS/CommandResult.swift` |
| `Core/UseCaseProtocols.swift` | `CQRS/UseCaseProtocols.swift` |
| `Mediator/Mediator.swift` | `CQRS/Mediator.swift` |
| `Mediator/MediatorRegistry.swift` | `CQRS/MediatorRegistry.swift` |
| `Mediator/MediatorError.swift` | `CQRS/MediatorError.swift` |
| `Events/DomainEvent.swift` | `Events/DomainEvent.swift` |
| `Events/EventBus.swift` | `Events/EventBus.swift` |
| `Observability/CQRSMetrics.swift` | `Observability/CQRSMetrics.swift` |

### NO copiar (especifico de EduGo)

| Directorio | Razon |
|---|---|
| `Commands/` | LoginCommand, UploadMaterialCommand, etc. |
| `Queries/` | GetUserContextQuery, ListMaterialsQuery, etc. |
| `Events/Subscribers/` | CacheInvalidationSubscriber, AuditLogSubscriber |
| `ReadModels/` | AssessmentReadModel, DashboardReadModel, etc. |

## 4. Copiar archivos fuente - StateManagement

Desde `Packages/Domain/Sources/StateManagement/`:

### SI copiar (generico)

| Archivo origen | Destino |
|---|---|
| `Core/AsyncState.swift` | `State/AsyncState.swift` |
| `Core/StatePublisher.swift` | `State/StatePublisher.swift` |
| `Core/BufferedStatePublisher.swift` | `State/BufferedStatePublisher.swift` |
| `Core/StateStream.swift` | `State/StateStream.swift` |
| `Operators/StateMap.swift` | `State/Operators/StateMap.swift` |
| `Operators/StateFilter.swift` | `State/Operators/StateFilter.swift` |
| `Operators/StateScan.swift` | `State/Operators/StateScan.swift` |
| `Operators/StateMerge.swift` | `State/Operators/StateMerge.swift` |
| `Operators/StateCombineLatest.swift` | `State/Operators/StateCombineLatest.swift` |
| `Buffering/BufferingStrategy.swift` | `State/Buffering/BufferingStrategy.swift` |
| `Buffering/UnboundedBuffer.swift` | `State/Buffering/UnboundedBuffer.swift` |
| `Buffering/BoundedBuffer.swift` | `State/Buffering/BoundedBuffer.swift` |
| `Buffering/DroppingBuffer.swift` | `State/Buffering/DroppingBuffer.swift` |

### NO copiar (especifico de EduGo)

| Directorio | Razon |
|---|---|
| `StateMachines/` | UploadStateMachine, AssessmentStateMachine, DashboardStateMachine |

## 5. Modificaciones necesarias

### 5.1 UseCaseProtocols.swift

Este archivo puede tener `import EduCore` o `import EduFoundation`. Verificar:
- Si importa tipos de EduGo, eliminar esos imports
- Los protocolos base (`UseCase`, `SimpleUseCase`, `CommandUseCase`) son genericos
- Si tienen `typealias` a tipos de EduGo, eliminarlos

### 5.2 Verificar todos los archivos

```bash
grep -r "import Edu" Sources/CQRSKit/
```

Si alguno tiene imports de Edu*, eliminarlos. Los archivos framework no deberian necesitarlos.

## 6. Compilar

```bash
swift build
```

**Posibles problemas:**
- `UseCaseProtocols.swift` podria referenciar tipos de EduCore -> eliminar o generalizar
- `CQRSMetrics.swift` podria usar `os.Logger` -> esta bien, es del sistema

## 7. Tests

Los tests del CQRS en el proyecto original estan dispersos y mezclados con implementaciones de EduGo. Recomendacion: **crear tests nuevos** para el framework generico:

```swift
// Tests/CQRSKitTests/MediatorTests.swift
import Testing
@testable import CQRSKit

struct TestCommand: Command {
    typealias Result = String
    let value: String
    func validate() throws {}
}

actor TestHandler: CommandHandler {
    typealias CommandType = TestCommand
    func handle(_ command: TestCommand) async throws -> CommandResult<String> {
        .success(command.value)
    }
}

@Test func mediatorExecutesCommand() async throws {
    let mediator = Mediator()
    try await mediator.registerCommandHandler(TestHandler())
    let result = try await mediator.execute(TestCommand(value: "hello"))
    #expect(result.isSuccess)
    #expect(result.getValue() == "hello")
}
```

## 8. Checklist final

- [ ] `swift build` compila sin errores
- [ ] `swift test` pasa tests basicos
- [ ] Cero imports de `Edu*`
- [ ] Solo contiene framework generico (Command, Query, Mediator, EventBus, State)
- [ ] No contiene Commands/Queries/Events concretos de EduGo
