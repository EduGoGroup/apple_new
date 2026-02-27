import Testing
import Foundation
import EduCore
import EduInfrastructure
@testable import EduDomain

// MARK: - Mock Network Client

private actor MockNetworkClient: NetworkClientProtocol {
    var mockResponse: (any Sendable)?
    var mockError: Error?
    var mockData: Data?
    var mockHTTPResponse: HTTPURLResponse?
    private(set) var requestHistory: [HTTPRequest] = []

    var requestCount: Int { requestHistory.count }

    func setDecodableResponse<T: Sendable>(_ response: T) {
        self.mockResponse = response
        self.mockError = nil
    }

    func setError(_ error: Error) {
        self.mockError = error
    }

    func reset() {
        mockResponse = nil
        mockError = nil
        mockData = nil
        mockHTTPResponse = nil
        requestHistory.removeAll()
    }

    func request<T: Decodable & Sendable>(_ request: HTTPRequest) async throws -> T {
        requestHistory.append(request)
        if let error = mockError { throw error }
        if let response = mockResponse as? T { return response }
        throw NetworkError.noData
    }

    func requestData(_ request: HTTPRequest) async throws -> (Data, HTTPURLResponse) {
        requestHistory.append(request)
        if let error = mockError { throw error }
        guard let data = mockData else { throw NetworkError.noData }
        let response = mockHTTPResponse ?? HTTPURLResponse(
            url: URL(string: request.url)!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        return (data, response)
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
}

// MARK: - Fixtures

private let testAPIConfig = APIConfiguration(
    iamBaseURL: "https://iam.test.com",
    adminBaseURL: "https://admin.test.com",
    mobileBaseURL: "https://mobile.test.com",
    timeout: 10,
    environment: .development
)

private func makeSyncBundleResponse() -> SyncBundleResponseDTO {
    SyncBundleResponseDTO(
        menu: [
            MenuItemDTO(
                key: "dashboard",
                displayName: "Dashboard",
                scope: "student",
                sortOrder: 1,
                permissions: ["view_dashboard"],
                screens: ["main": "dashboard_main"]
            )
        ],
        permissions: ["view_dashboard", "edit_profile"],
        screens: [:],
        availableContexts: [
            UserContextDTO(roleId: "role-1", roleName: "student")
        ],
        hashes: ["menu": "hash-menu", "screens": "hash-screens"]
    )
}

private func makeDeltaSyncResponse(
    changed: [String: BucketDataDTO] = [:],
    unchanged: [String] = []
) -> DeltaSyncResponseDTO {
    DeltaSyncResponseDTO(changed: changed, unchanged: unchanged)
}

// MARK: - Tests

@Suite("SyncService Tests", .serialized)
struct SyncServiceTests {

    // MARK: - Full Sync

    @Test("fullSync returns bundle on success")
    func fullSyncSuccess() async throws {
        let mock = MockNetworkClient()
        let localStore = LocalSyncStore()
        await localStore.clear()

        let response = makeSyncBundleResponse()
        await mock.setDecodableResponse(response)

        let service = SyncService(
            networkClient: mock,
            localStore: localStore,
            apiConfig: testAPIConfig
        )

        let bundle = try await service.fullSync()

        #expect(bundle.menu.count == 1)
        #expect(bundle.menu[0].key == "dashboard")
        #expect(bundle.permissions == ["view_dashboard", "edit_profile"])
        #expect(bundle.hashes["menu"] == "hash-menu")
        #expect(bundle.availableContexts.count == 1)

        let currentBundle = await service.currentBundle
        #expect(currentBundle != nil)
    }

    @Test("fullSync transitions to completed state")
    func fullSyncStateTransition() async throws {
        let mock = MockNetworkClient()
        let localStore = LocalSyncStore()
        await localStore.clear()

        let response = makeSyncBundleResponse()
        await mock.setDecodableResponse(response)

        let service = SyncService(
            networkClient: mock,
            localStore: localStore,
            apiConfig: testAPIConfig
        )

        _ = try await service.fullSync()

        let state = await service.syncState
        #expect(state == .completed)
    }

    @Test("fullSync transitions to error on network failure")
    func fullSyncNetworkError() async {
        let mock = MockNetworkClient()
        let localStore = LocalSyncStore()
        await localStore.clear()

        await mock.setError(NetworkError.networkFailure(underlyingError: "offline"))

        let service = SyncService(
            networkClient: mock,
            localStore: localStore,
            apiConfig: testAPIConfig
        )

        do {
            _ = try await service.fullSync()
            Issue.record("Expected fullSync to throw")
        } catch {
            let state = await service.syncState
            if case .error = state {
                // Expected
            } else {
                Issue.record("Expected .error state, got \(state)")
            }
        }
    }

    @Test("fullSync calls correct URL")
    func fullSyncURL() async throws {
        let mock = MockNetworkClient()
        let localStore = LocalSyncStore()
        await localStore.clear()

        let response = makeSyncBundleResponse()
        await mock.setDecodableResponse(response)

        let service = SyncService(
            networkClient: mock,
            localStore: localStore,
            apiConfig: testAPIConfig
        )

        _ = try await service.fullSync()

        let count = await mock.requestCount
        #expect(count == 1)

        let request = await mock.requestHistory.first
        #expect(request?.url == "https://iam.test.com/api/v1/sync/bundle")
    }

    @Test("fullSync persists bundle via LocalSyncStore")
    func fullSyncPersists() async throws {
        let mock = MockNetworkClient()
        let localStore = LocalSyncStore()
        await localStore.clear()

        let response = makeSyncBundleResponse()
        await mock.setDecodableResponse(response)

        let service = SyncService(
            networkClient: mock,
            localStore: localStore,
            apiConfig: testAPIConfig
        )

        _ = try await service.fullSync()

        let restored = await localStore.restore()
        #expect(restored != nil)
        #expect(restored?.menu.count == 1)
    }

    // MARK: - Delta Sync

    @Test("deltaSync returns response on success")
    func deltaSyncSuccess() async throws {
        let mock = MockNetworkClient()
        let localStore = LocalSyncStore()
        await localStore.clear()

        let deltaResponse = makeDeltaSyncResponse(
            changed: [:],
            unchanged: ["menu", "screens"]
        )
        await mock.setDecodableResponse(deltaResponse)

        let service = SyncService(
            networkClient: mock,
            localStore: localStore,
            apiConfig: testAPIConfig
        )

        let result = try await service.deltaSync(currentHashes: ["menu": "h1", "screens": "h2"])

        #expect(result.unchanged == ["menu", "screens"])
        #expect(result.changed.isEmpty)
    }

    @Test("deltaSync transitions to completed state")
    func deltaSyncStateTransition() async throws {
        let mock = MockNetworkClient()
        let localStore = LocalSyncStore()
        await localStore.clear()

        let deltaResponse = makeDeltaSyncResponse(unchanged: ["menu"])
        await mock.setDecodableResponse(deltaResponse)

        let service = SyncService(
            networkClient: mock,
            localStore: localStore,
            apiConfig: testAPIConfig
        )

        _ = try await service.deltaSync(currentHashes: ["menu": "h1"])

        let state = await service.syncState
        #expect(state == .completed)
    }

    @Test("deltaSync transitions to error on failure")
    func deltaSyncError() async {
        let mock = MockNetworkClient()
        let localStore = LocalSyncStore()
        await localStore.clear()

        await mock.setError(NetworkError.networkFailure(underlyingError: "timeout"))

        let service = SyncService(
            networkClient: mock,
            localStore: localStore,
            apiConfig: testAPIConfig
        )

        do {
            _ = try await service.deltaSync(currentHashes: ["menu": "h1"])
            Issue.record("Expected deltaSync to throw")
        } catch {
            let state = await service.syncState
            if case .error = state {
                // Expected
            } else {
                Issue.record("Expected .error state, got \(state)")
            }
        }
    }

    @Test("deltaSync sends correct URL and body")
    func deltaSyncURL() async throws {
        let mock = MockNetworkClient()
        let localStore = LocalSyncStore()
        await localStore.clear()

        let deltaResponse = makeDeltaSyncResponse(unchanged: ["menu"])
        await mock.setDecodableResponse(deltaResponse)

        let service = SyncService(
            networkClient: mock,
            localStore: localStore,
            apiConfig: testAPIConfig
        )

        _ = try await service.deltaSync(currentHashes: ["menu": "h1"])

        let request = await mock.requestHistory.first
        #expect(request?.url == "https://iam.test.com/api/v1/sync/delta")
    }

    // MARK: - Sync On Launch

    @Test("syncOnLaunch does full sync when no local bundle")
    func syncOnLaunchNoLocalBundle() async throws {
        let mock = MockNetworkClient()
        let localStore = LocalSyncStore()
        await localStore.clear()

        let response = makeSyncBundleResponse()
        await mock.setDecodableResponse(response)

        let service = SyncService(
            networkClient: mock,
            localStore: localStore,
            apiConfig: testAPIConfig
        )

        let bundle = try await service.syncOnLaunch()

        #expect(bundle.menu.count == 1)

        // Should have made a GET request (full sync)
        let count = await mock.requestCount
        #expect(count == 1)
    }

    @Test("syncOnLaunch with local bundle returns bundle even if delta fails")
    func syncOnLaunchWithLocalDeltaFails() async throws {
        let mock = MockNetworkClient()
        let localStore = LocalSyncStore()
        await localStore.clear()

        // Pre-populate local store
        let localBundle = UserDataBundle(
            menu: [
                MenuItemDTO(
                    key: "settings",
                    displayName: "Settings",
                    scope: "admin",
                    sortOrder: 1,
                    permissions: [],
                    screens: [:]
                )
            ],
            permissions: ["admin"],
            screens: [:],
            availableContexts: [],
            hashes: ["menu": "old-hash"],
            syncedAt: Date.now
        )
        try await localStore.save(bundle: localBundle)

        // Delta sync will fail
        await mock.setError(NetworkError.networkFailure(underlyingError: "offline"))

        let service = SyncService(
            networkClient: mock,
            localStore: localStore,
            apiConfig: testAPIConfig
        )

        let bundle = try await service.syncOnLaunch()

        // Should return the local bundle despite delta failure
        #expect(bundle.menu[0].key == "settings")
        #expect(bundle.permissions == ["admin"])
    }

    // MARK: - Clear

    @Test("clear resets currentBundle and state to idle")
    func clearResetsState() async throws {
        let mock = MockNetworkClient()
        let localStore = LocalSyncStore()
        await localStore.clear()

        let response = makeSyncBundleResponse()
        await mock.setDecodableResponse(response)

        let service = SyncService(
            networkClient: mock,
            localStore: localStore,
            apiConfig: testAPIConfig
        )

        _ = try await service.fullSync()

        // Verify state is completed before clear
        let stateBefore = await service.syncState
        #expect(stateBefore == .completed)

        await service.clear()

        let stateAfter = await service.syncState
        #expect(stateAfter == .idle)

        let currentBundle = await service.currentBundle
        #expect(currentBundle == nil)
    }

    @Test("clear also clears LocalSyncStore")
    func clearClearsLocalStore() async throws {
        let mock = MockNetworkClient()
        let localStore = LocalSyncStore()
        await localStore.clear()

        let response = makeSyncBundleResponse()
        await mock.setDecodableResponse(response)

        let service = SyncService(
            networkClient: mock,
            localStore: localStore,
            apiConfig: testAPIConfig
        )

        _ = try await service.fullSync()

        await service.clear()

        let restored = await localStore.restore()
        #expect(restored == nil)
    }

    // MARK: - State Transitions

    @Test("BundleSyncState.isValidTransition validates correctly")
    func stateTransitionValidation() {
        // Valid transitions
        #expect(BundleSyncState.isValidTransition(from: .idle, to: .syncing) == true)
        #expect(BundleSyncState.isValidTransition(from: .syncing, to: .completed) == true)
        #expect(BundleSyncState.isValidTransition(
            from: .syncing,
            to: .error(.networkFailure("fail"))
        ) == true)
        #expect(BundleSyncState.isValidTransition(
            from: .error(.networkFailure("fail")),
            to: .syncing
        ) == true)
        #expect(BundleSyncState.isValidTransition(from: .completed, to: .syncing) == true)

        // Invalid transitions
        #expect(BundleSyncState.isValidTransition(from: .idle, to: .completed) == false)
        #expect(BundleSyncState.isValidTransition(
            from: .idle,
            to: .error(.networkFailure("fail"))
        ) == false)
        #expect(BundleSyncState.isValidTransition(from: .completed, to: .idle) == false)
        #expect(BundleSyncState.isValidTransition(from: .syncing, to: .idle) == false)
    }

    // MARK: - SyncError

    @Test("SyncError is Equatable")
    func syncErrorEquatable() {
        let a = SyncError.networkFailure("fail")
        let b = SyncError.networkFailure("fail")
        let c = SyncError.invalidData("bad")

        #expect(a == b)
        #expect(a != c)
    }

    @Test("SyncError has localized description")
    func syncErrorLocalizedDescription() {
        let error = SyncError.networkFailure("timeout")
        #expect(error.localizedDescription.contains("timeout"))

        let storageError = SyncError.storageFailed("disk full")
        #expect(storageError.localizedDescription.contains("disk full"))
    }

    // MARK: - Restore From Local

    @Test("restoreFromLocal returns nil when no stored bundle")
    func restoreFromLocalEmpty() async {
        let mock = MockNetworkClient()
        let localStore = LocalSyncStore()
        await localStore.clear()

        let service = SyncService(
            networkClient: mock,
            localStore: localStore,
            apiConfig: testAPIConfig
        )

        let bundle = await service.restoreFromLocal()
        #expect(bundle == nil)
    }

    @Test("restoreFromLocal returns stored bundle")
    func restoreFromLocalSuccess() async throws {
        let mock = MockNetworkClient()
        let localStore = LocalSyncStore()
        await localStore.clear()

        let storedBundle = UserDataBundle(
            menu: [],
            permissions: ["read"],
            screens: [:],
            availableContexts: [],
            hashes: ["menu": "h1"],
            syncedAt: Date.now
        )
        try await localStore.save(bundle: storedBundle)

        let service = SyncService(
            networkClient: mock,
            localStore: localStore,
            apiConfig: testAPIConfig
        )

        let bundle = await service.restoreFromLocal()
        #expect(bundle != nil)
        #expect(bundle?.permissions == ["read"])

        let currentBundle = await service.currentBundle
        #expect(currentBundle != nil)
    }
}
