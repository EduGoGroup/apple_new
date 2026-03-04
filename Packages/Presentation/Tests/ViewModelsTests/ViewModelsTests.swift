import Testing
import Foundation
@testable import EduPresentation
@testable import EduDomain
import EduCore
import EduFoundation

// MARK: - Test Error

struct TestError: Error, LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

// MARK: - LoginViewModel Tests

@Suite("LoginViewModel Tests")
@MainActor
struct LoginViewModelTests {

    @Test("LoginViewModel initializes with empty credentials")
    func testInitialState() {
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let viewModel = LoginViewModel(mediator: mediator)

        #expect(viewModel.email.isEmpty)
        #expect(viewModel.password.isEmpty)
        #expect(!viewModel.isLoading)
        #expect(!viewModel.isAuthenticated)
        #expect(viewModel.error == nil)
    }

    @Test("LoginViewModel validates empty email - isFormValid")
    func testValidatesEmptyEmail() {
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let viewModel = LoginViewModel(mediator: mediator)
        viewModel.email = ""
        viewModel.password = "password123"

        #expect(!viewModel.isFormValid)
    }

    @Test("LoginViewModel validates empty password - isFormValid")
    func testValidatesEmptyPassword() {
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let viewModel = LoginViewModel(mediator: mediator)
        viewModel.email = "test@edugo.com"
        viewModel.password = ""

        #expect(!viewModel.isFormValid)
    }

    @Test("LoginViewModel isFormValid with valid credentials")
    func testIsFormValidWithValidCredentials() {
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let viewModel = LoginViewModel(mediator: mediator)
        viewModel.email = "test@edugo.com"
        viewModel.password = "password123"

        #expect(viewModel.isFormValid)
    }

    @Test("LoginViewModel clearError works")
    func testClearError() {
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let viewModel = LoginViewModel(mediator: mediator)
        viewModel.error = TestError(message: "Test error")

        viewModel.clearError()

        #expect(viewModel.error == nil)
    }

    @Test("LoginViewModel errorMessage computed property works")
    func testErrorMessage() {
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let viewModel = LoginViewModel(mediator: mediator)

        #expect(viewModel.errorMessage == nil)

        viewModel.error = TestError(message: "Test error")
        #expect(viewModel.errorMessage != nil)
    }

    @Test("LoginViewModel hasError computed property works")
    func testHasError() {
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let viewModel = LoginViewModel(mediator: mediator)

        #expect(!viewModel.hasError)

        viewModel.error = TestError(message: "Test error")
        #expect(viewModel.hasError)
    }

    @Test("LoginViewModel logout clears state")
    func testLogout() {
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let viewModel = LoginViewModel(mediator: mediator)
        viewModel.email = "test@edugo.com"
        viewModel.password = "password123"
        viewModel.isAuthenticated = true

        viewModel.logout()

        #expect(viewModel.email.isEmpty)
        #expect(viewModel.password.isEmpty)
        #expect(!viewModel.isAuthenticated)
    }
}

// MARK: - LoginViewModel Rate Limiting Tests

@Suite("LoginViewModel Rate Limiting Tests")
@MainActor
struct LoginViewModelRateLimitingTests {

    @Test("errorMessage returns rate limiting message with retryAfter seconds")
    func testErrorMessageWithRetryAfterSeconds() {
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let viewModel = LoginViewModel(mediator: mediator)

        // Simula el mensaje que produce NetworkError.rateLimited(retryAfter: 120)
        // "Demasiadas solicitudes. Intente de nuevo en 120 segundos"
        viewModel.error = TestError(message: "Demasiadas solicitudes. Intente de nuevo en 120 segundos")

        let message = viewModel.errorMessage
        #expect(message == "Demasiados intentos fallidos. Intenta de nuevo en 2 minutos.")
    }

    @Test("errorMessage rounds up partial minutes using ceiling division")
    func testErrorMessageRoundsUpPartialMinutes() {
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let viewModel = LoginViewModel(mediator: mediator)

        // 119 segundos → ceil(119/60) = 2 minutos (no 1)
        viewModel.error = TestError(message: "Demasiadas solicitudes. Intente de nuevo en 119 segundos")

        let message = viewModel.errorMessage
        #expect(message == "Demasiados intentos fallidos. Intenta de nuevo en 2 minutos.")
    }

