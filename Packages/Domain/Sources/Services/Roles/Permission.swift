import Foundation

/// Conjunto de permisos del sistema usando OptionSet para combinaciones eficientes.
///
/// Usa `UInt64` como rawValue para soportar hasta 64 permisos diferentes.
/// Los bits están organizados por categorías con espacios para expansión futura.
///
/// ## Categorías de permisos
/// - **Materiales** (bits 0-9): Gestión de contenido educativo
/// - **Quizzes** (bits 10-19): Evaluaciones y calificaciones
/// - **Progreso** (bits 20-29): Seguimiento de avance
/// - **Usuarios** (bits 30-39): Administración de usuarios
/// - **Reportes** (bits 40-49): Generación de informes
///
/// ## Ejemplo de uso
/// ```swift
/// // Crear un conjunto de permisos
/// let teacherPerms: Permission = [.viewMaterials, .uploadMaterials, .createQuizzes]
///
/// // Verificar un permiso
/// if teacherPerms.contains(.uploadMaterials) {
///     print("Puede subir materiales")
/// }
///
/// // Combinar permisos
/// let extended = teacherPerms.union(.gradeQuizzes)
/// ```
public struct Permission: OptionSet, Sendable, Hashable {
    public let rawValue: UInt64

    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }

    // MARK: - Materials (bits 0-9)

    /// Ver materiales educativos
    public static let viewMaterials = Permission(rawValue: 1 << 0)

    /// Subir nuevos materiales
    public static let uploadMaterials = Permission(rawValue: 1 << 1)

    /// Editar materiales existentes
    public static let editMaterials = Permission(rawValue: 1 << 2)

    /// Eliminar materiales
    public static let deleteMaterials = Permission(rawValue: 1 << 3)

    // MARK: - Quizzes (bits 10-19)

    /// Tomar/realizar evaluaciones
    public static let takeQuizzes = Permission(rawValue: 1 << 10)

    /// Crear nuevas evaluaciones
    public static let createQuizzes = Permission(rawValue: 1 << 11)

    /// Calificar evaluaciones de estudiantes
    public static let gradeQuizzes = Permission(rawValue: 1 << 12)

    // MARK: - Progress (bits 20-29)

    /// Ver el progreso propio
    public static let viewOwnProgress = Permission(rawValue: 1 << 20)

    /// Ver el progreso de estudiantes (para profesores/tutores)
    public static let viewStudentProgress = Permission(rawValue: 1 << 21)

    // MARK: - Users (bits 30-39)

    /// Ver información de usuarios
    public static let viewUsers = Permission(rawValue: 1 << 30)

    /// Gestionar usuarios (crear, editar, eliminar)
    public static let manageUsers = Permission(rawValue: 1 << 31)

    // MARK: - Reports (bits 40-49)

    /// Ver reportes del sistema
    public static let viewReports = Permission(rawValue: 1 << 40)

    /// Exportar reportes a diferentes formatos
    public static let exportReports = Permission(rawValue: 1 << 41)

    // MARK: - Convenience Sets

    /// Sin permisos
    public static let none: Permission = []

    /// Todos los permisos de materiales
    public static let allMaterials: Permission = [
        .viewMaterials, .uploadMaterials, .editMaterials, .deleteMaterials
    ]

    /// Todos los permisos de quizzes
    public static let allQuizzes: Permission = [
        .takeQuizzes, .createQuizzes, .gradeQuizzes
    ]

    /// Todos los permisos de progreso
    public static let allProgress: Permission = [
        .viewOwnProgress, .viewStudentProgress
    ]

    /// Todos los permisos de usuarios
    public static let allUsers: Permission = [
        .viewUsers, .manageUsers
    ]

    /// Todos los permisos de reportes
    public static let allReports: Permission = [
        .viewReports, .exportReports
    ]

    /// Todos los permisos del sistema
    public static let all: Permission = [
        .viewMaterials, .uploadMaterials, .editMaterials, .deleteMaterials,
        .takeQuizzes, .createQuizzes, .gradeQuizzes,
        .viewOwnProgress, .viewStudentProgress,
        .viewUsers, .manageUsers,
        .viewReports, .exportReports
    ]
}

// MARK: - CustomStringConvertible

extension Permission: CustomStringConvertible {
    public var description: String {
        var names: [String] = []

        if contains(.viewMaterials) { names.append("viewMaterials") }
        if contains(.uploadMaterials) { names.append("uploadMaterials") }
        if contains(.editMaterials) { names.append("editMaterials") }
        if contains(.deleteMaterials) { names.append("deleteMaterials") }
        if contains(.takeQuizzes) { names.append("takeQuizzes") }
        if contains(.createQuizzes) { names.append("createQuizzes") }
        if contains(.gradeQuizzes) { names.append("gradeQuizzes") }
        if contains(.viewOwnProgress) { names.append("viewOwnProgress") }
        if contains(.viewStudentProgress) { names.append("viewStudentProgress") }
        if contains(.viewUsers) { names.append("viewUsers") }
        if contains(.manageUsers) { names.append("manageUsers") }
        if contains(.viewReports) { names.append("viewReports") }
        if contains(.exportReports) { names.append("exportReports") }

        return "Permission([\(names.joined(separator: ", "))])"
    }
}
