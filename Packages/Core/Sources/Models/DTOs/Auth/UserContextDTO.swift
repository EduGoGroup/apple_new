import Foundation

// MARK: - User Context DTO

/// Contexto activo del usuario: rol, escuela y permisos.
///
/// Cada contexto representa una combinacion rol-escuela entre la que
/// el usuario puede alternar en la aplicacion.
///
/// ## JSON Structure (from backend)
/// ```json
/// {
///     "role_id": "550e8400-e29b-41d4-a716-446655440000",
///     "role_name": "teacher",
///     "school_id": "660e8400-e29b-41d4-a716-446655440000",
///     "school_name": "Lincoln High School",
///     "academic_unit_id": null,
///     "permissions": ["read", "write"]
/// }
/// ```
public struct UserContextDTO: Codable, Sendable, Equatable, Hashable {
    public let roleId: String
    public let roleName: String
    public let schoolId: String?
    public let schoolName: String?
    public let academicUnitId: String?
    public let permissions: [String]

    enum CodingKeys: String, CodingKey {
        case roleId = "role_id"
        case roleName = "role_name"
        case schoolId = "school_id"
        case schoolName = "school_name"
        case academicUnitId = "academic_unit_id"
        case permissions
    }

    public init(
        roleId: String,
        roleName: String,
        schoolId: String? = nil,
        schoolName: String? = nil,
        academicUnitId: String? = nil,
        permissions: [String] = []
    ) {
        self.roleId = roleId
        self.roleName = roleName
        self.schoolId = schoolId
        self.schoolName = schoolName
        self.academicUnitId = academicUnitId
        self.permissions = permissions
    }
}
