# Testing de ViewModels

Estrategias y patrones para testear ViewModels efectivamente.

## Overview

Los ViewModels en EduGo están diseñados para ser testeables mediante inyección de
dependencias. Usando stubs y mocks del Mediator y EventBus, podemos testear toda
la lógica del ViewModel de manera aislada y determinista.

## Estructura de Tests

### Configuración Básica con Swift Testing

```swift
import Testing
@testable import ViewModels
@testable import CQRS
@testable import Models

@Suite("LoginViewModel Tests")
@MainActor
struct LoginViewModelTests {
    
    // MARK: - Test Setup
    
    private func makeSUT(
        mockHandler: MockLoginHandler = MockLoginHandler()
    ) async -> (sut: LoginViewModel, handler: MockLoginHandler) {
        let mediator = Mediator()
        await mediator.register(handler: mockHandler)
        
        let sut = LoginViewModel(mediator: mediator)
        return (sut, mockHandler)
    }
    
    // MARK: - Tests
    
    @Test
    func login_withValidCredentials_authenticatesUser() async throws {
        // Arrange
        let (sut, handler) = await makeSUT()
        handler.mockResult = .success(LoginOutput(user: User.stub()))
        
        sut.email = "test@example.com"
        sut.password = "password123"
        
        // Act
        await sut.login()
        
        // Assert
        #expect(sut.isAuthenticated == true)
        #expect(sut.authenticatedUser != nil)
        #expect(sut.error == nil)
    }
}
```

### Patrón AAA (Arrange-Act-Assert)

```swift
@Test
func loadDashboard_succeeds_setsDashboardData() async throws {
    // Arrange - Configurar estado inicial y mocks
    let mockHandler = MockDashboardQueryHandler()
    let expectedDashboard = StudentDashboard.stub()
    mockHandler.mockResult = expectedDashboard
    
    let mediator = Mediator()
    await mediator.register(handler: mockHandler)
    
    let sut = DashboardViewModel(
        mediator: mediator,
        eventBus: EventBus(),
        userId: UUID()
    )
    
    // Act - Ejecutar la acción a testear
    await sut.loadDashboard()
    
    // Assert - Verificar resultados
    #expect(sut.dashboard == expectedDashboard)
    #expect(sut.isLoading == false)
    #expect(sut.error == nil)
}
```

## Creación de Mocks

### Mock de Query Handler

```swift
actor MockDashboardQueryHandler: QueryHandler {
    typealias QueryType = GetStudentDashboardQuery
    
    var mockResult: StudentDashboard?
    var mockError: Error?
    private(set) var callCount = 0
    private(set) var lastQuery: GetStudentDashboardQuery?
    
    func handle(_ query: GetStudentDashboardQuery) async throws -> StudentDashboard {
        callCount += 1
        lastQuery = query
        
        if let error = mockError {
            throw error
        }
        
        guard let result = mockResult else {
            throw TestError.noMockConfigured
        }
        
        return result
    }
}
```

### Mock de Command Handler

```swift
actor MockLoginHandler: CommandHandler {
    typealias CommandType = LoginCommand
    typealias ResultType = LoginOutput
    
    var mockResult: Result<LoginOutput, Error> = .failure(TestError.noMockConfigured)
    private(set) var callCount = 0
    private(set) var lastCommand: LoginCommand?
    
    func handle(_ command: LoginCommand) async throws -> CommandResult<LoginOutput> {
        callCount += 1
        lastCommand = command
        
        switch mockResult {
        case .success(let output):
            return CommandResult.success(
                value: output,
                events: [LoginSuccessEvent(userId: output.user.id, timestamp: Date())]
            )
        case .failure(let error):
            return CommandResult.failure(error: error)
        }
    }
}
```

### Mock de EventBus

```swift
actor MockEventBus: EventBusProtocol {
    private(set) var publishedEvents: [any DomainEvent] = []
    private(set) var subscriptions: [UUID: Any] = [:]
    
    func publish<E: DomainEvent>(_ event: E) async {
        publishedEvents.append(event)
    }
    
    func subscribe<E: DomainEvent>(
        to eventType: E.Type,
        handler: @escaping (E) async -> Void
    ) async -> UUID {
        let id = UUID()
        subscriptions[id] = handler
        return id
    }
    
    func unsubscribe(_ id: UUID) async {
        subscriptions.removeValue(forKey: id)
    }
    
    // Helper para tests
    func simulateEvent<E: DomainEvent>(_ event: E) async {
        if let handler = subscriptions.values.first(where: { $0 is (E) async -> Void }) as? (E) async -> Void {
            await handler(event)
        }
    }
}
```

## Casos de Test Esenciales

### 1. Happy Path (Caso Exitoso)

