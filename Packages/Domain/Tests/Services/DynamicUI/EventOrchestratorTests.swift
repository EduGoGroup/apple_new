import Foundation
import Testing
@testable import EduDomain
import EduCore
import EduInfrastructure
import EduDynamicUI

// MARK: - Mock NetworkClient

private actor MockNetworkClient: NetworkClientProtocol {
    var shouldFail = false
    var lastRequest: HTTPRequest?

    func setShouldFail(_ value: Bool) {
        shouldFail = value
    }

    func request<T: Decodable & Sendable>(_ request: HTTPRequest) async throws -> T {
        lastRequest = request
        if shouldFail {
            throw URLError(.notConnectedToInternet)
        }
        if let empty = EmptyResponse() as? T {
            return empty
        }
        throw URLError(.cannotDecodeContentData)
    }

    func requestData(_ request: HTTPRequest) async throws -> (Data, HTTPURLResponse) {
        lastRequest = request
        if shouldFail {
            throw URLError(.notConnectedToInternet)
        }
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        return (Data(), response)
    }

    func upload<T: Decodable & Sendable>(data: Data, request: HTTPRequest) async throws -> T {
        throw URLError(.unsupportedURL)
    }

    func upload<T: Decodable & Sendable>(fileURL: URL, request: HTTPRequest) async throws -> T {
        throw URLError(.unsupportedURL)
    }

    func download(_ request: HTTPRequest) async throws -> URL {
        throw URLError(.unsupportedURL)
    }

    func downloadData(_ request: HTTPRequest) async throws -> Data {
        throw URLError(.unsupportedURL)
    }
}

@Suite("EventOrchestrator Tests")
struct EventOrchestratorTests {

    @Test("Returns error when no contract found")
    @MainActor
    func noContract() async {
        let registry = ContractRegistry()
        let client = MockNetworkClient()
        let loader = DataLoader(
            networkClient: client,
            adminBaseURL: "https://admin.test",
            mobileBaseURL: "https://mobile.test"
        )
        let orchestrator = EventOrchestrator(
            registry: registry,
            networkClient: client,
            dataLoader: loader
        )
        let context = EventContext(
            screenKey: "nonexistent",
            userContext: .anonymous
        )
        let result = await orchestrator.execute(event: .loadData, context: context)
        if case .error(let message, _) = result {
            #expect(message.contains("No contract"))
        } else {
            #expect(Bool(false), "Expected error result")
        }
    }

    @Test("Returns permissionDenied when user lacks permission")
    @MainActor
    func permissionDenied() async {
        let registry = ContractRegistry()
        registry.register(SchoolsListContract())
        let client = MockNetworkClient()
        let loader = DataLoader(
            networkClient: client,
            adminBaseURL: "https://admin.test",
            mobileBaseURL: "https://mobile.test"
        )
        let orchestrator = EventOrchestrator(
            registry: registry,
            networkClient: client,
            dataLoader: loader
        )
        let context = EventContext(
            screenKey: "schools-list",
            userContext: ScreenUserContext(roleId: "1", roleName: "guest", permissions: [])
        )
        let result = await orchestrator.execute(event: .loadData, context: context)
        if case .permissionDenied = result {
            // Expected
        } else {
            #expect(Bool(false), "Expected permissionDenied")
        }
    }

    @Test("Executes custom event handler")
    @MainActor
    func customEvent() async {
        let registry = ContractRegistry()
        registry.register(SettingsContract())
        let client = MockNetworkClient()
        let loader = DataLoader(
            networkClient: client,
            adminBaseURL: "https://admin.test",
            mobileBaseURL: "https://mobile.test"
        )
        let orchestrator = EventOrchestrator(
            registry: registry,
            networkClient: client,
            dataLoader: loader
        )
        let context = EventContext(
            screenKey: "settings",
            userContext: .anonymous
        )
        let result = await orchestrator.executeCustom(eventId: "logout", context: context)
        if case .logout = result {
            // Expected
        } else {
            #expect(Bool(false), "Expected logout result")
        }
    }

