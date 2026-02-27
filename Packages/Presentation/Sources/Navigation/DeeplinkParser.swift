import Foundation

/// Parser para convertir URLs en Deeplinks tipados.
///
/// DeeplinkParser analiza URLs de diferentes fuentes (URL schemes, universal links,
/// notificaciones push) y las convierte en objetos Deeplink type-safe.
///
/// # Formatos soportados
/// - URL Scheme: `edugo://dashboard`
/// - Universal Link: `https://edugo.app/materials/123`
/// - Con query params: `edugo://assessments/123?userId=456`
///
/// # Ejemplo de uso:
/// ```swift
/// let url = URL(string: "edugo://materials/abc-123")!
/// if let deeplink = DeeplinkParser.parse(url) {
///     // deeplink == .materialDetail(materialId: uuid)
///     appCoordinator.navigate(to: deeplink.toScreen())
/// }
/// ```
public struct DeeplinkParser {

    // MARK: - Public Methods

    /// Parsea una URL y retorna el Deeplink correspondiente.
    ///
    /// Soporta diferentes esquemas de URL (edugo://, https://edugo.app)
    /// y extrae parámetros del path y query string.
    ///
    /// - Parameter url: URL a parsear
    /// - Returns: Deeplink si la URL es válida, nil si no se puede parsear
    ///
    /// # Ejemplos:
    /// ```swift
    /// parse(URL(string: "edugo://dashboard")!)
    /// // → .dashboard
    ///
    /// parse(URL(string: "edugo://materials/abc-123")!)
    /// // → .materialDetail(materialId: UUID("abc-123"))
    ///
    /// parse(URL(string: "edugo://assessments/abc?userId=def")!)
    /// // → .assessment(assessmentId: UUID("abc"), userId: UUID("def"))
    /// ```
    public static func parse(_ url: URL) -> Deeplink? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }

        // Para URL schemes (edugo://dashboard), el host contiene la ruta principal
        // Para Universal Links (https://edugo.app/dashboard), el path contiene la ruta
        let pathComponents: [String]

        if components.scheme == "edugo" || components.scheme == "edugo-dev" {
            // URL scheme: edugo://materials/123 → host="materials", path="/123"
            var parts: [String] = []
            if let host = components.host {
                parts.append(host)
            }
            let pathParts = components.path.split(separator: "/").map(String.init)
            parts.append(contentsOf: pathParts)
            pathComponents = parts
        } else {
            // Universal link: https://edugo.app/materials/123 → path="/materials/123"
            pathComponents = components.path.split(separator: "/").map(String.init)
        }

        guard let firstComponent = pathComponents.first else {
            return nil
        }

        switch firstComponent {
        case "dashboard":
            return .dashboard

        case "materials":
            return parseMaterialsRoute(pathComponents: pathComponents)

        case "assessments":
            return parseAssessmentsRoute(
                pathComponents: pathComponents,
                queryItems: components.queryItems
            )

        case "profile":
            return .userProfile

        case "login":
            return .login

        default:
            return nil
        }
    }

    // MARK: - Private Parsing Methods

    /// Parsea rutas de materiales.
    ///
    /// Formatos soportados:
    /// - `/materials` → lista de materiales
    /// - `/materials/abc-123` → detalle de material
    private static func parseMaterialsRoute(pathComponents: [String]) -> Deeplink? {
        if pathComponents.count == 1 {
            return .materialList
        } else if pathComponents.count == 2,
                  let uuid = UUID(uuidString: pathComponents[1]) {
            return .materialDetail(materialId: uuid)
        }
        return nil
    }

    /// Parsea rutas de evaluaciones.
    ///
    /// Formatos soportados:
    /// - `/assessments/abc-123?userId=def-456` → evaluación
    /// - `/assessments/abc-123/results` → resultados
    private static func parseAssessmentsRoute(
        pathComponents: [String],
        queryItems: [URLQueryItem]?
    ) -> Deeplink? {
        guard pathComponents.count >= 2,
              let assessmentId = UUID(uuidString: pathComponents[1]) else {
            return nil
        }

        // Check for results route
        if pathComponents.count == 3 && pathComponents[2] == "results" {
            return .assessmentResults(assessmentId: assessmentId)
        }

        // Extract userId from query params for assessment route
        if let userIdString = queryItems?.first(where: { $0.name == "userId" })?.value,
           let userId = UUID(uuidString: userIdString) {
            return .assessment(assessmentId: assessmentId, userId: userId)
        }

        return nil
    }
}
