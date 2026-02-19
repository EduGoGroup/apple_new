import Foundation

/// Configuración global del sistema de logging.
///
/// Permite controlar el comportamiento del logging a nivel global y por categoría.
///
/// ## Ejemplo de uso:
/// ```swift
/// let config = LogConfiguration(
///     globalLevel: .info,
///     isEnabled: true,
///     environment: .production,
///     subsystem: "com.myapp.ios"
/// )
/// ```
public struct LogConfiguration: Sendable {

    // MARK: - Environment

    /// Entorno de ejecución de la aplicación.
    public enum Environment: String, Sendable {
        case development
        case staging
        case production

        /// Nivel de log por defecto para este entorno.
        public var defaultLevel: LogLevel {
            switch self {
            case .development: return .debug
            case .staging: return .info
            case .production: return .warning
            }
        }
    }

    // MARK: - Properties

    /// Nivel de log global (mínimo) para todas las categorías.
    public let globalLevel: LogLevel

    /// Indica si el logging está habilitado globalmente.
    public let isEnabled: Bool

    /// Entorno de ejecución actual.
    public let environment: Environment

    /// Subsistema principal de la aplicación (reverse-domain notation).
    public let subsystem: String

    /// Configuraciones específicas por categoría.
    public let categoryOverrides: [String: LogLevel]

    /// Indica si se debe incluir metadata adicional (archivo, función, línea).
    public let includeMetadata: Bool

    // MARK: - Initialization

    /// Inicializa una nueva configuración de logging.
    ///
    /// - Parameters:
    ///   - globalLevel: Nivel mínimo global (por defecto: basado en entorno)
    ///   - isEnabled: Si el logging está habilitado (por defecto: `true`)
    ///   - environment: Entorno de ejecución (por defecto: detectado automáticamente)
    ///   - subsystem: Identificador del subsistema (requerido para SDK reutilizable)
    ///   - categoryOverrides: Configuraciones específicas por categoría
    ///   - includeMetadata: Si incluir metadata de origen
    public init(
        globalLevel: LogLevel? = nil,
        isEnabled: Bool = true,
        environment: Environment? = nil,
        subsystem: String = "com.app.default",
        categoryOverrides: [String: LogLevel] = [:],
        includeMetadata: Bool? = nil
    ) {
        let detectedEnv = environment ?? Self.detectEnvironment()
        self.environment = detectedEnv
        self.globalLevel = globalLevel ?? detectedEnv.defaultLevel
        self.isEnabled = isEnabled
        self.subsystem = subsystem
        self.categoryOverrides = categoryOverrides
        self.includeMetadata = includeMetadata ?? (detectedEnv == .development)
    }

    // MARK: - Level Resolution

    /// Determina el nivel efectivo para una categoría específica.
    public func effectiveLevel(for category: LogCategory?) -> LogLevel {
        guard let category = category else {
            return globalLevel
        }
        return categoryOverrides[category.identifier] ?? globalLevel
    }

    /// Verifica si un mensaje con el nivel dado debe registrarse para una categoría.
    public func shouldLog(level: LogLevel, for category: LogCategory?) -> Bool {
        guard isEnabled else { return false }
        return level >= effectiveLevel(for: category)
    }

    // MARK: - Environment Detection

    private static func detectEnvironment() -> Environment {
        #if DEBUG
        return .development
        #else
        if let envString = ProcessInfo.processInfo.environment["APP_ENVIRONMENT"],
           let env = Environment(rawValue: envString.lowercased()) {
            return env
        }
        return .production
        #endif
    }

    // MARK: - Presets

    /// Configuración para desarrollo: todos los logs habilitados.
    public static let development = LogConfiguration(
        globalLevel: .debug,
        environment: .development,
        includeMetadata: true
    )

    /// Configuración para staging: logs informativos y superiores.
    public static let staging = LogConfiguration(
        globalLevel: .info,
        environment: .staging,
        includeMetadata: true
    )

    /// Configuración para producción: solo warnings y errores.
    public static let production = LogConfiguration(
        globalLevel: .warning,
        environment: .production,
        includeMetadata: false
    )

    /// Configuración para testing: logging deshabilitado.
    public static let testing = LogConfiguration(
        globalLevel: .error,
        isEnabled: false,
        environment: .development,
        includeMetadata: false
    )
}

// MARK: - Configuration Builder

public extension LogConfiguration {

    /// Crea una nueva configuración con un override adicional para una categoría.
    func withOverride(level: LogLevel, for categoryId: String) -> LogConfiguration {
        var newOverrides = categoryOverrides
        newOverrides[categoryId] = level

        return LogConfiguration(
            globalLevel: globalLevel,
            isEnabled: isEnabled,
            environment: environment,
            subsystem: subsystem,
            categoryOverrides: newOverrides,
            includeMetadata: includeMetadata
        )
    }

    /// Crea una nueva configuración habilitando/deshabilitando el logging.
    func withEnabled(_ enabled: Bool) -> LogConfiguration {
        LogConfiguration(
            globalLevel: globalLevel,
            isEnabled: enabled,
            environment: environment,
            subsystem: subsystem,
            categoryOverrides: categoryOverrides,
            includeMetadata: includeMetadata
        )
    }
}
