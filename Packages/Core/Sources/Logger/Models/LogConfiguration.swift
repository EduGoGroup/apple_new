//
// LogConfiguration.swift
// Logger
//
// Created by EduGo Team on 27/01/2026.
// Copyright © 2026 EduGo. All rights reserved.
//

import Foundation
import EduFoundation

/// Configuración global del sistema de logging.
///
/// Permite controlar el comportamiento del logging a nivel global y por categoría,
/// soportando configuración basada en entorno (development/production) y ajustes
/// dinámicos en runtime.
///
/// ## Ejemplo de uso:
/// ```swift
/// let config = LogConfiguration(
///     globalLevel: .info,
///     isEnabled: true,
///     environment: .production
/// )
///
/// // Configurar nivel específico para una categoría
/// config.setLevel(.debug, for: "com.edugo.auth")
/// ```
public struct LogConfiguration: Sendable {

    // MARK: - Environment

    /// Consolidated: uses `AppEnvironment` from EduFoundation as the single source of truth.
    public typealias Environment = AppEnvironment

    // MARK: - Properties

    /// Nivel de log global (mínimo) para todas las categorías.
    ///
    /// Solo se registrarán mensajes con nivel igual o superior a este.
    public let globalLevel: LogLevel

    /// Indica si el logging está habilitado globalmente.
    ///
    /// Cuando está en `false`, no se registra ningún log independientemente
    /// del nivel configurado. Útil para testing o situaciones específicas.
    public let isEnabled: Bool

    /// Entorno de ejecución actual.
    public let environment: Environment

    /// Subsistema principal de la aplicación (reverse-domain notation).
    ///
    /// Usado como prefijo en todas las categorías y para identificar logs
    /// en herramientas del sistema (Console.app, Instruments).
    public let subsystem: String

    /// Configuraciones específicas por categoría.
    ///
    /// Permite sobrescribir el nivel global para categorías específicas.
    /// La clave es el identifier de la categoría.
    public let categoryOverrides: [String: LogLevel]

    /// Indica si se debe incluir metadata adicional (archivo, función, línea).
    ///
    /// En producción generalmente está en `false` para reducir overhead.
    public let includeMetadata: Bool

    // MARK: - Initialization

    /// Inicializa una nueva configuración de logging.
    ///
    /// - Parameters:
    ///   - globalLevel: Nivel mínimo global (por defecto: basado en entorno)
    ///   - isEnabled: Si el logging está habilitado (por defecto: `true`)
    ///   - environment: Entorno de ejecución (por defecto: detectado automáticamente)
    ///   - subsystem: Identificador del subsistema (por defecto: "com.edugo.apple")
    ///   - categoryOverrides: Configuraciones específicas por categoría (por defecto: vacío)
    ///   - includeMetadata: Si incluir metadata de origen (por defecto: basado en entorno)
    public init(
        globalLevel: LogLevel? = nil,
        isEnabled: Bool = true,
        environment: Environment? = nil,
        subsystem: String = "com.edugo.apple",
        categoryOverrides: [String: LogLevel] = [:],
        includeMetadata: Bool? = nil
    ) {
        // Detectar entorno si no se proporciona
        let detectedEnv = environment ?? Self.detectEnvironment()
        self.environment = detectedEnv

        // Usar nivel por defecto del entorno si no se proporciona
        self.globalLevel = globalLevel ?? detectedEnv.defaultLevel

        self.isEnabled = isEnabled
        self.subsystem = subsystem
        self.categoryOverrides = categoryOverrides

        // En development incluir metadata, en producción no
        self.includeMetadata = includeMetadata ?? (detectedEnv == .development)
    }

    // MARK: - Level Resolution

    /// Determina el nivel efectivo para una categoría específica.
    ///
    /// Si existe un override para la categoría, se usa ese nivel.
    /// Si no, se usa el nivel global.
    ///
    /// - Parameter category: La categoría a consultar (puede ser `nil`)
    /// - Returns: El nivel de log efectivo para esa categoría
    public func effectiveLevel(for category: LogCategory?) -> LogLevel {
        guard let category = category else {
            return globalLevel
        }

        return categoryOverrides[category.identifier] ?? globalLevel
    }

    /// Verifica si un mensaje con el nivel dado debe registrarse para una categoría.
    ///
    /// - Parameters:
    ///   - level: El nivel del mensaje
    ///   - category: La categoría del mensaje (opcional)
    /// - Returns: `true` si el mensaje debe registrarse
    public func shouldLog(level: LogLevel, for category: LogCategory?) -> Bool {
        guard isEnabled else { return false }
        return level >= effectiveLevel(for: category)
    }

    // MARK: - Environment Detection

    /// Delegates to `AppEnvironment.detect()` for consistent environment detection.
    private static func detectEnvironment() -> Environment {
        AppEnvironment.detect()
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
    ///
    /// - Parameters:
    ///   - level: El nivel a establecer
    ///   - categoryId: El identifier de la categoría
    /// - Returns: Nueva configuración con el override aplicado
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

// MARK: - AppEnvironment + Log Defaults

extension AppEnvironment {

    /// Default log level for this environment.
    public var defaultLevel: LogLevel {
        switch self {
        case .development: return .debug
        case .staging: return .info
        case .production: return .warning
        }
    }
}
