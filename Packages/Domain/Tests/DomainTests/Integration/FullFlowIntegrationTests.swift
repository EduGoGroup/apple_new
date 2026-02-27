// FullFlowIntegrationTests.swift
// EduDomainTests
//
// E2E integration tests validating multi-service flows.

import Testing
import Foundation
@testable import EduDomain
import EduCore
import EduInfrastructure
import EduDynamicUI

// MARK: - Mock NetworkClient

private final class IntegrationMockNetworkClient: NetworkClientProtocol, @unchecked Sendable {
    var requestDataHandler: ((HTTPRequest) async throws -> (Data, HTTPURLResponse))?
    var requestDataResults: [Result<(Data, HTTPURLResponse), Error>] = []
    private var callIndex = 0
    var recordedRequests: [HTTPRequest] = []

    func request<T: Decodable & Sendable>(_ request: HTTPRequest) async throws -> T {
        let (data, _) = try await requestData(request)
        return try JSONDecoder().decode(T.self, from: data)
    }

    func requestData(_ request: HTTPRequest) async throws -> (Data, HTTPURLResponse) {
        recordedRequests.append(request)
        if let handler = requestDataHandler {
            return try await handler(request)
        }
        guard callIndex < requestDataResults.count else {
            throw NetworkError.noData
        }
        let result = requestDataResults[callIndex]
        callIndex += 1
        return try result.get()
    }

    func upload<T: Decodable & Sendable>(data: Data, request: HTTPRequest) async throws -> T {
        throw NetworkError.noData
    }

    func upload<T: Decodable & Sendable>(fileURL: URL, request: HTTPRequest) async throws -> T {
        throw NetworkError.noData
    }

    func download(_ request: HTTPRequest) async throws -> URL {
        throw NetworkError.noData
    }

    func downloadData(_ request: HTTPRequest) async throws -> Data {
        throw NetworkError.noData
    }

    func reset() {
        callIndex = 0
        recordedRequests.removeAll()
    }
}

// MARK: - Helpers

private func makeSuccessResponse(json: String = "{}") -> (Data, HTTPURLResponse) {
    let data = json.data(using: .utf8)!
    let response = HTTPURLResponse(
        url: URL(string: "https://test.com")!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
    )!
    return (data, response)
}

// ============================================================
// MARK: - 1. Contract Resolution Tests
// ============================================================

@Suite("Integration: Contract Resolution")
struct ContractResolutionIntegrationTests {

    @Test("Registry resolves all dashboard contracts by role")
    @MainActor
    func registryResolvesAllDashboards() {
        let registry = ContractRegistry()
        registry.registerDefaults()

        let dashboardKeys = [
            "dashboard-superadmin",
            "dashboard-schooladmin",
            "dashboard-teacher",
            "dashboard-student",
            "dashboard-guardian"
        ]

        for key in dashboardKeys {
            let contract = registry.contract(for: key)
            #expect(contract != nil, "Contract for \(key) should exist")
            #expect(contract?.screenKey == key)
        }
    }

    @Test("Registry resolves CRUD pair for schools")
    @MainActor
    func registryResolvesCrudPair() {
        let registry = ContractRegistry()
        registry.registerDefaults()

        let list = registry.contract(for: "schools-list")
        let crud = registry.contract(for: "schools-crud")

        #expect(list != nil)
        #expect(crud != nil)
        #expect(list?.resource == "schools")
        #expect(crud?.resource == "schools")
    }

    @Test("Registry returns nil for unregistered key")
    @MainActor
    func registryReturnsNilForUnknown() {
        let registry = ContractRegistry()
        registry.registerDefaults()

        let contract = registry.contract(for: "nonexistent-screen")
        #expect(contract == nil)
    }

    @Test("Dashboard contracts require dashboard:read for loadData")
    @MainActor
    func dashboardPermissions() {
        let registry = ContractRegistry()
        registry.registerDefaults()

        let contract = registry.contract(for: "dashboard-superadmin")
        let permission = contract?.permissionFor(event: .loadData)
        #expect(permission == "dashboard:read")
    }

