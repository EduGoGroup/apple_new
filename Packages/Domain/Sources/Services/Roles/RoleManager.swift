import Foundation

/// Gestor de roles y permisos del usuario actual.
///
/// `RoleManager` es un actor que mantiene el estado de autorización
/// del usuario de forma thread-safe. Usar siempre con `await`.
///
/// ## Ejemplo de uso
/// ```swift
/// // Configurar rol después del login
/// await RoleManager.shared.setRole(.teacher)
///
/// // Verificar permisos antes de una acción
/// if await RoleManager.shared.hasPermission(.editMaterials) {
///     // Permitir edición
/// }
///
/// // Verificar jerarquía de roles
/// if await RoleManager.shared.hasRole(.student) {
///     // El usuario tiene al menos nivel de estudiante
/// }
///
/// // Logout - limpiar estado
/// await RoleManager.shared.reset()
/// ```
///
/// ## Thread Safety
/// Este actor es completamente thread-safe. Todas las operaciones
/// pueden llamarse desde cualquier contexto de concurrencia sin
/// preocuparse por data races.
///
/// ## Integración con AuthManager
/// Típicamente, `AuthManager` configura el rol después de decodificar
/// el JWT token del backend:
/// ```swift
/// // En AuthManager después del login
/// if let role = jwtClaims.role.flatMap(SystemRole.init(rawValue:)) {
///     await RoleManager.shared.setRole(role)
/// }
/// ```
public actor RoleManager {

    // MARK: - Singleton

    /// Instancia compartida para acceso global.
    ///
    /// Usar esta instancia en la mayoría de los casos.
    /// Para testing, crear instancias locales con `RoleManager()`.
    public static let shared = RoleManager()

    // MARK: - State

    /// Rol actual del usuario
    private var currentRole: SystemRole = .student

    /// Permisos efectivos (predeterminados + custom)
    private var permissions: Permission = []

    /// Permisos adicionales del backend (si los hay)
    private var customPermissions: Permission = []

    // MARK: - Initialization

    /// Crea una nueva instancia de RoleManager.
    ///
    /// Usar para testing o cuando se necesite una instancia aislada.
    /// Para uso general, preferir `RoleManager.shared`.
    public init() {
        // Estado inicial: estudiante sin permisos custom
        self.currentRole = .student
        self.permissions = Permission.defaultPermissions(for: .student)
        self.customPermissions = []
    }

    // MARK: - Role Configuration

    /// Configura el rol actual y actualiza los permisos predeterminados.
    ///
    /// Los permisos se establecen automáticamente según el rol usando
    /// `Permission.defaultPermissions(for:)`.
    ///
    /// - Parameter role: El nuevo rol del usuario
    ///
    /// ## Ejemplo
    /// ```swift
    /// await roleManager.setRole(.teacher)
    /// // Ahora tiene permisos de profesor
    /// ```
    public func setRole(_ role: SystemRole) {
        self.currentRole = role
        self.customPermissions = []
        self.permissions = Permission.defaultPermissions(for: role)
    }

    /// Configura el rol con permisos adicionales del backend.
    ///
    /// Útil cuando el backend otorga permisos extra más allá de los
    /// predeterminados para el rol.
    ///
    /// - Parameters:
    ///   - role: El nuevo rol del usuario
    ///   - additionalPermissions: Permisos extra otorgados por el backend
    ///
    /// ## Ejemplo
    /// ```swift
    /// // Estudiante con permiso especial de exportar reportes
    /// await roleManager.setRole(.student, withAdditionalPermissions: .exportReports)
    /// ```
    public func setRole(_ role: SystemRole, withAdditionalPermissions additionalPermissions: Permission) {
        self.currentRole = role
        self.customPermissions = additionalPermissions
        self.permissions = Permission.defaultPermissions(for: role).union(additionalPermissions)
    }

    // MARK: - Permission Checking

    /// Verifica si el usuario tiene un permiso específico.
    ///
    /// - Parameter permission: El permiso a verificar
    /// - Returns: `true` si el usuario tiene el permiso
    ///
    /// ## Ejemplo
    /// ```swift
    /// if await roleManager.hasPermission(.createQuizzes) {
    ///     showCreateQuizButton()
    /// }
    /// ```
    public func hasPermission(_ permission: Permission) -> Bool {
        permissions.contains(permission)
    }

    /// Verifica si el usuario tiene TODOS los permisos especificados.
    ///
    /// - Parameter requiredPermissions: El conjunto de permisos requeridos
    /// - Returns: `true` si el usuario tiene todos los permisos
    ///
    /// ## Ejemplo
    /// ```swift
    /// let editPerms: Permission = [.editMaterials, .deleteMaterials]
    /// if await roleManager.hasAllPermissions(editPerms) {
    ///     showFullEditMenu()
    /// }
    /// ```
    public func hasAllPermissions(_ requiredPermissions: Permission) -> Bool {
        permissions.isSuperset(of: requiredPermissions)
    }

    /// Verifica si el usuario tiene AL MENOS UNO de los permisos especificados.
    ///
    /// - Parameter anyPermissions: El conjunto de permisos a verificar
    /// - Returns: `true` si el usuario tiene al menos uno de los permisos
    ///
    /// ## Ejemplo
    /// ```swift
    /// let viewPerms: Permission = [.viewMaterials, .viewReports]
    /// if await roleManager.hasAnyPermission(viewPerms) {
    ///     showViewSection()
    /// }
    /// ```
    public func hasAnyPermission(_ anyPermissions: Permission) -> Bool {
        !permissions.intersection(anyPermissions).isEmpty
    }

    // MARK: - Role Checking

    /// Verifica si el usuario tiene al menos el nivel del rol especificado.
    ///
    /// Usa la jerarquía de roles para la comparación.
    ///
    /// - Parameter role: El rol mínimo requerido
    /// - Returns: `true` si el rol actual tiene nivel >= al rol especificado
    ///
    /// ## Ejemplo
    /// ```swift
    /// // Verificar si puede ver contenido de estudiante
    /// if await roleManager.hasRole(.student) {
    ///     showStudentContent()
    /// }
    /// ```
    public func hasRole(_ role: SystemRole) -> Bool {
        currentRole.hasAtLeast(role)
    }

    // MARK: - State Access

    /// Obtiene el rol actual del usuario.
    ///
    /// - Returns: El rol actual
    public func getCurrentRole() -> SystemRole {
        currentRole
    }

    /// Obtiene los permisos efectivos actuales.
    ///
    /// Incluye tanto los permisos predeterminados del rol como
    /// los permisos custom adicionales.
    ///
    /// - Returns: El conjunto de permisos actuales
    public func getCurrentPermissions() -> Permission {
        permissions
    }

    /// Obtiene solo los permisos custom adicionales.
    ///
    /// - Returns: Los permisos adicionales otorgados por el backend
    public func getCustomPermissions() -> Permission {
        customPermissions
    }

    // MARK: - Reset

    /// Limpia el estado y vuelve a la configuración inicial.
    ///
    /// Usar durante logout para asegurar que no quedan permisos
    /// de sesiones anteriores.
    ///
    /// ## Ejemplo
    /// ```swift
    /// func logout() async {
    ///     // Limpiar tokens...
    ///     await RoleManager.shared.reset()
    /// }
    /// ```
    public func reset() {
        self.currentRole = .student
        self.customPermissions = []
        self.permissions = Permission.defaultPermissions(for: .student)
    }
}
