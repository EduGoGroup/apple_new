import Foundation

/// Enum que representa todos los deeplinks soportados en la aplicación.
///
/// Los deeplinks permiten navegación directa a pantallas específicas mediante:
/// - URL Schemes: `edugo://dashboard`
/// - Universal Links: `https://edugo.app/materials/123`
/// - Push Notifications: Payload con deeplink
///
/// # Casos de uso
/// - Abrir material específico desde notificación
/// - Compartir enlaces directos a evaluaciones
/// - Navegación desde emails o SMS
///
/// # Ejemplo de uso:
/// ```swift
/// let deeplink = Deeplink.materialDetail(materialId: uuid)
/// let path = deeplink.path // "/materials/abc-123"
/// let screen = deeplink.toScreen() // .materialDetail(materialId: uuid)
/// ```
public enum Deeplink: Equatable, Sendable {
    /// Dashboard principal
    case dashboard

    /// Lista de materiales educativos
    case materialList

    /// Detalle de un material específico
    case materialDetail(materialId: UUID)

    /// Evaluación/Assessment con IDs de evaluación y usuario
    case assessment(assessmentId: UUID, userId: UUID)

    /// Resultados de una evaluación completada
    case assessmentResults(assessmentId: UUID)

    /// Perfil del usuario
    case userProfile

    /// Pantalla de login
    case login

    // MARK: - Computed Properties

    /// Path del deeplink para construcción de URLs.
    ///
    /// Retorna el path relativo que puede ser usado para construir
    /// URL schemes o universal links.
    ///
    /// # Ejemplos:
    /// - `.dashboard` → `"/dashboard"`
    /// - `.materialDetail(id)` → `"/materials/abc-123"`
    /// - `.assessment(aId, uId)` → `"/assessments/abc-123?userId=def-456"`
    public var path: String {
        switch self {
        case .dashboard:
            return "/dashboard"
        case .materialList:
            return "/materials"
        case .materialDetail(let id):
            return "/materials/\(id.uuidString)"
        case .assessment(let assessmentId, let userId):
            return "/assessments/\(assessmentId.uuidString)?userId=\(userId.uuidString)"
        case .assessmentResults(let id):
            return "/assessments/\(id.uuidString)/results"
        case .userProfile:
            return "/profile"
        case .login:
            return "/login"
        }
    }

    /// Convierte el deeplink a su Screen correspondiente.
    ///
    /// Facilita la navegación transformando deeplinks directamente
    /// a las pantallas del AppCoordinator.
    ///
    /// - Returns: Screen correspondiente al deeplink
    public func toScreen() -> Screen {
        switch self {
        case .dashboard:
            return .dashboard
        case .materialList:
            return .materialList
        case .materialDetail(let id):
            return .materialDetail(materialId: id)
        case .assessment(let assessmentId, let userId):
            return .assessment(assessmentId: assessmentId, userId: userId)
        case .assessmentResults(let id):
            return .assessmentResults(assessmentId: id)
        case .userProfile:
            return .userProfile
        case .login:
            return .login
        }
    }
}
