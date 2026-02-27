import EduCore

/// Contexto del usuario con permisos para el sistema de contratos.
///
/// Envuelve la informacion relevante de `UserContextDTO`
/// y provee verificacion de permisos.
///
/// Nota: Se usa `ScreenUserContext` para evitar colision con
/// `UserContext` definido en `LoadUserContextUseCase`.
public struct ScreenUserContext: Sendable {
    public let roleId: String
    public let roleName: String
    public let schoolId: String?
    public let permissions: [String]

    public init(
        roleId: String,
        roleName: String,
        schoolId: String? = nil,
        permissions: [String] = []
    ) {
        self.roleId = roleId
        self.roleName = roleName
        self.schoolId = schoolId
        self.permissions = permissions
    }

    /// Crea un `ScreenUserContext` a partir de un `UserContextDTO`.
    public init(dto: UserContextDTO) {
        self.roleId = dto.roleId
        self.roleName = dto.roleName
        self.schoolId = dto.schoolId
        self.permissions = dto.permissions
    }

    /// Crea un `ScreenUserContext` a partir de un `AuthContext`.
    public init(auth: AuthContext) {
        self.roleId = auth.roleId
        self.roleName = auth.roleName
        self.schoolId = auth.schoolId
        self.permissions = auth.permissions
    }

    /// Verifica si el usuario tiene un permiso especifico.
    public func hasPermission(_ permission: String) -> Bool {
        permissions.contains(permission)
    }

    /// Contexto vacio para pantallas publicas (e.g. login).
    public static let anonymous = ScreenUserContext(
        roleId: "",
        roleName: "anonymous"
    )
}