    @Test("errorMessage returns at least 1 minute for very short retryAfter")
    func testErrorMessageMinimumOneMinute() {
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let viewModel = LoginViewModel(mediator: mediator)

        // 30 segundos → ceil(30/60) = 1 minuto, max(1, 1) = 1
        viewModel.error = TestError(message: "Demasiadas solicitudes. Intente de nuevo en 30 segundos")

        let message = viewModel.errorMessage
        #expect(message == "Demasiados intentos fallidos. Intenta de nuevo en 1 minutos.")
    }

    @Test("errorMessage returns fallback when no retryAfter available")
    func testErrorMessageFallbackWithoutRetryAfter() {
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let viewModel = LoginViewModel(mediator: mediator)

        // Simula el mensaje sin segundos: NetworkError.rateLimited(retryAfter: nil)
        // "Demasiadas solicitudes. Intente de nuevo más tarde"
        viewModel.error = TestError(message: "Demasiadas solicitudes. Intente de nuevo más tarde")

        let message = viewModel.errorMessage
        #expect(message == "Demasiados intentos fallidos. Intenta de nuevo en 15 minutos.")
    }

    @Test("errorMessage returns rate limiting message from MediatorError.executionError with 429 keyword")
    func testErrorMessageFromMediatorExecutionError429() {
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let viewModel = LoginViewModel(mediator: mediator)

        viewModel.error = MediatorError.executionError(
            message: "429 rate limit exceeded",
            underlyingError: nil
        )

        let message = viewModel.errorMessage
        #expect(message != nil)
        #expect(message?.contains("Demasiados intentos fallidos") == true)
    }
}

// MARK: - AuditViewModel Tests

/// Mock del AuditDataProvider para tests unitarios.
actor MockAuditDataProvider: AuditDataProvider {
    private var stubbedListResult: (events: [AuditEventDTO], hasNextPage: Bool) = ([], false)
    private var stubbedGetEventResult: AuditEventDTO?
    private var stubbedSummaryResult: AuditSummaryDTO?
    private var stubbedError: Error?
    private(set) var listCallCount: Int = 0
    private(set) var lastListPage: Int = 0

    // MARK: - Setters for isolated mutation

    func setListResult(_ result: (events: [AuditEventDTO], hasNextPage: Bool)) {
        stubbedListResult = result
    }

    func setError(_ error: Error?) {
        stubbedError = error
    }

    // MARK: - AuditDataProvider

    func listEvents(page: Int, pageSize: Int, severity: String?) async throws -> (events: [AuditEventDTO], hasNextPage: Bool) {
        listCallCount += 1
        lastListPage = page
        if let error = stubbedError { throw error }
        return stubbedListResult
    }

    func getEvent(id: String) async throws -> AuditEventDTO {
        if let error = stubbedError { throw error }
        guard let event = stubbedGetEventResult else { throw TestError(message: "No stub") }
        return event
    }

    func getSummary() async throws -> AuditSummaryDTO {
        if let error = stubbedError { throw error }
        guard let summary = stubbedSummaryResult else { throw TestError(message: "No stub") }
        return summary
    }
}

@Suite("AuditViewModel Tests")
@MainActor
struct AuditViewModelTests {

    func makeEvent(id: String = "evt-001") -> AuditEventDTO {
        AuditEventDTO(
            id: id,
            actorEmail: "admin@edugo.com",
            actorRole: "superadmin",
            action: "CREATE",
            resourceType: "user",
            resourceId: "res-001",
            severity: "medium",
            category: "user_management",
            createdAt: "2026-03-04T10:30:00Z"
        )
    }

    func makeAuthContext(withAuditPermission: Bool) -> AuthContext {
        AuthContext(
            roleId: "role-001",
            roleName: withAuditPermission ? "superadmin" : "student",
            permissions: withAuditPermission ? ["audit:read"] : []
        )
    }

