# Testing — EduGo Apple

> Documentacion generada desde analisis directo del codigo fuente (marzo 2026).

---

## 1. Framework de Testing

El proyecto usa **Swift Testing** exclusivamente. No se usa XCTest.

```swift
import Testing

@Suite("LoginViewModel Tests")
struct LoginViewModelTests {
    @Test("Login exitoso con credenciales validas")
    func loginSuccess() async throws {
        let vm = LoginViewModel(authService: MockAuthService())
        vm.email = "test@edugo.test"
        vm.password = "EduGoTest123!"

        await vm.login()

        #expect(vm.isAuthenticated == true)
        #expect(vm.error == nil)
    }
}
```

| API | Uso |
|-----|-----|
| `@Suite` | Agrupar tests relacionados |
| `@Test` | Marcar funcion como test |
| `#expect` | Asercion (reemplaza XCTAssertEqual, XCTAssertTrue, etc.) |
| `#require` | Asercion que detiene el test si falla |

---

## 2. Cifras de Testing

| Metrica | Valor |
|---------|-------|
| Tests totales | ~2,083 |
| Suites de test | ~143 |
| Archivos test en Packages/ | ~133 |
| Archivos test en modulos/ | ~13 |

### Distribucion por Paquete

| Paquete | Tests | Cobertura |
|---------|-------|-----------|
| Core (Models, Mappers, Validation) | 36+ archivos | Alta |
| Domain (CQRS, State, UseCases) | 20+ archivos | Alta |
| Infrastructure (Network, Storage) | 15+ archivos | Alta |
| DynamicUI (Loader, Resolvers) | 15+ archivos | Alta |
| Presentation (ViewModels, Nav) | 20+ archivos | Media |
| Features | 5+ archivos | Media |
| Foundation | 5+ archivos | Alta |

---

## 3. Estructura de Tests

Cada paquete tiene su directorio de tests:

```
Packages/{Paquete}/
├── Sources/           # Codigo fuente
└── Tests/             # Tests
    └── {Paquete}Tests/
        ├── Models/
        ├── Mappers/
        ├── Services/
        └── Resources/JSON/  # Fixtures JSON
```

### Recursos de Test

El paquete Core incluye fixtures JSON en `Tests/CoreTests/Resources/JSON/` para testing de serializacion/deserializacion.

---

## 4. Patrones de Testing

### Testing con Actors

Los actors requieren `await` en los tests:

```swift
@Suite("ScreenLoader Tests")
struct ScreenLoaderTests {
    @Test("Cache hit retorna screen guardada")
    func cacheHit() async throws {
        let loader = ScreenLoader(networkClient: mockClient, baseURL: baseURL)

        // Seed cache
        await loader.seedFromBundle(screens: mockScreens)

        // Load from cache (no network call)
        let screen = try await loader.loadScreen(key: "schools-list")
        #expect(screen.key == "schools-list")
        #expect(screen.pattern == .list)
    }
}
```

### Mocking con Protocols

Todas las dependencias tienen protocolos para inyectar mocks:

```swift
// Protocolo en produccion
public protocol NetworkClientProtocol: Sendable {
    func request<T: Decodable & Sendable>(_ request: HTTPRequest) async throws -> T
}

// Mock para tests
actor MockNetworkClient: NetworkClientProtocol {
    var responses: [String: Any] = [:]

    func request<T: Decodable & Sendable>(_ request: HTTPRequest) async throws -> T {
        guard let response = responses[request.path] as? T else {
            throw NetworkError.notFound
        }
        return response
    }
}
```

### Testing de ViewModels (@MainActor)

```swift
@Suite("DashboardViewModel Tests")
struct DashboardViewModelTests {
    @Test("Carga dashboard con datos")
    @MainActor
    func loadDashboard() async throws {
        let vm = DashboardViewModel(/* mocks */)
        await vm.loadData()
        #expect(vm.items.isEmpty == false)
        #expect(vm.isLoading == false)
    }
}
```

### Testing de State Machines

```swift
@Suite("AssessmentStateMachine Tests")
struct AssessmentStateMachineTests {
    @Test("Transicion idle -> loading -> loaded")
    func stateTransitions() async {
        let machine = AssessmentStateMachine()
        #expect(machine.currentState == .idle)

        await machine.startLoading()
        #expect(machine.currentState == .loading)

        await machine.loaded(assessment: mockAssessment)
        #expect(machine.currentState == .loaded)
    }
}
```

### Testing de CQRS

```swift
@Suite("LoginCommandHandler Tests")
struct LoginCommandHandlerTests {
    @Test("Login command exitoso emite evento")
    func loginCommandSuccess() async throws {
        let handler = LoginCommandHandler(authService: MockAuthService())
        let command = LoginCommand(email: "test@edugo.test", password: "pass")

        let result = try await handler.handle(command)

        #expect(result.isSuccess)
        #expect(result.events.contains(where: { $0 is LoginSuccessEvent }))
    }
}
```

---

## 5. Comandos de Ejecucion

### Todos los Tests

```bash
# Desde la raiz del proyecto
make test

# Equivalente manual (ejecuta tests de cada paquete)
cd Packages/Foundation && swift test
cd Packages/Core && swift test
cd Packages/Infrastructure && swift test
cd Packages/Domain && swift test
cd Packages/DynamicUI && swift test
cd Packages/Presentation && swift test
cd Packages/Features && swift test
cd modulos/CQRSKit && swift test
cd modulos/NetworkSDK && swift test
# ... etc
```

### Test Especifico

```bash
# Un suite especifico
cd Packages/Core && swift test --filter LoginViewModelTests

# Un test especifico
cd Packages/Core && swift test --filter "LoginViewModelTests/loginSuccess"
```

### Test de un SDK

```bash
cd modulos/CQRSKit && swift test
cd modulos/NetworkSDK && swift test
```

---

## 6. Como Agregar Tests

### Paso 1: Crear archivo de test

```swift
// Packages/{Paquete}/Tests/{Paquete}Tests/MiNuevoTests.swift
import Testing
@testable import EduDomain

@Suite("MiNuevo Tests")
struct MiNuevoTests {
    @Test("Descripcion del comportamiento esperado")
    func testBehavior() async throws {
        // Given
        let sut = MiNuevoServicio(dependency: MockDependency())

        // When
        let result = try await sut.execute()

        // Then
        #expect(result.isSuccess)
    }
}
```

### Paso 2: Crear mocks si necesario

```swift
actor MockDependency: DependencyProtocol {
    var expectedResult: Result<Data, Error> = .success(Data())

    func fetch() async throws -> Data {
        try expectedResult.get()
    }
}
```

### Paso 3: Ejecutar

```bash
cd Packages/{Paquete} && swift test --filter MiNuevoTests
```

---

## 7. Buenas Practicas

1. **Usar `@Suite`** para agrupar tests relacionados
2. **Nombres descriptivos** en `@Test("...")` — describir el comportamiento, no la implementacion
3. **Given/When/Then** — estructura clara en cada test
4. **Mocks via protocols** — no mockear implementaciones concretas
5. **`async` por defecto** — los actors lo requieren
6. **`@MainActor` en tests de UI** — para ViewModels
7. **`#expect` sobre `#require`** — `#require` solo cuando el test no puede continuar sin la asercion
8. **Fixtures JSON** en `Resources/` — para testing de serializacion
9. **No usar XCTest** — todo con Swift Testing

---

*Generado: marzo 2026 | Basado en analisis directo del codigo fuente*
