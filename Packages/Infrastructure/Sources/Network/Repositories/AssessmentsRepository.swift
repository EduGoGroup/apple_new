import Foundation
import EduCore

// MARK: - Assessments Network Service Error

/// Errores especificos del servicio de red de assessments.
public enum AssessmentsNetworkError: Error, Sendable, Equatable {
    /// Error de autenticacion.
    case unauthorized

    /// Assessment no encontrado.
    case assessmentNotFound(String)

    /// Error de red subyacente.
    case networkError(NetworkError)
}

extension AssessmentsNetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "No autorizado. Por favor, inicie sesion"
        case .assessmentNotFound(let id):
            return "Assessment no encontrado: \(id)"
        case .networkError(let error):
            return "Error de red: \(error.localizedDescription)"
        }
    }
}

// MARK: - Assessments Network Service

/// Servicio de red para assessments que trabaja con DTOs.
///
/// ## Endpoints
/// - `GET /api/v1/assessments/{id}` - Obtiene un assessment por ID
///
/// ## Ejemplo de uso
/// ```swift
/// let service = AssessmentsNetworkService(
///     client: authenticatedClient,
///     baseURL: "https://api-mobile.edugo.com"
/// )
///
/// let dto = try await service.getAssessment(id: "uuid-string")
/// ```
public actor AssessmentsNetworkService {

    // MARK: - Properties

    private let client: any NetworkClientProtocol
    private let baseURL: String

    // MARK: - Constants

    private enum Endpoints {
        static func assessment(id: String) -> String {
            "/api/v1/assessments/\(id)"
        }
    }

    // MARK: - Initialization

    /// Inicializa el servicio de red de assessments.
    /// - Parameters:
    ///   - client: Cliente de red para realizar las requests.
    ///   - baseURL: URL base del API mobile (ej: "https://api-mobile.edugo.com").
    public init(client: any NetworkClientProtocol, baseURL: String) {
        self.client = client
        var sanitized = baseURL
        while sanitized.hasSuffix("/") { sanitized = String(sanitized.dropLast()) }
        self.baseURL = sanitized
    }

    // MARK: - Public Methods

    /// Obtiene un assessment por ID.
    ///
    /// - Parameter id: ID del assessment (UUID string)
    /// - Returns: DTO del assessment
    /// - Throws: `AssessmentsNetworkError` si la operacion falla
    public func getAssessment(id: String) async throws -> AssessmentDTO {
        let url = baseURL + Endpoints.assessment(id: id)
        do {
            return try await client.get(url)
        } catch let error as NetworkError {
            throw mapError(error, assessmentId: id)
        }
    }

    // MARK: - Private Methods

    private func mapError(
        _ error: NetworkError,
        assessmentId: String? = nil
    ) -> AssessmentsNetworkError {
        switch error {
        case .unauthorized:
            return .unauthorized
        case .notFound:
            if let assessmentId {
                return .assessmentNotFound(assessmentId)
            }
            return .networkError(error)
        default:
            return .networkError(error)
        }
    }
}