    @Test("Custom event returns noOp for unknown eventId")
    @MainActor
    func unknownCustomEvent() async {
        let registry = ContractRegistry()
        registry.register(SettingsContract())
        let client = MockNetworkClient()
        let loader = DataLoader(
            networkClient: client,
            adminBaseURL: "https://admin.test",
            mobileBaseURL: "https://mobile.test"
        )
        let orchestrator = EventOrchestrator(
            registry: registry,
            networkClient: client,
            dataLoader: loader
        )
        let context = EventContext(
            screenKey: "settings",
            userContext: .anonymous
        )
        let result = await orchestrator.executeCustom(eventId: "unknown", context: context)
        if case .noOp = result {
            // Expected
        } else {
            #expect(Bool(false), "Expected noOp result")
        }
    }

    @Test("Login contract validates empty fields")
    @MainActor
    func loginValidation() async {
        let registry = ContractRegistry()
        registry.register(LoginContract())
        let client = MockNetworkClient()
        let loader = DataLoader(
            networkClient: client,
            adminBaseURL: "https://admin.test",
            mobileBaseURL: "https://mobile.test"
        )
        let orchestrator = EventOrchestrator(
            registry: registry,
            networkClient: client,
            dataLoader: loader
        )
        let context = EventContext(
            screenKey: "login",
            userContext: .anonymous,
            fieldValues: [:]
        )
        let result = await orchestrator.executeCustom(eventId: "submit-login", context: context)
        if case .error(let message, _) = result {
            #expect(message.contains("required"))
        } else {
            #expect(Bool(false), "Expected error result for empty login fields")
        }
    }

    @Test("Login contract returns submitTo with valid fields")
    @MainActor
    func loginSubmit() async {
        let registry = ContractRegistry()
        registry.register(LoginContract())
        let client = MockNetworkClient()
        let loader = DataLoader(
            networkClient: client,
            adminBaseURL: "https://admin.test",
            mobileBaseURL: "https://mobile.test"
        )
        let orchestrator = EventOrchestrator(
            registry: registry,
            networkClient: client,
            dataLoader: loader
        )
        let context = EventContext(
            screenKey: "login",
            userContext: .anonymous,
            fieldValues: ["email": "user@test.com", "password": "pass123"]
        )
        let result = await orchestrator.executeCustom(eventId: "submit-login", context: context)
        if case .submitTo(let endpoint, let method, _) = result {
            #expect(endpoint == "iam:/api/v1/auth/login")
            #expect(method == "POST")
        } else {
            #expect(Bool(false), "Expected submitTo result")
        }
    }

    @Test("Create event navigates to form screen")
    @MainActor
    func createNavigatesToForm() async {
        let registry = ContractRegistry()
        registry.register(SchoolsListContract())
        registry.register(SchoolCrudContract())
        let client = MockNetworkClient()
        let loader = DataLoader(
            networkClient: client,
            adminBaseURL: "https://admin.test",
            mobileBaseURL: "https://mobile.test"
        )
        let orchestrator = EventOrchestrator(
            registry: registry,
            networkClient: client,
            dataLoader: loader
        )
        let context = EventContext(
            screenKey: "schools-list",
            userContext: ScreenUserContext(
                roleId: "1",
                roleName: "admin",
                permissions: ["schools:create"]
            )
        )
        let result = await orchestrator.execute(event: .create, context: context)
        if case .navigateTo(let key, _) = result {
            #expect(key == "schools-crud")
        } else {
            #expect(Bool(false), "Expected navigateTo result")
        }
    }

    @Test("SelectItem navigates to detail")
    @MainActor
    func selectItemNavigation() async {
        let registry = ContractRegistry()
        registry.register(SchoolsListContract())
        let client = MockNetworkClient()
        let loader = DataLoader(
            networkClient: client,
            adminBaseURL: "https://admin.test",
            mobileBaseURL: "https://mobile.test"
        )
        let orchestrator = EventOrchestrator(
            registry: registry,
            networkClient: client,
            dataLoader: loader
        )
        let context = EventContext(
            screenKey: "schools-list",
            userContext: ScreenUserContext(
                roleId: "1",
                roleName: "admin",
                permissions: ["schools:read"]
            ),
            selectedItem: ["id": .string("school-42")]
        )
        let result = await orchestrator.execute(event: .selectItem, context: context)
        if case .navigateTo(let key, let params) = result {
            #expect(key == "schools-crud")
            #expect(params["id"] == "school-42")
        } else {
            #expect(Bool(false), "Expected navigateTo result")
        }
    }
}
