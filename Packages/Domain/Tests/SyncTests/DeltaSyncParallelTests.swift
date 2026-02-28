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

@Suite("DeltaSync Parallel Tests", .serialized)
struct DeltaSyncParallelTests {

    @Test("deltaSync applies multiple changed buckets correctly")
    func deltaSyncMultipleBuckets() async throws {
        let mock = MockNetworkClient()
        let localStore = LocalSyncStore()
        await localStore.clear()

        // Pre-populate with a base bundle
        let baseBundle = UserDataBundle(
            menu: [
                MenuItemDTO(
                    key: "old_menu",
                    displayName: "Old Menu",
                    scope: "student",
                    sortOrder: 1,
                    permissions: [],
                    screens: [:]
                )
            ],
            permissions: ["old_perm"],
            screens: [:],
            availableContexts: [],
            hashes: ["menu": "old-hash", "permissions": "old-hash-p"],
            syncedAt: Date.now
        )
        try await localStore.save(bundle: baseBundle)

        // Create delta response with multiple changed buckets
        let newMenuJSON: JSONValue = .array([
            .object([
                "key": .string("new_menu"),
                "displayName": .string("New Menu"),
                "scope": .string("admin"),
                "sortOrder": .integer(1),
                "permissions": .array([.string("admin_perm")]),
                "screens": .object([:])
            ])
        ])

        let newPermissionsJSON: JSONValue = .array([
            .string("admin_perm"),
            .string("write_perm")
        ])

        let deltaResponse = DeltaSyncResponseDTO(
            changed: [
                "menu": BucketDataDTO(data: newMenuJSON, hash: "new-hash-m"),
                "permissions": BucketDataDTO(data: newPermissionsJSON, hash: "new-hash-p")
            ],
            unchanged: ["screens"]
        )
        await mock.setDecodableResponse(deltaResponse)

        let service = SyncService(
            networkClient: mock,
            localStore: localStore,
            apiConfig: testAPIConfig
        )

        let result = try await service.deltaSync(currentHashes: [
            "menu": "old-hash",
            "permissions": "old-hash-p"
        ])

        // Verify both buckets were applied
        #expect(result.changed.count == 2)
        #expect(result.unchanged == ["screens"])

        // Verify the bundle was updated
        let currentBundle = await service.currentBundle
        #expect(currentBundle != nil)
        #expect(currentBundle?.hashes["menu"] == "new-hash-m")
        #expect(currentBundle?.hashes["permissions"] == "new-hash-p")
    }

    @Test("deltaSync with no changes completes successfully")
    func deltaSyncNoChanges() async throws {
        let mock = MockNetworkClient()
        let localStore = LocalSyncStore()
        await localStore.clear()

        let deltaResponse = DeltaSyncResponseDTO(
            changed: [:],
            unchanged: ["menu", "screens", "permissions"]
        )
        await mock.setDecodableResponse(deltaResponse)

        let service = SyncService(
            networkClient: mock,
            localStore: localStore,
            apiConfig: testAPIConfig
        )

        let result = try await service.deltaSync(currentHashes: [
            "menu": "h1",
            "screens": "h2",
            "permissions": "h3"
        ])

        #expect(result.changed.isEmpty)
        #expect(result.unchanged.count == 3)

        let state = await service.syncState
        #expect(state == .completed)
    }
}
