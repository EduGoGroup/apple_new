import Foundation

// MARK: - Stats Repository Protocol

/// Protocolo que define las operaciones del repositorio de estadísticas.
///
/// Permite abstraer la implementación para facilitar testing e inyección de dependencias.
public protocol StatsRepositoryProtocol: Sendable {
    /// Obtiene las estadísticas globales del sistema.
    /// - Returns: Estadísticas globales.
    /// - Throws: `StatsRepositoryError` si la operación falla.
    /// - Note: Este endpoint está restringido solo a usuarios administradores.
    func getGlobalStats() async throws -> GlobalStatsDTO
}

// MARK: - Stats Repository Error

/// Errores específicos del repositorio de estadísticas.
public enum StatsRepositoryError: Error, Sendable, Equatable {
    /// Error de autenticación.
    case unauthorized

    /// El usuario no tiene permisos de administrador.
    case forbidden

    /// Error de red subyacente.
    case networkError(NetworkError)
}

extension StatsRepositoryError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "No autorizado. Por favor, inicie sesión"
        case .forbidden:
            return "Acceso denegado. Solo administradores pueden ver estadísticas globales"
        case .networkError(let error):
            return "Error de red: \(error.localizedDescription)"
        }
    }
}

// MARK: - Stats Repository Implementation

/// Implementación del repositorio de estadísticas usando el cliente de red.
///
/// ## Endpoints
/// - `GET /v1/stats/global` - Obtiene estadísticas globales (solo admins)
///
/// ## Restricción de acceso
/// Este repositorio requiere que el usuario tenga permisos de administrador.
/// Los usuarios sin permisos recibirán un error `forbidden`.
///
/// ## Ejemplo de uso
/// ```swift
/// let repository = StatsRepository(
///     client: NetworkClient.shared,
///     baseURL: "https://api.edugo.com"
/// )
///
/// // Obtener estadísticas globales (requiere admin)
/// do {
///     let stats = try await repository.getGlobalStats()
///     print("Total usuarios: \(stats.totalUsers ?? 0)")
///     print("Total materiales: \(stats.totalMaterials ?? 0)")
///
///     // Acceder a campos dinámicos
///     if let customField = stats.additionalFields["customMetric"] {
///         print("Custom metric: \(customField.value)")
///     }
/// } catch StatsRepositoryError.forbidden {
///     print("Requiere permisos de administrador")
/// }
/// ```
public actor StatsRepository: StatsRepositoryProtocol {
    // MARK: - Properties

    private let client: any NetworkClientProtocol
    private let baseURL: String

    // MARK: - Constants

    private enum Endpoints {
        static let globalStats = "/v1/stats/global"
    }

    // MARK: - Initialization

    /// Inicializa el repositorio de estadísticas.
    /// - Parameters:
    ///   - client: Cliente de red para realizar las requests.
    ///   - baseURL: URL base del API (ej: "https://api.edugo.com").
    public init(client: any NetworkClientProtocol, baseURL: String) {
        self.client = client
        self.baseURL = baseURL
    }

    // MARK: - Public Methods

    public func getGlobalStats() async throws -> GlobalStatsDTO {
        let url = baseURL + Endpoints.globalStats
        do {
            return try await client.get(url)
        } catch let error as NetworkError {
            throw mapError(error)
        }
    }

    // MARK: - Private Methods

    private func mapError(_ error: NetworkError) -> StatsRepositoryError {
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
