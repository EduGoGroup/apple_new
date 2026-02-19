import Foundation

/// Configuración del logger basada en variables de entorno.
///
/// Lee y parsea variables de entorno del sistema para configurar el logging.
/// El prefijo de las variables es configurable para cada aplicación.
///
/// ## Variables Soportadas (con prefijo por defecto "APP"):
///
/// | Variable | Valores | Descripción |
/// |----------|---------|-------------|
/// | `APP_LOG_LEVEL` | debug, info, warning, error | Nivel mínimo global |
/// | `APP_LOG_ENABLED` | true, false, 1, 0 | Habilitar/deshabilitar logging |
/// | `APP_LOG_METADATA` | true, false, 1, 0 | Incluir metadata de origen |
/// | `APP_ENVIRONMENT` | development, staging, production | Environment de ejecución |
/// | `APP_LOG_SUBSYSTEM` | string | Subsystem identifier |
///
/// ## Ejemplo de uso:
/// ```swift
/// // Con prefijo custom
/// let envConfig = EnvironmentConfiguration.load(prefix: "MYAPP")
/// // Lee: MYAPP_LOG_LEVEL, MYAPP_LOG_ENABLED, etc.
/// ```
public struct EnvironmentConfiguration: Sendable {

    // MARK: - Properties

    /// Nivel de log global (si está configurado).
    public let logLevel: LogLevel?

    /// Si el logging está habilitado (si está configurado).
    public let isEnabled: Bool?

    /// Si incluir metadata (si está configurado).
    public let includeMetadata: Bool?

    /// Environment de ejecución (si está configurado).
    public let environment: LogConfiguration.Environment?

    /// Subsystem identifier (si está configurado).
    public let subsystem: String?

    /// Indica si se encontró alguna configuración en el environment.
    public var hasAnyConfiguration: Bool {
        logLevel != nil ||
        isEnabled != nil ||
        includeMetadata != nil ||
        environment != nil ||
        subsystem != nil
    }

    // MARK: - Loading

    /// Carga la configuración desde las variables de entorno del proceso.
    ///
    /// - Parameter prefix: Prefijo para las variables de entorno (por defecto: "APP")
    /// - Returns: Configuración con valores encontrados
    public static func load(prefix: String = "APP") -> EnvironmentConfiguration {
        load(from: ProcessInfo.processInfo.environment, prefix: prefix)
    }

    /// Carga configuración desde un diccionario específico. Útil para testing.
    ///
    /// - Parameters:
    ///   - environment: Diccionario de variables de entorno
    ///   - prefix: Prefijo para las variables de entorno (por defecto: "APP")
    /// - Returns: Configuración parseada
    public static func load(from environment: [String: String], prefix: String = "APP") -> EnvironmentConfiguration {
        return EnvironmentConfiguration(
            logLevel: parseLogLevel(from: environment["\(prefix)_LOG_LEVEL"]),
            isEnabled: parseBool(from: environment["\(prefix)_LOG_ENABLED"]),
            includeMetadata: parseBool(from: environment["\(prefix)_LOG_METADATA"]),
            environment: parseEnvironment(from: environment["\(prefix)_ENVIRONMENT"]),
            subsystem: environment["\(prefix)_LOG_SUBSYSTEM"]
        )
    }

    /// Lista todas las claves de variables de entorno soportadas.
    public static func supportedKeys(prefix: String = "APP") -> [String] {
        [
            "\(prefix)_LOG_LEVEL",
            "\(prefix)_LOG_ENABLED",
            "\(prefix)_LOG_METADATA",
            "\(prefix)_ENVIRONMENT",
            "\(prefix)_LOG_SUBSYSTEM"
        ]
    }

    // MARK: - Parsing

    private static func parseLogLevel(from string: String?) -> LogLevel? {
        guard let string = string else { return nil }
        switch string.lowercased() {
        case "debug": return .debug
        case "info": return .info
        case "warning", "warn": return .warning
        case "error": return .error
        default: return nil
        }
    }

    private static func parseBool(from string: String?) -> Bool? {
        guard let string = string else { return nil }
        switch string.lowercased() {
        case "true", "1", "yes": return true
        case "false", "0", "no": return false
        default: return nil
        }
    }

    private static func parseEnvironment(from string: String?) -> LogConfiguration.Environment? {
        guard let string = string else { return nil }
        return LogConfiguration.Environment(rawValue: string.lowercased())
    }
}

// MARK: - CustomStringConvertible

extension EnvironmentConfiguration: CustomStringConvertible {
    public var description: String {
        var parts: [String] = []
        if let level = logLevel { parts.append("level=\(level)") }
        if let enabled = isEnabled { parts.append("enabled=\(enabled)") }
        if let metadata = includeMetadata { parts.append("metadata=\(metadata)") }
        if let env = environment { parts.append("environment=\(env)") }
        if let sub = subsystem { parts.append("subsystem=\(sub)") }

        if parts.isEmpty {
            return "EnvironmentConfiguration(empty)"
        }
        return "EnvironmentConfiguration(\(parts.joined(separator: ", ")))"
    }
}
