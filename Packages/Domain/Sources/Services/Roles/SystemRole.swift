import Foundation

/// Roles del sistema que coinciden EXACTAMENTE con el backend Go.
///
/// Los valores raw (`admin`, `teacher`, `student`, `guardian`) deben mantenerse
/// sincronizados con `edugo-shared/common/types/enum/role.go`.
///
/// ## Jerarquía de Roles
/// - `admin` (level: 100) - Acceso total al sistema
/// - `teacher` (level: 50) - Gestión de cursos y estudiantes
/// - `student` (level: 30) - Acceso a contenido educativo
/// - `guardian` (level: 20) - Seguimiento de progreso de estudiantes
///
/// ## Ejemplo de uso
/// ```swift
/// let role = SystemRole.teacher
///
/// // Verificar jerarquía
/// if role.hasAtLeast(.student) {
///     print("Puede ver contenido de estudiante")
/// }
///
/// // Decodificar desde JSON del backend
/// let decoded = try JSONDecoder().decode(SystemRole.self, from: jsonData)
/// ```
public enum SystemRole: String, Codable, Sendable, CaseIterable {
    /// Administrador del sistema con acceso total
    case admin = "admin"

    /// Profesor con capacidad de gestionar cursos y estudiantes
    case teacher = "teacher"

    /// Estudiante con acceso a contenido educativo
    case student = "student"

    /// Tutor/Acudiente con acceso al progreso de estudiantes
    case guardian = "guardian"

    // MARK: - Hierarchy

    /// Nivel jerárquico del rol (mayor = más privilegios)
    ///
    /// - admin: 100
    /// - teacher: 50
    /// - student: 30
    /// - guardian: 20
    public var level: Int {
        switch self {
        case .admin: return 100
        case .teacher: return 50
        case .student: return 30
        case .guardian: return 20
        }
    }

    /// Verifica si este rol tiene al menos el nivel del rol especificado.
    ///
    /// - Parameter role: El rol mínimo requerido
    /// - Returns: `true` si el nivel de este rol es >= al nivel del rol especificado
    ///
    /// ## Ejemplo
    /// ```swift
    /// SystemRole.admin.hasAtLeast(.student)  // true
    /// SystemRole.student.hasAtLeast(.teacher) // false
    /// SystemRole.teacher.hasAtLeast(.teacher) // true
    /// ```
    public func hasAtLeast(_ role: SystemRole) -> Bool {
        self.level >= role.level
    }

    // MARK: - Display

    /// Nombre localizable para mostrar en la UI
    public var displayName: String {
        switch self {
        case .admin: return "Administrador"
        case .teacher: return "Profesor"
        case .student: return "Estudiante"
        case .guardian: return "Acudiente"
        }
    }

    /// Descripción corta del rol
    public var roleDescription: String {
        switch self {
        case .admin: return "Acceso total al sistema"
        case .teacher: return "Gestión de cursos y calificaciones"
        case .student: return "Acceso a contenido educativo"
        case .guardian: return "Seguimiento de progreso"
        }
    }
}