    @Test("AuditViewModel hasAccess is true when audit:read permission present")
    func testHasAccessWithPermission() {
        let provider = MockAuditDataProvider()
        let context = makeAuthContext(withAuditPermission: true)
        let viewModel = AuditViewModel(dataProvider: provider, authContext: context)

        #expect(viewModel.hasAccess == true)
    }

    @Test("AuditViewModel hasAccess is false without audit:read permission")
    func testHasAccessWithoutPermission() {
        let provider = MockAuditDataProvider()
        let context = makeAuthContext(withAuditPermission: false)
        let viewModel = AuditViewModel(dataProvider: provider, authContext: context)

        #expect(viewModel.hasAccess == false)
    }

    @Test("AuditViewModel hasAccess is false when authContext is nil")
    func testHasAccessWithNilContext() {
        let provider = MockAuditDataProvider()
        let viewModel = AuditViewModel(dataProvider: provider, authContext: nil)

        #expect(viewModel.hasAccess == false)
    }

    @Test("loadEvents sets accessDenied error when user lacks audit:read")
    func testLoadEventsAccessDenied() async {
        let provider = MockAuditDataProvider()
        let context = makeAuthContext(withAuditPermission: false)
        let viewModel = AuditViewModel(dataProvider: provider, authContext: context)

        await viewModel.loadEvents()

        #expect(viewModel.error is AuditViewModelError)
        if case .accessDenied = viewModel.error as? AuditViewModelError {
            // ok
        } else {
            Issue.record("Expected accessDenied error")
        }
        #expect(viewModel.isLoading == false)
    }

    @Test("loadEvents populates events on success")
    func testLoadEventsSuccess() async {
        let provider = MockAuditDataProvider()
        let events = [makeEvent(id: "evt-001"), makeEvent(id: "evt-002")]
        await provider.setListResult((events: events, hasNextPage: true))

        let context = makeAuthContext(withAuditPermission: true)
        let viewModel = AuditViewModel(dataProvider: provider, authContext: context)

        await viewModel.loadEvents()

        #expect(viewModel.events.count == 2)
        #expect(viewModel.events[0].id == "evt-001")
        #expect(viewModel.hasNextPage == true)
        #expect(viewModel.currentPage == 1)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
    }

    @Test("loadEvents resets to page 1 on each call")
    func testLoadEventsResetsPage() async {
        let provider = MockAuditDataProvider()
        await provider.setListResult((events: [makeEvent()], hasNextPage: false))

        let context = makeAuthContext(withAuditPermission: true)
        let viewModel = AuditViewModel(dataProvider: provider, authContext: context)

        await viewModel.loadEvents()
        await viewModel.loadEvents()

        let callCount = await provider.listCallCount
        let lastPage = await provider.lastListPage
        #expect(callCount == 2)
        #expect(lastPage == 1)
        #expect(viewModel.currentPage == 1)
    }

    @Test("loadEvents sets error on failure")
    func testLoadEventsError() async {
        let provider = MockAuditDataProvider()
        await provider.setError(TestError(message: "Network error"))

        let context = makeAuthContext(withAuditPermission: true)
        let viewModel = AuditViewModel(dataProvider: provider, authContext: context)

        await viewModel.loadEvents()

        #expect(viewModel.error != nil)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.events.isEmpty)
    }

    @Test("loadMore appends events and increments page when hasNextPage is true")
    func testLoadMoreAppendsEvents() async {
        let provider = MockAuditDataProvider()
        // First load returns page 1
        await provider.setListResult((events: [makeEvent(id: "evt-001")], hasNextPage: true))

        let context = makeAuthContext(withAuditPermission: true)
        let viewModel = AuditViewModel(dataProvider: provider, authContext: context)

        await viewModel.loadEvents()
        #expect(viewModel.events.count == 1)

        // Now return page 2 data
        await provider.setListResult((events: [makeEvent(id: "evt-002")], hasNextPage: false))
        await viewModel.loadMore()

        #expect(viewModel.events.count == 2)
        #expect(viewModel.events[1].id == "evt-002")
        #expect(viewModel.currentPage == 2)
        #expect(viewModel.hasNextPage == false)
        #expect(viewModel.isLoading == false)
    }

