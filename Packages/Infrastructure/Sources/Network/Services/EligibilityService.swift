import Foundation
import EduCore

// MARK: - Eligibility Network Service Error

/// Errores especificos del servicio de red de elegibilidad.
public enum EligibilityNetworkError: Error, Sendable, Equatable {
    /// Error de autenticacion.
    case unauthorized

    /// Assessment no encontrado.
    case assessmentNotFound(String)

    /// Error de red subyacente.
    case networkError(NetworkError)
}

extension EligibilityNetworkError: LocalizedError {
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

// MARK: - Eligibility Network Service

/// Servicio de red para verificar elegibilidad de evaluaciones.
///
/// ## Endpoint
/// - `GET /api/v1/assessments/{assessmentId}/eligibility?user_id={userId}`
///
/// ## Ejemplo de uso
/// ```swift
/// let service = EligibilityNetworkService(
///     client: authenticatedClient,
///     baseURL: "https://api-mobile.edugo.com"
/// )
///
/// let eligibility = try await service.checkEligibility(
///     assessmentId: "uuid-string",
///     userId: "uuid-string"
/// )
/// ```
public actor EligibilityNetworkService {

    // MARK: - Properties

    private let client: any NetworkClientProtocol
    private let baseURL: String

    // MARK: - Constants

    private enum Endpoints {
        static func eligibility(assessmentId: String, userId: String) -> String {
            "/api/v1/assessments/\(assessmentId)/eligibility?user_id=\(userId)"
        }
    }

    // MARK: - Initialization

    /// Inicializa el servicio de red de elegibilidad.
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

    /// Verifica la elegibilidad de un usuario para tomar una evaluacion.
    ///
    /// - Parameters:
    ///   - assessmentId: ID del assessment (UUID string)
    ///   - userId: ID del usuario (UUID string)
    /// - Returns: DTO con la informacion de elegibilidad
    public func checkEligibility(
        assessmentId: String,
        userId: String
    ) async throws -> EligibilityDTO {
        let url = baseURL + Endpoints.eligibility(
            assessmentId: assessmentId,
            userId: userId
        )
        do {
            return try await client.get(url)
        } catch let error as NetworkError {
            throw mapError(error, assessmentId: assessmentId)
        }
    }

    // MARK: - Private Methods

    private func mapError(
        _ error: NetworkError,
        assessmentId: String? = nil
    ) -> EligibilityNetworkError {
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