    @Test("Total default contracts count")
    @MainActor
    func totalContractsCount() {
        let registry = ContractRegistry()
        registry.registerDefaults()
        // 2 auth + 5 dashboards + 14 CRUD (7 pairs) + 2 roles/perms + 1 guardian
        #expect(registry.count >= 20)
    }
}

// ============================================================
// MARK: - 2. Event Orchestration Tests
// ============================================================

@Suite("Integration: Event Orchestration")
struct EventOrchestrationIntegrationTests {

    @Test("Load event flows through contract → permission check → data fetch")
    @MainActor
    func loadEventFullFlow() async {
        let registry = ContractRegistry()
        registry.registerDefaults()

        let client = IntegrationMockNetworkClient()
        let statsJson = """
        {"items":[{"label":"Total","value":"42"}]}
        """
        client.requestDataHandler = { _ in makeSuccessResponse(json: statsJson) }

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
            screenKey: "dashboard-superadmin",
            userContext: ScreenUserContext(
                roleId: "1",
                roleName: "super_admin",
                permissions: ["dashboard:read"]
            )
        )

        let result = await orchestrator.execute(event: .loadData, context: context)
        if case .success(_, let data) = result {
            #expect(data != nil)
        } else {
            #expect(Bool(false), "Expected success, got \(result)")
        }
    }

    @Test("Permission denied blocks event execution")
    @MainActor
    func permissionDeniedBlocksEvent() async {
        let registry = ContractRegistry()
        registry.registerDefaults()

        let client = IntegrationMockNetworkClient()
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

        // User without dashboard:read
        let context = EventContext(
            screenKey: "dashboard-student",
            userContext: ScreenUserContext(
                roleId: "99",
                roleName: "guest",
                permissions: []
            )
        )

        let result = await orchestrator.execute(event: .loadData, context: context)
        if case .permissionDenied = result {
            // Expected
        } else {
            #expect(Bool(false), "Expected permissionDenied, got \(result)")
        }
    }

    @Test("Write event with offline fallback enqueues mutation")
    @MainActor
    func writeOfflineFallback() async {
        let registry = ContractRegistry()
        registry.registerDefaults()

        let client = IntegrationMockNetworkClient()
        client.requestDataHandler = { _ in throw NetworkError.networkFailure(underlyingError: "offline") }

        let loader = DataLoader(
            networkClient: client,
            adminBaseURL: "https://admin.test",
            mobileBaseURL: "https://mobile.test"
        )

        let queue = MutationQueue()
        await queue.clear()

        let orchestrator = EventOrchestrator(
            registry: registry,
            networkClient: client,
            dataLoader: loader,
            mutationQueue: queue
        )

        let context = EventContext(
            screenKey: "schools-list",
            userContext: ScreenUserContext(
                roleId: "1",
                roleName: "admin",
                permissions: ["schools:create"]
            ),
            fieldValues: ["name": "Test School"]
        )

        let result = await orchestrator.execute(event: .saveNew, context: context)

        if case .success(let message, _) = result {
            #expect(message.contains("offline"))
        } else {
            #expect(Bool(false), "Expected offline success, got \(result)")
        }

        let pendingCount = await queue.pendingCount
        #expect(pendingCount == 1)
    }

    @Test("SelectItem navigates to crud screen with id")
    @MainActor
    func selectItemNavigation() async {
        let registry = ContractRegistry()
        registry.registerDefaults()

        let client = IntegrationMockNetworkClient()
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
            screenKey: "users-list",
            userContext: ScreenUserContext(
                roleId: "1",
                roleName: "admin",
                permissions: ["users:read"]
            ),
            selectedItem: ["id": .string("user-123")]
        )

        let result = await orchestrator.execute(event: .selectItem, context: context)
        if case .navigateTo(let key, let params) = result {
            #expect(key == "users-crud")
            #expect(params["id"] == "user-123")
        } else {
            #expect(Bool(false), "Expected navigateTo, got \(result)")
        }
    }
}

