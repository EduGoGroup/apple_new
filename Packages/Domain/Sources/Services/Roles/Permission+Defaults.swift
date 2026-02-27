import Foundation

// MARK: - Default Permissions by Role

/// Extensión que define los conjuntos de permisos predeterminados para cada rol del sistema.
///
/// Esta extensión proporciona configuraciones de permisos listas para usar
/// que coinciden con las políticas de autorización del backend.
///
/// ## Uso Típico
/// ```swift
/// // Obtener permisos predeterminados para un rol
/// let teacherPerms = Permission.defaultPermissions(for: .teacher)
///
/// // Verificar si un permiso está en los predeterminados
/// if Permission.studentPermissions.contains(.viewMaterials) {
///     print("Los estudiantes pueden ver materiales")
/// }
/// ```
///
/// ## Personalización
/// Los permisos predeterminados pueden extenderse con permisos adicionales
/// usando el método `setRole(_:withAdditionalPermissions:)` de `RoleManager`.
///
/// - Note: Estos conjuntos deben mantenerse sincronizados con las políticas
///   de autorización del backend Go.
extension Permission {

    /// Permisos predeterminados para estudiantes.
    ///
    /// Incluye los permisos básicos para consumir contenido educativo:
    /// - `viewMaterials`: Ver materiales de estudio
    /// - `takeQuizzes`: Realizar evaluaciones
    /// - `viewOwnProgress`: Ver su propio progreso académico
    ///
    /// ## Ejemplo
    /// ```swift
    /// // Verificar si un estudiante puede realizar una acción
    /// let studentPerms = Permission.studentPermissions
    ///
    /// if studentPerms.contains(.takeQuizzes) {
    ///     showQuizButton()
    /// }
    ///
    /// if !studentPerms.contains(.createQuizzes) {
    ///     hideCreateQuizButton() // Los estudiantes no crean quizzes
    /// }
    /// ```
    public static let studentPermissions: Permission = [
        .viewMaterials,
        .takeQuizzes,
        .viewOwnProgress
    ]

    /// Permisos predeterminados para tutores/acudientes.
    ///
    /// Permisos limitados enfocados en el seguimiento del progreso
    /// de los estudiantes asociados:
    /// - `viewOwnProgress`: Ver el progreso de estudiantes bajo su tutela
    ///
    /// ## Ejemplo
    /// ```swift
    /// // Los tutores solo pueden ver progreso
    /// let guardianPerms = Permission.guardianPermissions
    ///
    /// if guardianPerms.contains(.viewOwnProgress) {
    ///     showStudentProgressDashboard()
    /// }
    ///
    /// // No tienen acceso a materiales directamente
    /// assert(!guardianPerms.contains(.viewMaterials))
    /// ```
    ///
    /// - Note: El permiso `viewOwnProgress` en el contexto de un tutor
    ///   se interpreta como ver el progreso de sus estudiantes asociados,
    ///   no su propio progreso académico.
    public static let guardianPermissions: Permission = [
        .viewOwnProgress
    ]

    /// Permisos predeterminados para profesores.
    ///
    /// Conjunto amplio de permisos para gestión educativa:
    /// - **Materiales**: Ver, subir y editar (sin eliminar)
    /// - **Evaluaciones**: Crear y calificar
    /// - **Seguimiento**: Ver progreso de estudiantes
    /// - **Reportes**: Ver reportes del sistema
    ///
    /// ## Ejemplo
    /// ```swift
    /// let teacherPerms = Permission.teacherPermissions
    ///
    /// // Los profesores pueden gestionar contenido
    /// if teacherPerms.contains(.uploadMaterials) {
    ///     showUploadButton()
    /// }
    ///
    /// // Pero no pueden eliminar materiales
    /// if !teacherPerms.contains(.deleteMaterials) {
    ///     disableDeleteOption()
    /// }
    ///
    /// // Pueden calificar evaluaciones
    /// if teacherPerms.contains(.gradeQuizzes) {
    ///     showGradingInterface()
    /// }
    /// ```
    ///
    /// - Important: Los profesores no tienen permisos de administración
    ///   de usuarios (`manageUsers`) ni exportación de reportes (`exportReports`).
    public static let teacherPermissions: Permission = [
        .viewMaterials,
        .uploadMaterials,
        .editMaterials,
        .createQuizzes,
        .gradeQuizzes,
        .viewStudentProgress,
        .viewReports
    ]

    /// Permisos predeterminados para administradores.
    ///
    /// Incluye **TODOS** los permisos del sistema sin restricciones.
    /// Los administradores tienen acceso completo a todas las funcionalidades.
    ///
    /// ## Ejemplo
    /// ```swift
    /// let adminPerms = Permission.adminPermissions
    ///
    /// // Los administradores pueden hacer todo
    /// assert(adminPerms == Permission.all)
    /// assert(adminPerms.contains(.manageUsers))
    /// assert(adminPerms.contains(.exportReports))
    /// assert(adminPerms.contains(.deleteMaterials))
    /// ```
    ///
    /// - Warning: Asignar rol de administrador otorga acceso irrestricto.
    ///   Usar con precaución y solo para usuarios de confianza.
    public static let adminPermissions: Permission = .all

    /// Obtiene los permisos predeterminados para un rol específico.
    ///
    /// Este método es el punto de entrada recomendado para obtener
    /// los permisos base de un rol. Es utilizado internamente por
    /// `RoleManager.setRole(_:)`.
    ///
    /// - Parameter role: El rol del sistema para el cual obtener permisos
    /// - Returns: El conjunto de permisos predeterminados para ese rol
    ///
    /// ## Ejemplo
    /// ```swift
    /// // Obtener permisos para cualquier rol dinámicamente
    /// func configureUI(for role: SystemRole) {
    ///     let perms = Permission.defaultPermissions(for: role)
    ///
    ///     uploadButton.isEnabled = perms.contains(.uploadMaterials)
    ///     deleteButton.isEnabled = perms.contains(.deleteMaterials)
    ///     usersTab.isHidden = !perms.contains(.viewUsers)
    /// }
    ///
    /// // Comparar permisos entre roles
    /// let studentPerms = Permission.defaultPermissions(for: .student)
    /// let teacherPerms = Permission.defaultPermissions(for: .teacher)
    ///
    /// let teacherOnly = teacherPerms.subtracting(studentPerms)
    /// print("Permisos exclusivos de profesor: \(teacherOnly)")
    /// ```
    ///
    /// - Note: Los permisos retornados son los predeterminados del sistema.
    ///   El backend puede otorgar permisos adicionales que se combinan
    ///   usando `RoleManager.setRole(_:withAdditionalPermissions:)`.
    public static func defaultPermissions(for role: SystemRole) -> Permission {
        switch role {
        case .admin:
            return .adminPermissions
        case .teacher:
            return .teacherPermissions
        case .student:
            return .studentPermissions
        case .guardian:
            return .guardianPermissions
        }
    }
}