```swift
@Test
func loadData_succeeds_updatesState() async {
    let (sut, handler) = await makeSUT()
    handler.mockResult = ExpectedData.stub()
    
    await sut.loadData()
    
    #expect(sut.data != nil)
    #expect(sut.isLoading == false)
    #expect(sut.error == nil)
}
```

### 2. Error Handling

```swift
@Test
func loadData_fails_setsError() async {
    let (sut, handler) = await makeSUT()
    handler.mockError = TestError.networkError
    
    await sut.loadData()
    
    #expect(sut.data == nil)
    #expect(sut.isLoading == false)
    #expect(sut.error != nil)
}
```

### 3. Loading States

```swift
@Test
func loadData_setsLoadingStateDuringExecution() async {
    let (sut, handler) = await makeSUT()
    
    // Configurar delay para capturar estado intermedio
    handler.delay = .milliseconds(100)
    handler.mockResult = Data.stub()
    
    let loadTask = Task {
        await sut.loadData()
    }
    
    // Verificar estado durante carga
    try? await Task.sleep(for: .milliseconds(50))
    #expect(sut.isLoading == true)
    
    await loadTask.value
    #expect(sut.isLoading == false)
}
```

### 4. Validation

```swift
@Test
func login_withEmptyEmail_setsValidationError() async {
    let (sut, _) = await makeSUT()
    sut.email = ""
    sut.password = "password123"
    
    let isValid = sut.validateForm()
    
    #expect(isValid == false)
    #expect(sut.error != nil)
}

@Test
func login_withShortPassword_setsValidationError() async {
    let (sut, _) = await makeSUT()
    sut.email = "test@example.com"
    sut.password = "short"
    
    let isValid = sut.validateForm()
    
    #expect(isValid == false)
}
```

### 5. Computed Properties

```swift
@Test
func isFormValid_withValidInputs_returnsTrue() async {
    let (sut, _) = await makeSUT()
    sut.email = "test@example.com"
    sut.password = "password123"
    
    #expect(sut.isFormValid == true)
}

@Test
func isFormValid_withEmptyEmail_returnsFalse() async {
    let (sut, _) = await makeSUT()
    sut.email = ""
    sut.password = "password123"
    
    #expect(sut.isFormValid == false)
}
```

### 6. Event Subscriptions

```swift
@Test
func refreshesOnLoginSuccessEvent() async throws {
    let eventBus = EventBus()
    let mockHandler = MockDashboardQueryHandler()
    mockHandler.mockResult = StudentDashboard.stub()
    
    let mediator = Mediator()
    await mediator.register(handler: mockHandler)
    
    let sut = DashboardViewModel(
        mediator: mediator,
        eventBus: eventBus,
        userId: UUID()
    )
    
    // Cargar inicial
    await sut.loadDashboard()
    let initialCount = await mockHandler.callCount
    
    // Publicar evento
    let event = LoginSuccessEvent(userId: sut.userId, timestamp: Date())
    await eventBus.publish(event)
    
    // Esperar propagación
    try await Task.sleep(for: .milliseconds(150))
    
    // Verificar refresh
    let finalCount = await mockHandler.callCount
    #expect(finalCount > initialCount)
}
```

## Stubs de Modelos

### Patrón de Stub Factory

```swift
extension User {
    static func stub(
        id: UUID = UUID(),
        email: String = "test@example.com",
        name: String = "Test User"
    ) -> User {
        User(id: id, email: email, name: name)
    }
}

extension StudentDashboard {
    static func stub(
        recentMaterials: [Material] = [],
        progressSummary: ProgressSummary? = nil,
        recentAttempts: [AssessmentAttempt] = []
    ) -> StudentDashboard {
        StudentDashboard(
            recentMaterials: recentMaterials,
            progressSummary: progressSummary,
            recentAttempts: recentAttempts,
            loadedAt: Date(),
            metadata: DashboardMetadata.stub()
        )
    }
}
```

## Cobertura Mínima Requerida

Cada ViewModel debe tener tests para:

| Categoría | Cobertura |
|-----------|-----------|
| Happy path | 100% de métodos públicos |
| Error handling | Todos los tipos de error |
| Loading states | Inicio y fin de carga |
| Validation | Todos los campos validados |
| Computed properties | Todas las condiciones |
| Event subscriptions | Todos los eventos suscritos |

**Meta de cobertura**: 80-85%

## Checklist de Testing

- [ ] Tests usan `@MainActor` en el Suite
- [ ] Patrón AAA (Arrange-Act-Assert)
- [ ] Mocks para todas las dependencias
- [ ] Happy path testeado
- [ ] Error handling testeado
- [ ] Loading states verificados
- [ ] Computed properties cubiertas
- [ ] Event subscriptions testeadas
- [ ] Stubs reutilizables creados

## See Also

- <doc:CreatingAViewModel>
- <doc:MediatorIntegration>
- <doc:EventBusUsage>