// ============================================================
// MARK: - 3. Offline Flow Tests
// ============================================================

@Suite("Integration: Offline Flow", .serialized)
struct OfflineFlowIntegrationTests {

    @Test("MutationQueue → SyncEngine processes successfully")
    func fullOfflineSync() async throws {
        // Clean state
        UserDefaults.standard.removeObject(forKey: "com.edugo.mutation.queue")
        let queue = MutationQueue()
        await queue.clear()

        // Enqueue mutations
        let mutation1 = PendingMutation(
            id: "m1",
            endpoint: "/api/v1/users",
            method: "POST",
            body: .object(["name": .string("Alice")])
        )
        let mutation2 = PendingMutation(
            id: "m2",
            endpoint: "/api/v1/users",
            method: "PUT",
            body: .object(["name": .string("Bob")])
        )

        try await queue.enqueue(mutation1)
        try await queue.enqueue(mutation2)

        let pendingBefore = await queue.pendingCount
        #expect(pendingBefore == 2)

        // Process with successful network
        let client = IntegrationMockNetworkClient()
        client.requestDataResults = [
            .success(makeSuccessResponse()),
            .success(makeSuccessResponse())
        ]

        let engine = SyncEngine(mutationQueue: queue, networkClient: client)
        await engine.processQueue()

        let state = await engine.syncState
        #expect(state == .completed)

        let pendingAfter = await queue.pendingCount
        #expect(pendingAfter == 0)
    }

    @Test("SyncEngine handles mixed success and failure")
    func mixedSuccessFailure() async throws {
        UserDefaults.standard.removeObject(forKey: "com.edugo.mutation.queue")
        let queue = MutationQueue()
        await queue.clear()

        let mutation1 = PendingMutation(
            id: "ok",
            endpoint: "/api/v1/users/1",
            method: "PUT",
            body: .null
        )
        let mutation2 = PendingMutation(
            id: "fail",
            endpoint: "/api/v1/users/2",
            method: "DELETE",
            body: .null
        )

        try await queue.enqueue(mutation1)
        try await queue.enqueue(mutation2)

        let client = IntegrationMockNetworkClient()
        client.requestDataResults = [
            .success(makeSuccessResponse()),
            .failure(NetworkError.unauthorized)
        ]

        let engine = SyncEngine(mutationQueue: queue, networkClient: client)
        await engine.processQueue()

        // First mutation completed, second failed
        let state = await engine.syncState
        #expect(state == .completed)
    }

    @Test("ConflictResolver: 404 → skipSilently, 409 → applyLocal, 500 → retry")
    func conflictResolutionStrategies() {
        let mutation = PendingMutation(
            endpoint: "/api/v1/test",
            method: "POST",
            body: .null
        )

        // 404 → skip
        let r404 = OfflineConflictResolver.resolve(
            mutation: mutation,
            serverError: .notFound
        )
        #expect(r404 == .skipSilently)

        // 409 → applyLocal
        let r409 = OfflineConflictResolver.resolve(
            mutation: mutation,
            serverError: .serverError(statusCode: 409, message: "conflict")
        )
        #expect(r409 == .applyLocal)

        // 500 → retry
        let r500 = OfflineConflictResolver.resolve(
            mutation: mutation,
            serverError: .serverError(statusCode: 500, message: "internal")
        )
        #expect(r500 == .retry)

        // 400 → fail
        let r400 = OfflineConflictResolver.resolve(
            mutation: mutation,
            serverError: .serverError(statusCode: 400, message: "bad request")
        )
        #expect(r400 == .fail)

        // timeout → retry
        let rTimeout = OfflineConflictResolver.resolve(
            mutation: mutation,
            serverError: .timeout
        )
        #expect(rTimeout == .retry)

        // network failure → retry
        let rNetwork = OfflineConflictResolver.resolve(
            mutation: mutation,
            serverError: .networkFailure(underlyingError: "no internet")
        )
        #expect(rNetwork == .retry)
    }

