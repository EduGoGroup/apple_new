import Foundation
import EduCore

// MARK: - Audit Repository Protocol

/// Protocolo que define las operaciones del repositorio de auditoría.
///
/// Permite abstraer la implementación para facilitar testing e inyección de dependencias.
public protocol AuditRepositoryProtocol: Sendable {
    /// Obtiene una lista paginada de eventos de auditoría.
    /// - Parameters:
    ///   - page: Número de página (1-based).
    ///   - pageSize: Tamaño de página.
    ///   - severity: Filtro opcional por severidad.
    /// - Returns: Respuesta paginada de eventos de auditoría.
    /// - Throws: `AuditRepositoryError` si la operación falla.
    func listEvents(
        page: Int,
        pageSize: Int,
        severity: String?
    ) async throws -> PaginatedResponse<AuditEventDTO>

    /// Obtiene un evento de auditoría por su ID.
    /// - Parameter id: ID del evento.
    /// - Returns: Evento de auditoría encontrado.
    /// - Throws: `AuditRepositoryError` si la operación falla.
    func getEvent(id: String) async throws -> AuditEventDTO

    /// Obtiene el resumen de auditoría con conteos por severidad.
    /// - Returns: Resumen de auditoría.
    /// - Throws: `AuditRepositoryError` si la operación falla.
    func getSummary() async throws -> AuditSummaryDTO
}

// MARK: - Audit Repository Error

/// Errores específicos del repositorio de auditoría.
public enum AuditRepositoryError: Error, Sendable, Equatable {
    /// Error de autenticación.
    case unauthorized

    /// El usuario no tiene permisos para ver auditoría.
    case forbidden

    /// Evento de auditoría no encontrado.
    case eventNotFound(String)

    /// Error de red subyacente.
    case networkError(NetworkError)
}

extension AuditRepositoryError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "No autorizado. Por favor, inicie sesión"
        case .forbidden:
            return "Acceso denegado. No tiene permisos para ver registros de auditoría"
        case .eventNotFound(let id):
            return "Evento de auditoría no encontrado: \(id)"
        case .networkError(let error):
            return "Error de red: \(error.localizedDescription)"
        }
    }
}

// MARK: - Audit Repository Implementation

/// Implementación del repositorio de auditoría usando el cliente de red.
///
/// ## Endpoints
/// - `GET /api/v1/audit/events` - Lista eventos de auditoría (paginado)
/// - `GET /api/v1/audit/events/{id}` - Obtiene un evento por ID
/// - `GET /api/v1/audit/summary` - Obtiene resumen por severidad
///
/// ## Ejemplo de uso
/// ```swift
/// let repository = AuditRepository(
///     client: NetworkClient.shared,
///     baseURL: "https://iam.edugo.com"
/// )
///
/// let events = try await repository.listEvents(page: 1, pageSize: 20, severity: nil)
/// let summary = try await repository.getSummary()
/// ```
public actor AuditRepository: AuditRepositoryProtocol {
    // MARK: - Properties

    private let client: any NetworkClientProtocol
    private let baseURL: String

    // MARK: - Constants

    private enum Endpoints {
        static let events = "/api/v1/audit/events"
        static func event(id: String) -> String { "/api/v1/audit/events/\(id)" }
        static let summary = "/api/v1/audit/summary"
    }

    // MARK: - Initialization

    /// Inicializa el repositorio de auditoría.
    /// - Parameters:
    ///   - client: Cliente de red para realizar las requests.
    ///   - baseURL: URL base del API IAM (ej: "https://iam.edugo.com").
    public init(client: any NetworkClientProtocol, baseURL: String) {
        self.client = client
        var sanitized = baseURL
        while sanitized.hasSuffix("/") { sanitized = String(sanitized.dropLast()) }
        self.baseURL = sanitized
    }

    // MARK: - Public Methods

    public func listEvents(
        page: Int,
        pageSize: Int,
        severity: String?
    ) async throws -> PaginatedResponse<AuditEventDTO> {
        var url = baseURL + Endpoints.events + "?page=\(page)&page_size=\(pageSize)"
        if let severity, !severity.isEmpty {
            let encoded = severity.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? severity
            url += "&severity=\(encoded)"
        }
        do {
            return try await client.get(url)
        } catch let error as NetworkError {
            throw mapError(error)
        }
    }

    public func getEvent(id: String) async throws -> AuditEventDTO {
        let url = baseURL + Endpoints.event(id: id)
        do {
            return try await client.get(url)
        } catch let error as NetworkError {
            throw mapError(error, eventId: id)
        }
    }

    public func getSummary() async throws -> AuditSummaryDTO {
        let url = baseURL + Endpoints.summary
        do {
            return try await client.get(url)
        } catch let error as NetworkError {
            throw mapError(error)
        }
    }

    // MARK: - Private Methods

    private func mapError(
        _ error: NetworkError,
        eventId: String? = nil
    ) -> AuditRepositoryError {
        switch error {
        case .unauthorized:
            return .unauthorized
        case .forbidden:
            return .forbidden
        case .notFound:
            if let eventId {
                return .eventNotFound(eventId)
            }
            return .networkError(error)
        default:
            return .networkError(error)
        }
    }
}
