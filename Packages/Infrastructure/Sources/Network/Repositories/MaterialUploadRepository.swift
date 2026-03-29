import Foundation

// MARK: - Upload URL Response DTO

/// DTO for the presigned upload URL response from the backend.
struct UploadURLResponseDTO: Codable, Sendable {
    let url: String
    let fileUrl: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case url
        case fileUrl = "file_url"
        case expiresIn = "expires_in"
    }
}

// MARK: - Create Material Request DTO

/// DTO for the create material request body.
struct CreateMaterialRequestDTO: Codable, Sendable {
    let title: String
    let description: String?
    let subject: String?
    let grade: String?
}

// MARK: - Upload Complete Request DTO

/// DTO for the upload-complete notification request body.
struct UploadCompleteRequestDTO: Codable, Sendable {
    let fileUrl: String
    let fileType: String
    let fileSizeBytes: Int

    enum CodingKeys: String, CodingKey {
        case fileUrl = "file_url"
        case fileType = "file_type"
        case fileSizeBytes = "file_size_bytes"
    }
}

// MARK: - Material Upload Network Error

/// Errors specific to the material upload repository.
public enum MaterialUploadNetworkError: Error, Sendable, Equatable {
    /// Invalid URL received from the backend.
    case invalidURL(String)

    /// S3 upload returned a non-success status code.
    case s3UploadFailed(statusCode: Int)

    /// Error reading the local file.
    case fileReadError(String)

    /// Network error.
    case networkError(NetworkError)
}

extension MaterialUploadNetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "URL invalida recibida del servidor: \(url)"
        case .s3UploadFailed(let statusCode):
            return "Error al subir a S3: status \(statusCode)"
        case .fileReadError(let reason):
            return "Error al leer archivo: \(reason)"
        case .networkError(let error):
            return "Error de red: \(error.localizedDescription)"
        }
    }
}

// MARK: - MaterialUploadRepository

/// Network service for the full material upload flow:
/// create -> presigned URL -> S3 upload -> notify complete.
///
/// Returns raw DTOs at the Infrastructure level. Conformance to
/// `MaterialUploadRepositoryProtocol` (Domain layer) is added via extension
/// in the app layer (DemoApp) where both modules are visible.
///
/// ## Endpoints
/// - `POST /api/v1/materials` - Create material
/// - `POST /api/v1/materials/{id}/upload-url` - Request presigned URL
/// - `POST /api/v1/materials/{id}/upload-complete` - Notify upload complete
/// - `GET  /api/v1/materials/{id}` - Get material by ID
/// - `DELETE /api/v1/materials/{id}` - Delete material
///
/// ## Example
/// ```swift
/// let repo = MaterialUploadRepository(
///     client: authenticatedClient,
///     baseURL: "https://api-mobile.edugo.com"
/// )
/// let dto = try await repo.createMaterialDTO(title: "Intro", description: nil, subject: nil, grade: nil)
/// ```
public actor MaterialUploadRepository {

    // MARK: - Properties

    private let client: any NetworkClientProtocol
    private let baseURL: String

    // MARK: - Constants

    private enum Endpoints {
        static let materials = "/api/v1/materials"
        static func material(id: UUID) -> String { "/api/v1/materials/\(id.uuidString)" }
        static func uploadURL(id: UUID) -> String { "/api/v1/materials/\(id.uuidString)/upload-url" }
        static func uploadComplete(id: UUID) -> String { "/api/v1/materials/\(id.uuidString)/upload-complete" }
    }

    // MARK: - Initialization

    /// Creates a new MaterialUploadRepository.
    /// - Parameters:
    ///   - client: Authenticated network client.
    ///   - baseURL: Base URL of the mobile API (e.g. "https://api-mobile.edugo.com").
    public init(client: any NetworkClientProtocol, baseURL: String) {
        var sanitized = baseURL
        while sanitized.hasSuffix("/") { sanitized = String(sanitized.dropLast()) }
        self.baseURL = sanitized
        self.client = client
    }

    // MARK: - Public Methods

    /// Creates a new material in the backend.
    ///
    /// - Returns: The created Material DTO.
    public func createMaterialDTO(
        title: String,
        description: String?,
        subject: String?,
        grade: String?
    ) async throws -> MaterialDTO {
        let url = baseURL + Endpoints.materials
        let body = CreateMaterialRequestDTO(
            title: title,
            description: description,
            subject: subject,
            grade: grade
        )
        return try await client.post(url, body: body)
    }

    /// Requests a presigned S3 upload URL for a material file.
    ///
    /// - Returns: Tuple with upload URL, permanent file URL, and expiration seconds.
    public func requestUploadURL(
        materialId: UUID,
        fileName: String,
        contentType: String
    ) async throws -> (uploadURL: URL, fileURL: URL, expiresIn: Int) {
        let url = baseURL + Endpoints.uploadURL(id: materialId)

        struct RequestBody: Codable, Sendable {
            let fileName: String
            let contentType: String

            enum CodingKeys: String, CodingKey {
                case fileName = "file_name"
                case contentType = "content_type"
            }
        }

        let body = RequestBody(fileName: fileName, contentType: contentType)
        let dto: UploadURLResponseDTO = try await client.post(url, body: body)

        guard let uploadURL = URL(string: dto.url) else {
            throw MaterialUploadNetworkError.invalidURL(dto.url)
        }
        guard let fileURL = URL(string: dto.fileUrl) else {
            throw MaterialUploadNetworkError.invalidURL(dto.fileUrl)
        }

        return (uploadURL: uploadURL, fileURL: fileURL, expiresIn: dto.expiresIn)
    }

    /// Uploads file data directly to S3 using the presigned URL.
    ///
    /// - Parameters:
    ///   - fileURL: Local file URL.
    ///   - uploadURL: Presigned S3 URL.
    ///   - contentType: MIME type of the file.
    ///   - progressHandler: Callback for progress updates (0-100).
    public func uploadToS3(
        fileURL: URL,
        uploadURL: URL,
        contentType: String,
        progressHandler: @escaping @Sendable (Int) -> Void
    ) async throws {
        let fileData = try Data(contentsOf: fileURL)

        var request = URLRequest(url: uploadURL)
        request.httpMethod = "PUT"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("\(fileData.count)", forHTTPHeaderField: "Content-Length")

        let (_, response) = try await URLSession.shared.upload(for: request, from: fileData)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw MaterialUploadNetworkError.s3UploadFailed(statusCode: statusCode)
        }

        progressHandler(100)
    }

    /// Notifies the backend that the S3 upload completed.
    public func notifyUploadComplete(
        materialId: UUID,
        fileURL: URL,
        fileType: String,
        fileSizeBytes: Int
    ) async throws {
        let url = baseURL + Endpoints.uploadComplete(id: materialId)
        let body = UploadCompleteRequestDTO(
            fileUrl: fileURL.absoluteString,
            fileType: fileType,
            fileSizeBytes: fileSizeBytes
        )
        let _: EmptyResponse = try await client.post(url, body: body)
    }

    /// Gets a material DTO by ID.
    public func getMaterialDTO(id: UUID) async throws -> MaterialDTO {
        let url = baseURL + Endpoints.material(id: id)
        return try await client.get(url)
    }

    /// Deletes a material by ID (for cleanup on upload failure).
    public func deleteMaterial(id: UUID) async throws {
        let url = baseURL + Endpoints.material(id: id)
        let _: EmptyResponse = try await client.delete(url)
    }
}