    @Test("MutationQueue dedup replaces same endpoint+method")
    func dedupIntegration() async throws {
        UserDefaults.standard.removeObject(forKey: "com.edugo.mutation.queue")
        let queue = MutationQueue()
        await queue.clear()

        // Same endpoint + method → dedup
        let v1 = PendingMutation(id: "v1", endpoint: "/api/v1/users", method: "POST", body: .string("first"))
        let v2 = PendingMutation(id: "v2", endpoint: "/api/v1/users", method: "POST", body: .string("second"))

        try await queue.enqueue(v1)
        try await queue.enqueue(v2)

        let count = await queue.pendingCount
        #expect(count == 1)

        let next = await queue.dequeue()
        #expect(next?.id == "v2")
    }
}

// ============================================================
// MARK: - 4. i18n Flow Tests
// ============================================================

@Suite("Integration: i18n Flow")
struct I18nFlowIntegrationTests {

    @Test("GlossaryProvider resolves terms from bundle")
    @MainActor
    func glossaryFromBundle() {
        let provider = GlossaryProvider()

        // Before update: returns default
        let defaultTerm = provider.term(for: .orgNameSingular)
        #expect(defaultTerm == "Institución")

        // Update from bundle
        let bundle = UserDataBundle(
            menu: [],
            permissions: [],
            screens: [:],
            availableContexts: [],
            hashes: [:],
            glossary: [
                "org.name_singular": "Colegio",
                "org.name_plural": "Colegios"
            ]
        )
        provider.updateFromBundle(bundle)

        let resolved = provider.term(for: .orgNameSingular)
        #expect(resolved == "Colegio")

        let plural = provider.term(for: .orgNamePlural)
        #expect(plural == "Colegios")
    }

    @Test("GlossaryProvider falls back to key for unknown terms")
    @MainActor
    func glossaryFallback() {
        let provider = GlossaryProvider()
        let unknown = provider.term(for: "custom.unknown_key")
        #expect(unknown == "custom.unknown_key")
    }

    @Test("ServerStringResolver resolves server strings with fallback")
    @MainActor
    func serverStringsFromBundle() {
        let resolver = ServerStringResolver()

        // Before update: returns fallback
        let fallback = resolver.resolve(key: "welcome.title", fallback: "Bienvenido")
        #expect(fallback == "Bienvenido")

        // Update from bundle
        let bundle = UserDataBundle(
            menu: [],
            permissions: [],
            screens: [:],
            availableContexts: [],
            hashes: [:],
            strings: [
                "welcome.title": "Welcome to EduGo",
                "nav.home": "Home"
            ]
        )
        resolver.updateFromBundle(bundle)

        let resolved = resolver.resolve(key: "welcome.title", fallback: "Bienvenido")
        #expect(resolved == "Welcome to EduGo")

        let nav = resolver.resolve(key: "nav.home", fallback: "Inicio")
        #expect(nav == "Home")

        // Missing key still falls back
        let missing = resolver.resolve(key: "nonexistent", fallback: "Default")
        #expect(missing == "Default")
    }

    @Test("LocaleService persists and resolves locale")
    @MainActor
    func localeServiceFlow() {
        // Resolve locale chain
        #expect(LocaleService.resolvedLocale(from: "es") == "es")
        #expect(LocaleService.resolvedLocale(from: "en") == "en")
        #expect(LocaleService.resolvedLocale(from: "es-CO") == "es")
        #expect(LocaleService.resolvedLocale(from: "fr") == "en")
        #expect(LocaleService.resolvedLocale(from: "pt-BR") == "pt-BR")
    }

