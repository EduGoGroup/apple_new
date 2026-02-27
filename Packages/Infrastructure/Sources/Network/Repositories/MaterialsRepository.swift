import Foundation

// MARK: - Materials Repository Protocol

/// Protocolo que define las operaciones del repositorio de materiales.
///
/// Permite abstraer la implementación para facilitar testing e inyección de dependencias.
public protocol MaterialsRepositoryProtocol: Sendable {
    /// Obtiene todos los materiales disponibles.
    /// - Returns: Lista de materiales.
    /// - Throws: `MaterialsRepositoryError` si la operación falla.
    func getMaterials() async throws -> [MaterialDTO]

    /// Obtiene un material por su ID.
    /// - Parameter id: ID del material (UUID).
    /// - Returns: Material encontrado.
    /// - Throws: `MaterialsRepositoryError` si la operación falla.
    func getMaterial(id: String) async throws -> MaterialDTO

    /// Envía un intento de assessment para un material.
    /// - Parameters:
    ///   - materialId: ID del material (UUID).
    ///   - request: Datos del intento de assessment.
    /// - Returns: Resultado del intento.
    /// - Throws: `MaterialsRepositoryError` si la operación falla.
    func submitAssessment(
        materialId: String,
        request: CreateAttemptRequest
    ) async throws -> AttemptResultDTO
}

// MARK: - Materials Repository Error

/// Errores específicos del repositorio de materiales.
public enum MaterialsRepositoryError: Error, Sendable, Equatable {
    /// ID de material inválido.
    case invalidMaterialId(String)

    /// Material no encontrado.
    case materialNotFound(String)

    /// Las respuestas del assessment están vacías.
    case emptyAnswers

    /// El tiempo empleado está fuera del rango válido (1-7200 segundos).
    case invalidTimeSpent(Int)

    /// Error de autenticación.
    case unauthorized

    /// Assessment no encontrado para el material.
    case assessmentNotFound(String)

    /// Error de red subyacente.
    case networkError(NetworkError)
}

extension MaterialsRepositoryError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidMaterialId(let id):
            return "ID de material inválido: \(id)"
        case .materialNotFound(let id):
            return "Material no encontrado: \(id)"
        case .emptyAnswers:
            return "Las respuestas del assessment no pueden estar vacías"
        case .invalidTimeSpent(let seconds):
            return "Tiempo empleado inválido: \(seconds). Debe estar entre 1 y 7200 segundos"
        case .unauthorized:
            return "No autorizado. Por favor, inicie sesión"
        case .assessmentNotFound(let id):
            return "Assessment no encontrado para el material: \(id)"
        case .networkError(let error):
            return "Error de red: \(error.localizedDescription)"
        }
    }
}

// MARK: - Materials Repository Implementation

/// Implementación del repositorio de materiales usando el cliente de red.
///
/// ## Endpoints
/// - `GET /v1/materials` - Lista todos los materiales
/// - `GET /v1/materials/{id}` - Obtiene un material por ID
/// - `POST /v1/materials/{id}/assessment/attempts` - Envía intento de assessment
///
/// ## Ejemplo de uso
/// ```swift
/// let repository = MaterialsRepository(
///     client: NetworkClient.shared,
///     baseURL: "https://api.edugo.com"
/// )
///
/// // Obtener todos los materiales
/// let materials = try await repository.getMaterials()
///
/// // Obtener material específico
/// let material = try await repository.getMaterial(id: "uuid-123")
///
/// // Enviar assessment
/// let request = CreateAttemptRequest(
///     answers: [
///         AnswerRequest(questionId: "q1", selectedAnswerId: "a1", timeSpentSeconds: 30)
///     ],
///     timeSpentSeconds: 120
/// )
/// let result = try await repository.submitAssessment(materialId: "uuid-123", request: request)
/// ```
public actor MaterialsRepository: MaterialsRepositoryProtocol {
    // MARK: - Properties

    private let client: any NetworkClientProtocol
    private let baseURL: String

    // MARK: - Constants

    private enum Endpoints {
        static let materials = "/v1/materials"
        static func material(id: String) -> String { "/v1/materials/\(id)" }
        static func assessment(materialId: String) -> String {
            "/v1/materials/\(materialId)/assessment/attempts"
        }
    }

    private enum Validation {
        static let minTimeSpentSeconds = 1
        static let maxTimeSpentSeconds = 7200
    }

    // MARK: - Initialization

    /// Inicializa el repositorio de materiales.
    /// - Parameters:
    ///   - client: Cliente de red para realizar las requests.
    ///   - baseURL: URL base del API (ej: "https://api.edugo.com").
    public init(client: any NetworkClientProtocol, baseURL: String) {
        self.client = client
        self.baseURL = baseURL
    }

    // MARK: - Public Methods

    public func getMaterials() async throws -> [MaterialDTO] {
        let url = baseURL + Endpoints.materials
        do {
            return try await client.get(url)
        } catch let error as NetworkError {
            throw mapError(error)
        }
    }

    public func getMaterial(id: String) async throws -> MaterialDTO {
        try validateMaterialId(id)

        let url = baseURL + Endpoints.material(id: id)
        do {
            return try await client.get(url)
        } catch let error as NetworkError {
            throw mapError(error, materialId: id)
        }
    }

    public func submitAssessment(
        materialId: String,
        request: CreateAttemptRequest
    ) async throws -> AttemptResultDTO {
        try validateMaterialId(materialId)
        try validateAssessmentRequest(request)

        let url = baseURL + Endpoints.assessment(materialId: materialId)
        do {
            return try await client.post(url, body: request)
        } catch let error as NetworkError {
            throw mapError(error, materialId: materialId, isAssessment: true)
        }
    }

    // MARK: - Private Methods

    private func validateMaterialId(_ id: String) throws {
        guard !id.isEmpty else {
            throw MaterialsRepositoryError.invalidMaterialId(id)
        }

        guard UUID(uuidString: id) != nil else {
            throw MaterialsRepositoryError.invalidMaterialId(id)
        }
    }

    private func validateAssessmentRequest(_ request: CreateAttemptRequest) throws {
        guard !request.answers.isEmpty else {
            throw MaterialsRepositoryError.emptyAnswers
        }

        guard request.timeSpentSeconds >= Validation.minTimeSpentSeconds,
              request.timeSpentSeconds <= Validation.maxTimeSpentSeconds else {
            throw MaterialsRepositoryError.invalidTimeSpent(request.timeSpentSeconds)
        }
    }

    private func mapError(
        _ error: NetworkError,
        materialId: String? = nil,
        isAssessment: Bool = false
    ) -> MaterialsRepositoryError {
        switch error {
        case .unauthorized:
            return .unauthorized
        case .notFound:
            if let materialId {
                return isAssessment
                    ? .assessmentNotFound(materialId)
                    : .materialNotFound(materialId)
            }
            return .networkError(error)
        default:
            return .networkError(error)
        }
    }
}
