//
// LoggerRegistry.swift
// Logger
//
// Created by EduGo Team on 27/01/2026.
// Copyright © 2026 EduGo. All rights reserved.
//

import Foundation

/// Registry centralizado para gestionar instancias de logger por categoría.
///
/// Actúa como punto único de acceso al sistema de logging, gestionando la configuración
/// global, overrides por categoría, y el ciclo de vida de las instancias de logger.
/// Implementado como actor para garantizar thread-safety.
///
/// ## Características:
/// - Singleton pattern para acceso global
/// - Configuración global con overrides por categoría
/// - Lazy loading de loggers
/// - Validación de duplicados
/// - Thread-safe mediante actor isolation
///
/// ## Ejemplo de uso:
/// ```swift
/// // Configurar el registry al inicio de la app
/// await LoggerRegistry.shared.configure(with: .production)
///
/// // Obtener logger para una categoría
/// let authLogger = await LoggerRegistry.shared.logger(for: AuthCategory.login)
///
/// // Registrar categorías predefinidas
/// await LoggerRegistry.shared.register(category: AuthCategory.login, level: .debug)
/// ```
public actor LoggerRegistry {

    // MARK: - Singleton

    /// Instancia compartida del registry.
    public static let shared = LoggerRegistry()

    // MARK: - Properties

    /// Configuración global del sistema de logging.
    private var globalConfiguration: LogConfiguration

    /// Cache de loggers por categoría.
    /// Key: category identifier, Value: logger instance
    private var loggerCache: [String: OSLoggerAdapter] = [:]

    /// Registro de categorías conocidas.
    /// Permite validar y evitar duplicados.
    private var registeredCategories: Set<String> = []

    /// Overrides de configuración por categoría.
    /// Permite configuración específica que sobrescribe la global.
    private var categoryConfigurations: [String: LogConfiguration] = [:]

    // MARK: - Initialization

    /// Inicializa el registry con configuración por defecto.
    init() {
        #if DEBUG
        self.globalConfiguration = .development
        #else
        self.globalConfiguration = .production
        #endif
    }

    // MARK: - Configuration

    /// Configura el registry con una configuración global.
    ///
    /// Esta configuración se aplicará a todos los loggers a menos que exista
    /// un override específico para la categoría.
    ///
    /// - Parameter configuration: La configuración global a aplicar
    public func configure(with configuration: LogConfiguration) {
        self.globalConfiguration = configuration

        // Limpiar cache para forzar recreación con nueva configuración
        loggerCache.removeAll()
    }

    /// Obtiene la configuración global actual.
    ///
    /// - Returns: La configuración global
    public var configuration: LogConfiguration {
        globalConfiguration
    }

    /// Establece un override de configuración para una categoría específica.
    ///
    /// - Parameters:
    ///   - configuration: La configuración a aplicar
    ///   - category: La categoría a configurar
    public func setConfiguration(_ configuration: LogConfiguration, for category: LogCategory) {
        categoryConfigurations[category.identifier] = configuration

        // Remover del cache para forzar recreación con nueva configuración
        loggerCache.removeValue(forKey: category.identifier)
    }

    /// Establece un override de nivel para una categoría específica.
    ///
    /// Convenience method que crea una nueva configuración basada en la global
    /// con el nivel sobrescrito.
    ///
    /// - Parameters:
    ///   - level: El nivel a establecer
    ///   - category: La categoría a configurar
    public func setLevel(_ level: LogLevel, for category: LogCategory) {
        let newConfig = globalConfiguration.withOverride(
            level: level,
            for: category.identifier
        )
        setConfiguration(newConfig, for: category)
    }

    /// Remueve el override de configuración para una categoría.
    ///
    /// La categoría volverá a usar la configuración global.
    ///
    /// - Parameter category: La categoría a resetear
    public func resetConfiguration(for category: LogCategory) {
        categoryConfigurations.removeValue(forKey: category.identifier)
        loggerCache.removeValue(forKey: category.identifier)
    }

    // MARK: - Category Management

    /// Registra una categoría en el registry.
    ///
    /// Permite validar que las categorías son conocidas y evitar typos.
    /// Es opcional registrar categorías, pero recomendado para validación.
    ///
    /// - Parameter category: La categoría a registrar
    /// - Returns: `true` si se registró exitosamente, `false` si ya existía
    @discardableResult
    public func register(category: LogCategory) -> Bool {
        let wasInserted = registeredCategories.insert(category.identifier).inserted
        return wasInserted
    }

    /// Registra múltiples categorías.
    ///
    /// - Parameter categories: Array de categorías a registrar
    /// - Returns: Número de categorías nuevas registradas
    @discardableResult
    public func register(categories: [LogCategory]) -> Int {
        var count = 0
        for category in categories {
            if register(category: category) {
                count += 1
            }
        }
        return count
    }

    /// Verifica si una categoría está registrada.
    ///
    /// - Parameter category: La categoría a verificar
    /// - Returns: `true` si la categoría está registrada
    public func isRegistered(category: LogCategory) -> Bool {
        registeredCategories.contains(category.identifier)
    }

    /// Obtiene todas las categorías registradas.
    ///
    /// - Returns: Set con los identifiers de categorías registradas
    public var allRegisteredCategories: Set<String> {
        registeredCategories
    }

    // MARK: - Logger Factory

    /// Obtiene o crea un logger para una categoría específica.
    ///
    /// Si el logger ya existe en cache, lo retorna. Si no, crea uno nuevo
    /// con la configuración apropiada (override o global).
    ///
    /// - Parameter category: La categoría del logger (opcional)
    /// - Returns: Instancia de OSLoggerAdapter configurada
    public func logger(for category: LogCategory? = nil) -> OSLoggerAdapter {
        guard let category = category else {
            // Retornar logger con configuración global
            return OSLoggerAdapter(configuration: globalConfiguration)
        }

        let categoryId = category.identifier

        // Retornar del cache si existe
        if let cachedLogger = loggerCache[categoryId] {
            return cachedLogger
        }

        // Determinar configuración a usar
        let config = categoryConfigurations[categoryId] ?? globalConfiguration

        // Crear nuevo logger
        let newLogger = OSLoggerAdapter(configuration: config)

        // Guardar en cache
        loggerCache[categoryId] = newLogger

        return newLogger
    }

    /// Obtiene un logger para una categoría especificada por string.
    ///
    /// Útil cuando se trabaja con categorías dinámicas.
    ///
    /// - Parameter categoryId: El identifier de la categoría
    /// - Returns: Instancia de OSLoggerAdapter configurada
    public func logger(forCategoryId categoryId: String) -> OSLoggerAdapter {
        // Buscar en cache
        if let cachedLogger = loggerCache[categoryId] {
            return cachedLogger
        }

        // Determinar configuración
        let config = categoryConfigurations[categoryId] ?? globalConfiguration

        // Crear y cachear
        let newLogger = OSLoggerAdapter(configuration: config)
        loggerCache[categoryId] = newLogger

        return newLogger
    }

    // MARK: - Cache Management

    /// Limpia el cache de loggers.
    ///
    /// Útil para forzar recreación después de cambios de configuración.
    public func clearCache() {
        loggerCache.removeAll()
    }

    /// Limpia el cache para una categoría específica.
    ///
    /// - Parameter category: La categoría a limpiar del cache
    public func clearCache(for category: LogCategory) {
        loggerCache.removeValue(forKey: category.identifier)
    }

    /// Número de loggers actualmente en cache.
    public var cachedLoggerCount: Int {
        loggerCache.count
    }

    /// Número de categorías registradas.
    public var registeredCategoryCount: Int {
        registeredCategories.count
    }

    // MARK: - Bulk Operations

    /// Registra todas las categorías predefinidas del sistema.
    ///
    /// Convenience method para registrar todas las categorías de `SystemLogCategory`.
    @discardableResult
    public func registerSystemCategories() -> Int {
        let categories: [LogCategory] = [
            SystemLogCategory.commonError,
            SystemLogCategory.commonDomain,
            SystemLogCategory.commonRepository,
            SystemLogCategory.commonUseCase,
            SystemLogCategory.logger,
            SystemLogCategory.loggerRegistry,
            SystemLogCategory.loggerConfig,
            SystemLogCategory.system,
            SystemLogCategory.performance,
            SystemLogCategory.network,
            SystemLogCategory.database
        ]
        return register(categories: categories)
    }

    /// Resetea completamente el registry a estado inicial.
    ///
    /// Limpia cache, categorías registradas y overrides de configuración.
    /// Mantiene la configuración global.
    public func reset() {
        loggerCache.removeAll()
        registeredCategories.removeAll()
        categoryConfigurations.removeAll()
    }
}

// MARK: - Convenience Methods

public extension LoggerRegistry {

    /// Configura el registry con un preset.
    ///
    /// - Parameter preset: El preset a aplicar (.development, .staging, .production, .testing)
    func configure(preset: LogConfigurationPreset) {
        switch preset {
        case .development:
            configure(with: .development)
        case .staging:
            configure(with: .staging)
        case .production:
            configure(with: .production)
        case .testing:
            configure(with: .testing)
        }
    }
}

// MARK: - Configuration Presets

/// Presets de configuración para el registry.
public enum LogConfigurationPreset: Sendable {
    case development
    case staging
    case production
    case testing
}
