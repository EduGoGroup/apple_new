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
