import Foundation

// MARK: - Progress Repository Protocol

/// Protocolo que define las operaciones del repositorio de progreso.
///
/// Permite abstraer la implementación para facilitar testing e inyección de dependencias.
public protocol ProgressRepositoryProtocol: Sendable {
    /// Actualiza el progreso de un usuario en un material (operación upsert).
    /// - Parameter request: Datos del progreso a actualizar.
    /// - Returns: Progreso actualizado.
    /// - Throws: `ProgressRepositoryError` si la operación falla.
    func updateProgress(request: UpsertProgressRequest) async throws -> ProgressDTO
}

// MARK: - Progress Repository Error

/// Errores específicos del repositorio de progreso.
public enum ProgressRepositoryError: Error, Sendable, Equatable {
    /// ID de material inválido.
    case invalidMaterialId(String)

    /// ID de usuario inválido.
    case invalidUserId(String)

    /// Porcentaje fuera del rango válido (0-100).
    case invalidPercentage(Int)

    /// Error de autenticación.
    case unauthorized

    /// El usuario no puede modificar el progreso de otro usuario.
    case forbidden

    /// Error de red subyacente.
    case networkError(NetworkError)
}

extension ProgressRepositoryError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidMaterialId(let id):
            return "ID de material inválido: \(id)"
        case .invalidUserId(let id):
            return "ID de usuario inválido: \(id)"
        case .invalidPercentage(let percentage):
            return "Porcentaje inválido: \(percentage). Debe estar entre 0 y 100"
        case .unauthorized:
            return "No autorizado. Por favor, inicie sesión"
        case .forbidden:
            return "No tiene permisos para modificar este progreso"
        case .networkError(let error):
            return "Error de red: \(error.localizedDescription)"
        }
    }
}

// MARK: - Progress Repository Implementation

/// Implementación del repositorio de progreso usando el cliente de red.
///
/// ## Endpoints
/// - `PUT /v1/progress` - Actualiza o crea progreso (upsert idempotente)
///
/// ## Nota sobre idempotencia
/// El endpoint es una operación upsert, lo que significa que múltiples llamadas
/// con los mismos datos son seguras y producen el mismo resultado.
///
/// ## Ejemplo de uso
/// ```swift
/// let repository = ProgressRepository(
///     client: NetworkClient.shared,
///     baseURL: "https://api.edugo.com"
/// )
///
/// // Actualizar progreso
/// let request = UpsertProgressRequest(
///     materialId: "material-uuid",
///     userId: "user-uuid",
///     percentage: 75
/// )
/// let progress = try await repository.updateProgress(request: request)
/// print("Progreso actualizado: \(progress.percentage)%")
/// ```
public actor ProgressRepository: ProgressRepositoryProtocol {
    // MARK: - Properties

    private let client: any NetworkClientProtocol
    private let baseURL: String

    // MARK: - Constants

    private enum Endpoints {
        static let progress = "/v1/progress"
    }

    private enum Validation {
        static let minPercentage = 0
        static let maxPercentage = 100
    }

    // MARK: - Initialization

    /// Inicializa el repositorio de progreso.
    /// - Parameters:
    ///   - client: Cliente de red para realizar las requests.
    ///   - baseURL: URL base del API (ej: "https://api.edugo.com").
    public init(client: any NetworkClientProtocol, baseURL: String) {
        self.client = client
        self.baseURL = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
    }

    // MARK: - Public Methods

    public func updateProgress(request: UpsertProgressRequest) async throws -> ProgressDTO {
        try validateProgressRequest(request)

        let url = baseURL + Endpoints.progress
        do {
            return try await client.put(url, body: request)
        } catch let error as NetworkError {
            throw mapError(error)
        }
    }

    // MARK: - Private Methods

    private func validateProgressRequest(_ request: UpsertProgressRequest) throws {
        guard !request.materialId.isEmpty, UUID(uuidString: request.materialId) != nil else {
            throw ProgressRepositoryError.invalidMaterialId(request.materialId)
        }

        guard !request.userId.isEmpty, UUID(uuidString: request.userId) != nil else {
            throw ProgressRepositoryError.invalidUserId(request.userId)
        }

        guard request.percentage >= Validation.minPercentage,
              request.percentage <= Validation.maxPercentage else {
            throw ProgressRepositoryError.invalidPercentage(request.percentage)
        }
    }

    private func mapError(_ error: NetworkError) -> ProgressRepositoryError {
        switch error {
        case .unauthorized:
            return .unauthorized
        case .forbidden:
            return .forbidden
        default:
            return .networkError(error)
        }
    }
}
