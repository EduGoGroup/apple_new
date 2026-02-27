//
// LoggerConfigurator.swift
// Logger
//
// Created by EduGo Team on 27/01/2026.
// Copyright © 2026 EduGo. All rights reserved.
//

import Foundation

/// Configurador centralizado para gestión dinámica del sistema de logging.
///
/// Proporciona una API de alto nivel para configurar el sistema de logging,
/// leyendo configuración desde variables de entorno, aplicando cambios en runtime,
/// y propagando actualizaciones al registry global.
///
/// ## Variables de Entorno Soportadas:
/// - `EDUGO_LOG_LEVEL`: Nivel global (debug, info, warning, error)
/// - `EDUGO_LOG_ENABLED`: Habilitar/deshabilitar logging (true/false)
/// - `EDUGO_LOG_METADATA`: Incluir metadata de origen (true/false)
/// - `EDUGO_ENVIRONMENT`: Environment de ejecución (development, staging, production)
/// - `EDUGO_LOG_SUBSYSTEM`: Subsystem identifier (default: com.edugo.apple)
///
/// ## Ejemplo de uso:
/// ```swift
/// // Configuración inicial desde environment
/// await LoggerConfigurator.shared.configureFromEnvironment()
///
/// // Cambiar nivel global en runtime
/// await LoggerConfigurator.shared.setGlobalLevel(.debug)
///
/// // Configurar categoría específica
/// await LoggerConfigurator.shared.setLevel(.error, for: "com.edugo.network")
/// ```
public actor LoggerConfigurator {

    // MARK: - Singleton

    /// Instancia compartida del configurador.
    public static let shared = LoggerConfigurator()

    // MARK: - Properties

    /// Registry al que se aplican las configuraciones.
    private let registry: LoggerRegistry

    /// Configuración actualmente aplicada.
    private var currentConfiguration: LogConfiguration

    // MARK: - Initialization

    /// Inicializa el configurador con el registry proporcionado.
    init(registry: LoggerRegistry = .shared) {
        self.registry = registry

        // Detectar configuración inicial
        #if DEBUG
        self.currentConfiguration = .development
        #else
        self.currentConfiguration = .production
        #endif
    }

    // MARK: - Environment Configuration

    /// Configura el logger leyendo variables de entorno.
    ///
    /// Lee variables como `EDUGO_LOG_LEVEL`, `EDUGO_ENVIRONMENT`, etc.
    /// y construye una configuración apropiada.
    ///
    /// - Returns: `true` si se encontró configuración en el environment
    @discardableResult
    public func configureFromEnvironment() async -> Bool {
        let envConfig = EnvironmentConfiguration.load()

        guard envConfig.hasAnyConfiguration else {
            // No hay configuración en environment, usar defaults
            return false
        }

        // Construir configuración desde environment
        let config = LogConfiguration(
            globalLevel: envConfig.logLevel ?? currentConfiguration.globalLevel,
            isEnabled: envConfig.isEnabled ?? currentConfiguration.isEnabled,
            environment: envConfig.environment ?? currentConfiguration.environment,
            subsystem: envConfig.subsystem ?? currentConfiguration.subsystem,
            categoryOverrides: [:],
            includeMetadata: envConfig.includeMetadata ?? currentConfiguration.includeMetadata
        )

        // Aplicar al registry
        await registry.configure(with: config)
        self.currentConfiguration = config

        return true
    }

    // MARK: - Runtime Configuration

    /// Establece el nivel de log global.
    ///
    /// Cambio se aplica inmediatamente a todos los loggers.
    ///
    /// - Parameter level: El nuevo nivel global
    public func setGlobalLevel(_ level: LogLevel) async {
        let newConfig = LogConfiguration(
            globalLevel: level,
            isEnabled: currentConfiguration.isEnabled,
            environment: currentConfiguration.environment,
            subsystem: currentConfiguration.subsystem,
            categoryOverrides: currentConfiguration.categoryOverrides,
            includeMetadata: currentConfiguration.includeMetadata
        )

        await registry.configure(with: newConfig)
        self.currentConfiguration = newConfig
    }

    /// Habilita o deshabilita el logging globalmente.
    ///
    /// - Parameter enabled: `true` para habilitar, `false` para deshabilitar
    public func setEnabled(_ enabled: Bool) async {
        let newConfig = currentConfiguration.withEnabled(enabled)
        await registry.configure(with: newConfig)
        self.currentConfiguration = newConfig
    }

    /// Habilita o deshabilita la inclusión de metadata.
    ///
    /// - Parameter include: `true` para incluir metadata
    public func setIncludeMetadata(_ include: Bool) async {
        let newConfig = LogConfiguration(
            globalLevel: currentConfiguration.globalLevel,
            isEnabled: currentConfiguration.isEnabled,
            environment: currentConfiguration.environment,
            subsystem: currentConfiguration.subsystem,
            categoryOverrides: currentConfiguration.categoryOverrides,
            includeMetadata: include
        )

        await registry.configure(with: newConfig)
        self.currentConfiguration = newConfig
    }

    /// Establece un nivel específico para una categoría.
    ///
    /// - Parameters:
    ///   - level: El nivel a establecer
    ///   - categoryId: El identifier de la categoría
    public func setLevel(_ level: LogLevel, for categoryId: String) async {
        // Crear categoría dinámica para el identifier proporcionado
        let dynamicCategory = DynamicLogCategory(identifier: categoryId)
        await registry.setLevel(level, for: dynamicCategory)
    }

    /// Establece un nivel específico para una categoría.
    ///
    /// - Parameters:
    ///   - level: El nivel a establecer
    ///   - category: La categoría
    public func setLevel(_ level: LogLevel, for category: LogCategory) async {
        await registry.setLevel(level, for: category)
    }

    /// Resetea la configuración de una categoría a los defaults globales.
    ///
    /// - Parameter category: La categoría a resetear
    public func resetCategory(_ category: LogCategory) async {
        await registry.resetConfiguration(for: category)
    }

    // MARK: - Preset Configuration

    /// Aplica un preset de configuración.
    ///
    /// - Parameter preset: El preset a aplicar
    public func applyPreset(_ preset: LogConfigurationPreset) async {
        await registry.configure(preset: preset)

        // Actualizar configuración actual
        switch preset {
        case .development:
            self.currentConfiguration = .development
        case .staging:
            self.currentConfiguration = .staging
        case .production:
            self.currentConfiguration = .production
        case .testing:
            self.currentConfiguration = .testing
        }
    }

    // MARK: - Query

    /// Obtiene la configuración actual.
    public var configuration: LogConfiguration {
        currentConfiguration
    }

    /// Obtiene el nivel global actual.
    public var globalLevel: LogLevel {
        currentConfiguration.globalLevel
    }

    /// Indica si el logging está habilitado.
    public var isEnabled: Bool {
        currentConfiguration.isEnabled
    }

    /// Obtiene el environment actual.
    public var environment: LogConfiguration.Environment {
        currentConfiguration.environment
    }
}

// MARK: - Convenience Extensions

public extension LoggerConfigurator {

    /// Configuración rápida para development.
    func configureDevelopment() async {
        await applyPreset(.development)
    }

    /// Configuración rápida para staging.
    func configureStaging() async {
        await applyPreset(.staging)
    }

    /// Configuración rápida para production.
    func configureProduction() async {
        await applyPreset(.production)
    }

    /// Configuración rápida para testing.
    func configureTesting() async {
        await applyPreset(.testing)
    }
}
