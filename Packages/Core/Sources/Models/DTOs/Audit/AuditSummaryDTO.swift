import Foundation

/// Data Transfer Object para el resumen de auditoría.
///
/// Contiene conteos agrupados por severidad de los eventos de auditoría.
///
/// ## JSON Structure
/// ```json
/// {
///     "total": 150,
///     "by_severity": {
///         "critical": 5,
///         "high": 20,
///         "medium": 50,
///         "low": 75
///     }
/// }
/// ```
public struct AuditSummaryDTO: Codable, Sendable, Equatable {
    public let total: Int
    public let bySeverity: [String: Int]

    enum CodingKeys: String, CodingKey {
        case total
        case bySeverity = "by_severity"
    }

    public init(total: Int, bySeverity: [String: Int]) {
        self.total = total
        self.bySeverity = bySeverity
    }
}
