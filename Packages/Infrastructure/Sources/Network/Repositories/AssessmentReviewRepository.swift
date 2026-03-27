import Foundation
import EduCore

// MARK: - Assessment Review Network Error

/// Errores especificos del servicio de red de revision de assessments.
public enum AssessmentReviewNetworkError: Error, Sendable, Equatable {
    /// Error de autenticacion.
    case unauthorized

    /// Assessment no encontrado.
    case assessmentNotFound(String)

    /// Intento no encontrado.
    case attemptNotFound(String)

    /// Respuesta no encontrada.
    case answerNotFound(String)

    /// Conflicto (ya finalizado, etc.).
    case conflict(String)

    /// Error de red subyacente.
    case networkError(NetworkError)
}

extension AssessmentReviewNetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "No autorizado. Por favor, inicie sesion"
        case .assessmentNotFound(let id):
            return "Assessment no encontrado: \(id)"
        case .attemptNotFound(let id):
            return "Intento no encontrado: \(id)"
        case .answerNotFound(let id):
            return "Respuesta no encontrada: \(id)"
        case .conflict(let message):
            return "Conflicto: \(message)"
        case .networkError(let error):
            return "Error de red: \(error.localizedDescription)"
        }
    }
}

// MARK: - Assessment Review Network Service

/// Servicio de red para la revision de assessments por el profesor.
///
/// ## Endpoints
/// - `GET /api/v1/assessments/{id}/attempts` — Lista intentos de un assessment
/// - `GET /api/v1/assessments/{id}/stats` — Estadisticas del assessment
/// - `GET /api/v1/attempts/{id}/review` — Detalle de intento para revision
/// - `POST /api/v1/attempts/{id}/answers/{answerId}/review` — Califica una respuesta
/// - `POST /api/v1/attempts/{id}/finalize` — Finaliza revision de un intento
/// - `POST /api/v1/assessments/{id}/finalize-all` — Finaliza todos los intentos
///
/// ## Ejemplo de uso
/// ```swift
/// let service = AssessmentReviewNetworkService(
///     client: authenticatedClient,
///     baseURL: "https://api-mobile.edugo.com"
/// )
///
/// let attempts = try await service.listAttempts(assessmentId: "uuid-string")
/// ```
public actor AssessmentReviewNetworkService {

    // MARK: - Properties

    private let client: any NetworkClientProtocol
    private let baseURL: String

    // MARK: - Constants

    private enum Endpoints {
        static func attempts(assessmentId: String) -> String {
            "/api/v1/assessments/\(assessmentId)/attempts"
        }
        static func stats(assessmentId: String) -> String {
            "/api/v1/assessments/\(assessmentId)/stats"
        }
        static func attemptReview(attemptId: String) -> String {
            "/api/v1/attempts/\(attemptId)/review"
        }
        static func reviewAnswer(attemptId: String, answerId: String) -> String {
            "/api/v1/attempts/\(attemptId)/answers/\(answerId)/review"
        }
        static func finalizeAttempt(attemptId: String) -> String {
            "/api/v1/attempts/\(attemptId)/finalize"
        }
        static func finalizeAll(assessmentId: String) -> String {
            "/api/v1/assessments/\(assessmentId)/finalize-all"
        }
    }

    // MARK: - Initialization

    /// Inicializa el servicio de red de revision de assessments.
    /// - Parameters:
    ///   - client: Cliente de red para realizar las requests.
    ///   - baseURL: URL base del API (ej: "https://api-mobile.edugo.com").
    public init(client: any NetworkClientProtocol, baseURL: String) {
        self.client = client
        var sanitized = baseURL
        while sanitized.hasSuffix("/") { sanitized = String(sanitized.dropLast()) }
        self.baseURL = sanitized
    }

    // MARK: - Public Methods

    /// Lista los intentos de un assessment para revision.
    ///
    /// - Parameter assessmentId: ID del assessment (UUID string)
    /// - Returns: Lista de resumen de intentos
    public func listAttempts(assessmentId: String) async throws -> [TeacherAttemptSummaryDTO] {
        let url = baseURL + Endpoints.attempts(assessmentId: assessmentId)
        do {
            return try await client.get(url)
        } catch let error as NetworkError {
            throw mapError(error, assessmentId: assessmentId)
        }
    }

    /// Obtiene las estadisticas de un assessment.
    ///
    /// - Parameter assessmentId: ID del assessment (UUID string)
    /// - Returns: Estadisticas del assessment
    public func getStats(assessmentId: String) async throws -> AssessmentStatsDTO {
        let url = baseURL + Endpoints.stats(assessmentId: assessmentId)
        do {
            return try await client.get(url)
        } catch let error as NetworkError {
            throw mapError(error, assessmentId: assessmentId)
        }
    }

    /// Obtiene el detalle de un intento para revision.
    ///
    /// - Parameter attemptId: ID del intento (UUID string)
    /// - Returns: Detalle del intento con respuestas
    public func getAttemptForReview(attemptId: String) async throws -> AttemptReviewDetailDTO {
        let url = baseURL + Endpoints.attemptReview(attemptId: attemptId)
        do {
            return try await client.get(url)
        } catch let error as NetworkError {
            throw mapError(error, attemptId: attemptId)
        }
    }

    /// Califica una respuesta individual.
    ///
    /// - Parameters:
    ///   - attemptId: ID del intento (UUID string)
    ///   - answerId: ID de la respuesta (UUID string)
    ///   - request: Datos de la calificacion
    public func reviewAnswer(
        attemptId: String,
        answerId: String,
        request: ReviewAnswerRequestDTO
    ) async throws {
        let url = baseURL + Endpoints.reviewAnswer(attemptId: attemptId, answerId: answerId)
        do {
            let _: EmptyResponse = try await client.post(url, body: request)
        } catch let error as NetworkError {
            throw mapError(error, attemptId: attemptId, answerId: answerId)
        }
    }

    /// Finaliza la revision de un intento.
    ///
    /// - Parameter attemptId: ID del intento (UUID string)
    public func finalizeAttempt(attemptId: String) async throws {
        let url = baseURL + Endpoints.finalizeAttempt(attemptId: attemptId)
        do {
            let _: EmptyResponse = try await client.post(url, body: ReviewEmptyRequestBody())
        } catch let error as NetworkError {
            throw mapError(error, attemptId: attemptId)
        }
    }

    /// Finaliza todos los intentos de un assessment.
    ///
    /// - Parameter assessmentId: ID del assessment (UUID string)
    public func finalizeAll(assessmentId: String) async throws {
        let url = baseURL + Endpoints.finalizeAll(assessmentId: assessmentId)
        do {
            let _: EmptyResponse = try await client.post(url, body: ReviewEmptyRequestBody())
        } catch let error as NetworkError {
            throw mapError(error, assessmentId: assessmentId)
        }
    }

    // MARK: - Private Methods

    private func mapError(
        _ error: NetworkError,
        assessmentId: String? = nil,
        attemptId: String? = nil,
        answerId: String? = nil
    ) -> AssessmentReviewNetworkError {
        switch error {
        case .unauthorized:
            return .unauthorized
        case .notFound:
            if let answerId {
                return .answerNotFound(answerId)
            }
            if let attemptId {
                return .attemptNotFound(attemptId)
            }
            if let assessmentId {
                return .assessmentNotFound(assessmentId)
            }
            return .networkError(error)
        case .serverError(let statusCode, let message) where statusCode == 409:
            return .conflict(message ?? "Conflicto en la operacion")
        default:
            return .networkError(error)
        }
    }
}

// MARK: - Empty Request Body

/// Body vacio para requests POST que no requieren datos.
private struct ReviewEmptyRequestBody: Encodable, Sendable {
    enum CodingKeys: CodingKey {}
}
