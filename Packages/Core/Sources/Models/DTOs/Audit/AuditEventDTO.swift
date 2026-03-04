import Foundation

/// Data Transfer Object para un evento de auditoría del backend.
///
/// Mapea la estructura JSON del endpoint `/api/v1/audit/events`.
///
/// ## JSON Structure
/// ```json
/// {
///     "id": "550e8400-e29b-41d4-a716-446655440000",
///     "actor_email": "admin@edugo.com",
///     "actor_role": "superadmin",
///     "action": "CREATE",
///     "resource_type": "user",
///     "resource_id": "660e8400-e29b-41d4-a716-446655440001",
///     "severity": "medium",
///     "category": "user_management",
///     "created_at": "2026-03-04T10:30:00Z"
/// }
/// ```
public struct AuditEventDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let actorEmail: String
    public let actorRole: String
    public let action: String
    public let resourceType: String
    public let resourceId: String?
    public let severity: String
    public let category: String
    public let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case actorEmail = "actor_email"
        case actorRole = "actor_role"
        case action
        case resourceType = "resource_type"
        case resourceId = "resource_id"
        case severity
        case category
        case createdAt = "created_at"
    }

    public init(
        id: String,
        actorEmail: String,
        actorRole: String,
        action: String,
        resourceType: String,
        resourceId: String?,
        severity: String,
        category: String,
        createdAt: String
    ) {
        self.id = id
        self.actorEmail = actorEmail
        self.actorRole = actorRole
        self.action = action
        self.resourceType = resourceType
        self.resourceId = resourceId
        self.severity = severity
        self.category = category
        self.createdAt = createdAt
    }
}