    @Test("GlossaryProvider + ServerStringResolver update together from same bundle")
    @MainActor
    func combinedI18nUpdate() {
        let glossary = GlossaryProvider()
        let strings = ServerStringResolver()

        let bundle = UserDataBundle(
            menu: [],
            permissions: [],
            screens: [:],
            availableContexts: [],
            hashes: [:],
            glossary: ["member.student": "Alumno"],
            strings: ["btn.save": "Guardar"]
        )

        glossary.updateFromBundle(bundle)
        strings.updateFromBundle(bundle)

        #expect(glossary.term(for: .memberStudent) == "Alumno")
        #expect(strings.resolve(key: "btn.save", fallback: "Save") == "Guardar")
    }
}

// ============================================================
// MARK: - 5. Cross-Service Integration Tests
// ============================================================

@Suite("Integration: Cross-Service Flows")
struct CrossServiceIntegrationTests {

    @Test("Orchestrator + MutationQueue: write failure enqueues, engine processes later")
    @MainActor
    func writeFailureToOfflineToSync() async throws {
        UserDefaults.standard.removeObject(forKey: "com.edugo.mutation.queue")

        let registry = ContractRegistry()
        registry.registerDefaults()

        // Client fails on first call (simulates offline)
        let client = IntegrationMockNetworkClient()
        var callCount = 0
        client.requestDataHandler = { _ in
            callCount += 1
            if callCount <= 1 {
                throw NetworkError.networkFailure(underlyingError: "offline")
            }
            return makeSuccessResponse()
        }

        let loader = DataLoader(
            networkClient: client,
            adminBaseURL: "https://admin.test",
            mobileBaseURL: "https://mobile.test"
        )

        let queue = MutationQueue()
        await queue.clear()

        let orchestrator = EventOrchestrator(
            registry: registry,
            networkClient: client,
            dataLoader: loader,
            mutationQueue: queue
        )

        // Step 1: Execute write → fails → enqueued offline
        let context = EventContext(
            screenKey: "schools-list",
            userContext: ScreenUserContext(
                roleId: "1",
                roleName: "admin",
                permissions: ["schools:create"]
            ),
            fieldValues: ["name": "New School"]
        )

        let result = await orchestrator.execute(event: .saveNew, context: context)
        if case .success(let msg, _) = result {
            #expect(msg.contains("offline"))
        }

        let queued = await queue.pendingCount
        #expect(queued == 1)

        // Step 2: Network comes back, SyncEngine processes queue
        // Reset client to succeed
        let syncClient = IntegrationMockNetworkClient()
        syncClient.requestDataResults = [.success(makeSuccessResponse())]

        let engine = SyncEngine(mutationQueue: queue, networkClient: syncClient)
        await engine.processQueue()

        let afterSync = await queue.pendingCount
        #expect(afterSync == 0)
    }

    @Test("Contract registry + orchestrator: create navigates to crud form")
    @MainActor
    func createNavigationFlow() async {
        let registry = ContractRegistry()
        registry.registerDefaults()

        let client = IntegrationMockNetworkClient()
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

        // Schools list → create → navigates to schools-crud
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
            #expect(Bool(false), "Expected navigateTo schools-crud")
        }
    }

    @Test("Field mapping applied to API response data")
    func fieldMappingApplied() {
        let data: [String: JSONValue] = [
            "items": .array([
                .object([
                    "is_active": .bool(true),
                    "full_name": .string("Alice"),
                    "created_at": .string("2026-01-01")
                ])
            ])
        ]

        let mapping = ["is_active": "status", "full_name": "name"]
        let defaults = ["avatar": "/default.png"]

        let result = EventOrchestrator.applyFieldMapping(
            data: data,
            mapping: mapping,
            defaults: defaults
        )

        if case .array(let items) = result["items"],
           case .object(let first) = items.first {
            // is_active bool mapped to "Activo" text
            #expect(first["status"] == .string("Activo"))
            // full_name mapped to name
            #expect(first["name"] == .string("Alice"))
            // Default injected
            #expect(first["avatar"] == .string("/default.png"))
            // created_at removed
            #expect(first["created_at"] == nil)
        } else {
            #expect(Bool(false), "Expected mapped items array")
        }
    }
}
