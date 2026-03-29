import Foundation

// MARK: - Cursor Paginated Materials Response DTO

/// DTO for cursor-based paginated material list responses from the backend.
struct CursorPaginatedMaterialsResponseDTO: Decodable, Sendable {
    let items: [MaterialDTO]
    let nextCursor: String?
    let totalCount: Int?

    enum CodingKeys: String, CodingKey {
        case items
        case nextCursor = "next_cursor"
        case totalCount = "total_count"
    }
}

// MARK: - Material List Query Parameters

/// Parameters for querying the material list endpoint.
///
/// This type is local to the Infrastructure layer and mirrors the
/// Domain-level `MaterialsQuery` without depending on EduDomain.
public struct MaterialListQueryParams: Sendable {
    public let subjectId: UUID?
    public let unitId: UUID?
    public let type: String?
    public let status: String?
    public let searchQuery: String?
    public let cursor: String?
    public let limit: Int
    public let sortBy: String
    public let sortOrder: String

    public init(
        subjectId: UUID? = nil,
        unitId: UUID? = nil,
        type: String? = nil,
        status: String? = nil,
        searchQuery: String? = nil,
        cursor: String? = nil,
        limit: Int = 20,
        sortBy: String = "created_at",
        sortOrder: String = "desc"
    ) {
        self.subjectId = subjectId
        self.unitId = unitId
        self.type = type
        self.status = status
        self.searchQuery = searchQuery
        self.cursor = cursor
        self.limit = limit
        self.sortBy = sortBy
        self.sortOrder = sortOrder
    }
}

// MARK: - Material List Response

/// Response from the material list endpoint containing raw DTOs.
public struct MaterialListResponse: Sendable {
    public let items: [MaterialDTO]
    public let nextCursor: String?
    public let totalCount: Int?

    public init(items: [MaterialDTO], nextCursor: String?, totalCount: Int? = nil) {
        self.items = items
        self.nextCursor = nextCursor
        self.totalCount = totalCount
    }
}

// MARK: - MaterialListRepository

/// Network service for paginated material listing with filters and sorting.
///
/// Returns raw DTOs. Conversion to domain models happens in the app/domain layer.
///
/// ## Endpoints
/// - `GET /api/v1/materials` - List materials with query parameters
///
/// ## Example
/// ```swift
/// let repo = MaterialListRepository(
///     client: authenticatedClient,
///     baseURL: "https://api-mobile.edugo.com"
/// )
/// let response = try await repo.list(params: MaterialListQueryParams())
/// ```
public actor MaterialListRepository {

    // MARK: - Properties

    private let client: any NetworkClientProtocol
    private let baseURL: String

    // MARK: - Constants

    private enum Endpoints {
        static let materials = "/api/v1/materials"
    }

    // MARK: - Initialization

    /// Creates a new MaterialListRepository.
    /// - Parameters:
    ///   - client: Authenticated network client.
    ///   - baseURL: Base URL of the mobile API.
    public init(client: any NetworkClientProtocol, baseURL: String) {
        var sanitized = baseURL
        while sanitized.hasSuffix("/") { sanitized = String(sanitized.dropLast()) }
        self.baseURL = sanitized
        self.client = client
    }

    // MARK: - Public Methods

    /// Lists materials with pagination and filters.
    ///
    /// - Parameter params: Query parameters for filtering, pagination, and sorting.
    /// - Returns: Response with material DTOs and pagination metadata.
    public func list(params: MaterialListQueryParams) async throws -> MaterialListResponse {
        let url = baseURL + Endpoints.materials

        // Build query parameters
        var request = HTTPRequest.get(url)

        if let cursor = params.cursor {
            request = request.queryParam("cursor", cursor)
        }
        request = request.queryParam("limit", "\(params.limit)")
        request = request.queryParam("sort_by", params.sortBy)
        request = request.queryParam("sort_order", params.sortOrder)

        if let subjectId = params.subjectId {
            request = request.queryParam("subject_id", subjectId.uuidString)
        }
        if let unitId = params.unitId {
            request = request.queryParam("unit_id", unitId.uuidString)
        }
        if let type = params.type {
            request = request.queryParam("type", type)
        }
        if let status = params.status {
            request = request.queryParam("status", status)
        }
        if let searchQuery = params.searchQuery, !searchQuery.isEmpty {
            request = request.queryParam("q", searchQuery)
        }

        let dto: CursorPaginatedMaterialsResponseDTO = try await client.request(request)

        return MaterialListResponse(
            items: dto.items,
            nextCursor: dto.nextCursor,
            totalCount: dto.totalCount
        )
    }
}
