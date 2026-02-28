import Testing
import Foundation
import EduCore
import EduInfrastructure
import EduModels
@testable import EduDomain

@Suite("SyncBucket Tests")
struct SyncBucketTests {

    @Test("SyncBucket raw values match API expectations")
    func rawValues() {
        #expect(SyncBucket.menu.rawValue == "menu")
        #expect(SyncBucket.permissions.rawValue == "permissions")
        #expect(SyncBucket.availableContexts.rawValue == "available_contexts")
        #expect(SyncBucket.screens.rawValue == "screens")
        #expect(SyncBucket.glossary.rawValue == "glossary")
        #expect(SyncBucket.strings.rawValue == "strings")
    }

    @Test("SyncBucket.allCases contains 6 buckets")
    func allCases() {
        #expect(SyncBucket.allCases.count == 6)
    }

    @Test("Joining bucket raw values produces correct query string")
    func joinedBuckets() {
        let buckets: [SyncBucket] = [.menu, .permissions, .availableContexts]
        let joined = buckets.map(\.rawValue).joined(separator: ",")
        #expect(joined == "menu,permissions,available_contexts")
    }
}

// MARK: - LocalSyncStore mergePartial Tests

@Suite("LocalSyncStore MergePartial Tests", .serialized)
struct LocalSyncStoreMergePartialTests {

