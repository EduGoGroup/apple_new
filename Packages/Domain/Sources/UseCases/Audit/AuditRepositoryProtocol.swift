import Foundation
import EduCore

// MARK: - Audit Data Provider Protocol

/// Protocolo que define el acceso a datos de auditoría.
///
/// Definido en Domain para permitir que Presentation dependa
/// de la abstracción sin conocer la implementación en Infrastructure.
///
/// La implementación concreta (AuditRepository) vive en Infrastructure.
/// La inyección se realiza en la composición de la app.
public protocol AuditDataProvider: Sendable {
    /// Obtiene una lista de eventos de auditoría.
    /// - Parameters:
    ///   - page: Número de página (1-based).
    ///   - pageSize: Tamaño de página.
    ///   - severity: Filtro opcional por severidad.
    /// - Returns: Tupla con eventos y flag de si hay más páginas.
    func listEvents(
        page: Int,
        pageSize: Int,
        severity: String?
    ) async throws -> (events: [AuditEventDTO], hasNextPage: Bool)

    /// Obtiene un evento de auditoría por su ID.
    func getEvent(id: String) async throws -> AuditEventDTO

    /// Obtiene el resumen de auditoría con conteos por severidad.
    func getSummary() async throws -> AuditSummaryDTO
}