    @Test("loadMore does nothing when hasNextPage is false")
    func testLoadMoreSkippedWhenNoNextPage() async {
        let provider = MockAuditDataProvider()
        await provider.setListResult((events: [makeEvent()], hasNextPage: false))

        let context = makeAuthContext(withAuditPermission: true)
        let viewModel = AuditViewModel(dataProvider: provider, authContext: context)

        await viewModel.loadEvents()
        let countBefore = await provider.listCallCount
        await viewModel.loadMore()
        let countAfter = await provider.listCallCount

        // loadMore should not call the provider again
        #expect(countAfter == countBefore)
    }

    @Test("loadMore sets error on failure")
    func testLoadMoreError() async {
        let provider = MockAuditDataProvider()
        await provider.setListResult((events: [makeEvent()], hasNextPage: true))

        let context = makeAuthContext(withAuditPermission: true)
        let viewModel = AuditViewModel(dataProvider: provider, authContext: context)

        await viewModel.loadEvents()

        await provider.setError(TestError(message: "Network error on page 2"))
        await viewModel.loadMore()

        #expect(viewModel.error != nil)
        #expect(viewModel.isLoading == false)
    }

    @Test("clearError resets error state")
    func testClearError() async {
        let provider = MockAuditDataProvider()
        await provider.setError(TestError(message: "error"))

        let context = makeAuthContext(withAuditPermission: true)
        let viewModel = AuditViewModel(dataProvider: provider, authContext: context)

        await viewModel.loadEvents()
        #expect(viewModel.hasError == true)

        viewModel.clearError()
        #expect(viewModel.hasError == false)
    }
}

// MARK: - DashboardViewModel Tests

@Suite("DashboardViewModel Tests")
@MainActor
struct DashboardViewModelTests {

    @Test("DashboardViewModel initializes correctly")
    func testInitialState() {
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let userId = UUID()
        let viewModel = DashboardViewModel(mediator: mediator, eventBus: eventBus, userId: userId)

        #expect(viewModel.error == nil)
        #expect(viewModel.dashboard == nil)
        #expect(!viewModel.hasDashboard)
    }

    @Test("DashboardViewModel clearError works")
    func testClearError() {
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let userId = UUID()
        let viewModel = DashboardViewModel(mediator: mediator, eventBus: eventBus, userId: userId)
        viewModel.error = TestError(message: "Test error")

        viewModel.clearError()

        #expect(viewModel.error == nil)
    }

    @Test("DashboardViewModel errorMessage computed property works")
    func testErrorMessage() {
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let userId = UUID()
        let viewModel = DashboardViewModel(mediator: mediator, eventBus: eventBus, userId: userId)

        #expect(viewModel.errorMessage == nil)

        viewModel.error = TestError(message: "Test error")
        #expect(viewModel.errorMessage != nil)
    }

    @Test("DashboardViewModel hasError computed property works")
    func testHasError() {
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let userId = UUID()
        let viewModel = DashboardViewModel(mediator: mediator, eventBus: eventBus, userId: userId)

        #expect(!viewModel.hasError)

        viewModel.error = TestError(message: "Test error")
        #expect(viewModel.hasError)
    }
}

// MARK: - ContextSwitchViewModel Tests

@Suite("ContextSwitchViewModel Tests")
@MainActor
struct ContextSwitchViewModelTests {

    @Test("ContextSwitchViewModel initializes correctly")
    func testInitialState() {
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let roleManager = RoleManager()
        let eventBus = EventBus()
        let userId = UUID()

        let viewModel = ContextSwitchViewModel(
            mediator: mediator,
            roleManager: roleManager,
            eventBus: eventBus,
            userId: userId
        )

        #expect(!viewModel.hasContexts)
        #expect(viewModel.membershipCount == 0)
        #expect(viewModel.error == nil)
    }