    private static func makeBundle(
        menu: [MenuItemDTO] = [],
        permissions: [String] = ["read"],
        screens: [String: ScreenBundleDTO] = [:],
        availableContexts: [UserContextDTO] = [],
        hashes: [String: String] = [:]
    ) -> UserDataBundle {
        UserDataBundle(
            menu: menu,
            permissions: permissions,
            screens: screens,
            availableContexts: availableContexts,
            hashes: hashes,
            syncedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }

    @Test("mergePartial preserves existing screens when only menu and permissions requested")
    func mergePreservesScreens() async throws {
        let store = LocalSyncStore()
        await store.clear()

        // Existing bundle with screens
        let existing = Self.makeBundle(
            permissions: ["old_perm"],
            screens: ["dashboard": ScreenBundleDTO(screenKey: "dashboard", screenName: "Dashboard", pattern: "dashboard", version: "1", template: .object([:]))],
            hashes: ["screens": "scr-hash", "permissions": "old-perm-hash"]
        )
        try await store.save(bundle: existing)

        // Incoming partial (only menu + permissions)
        let incoming = Self.makeBundle(
            permissions: ["new_perm_1", "new_perm_2"],
            hashes: ["permissions": "new-perm-hash"]
        )

        let merged = await store.mergePartial(
            incoming: incoming,
            receivedBuckets: Set(["permissions"])
        )

        // Permissions updated
        #expect(merged.permissions == ["new_perm_1", "new_perm_2"])
        // Screens preserved from existing
        #expect(merged.screens.count == 1)
        #expect(merged.screens["dashboard"] != nil)
        // Hashes merged
        #expect(merged.hashes["permissions"] == "new-perm-hash")
        #expect(merged.hashes["screens"] == "scr-hash")

        await store.clear()
    }

    @Test("mergePartial returns incoming when no existing bundle")
    func mergeReturnsIncomingWhenEmpty() async {
        let store = LocalSyncStore()
        await store.clear()

        let incoming = Self.makeBundle(permissions: ["admin"])

        let merged = await store.mergePartial(
            incoming: incoming,
            receivedBuckets: Set(["permissions"])
        )

        #expect(merged.permissions == ["admin"])
    }

    @Test("mergePartial with all buckets replaces entire bundle")
    func mergeWithAllBuckets() async throws {
        let store = LocalSyncStore()
        await store.clear()

        let existing = Self.makeBundle(permissions: ["old"])
        try await store.save(bundle: existing)

        let incoming = Self.makeBundle(permissions: ["new"])
        let allBucketNames = Set(SyncBucket.allCases.map(\.rawValue))

        let merged = await store.mergePartial(
            incoming: incoming,
            receivedBuckets: allBucketNames
        )

        #expect(merged.permissions == ["new"])

        await store.clear()
    }
}

// MARK: - SyncService syncBuckets Tests

private actor MockSyncNetworkClient: NetworkClientProtocol {
    var mockResponse: (any Sendable)?
    var mockError: Error?
    private(set) var requestHistory: [HTTPRequest] = []

    func setDecodableResponse<T: Sendable>(_ response: T) {
        self.mockResponse = response
        self.mockError = nil
    }

    func setError(_ error: Error) {
        self.mockError = error
    }

    func request<T: Decodable & Sendable>(_ request: HTTPRequest) async throws -> T {
        requestHistory.append(request)
        if let error = mockError { throw error }
        if let response = mockResponse as? T { return response }
        throw NetworkError.noData
    }

    func requestData(_ request: HTTPRequest) async throws -> (Data, HTTPURLResponse) {
        throw NetworkError.noData
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

private let testAPIConfig = APIConfiguration(
    iamBaseURL: "https://iam.test.com",
    adminBaseURL: "https://admin.test.com",
    mobileBaseURL: "https://mobile.test.com",
    timeout: 10,
    environment: .development
)

@Suite("SyncService syncBuckets Tests", .serialized)
struct SyncServiceBucketsTests {

    @Test("syncBuckets adds buckets query parameter to URL")
    func syncBucketsQueryParam() async throws {
        let mock = MockSyncNetworkClient()
        let localStore = LocalSyncStore()
        await localStore.clear()

        let response = SyncBundleResponseDTO(
            menu: [],
            permissions: ["admin"],
            screens: [:],
            availableContexts: [],
            hashes: ["permissions": "h1"]
        )
        await mock.setDecodableResponse(response)

        let service = SyncService(
            networkClient: mock,
            localStore: localStore,
            apiConfig: testAPIConfig
        )

        _ = try await service.syncBuckets([.menu, .permissions, .availableContexts])

        let request = await mock.requestHistory.first
        #expect(request != nil)
        #expect(request?.url == "https://iam.test.com/api/v1/sync/bundle")
        #expect(request?.queryParameters["buckets"] == "menu,permissions,available_contexts")

        await localStore.clear()
    }

    @Test("syncBuckets transitions to completed on success")
    func syncBucketsState() async throws {
        let mock = MockSyncNetworkClient()
        let localStore = LocalSyncStore()
        await localStore.clear()

        let response = SyncBundleResponseDTO(
            menu: [],
            permissions: [],
            screens: [:],
            availableContexts: [],
            hashes: [:]
        )
        await mock.setDecodableResponse(response)

        let service = SyncService(
            networkClient: mock,
            localStore: localStore,
            apiConfig: testAPIConfig
        )

        _ = try await service.syncBuckets([.permissions])

        let state = await service.syncState
        #expect(state == .completed)

        await localStore.clear()
    }

    @Test("syncBuckets merges partial result with existing local bundle")
    func syncBucketsMergesPartial() async throws {
        let mock = MockSyncNetworkClient()
        let localStore = LocalSyncStore()
        await localStore.clear()

        // Pre-populate with existing screens
        let existingBundle = UserDataBundle(
            menu: [],
            permissions: ["old_perm"],
            screens: ["dash": ScreenBundleDTO(screenKey: "dash", screenName: "Dash", pattern: "dashboard", version: "1", template: .object([:]))],
            availableContexts: [],
            hashes: ["screens": "scr-h"],
            syncedAt: Date.now
        )
        try await localStore.save(bundle: existingBundle)

        // Partial response: only permissions
        let response = SyncBundleResponseDTO(
            menu: [],
            permissions: ["new_perm"],
            screens: [:],
            availableContexts: [],
            hashes: ["permissions": "new-h"]
        )
        await mock.setDecodableResponse(response)

        let service = SyncService(
            networkClient: mock,
            localStore: localStore,
            apiConfig: testAPIConfig
        )

        let bundle = try await service.syncBuckets([.permissions])

        // Permissions updated
        #expect(bundle.permissions == ["new_perm"])
        // Screens preserved
        #expect(bundle.screens.count == 1)
        #expect(bundle.screens["dash"] != nil)

        await localStore.clear()
    }

    @Test("syncBuckets transitions to error on failure")
    func syncBucketsError() async {
        let mock = MockSyncNetworkClient()
        let localStore = LocalSyncStore()
        await localStore.clear()

        await mock.setError(NetworkError.networkFailure(underlyingError: "offline"))

        let service = SyncService(
            networkClient: mock,
            localStore: localStore,
            apiConfig: testAPIConfig
        )

        do {
            _ = try await service.syncBuckets([.menu])
            Issue.record("Expected syncBuckets to throw")
        } catch {
            let state = await service.syncState
            if case .error = state {
                // Expected
            } else {
                Issue.record("Expected .error state, got \(state)")
            }
        }
    }

    @Test("fullSync still works without buckets parameter")
    func fullSyncStillWorks() async throws {
        let mock = MockSyncNetworkClient()
        let localStore = LocalSyncStore()
        await localStore.clear()

        let response = SyncBundleResponseDTO(
            menu: [],
            permissions: ["admin"],
            screens: [:],
            availableContexts: [],
            hashes: ["permissions": "h1"]
        )
        await mock.setDecodableResponse(response)

        let service = SyncService(
            networkClient: mock,
            localStore: localStore,
            apiConfig: testAPIConfig
        )

        let bundle = try await service.fullSync()

        #expect(bundle.permissions == ["admin"])

        let request = await mock.requestHistory.first
        #expect(request?.queryParameters.isEmpty == true)

        await localStore.clear()
    }
}
