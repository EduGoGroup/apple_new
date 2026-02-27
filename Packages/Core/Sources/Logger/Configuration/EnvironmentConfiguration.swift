//
// EnvironmentConfiguration.swift
// Logger
//
// Created by EduGo Team on 27/01/2026.
// Copyright © 2026 EduGo. All rights reserved.
//

import Foundation

/// Configuración del logger basada en variables de entorno.
///
/// Lee y parsea variables de entorno del sistema para configurar el logging.
/// Todas las propiedades son opcionales - si no están presentes en el environment,
/// retornan `nil` y se usan los defaults.
///
/// ## Variables Soportadas:
///
/// | Variable | Valores | Default | Descripción |
/// |----------|---------|---------|-------------|
/// | `EDUGO_LOG_LEVEL` | debug, info, warning, error | según environment | Nivel mínimo global |
/// | `EDUGO_LOG_ENABLED` | true, false, 1, 0 | true | Habilitar/deshabilitar logging |
/// | `EDUGO_LOG_METADATA` | true, false, 1, 0 | según environment | Incluir metadata de origen |
/// | `EDUGO_ENVIRONMENT` | development, staging, production | según build | Environment de ejecución |
/// | `EDUGO_LOG_SUBSYSTEM` | string | com.edugo.apple | Subsystem identifier |
///
/// ## Ejemplo de uso:
/// ```swift
/// // Leer configuración
/// let envConfig = EnvironmentConfiguration.load()
///
/// if let level = envConfig.logLevel {
///     print("Log level from environment: \(level)")
/// }
///
/// // Verificar si hay configuración
/// if envConfig.hasAnyConfiguration {
///     print("Found environment configuration")
/// }
/// ```
public struct EnvironmentConfiguration: Sendable {

    // MARK: - Environment Variable Keys

    /// Claves de variables de entorno soportadas.
    public enum Key: String, CaseIterable {
        case logLevel = "EDUGO_LOG_LEVEL"
        case enabled = "EDUGO_LOG_ENABLED"
        case metadata = "EDUGO_LOG_METADATA"
        case environment = "EDUGO_ENVIRONMENT"
        case subsystem = "EDUGO_LOG_SUBSYSTEM"
    }

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
    /// - Returns: Configuración con valores encontrados (propiedades nil si no existen)
    public static func load() -> EnvironmentConfiguration {
        let processInfo = ProcessInfo.processInfo

        return EnvironmentConfiguration(
            logLevel: parseLogLevel(from: processInfo.environment[Key.logLevel.rawValue]),
            isEnabled: parseBool(from: processInfo.environment[Key.enabled.rawValue]),
            includeMetadata: parseBool(from: processInfo.environment[Key.metadata.rawValue]),
            environment: parseEnvironment(from: processInfo.environment[Key.environment.rawValue]),
            subsystem: processInfo.environment[Key.subsystem.rawValue]
        )
    }

    /// Carga configuración desde un diccionario específico.
    ///
    /// Útil para testing.
    ///
    /// - Parameter environment: Diccionario de variables de entorno
    /// - Returns: Configuración parseada
    public static func load(from environment: [String: String]) -> EnvironmentConfiguration {
        return EnvironmentConfiguration(
            logLevel: parseLogLevel(from: environment[Key.logLevel.rawValue]),
            isEnabled: parseBool(from: environment[Key.enabled.rawValue]),
            includeMetadata: parseBool(from: environment[Key.metadata.rawValue]),
            environment: parseEnvironment(from: environment[Key.environment.rawValue]),
            subsystem: environment[Key.subsystem.rawValue]
        )
    }

    // MARK: - Parsing

    /// Parsea un LogLevel desde string.
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

    /// Parsea un booleano desde string.
    ///
    /// Acepta: "true", "false", "1", "0", "yes", "no"
    private static func parseBool(from string: String?) -> Bool? {
        guard let string = string else { return nil }

        switch string.lowercased() {
        case "true", "1", "yes": return true
        case "false", "0", "no": return false
        default: return nil
        }
    }

    /// Parsea un Environment desde string.
    private static func parseEnvironment(from string: String?) -> LogConfiguration.Environment? {
        guard let string = string else { return nil }
        return LogConfiguration.Environment(rawValue: string.lowercased())
    }
}

// MARK: - Documentation Extensions

public extension EnvironmentConfiguration {

    /// Genera documentación de las variables de entorno soportadas.
    ///
    /// Útil para generar documentación o help text.
    ///
    /// - Returns: String con documentación formateada
    static func documentation() -> String {
        """
        EduGo Logger Environment Variables
        ===================================

        The logging system can be configured via environment variables:

        EDUGO_LOG_LEVEL
            Sets the minimum global log level.
            Values: debug, info, warning, error
            Default: debug (DEBUG build) / warning (RELEASE build)
            Example: EDUGO_LOG_LEVEL=debug

        EDUGO_LOG_ENABLED
            Enables or disables logging globally.
            Values: true, false, 1, 0, yes, no
            Default: true
            Example: EDUGO_LOG_ENABLED=false

        EDUGO_LOG_METADATA
            Include source location metadata (file, function, line).
            Values: true, false, 1, 0, yes, no
            Default: true (DEBUG) / false (RELEASE)
            Example: EDUGO_LOG_METADATA=true

        EDUGO_ENVIRONMENT
            Execution environment.
            Values: development, staging, production
            Default: development (DEBUG) / production (RELEASE)
            Example: EDUGO_ENVIRONMENT=staging

        EDUGO_LOG_SUBSYSTEM
            Subsystem identifier for os.Logger.
            Values: any string
            Default: com.edugo.apple
            Example: EDUGO_LOG_SUBSYSTEM=com.myapp.custom

        Usage Example:
        ==============

        export EDUGO_LOG_LEVEL=debug
        export EDUGO_LOG_ENABLED=true
        export EDUGO_ENVIRONMENT=development
        ./MyApp

        Or in Xcode scheme:
        Edit Scheme → Run → Arguments → Environment Variables
        """
    }

    /// Lista todas las claves de variables de entorno soportadas.
    ///
    /// - Returns: Array de nombres de variables
    static func supportedKeys() -> [String] {
        Key.allCases.map { $0.rawValue }
    }
}

// MARK: - CustomStringConvertible

extension EnvironmentConfiguration: CustomStringConvertible {
    public var description: String {
        var parts: [String] = []

        if let level = logLevel {
            parts.append("level=\(level)")
        }
        if let enabled = isEnabled {
            parts.append("enabled=\(enabled)")
        }
        if let metadata = includeMetadata {
            parts.append("metadata=\(metadata)")
        }
        if let env = environment {
            parts.append("environment=\(env)")
        }
        if let sub = subsystem {
            parts.append("subsystem=\(sub)")
        }

        if parts.isEmpty {
            return "EnvironmentConfiguration(empty)"
        }

        return "EnvironmentConfiguration(\(parts.joined(separator: ", ")))"
    }
}
