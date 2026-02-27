import Foundation

// MARK: - AuthContext

/// Contexto activo del usuario autenticado: rol, escuela y permisos.
///
/// Modelo de dominio que representa la combinacion rol-escuela
/// seleccionada por el usuario. Incluye metodos para consultar permisos.
///
/// Nota: Se usa `AuthContext` (no `UserContext`) para evitar conflicto
/// con `EduDomain.UserContext` que es el contexto completo del dashboard.
///
/// ## Ejemplo
/// ```swift
/// let context = AuthContext(
///     roleId: "uuid-1",
///     roleName: "teacher",
///     schoolId: "uuid-2",
///     schoolName: "Lincoln High",
///     permissions: ["view_dashboard", "edit_grades", "view_students"]
/// )
///
/// context.hasPermission("edit_grades")          // true
/// context.hasAnyPermission(["admin", "edit_grades"]) // true
/// context.hasAllPermissions(["edit_grades", "view_students"]) // true
/// ```
public struct AuthContext: Sendable, Equatable, Hashable, Codable {

    // MARK: - Properties

    /// Identificador unico del rol.
    public let roleId: String

    /// Nombre visible del rol (e.g. "teacher", "student").
    public let roleName: String

    /// Identificador de la escuela (nil si el rol es global).
    public let schoolId: String?

    /// Nombre visible de la escuela.
    public let schoolName: String?

    /// Identificador de la unidad academica.
    public let academicUnitId: String?

    /// Lista de permisos otorgados en este contexto.
    public let permissions: [String]

    // MARK: - Permission Methods

    /// Verifica si el contexto tiene un permiso especifico.
    ///
    /// - Parameter permission: Clave del permiso a verificar.
    /// - Returns: `true` si el permiso esta presente.
    public func hasPermission(_ permission: String) -> Bool {
        permissions.contains(permission)
    }

    /// Verifica si el contexto tiene al menos uno de los permisos indicados.
    ///
    /// - Parameter required: Lista de permisos a verificar.
    /// - Returns: `true` si al menos uno esta presente.
    public func hasAnyPermission(_ required: [String]) -> Bool {
        required.contains(where: permissions.contains)
    }

    /// Verifica si el contexto tiene todos los permisos indicados.
    ///
    /// - Parameter required: Lista de permisos requeridos.
    /// - Returns: `true` si todos estan presentes.
    public func hasAllPermissions(_ required: [String]) -> Bool {
        required.allSatisfy(permissions.contains)
    }

    // MARK: - Initialization

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

// MARK: - Factory Methods

extension AuthContext {
    /// Crea un `AuthContext` a partir de un `UserContextDTO`.
    public static func from(dto: UserContextDTO) -> AuthContext {
        AuthContext(
            roleId: dto.roleId,
            roleName: dto.roleName,
            schoolId: dto.schoolId,
            schoolName: dto.schoolName,
            academicUnitId: dto.academicUnitId,
            permissions: dto.permissions
        )
    }
}