    @Test("ContextSwitchViewModel clearError works")
    func testClearError() {
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let roleManager = RoleManager()
        let eventBus = EventBus()
        let userId = UUID()

        let viewModel = ContextSwitchViewModel(
            mediator: mediator,
            roleManager: roleManager,
            eventBus: eventBus,
            userId: userId
        )
        viewModel.error = TestError(message: "Test error")

        viewModel.clearError()

        #expect(viewModel.error == nil)
    }

    @Test("ContextSwitchViewModel reset clears state")
    func testReset() {
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let roleManager = RoleManager()
        let eventBus = EventBus()
        let userId = UUID()

        let viewModel = ContextSwitchViewModel(
            mediator: mediator,
            roleManager: roleManager,
            eventBus: eventBus,
            userId: userId
        )

        viewModel.reset()

        #expect(!viewModel.hasContexts)
        #expect(viewModel.membershipCount == 0)
        #expect(viewModel.currentMembershipId == nil)
    }

    @Test("ContextSwitchViewModel canSwitchContext is false with no contexts")
    func testCanSwitchContextFalseWithNoContexts() {
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let roleManager = RoleManager()
        let eventBus = EventBus()
        let userId = UUID()

        let viewModel = ContextSwitchViewModel(
            mediator: mediator,
            roleManager: roleManager,
            eventBus: eventBus,
            userId: userId
        )

        #expect(!viewModel.canSwitchContext)
    }

    @Test("ContextSwitchViewModel computed properties work")
    func testComputedProperties() {
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let roleManager = RoleManager()
        let eventBus = EventBus()
        let userId = UUID()

        let viewModel = ContextSwitchViewModel(
            mediator: mediator,
            roleManager: roleManager,
            eventBus: eventBus,
            userId: userId
        )

        #expect(!viewModel.isBusy)
        #expect(!viewModel.hasError)
        #expect(viewModel.schoolCount == 0)
        #expect(!viewModel.canSwitchSchool)
    }
}

// MARK: - Mediator Integration Tests

@Suite("Mediator Integration Tests")
struct MediatorIntegrationTests {

    @Test("Mediator initializes with disabled logging")
    func testMediatorInitialization() {
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        _ = mediator
    }

    @Test("EventBus initializes correctly")
    func testEventBusInitialization() {
        let eventBus = EventBus()
        _ = eventBus
    }

    @Test("RoleManager is accessible from ViewModels")
    func testRoleManagerAccessible() async {
        let roleManager = RoleManager()

        await roleManager.setRole(.student)
        let role = await roleManager.getCurrentRole()

        #expect(role == .student)
    }

    @Test("RoleManager permissions work correctly")
    func testRoleManagerPermissions() async {
        let roleManager = RoleManager()

        await roleManager.setRole(.teacher)
        let hasPermission = await roleManager.hasPermission(.viewMaterials)

        #expect(hasPermission)
    }
}

// MARK: - ViewModel Observable Pattern Tests

@Suite("ViewModel Observable Pattern Tests")
@MainActor
struct ViewModelObservablePatternTests {

    @Test("LoginViewModel properties are observable")
    func testLoginViewModelObservable() {
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let viewModel = LoginViewModel(mediator: mediator)

        viewModel.email = "test@example.com"
        viewModel.password = "password123"

        #expect(viewModel.email == "test@example.com")
        #expect(viewModel.password == "password123")
    }

    @Test("DashboardViewModel properties are observable")
    func testDashboardViewModelObservable() {
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let userId = UUID()
        let viewModel = DashboardViewModel(mediator: mediator, eventBus: eventBus, userId: userId)

        viewModel.includeProgress = false

        #expect(!viewModel.includeProgress)
    }

    @Test("ContextSwitchViewModel properties are observable")
    func testContextSwitchViewModelObservable() {
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let roleManager = RoleManager()
        let eventBus = EventBus()
        let userId = UUID()

        let viewModel = ContextSwitchViewModel(
            mediator: mediator,
            roleManager: roleManager,
            eventBus: eventBus,
            userId: userId
        )

        #expect(viewModel.membershipCount == 0)
        #expect(!viewModel.isLoading)
        #expect(!viewModel.isSwitching)
    }
}
