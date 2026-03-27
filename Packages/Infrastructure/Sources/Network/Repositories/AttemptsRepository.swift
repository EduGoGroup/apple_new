import Foundation
import EduCore

// MARK: - Attempts Network Service Error

/// Errores especificos del servicio de red de attempts.
public enum AttemptsNetworkError: Error, Sendable, Equatable {
    /// Error de autenticacion.
    case unauthorized

    /// Intento no encontrado.
    case attemptNotFound(String)

    /// Assessment no encontrado.
    case assessmentNotFound(String)

    /// Conflicto (intento duplicado, ya completado, etc.).
    case conflict(String)

    /// Error de red subyacente.
    case networkError(NetworkError)
}

extension AttemptsNetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "No autorizado. Por favor, inicie sesion"
        case .attemptNotFound(let id):
            return "Intento no encontrado: \(id)"
        case .assessmentNotFound(let id):
            return "Assessment no encontrado: \(id)"
        case .conflict(let message):
            return "Conflicto: \(message)"
        case .networkError(let error):
            return "Error de red: \(error.localizedDescription)"
        }
    }
}

// MARK: - Attempts Network Service

/// Servicio de red para attempts que trabaja con DTOs.
///
/// ## Endpoints
/// - `POST /api/v1/assessments/{assessmentId}/start` - Inicia un nuevo intento
/// - `PUT /api/v1/attempts/{attemptId}/answers/{questionIndex}` - Guarda una respuesta
/// - `POST /api/v1/attempts/{attemptId}/submit` - Envia un intento completo
/// - `GET /api/v1/attempts/{attemptId}/results` - Obtiene resultados de un intento
/// - `GET /api/v1/users/me/attempts` - Lista intentos del usuario autenticado
///
/// ## Ejemplo de uso
/// ```swift
/// let service = AttemptsNetworkService(
///     client: authenticatedClient,
///     baseURL: "https://api-mobile.edugo.com"
/// )
///
/// let response = try await service.startAttempt(assessmentId: "uuid-string")
/// ```
public actor AttemptsNetworkService {

    // MARK: - Properties

    private let client: any NetworkClientProtocol
    private let baseURL: String

    // MARK: - Constants

    private enum Endpoints {
        static func start(assessmentId: String) -> String {
            "/api/v1/assessments/\(assessmentId)/start"
        }
        static func saveAnswer(attemptId: String, questionIndex: Int) -> String {
            "/api/v1/attempts/\(attemptId)/answers/\(questionIndex)"
        }
        static func submit(attemptId: String) -> String {
            "/api/v1/attempts/\(attemptId)/submit"
        }
        static func results(attemptId: String) -> String {
            "/api/v1/attempts/\(attemptId)/results"
        }
        static let myAttempts = "/api/v1/users/me/attempts"
    }

    // MARK: - Initialization

    /// Inicializa el servicio de red de attempts.
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

    /// Inicia un nuevo intento de assessment.
    ///
    /// - Parameter assessmentId: ID del assessment (UUID string)
    /// - Returns: DTO con el ID del intento creado
    public func startAttempt(assessmentId: String) async throws -> StartAttemptResponseDTO {
        let url = baseURL + Endpoints.start(assessmentId: assessmentId)
        do {
            return try await client.post(url, body: EmptyRequestBody())
        } catch let error as NetworkError {
            throw mapError(error, assessmentId: assessmentId)
        }
    }

    /// Guarda una respuesta individual para un intento.
    ///
    /// - Parameters:
    ///   - attemptId: ID del intento (UUID string)
    ///   - questionIndex: Indice de la pregunta (0-based)
    ///   - answer: Datos de la respuesta
    public func saveAnswer(
        attemptId: String,
        questionIndex: Int,
        answer: SaveAnswerRequestDTO
    ) async throws {
        let url = baseURL + Endpoints.saveAnswer(
            attemptId: attemptId,
            questionIndex: questionIndex
        )
        do {
            let _: EmptyResponse = try await client.put(url, body: answer)
        } catch let error as NetworkError {
            throw mapError(error, attemptId: attemptId)
        }
    }

    /// Envia un intento completo con todas las respuestas.
    ///
    /// - Parameters:
    ///   - attemptId: ID del intento (UUID string)
    ///   - request: Datos del submit
    /// - Returns: DTO con el resultado del intento
    public func submitAttempt(
        attemptId: String,
        request: SubmitAttemptRequestDTO
    ) async throws -> AttemptResultResponseDTO {
        let url = baseURL + Endpoints.submit(attemptId: attemptId)
        do {
            return try await client.post(url, body: request)
        } catch let error as NetworkError {
            throw mapError(error, attemptId: attemptId)
        }
    }

    /// Obtiene los resultados de un intento completado.
    ///
    /// - Parameter attemptId: ID del intento (UUID string)
    /// - Returns: DTO con el resultado del intento
    public func getResults(attemptId: String) async throws -> AttemptResultResponseDTO {
        let url = baseURL + Endpoints.results(attemptId: attemptId)
        do {
            return try await client.get(url)
        } catch let error as NetworkError {
            throw mapError(error, attemptId: attemptId)
        }
    }

    /// Lista los intentos del usuario autenticado con paginacion.
    ///
    /// - Parameters:
    ///   - page: Numero de pagina (1-based)
    ///   - perPage: Tamano de pagina
    /// - Returns: Respuesta paginada de intentos
    public func listMyAttempts(
        page: Int,
        perPage: Int
    ) async throws -> PaginatedAttemptsDTO {
        let url = baseURL + Endpoints.myAttempts
            + "?page=\(page)&per_page=\(perPage)"
        do {
            return try await client.get(url)
        } catch let error as NetworkError {
            throw mapError(error)
        }
    }

    // MARK: - Private Methods

    private func mapError(
        _ error: NetworkError,
        assessmentId: String? = nil,
        attemptId: String? = nil
    ) -> AttemptsNetworkError {
        switch error {
        case .unauthorized:
            return .unauthorized
        case .notFound:
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
private struct EmptyRequestBody: Encodable, Sendable {
    enum CodingKeys: CodingKey {}
}
