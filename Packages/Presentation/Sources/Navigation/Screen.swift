import Foundation

/// Define las pantallas disponibles en la aplicación de forma type-safe.
///
/// Este enum representa todas las rutas de navegación posibles en la app,
/// permitiendo navegación type-safe con SwiftUI NavigationStack.
///
/// # Características
/// - Type-safe routes: El compilador valida las rutas en tiempo de compilación
/// - Associated values: Permite pasar parámetros type-safe a las pantallas
/// - Hashable: Compatible con NavigationPath
/// - Sendable: Thread-safe para concurrencia
///
/// # Ejemplo de uso:
/// ```swift
/// coordinator.navigate(to: .materialDetail(materialId: materialId))
/// coordinator.presentSheet(.materialUpload)
/// coordinator.navigate(to: .assessment(assessmentId: id, userId: userId))
/// ```
public enum Screen: Hashable, Sendable {
    // MARK: - Auth Flow

    /// Pantalla de login/autenticación
    case login

    // MARK: - Main Flow

    /// Dashboard principal con resumen de actividades
    case dashboard

    /// Listado de materiales educativos
    case materialList

    /// Formulario para subir un nuevo material
    case materialUpload

    /// Pantalla para asignar un material a estudiantes/grupos
    /// - Parameter materialId: ID del material a asignar
    case materialAssignment(materialId: UUID)

    /// Pantalla de evaluación/examen
    /// - Parameters:
    ///   - assessmentId: ID de la evaluación
    ///   - userId: ID del usuario que realiza la evaluación
    case assessment(assessmentId: UUID, userId: UUID)

    /// Perfil del usuario actual
    case userProfile

    /// Pantalla para cambiar de contexto (rol, grupo, etc.)
    case contextSwitch

    // MARK: - Detail Views

    /// Vista de detalle de un material específico
    /// - Parameter materialId: ID del material a mostrar
    case materialDetail(materialId: UUID)

    /// Resultados de una evaluación completada
    /// - Parameter assessmentId: ID de la evaluación
    case assessmentResults(assessmentId: UUID)

    // MARK: - Computed Properties

    /// Identificador único de la pantalla para tracking y analytics
    public var id: String {
        switch self {
        case .login:
            return "login"
        case .dashboard:
            return "dashboard"
        case .materialList:
            return "materialList"
        case .materialUpload:
            return "materialUpload"
        case .materialAssignment(let id):
            return "materialAssignment-\(id)"
        case .assessment(let id, _):
            return "assessment-\(id)"
        case .userProfile:
            return "userProfile"
        case .contextSwitch:
            return "contextSwitch"
        case .materialDetail(let id):
            return "materialDetail-\(id)"
        case .assessmentResults(let id):
            return "assessmentResults-\(id)"
        }
    }
}
