//
// OSLoggerFactory.swift
// Logger
//
// Created by EduGo Team on 27/01/2026.
// Copyright © 2026 EduGo. All rights reserved.
//

import Foundation

/// Factory para crear instancias de OSLoggerAdapter con configuraciones predefinidas.
///
/// Proporciona convenience methods para crear loggers configurados según diferentes
/// escenarios de uso (development, production, testing, etc.), eliminando la
/// necesidad de configurar manualmente cada instancia.
///
/// ## Ejemplo de uso:
/// ```swift
/// // Logger para desarrollo
/// let devLogger = OSLoggerFactory.development()
///
/// // Logger para producción con override específico
/// let prodLogger = OSLoggerFactory.production(
///     categoryOverrides: ["com.edugo.auth": .debug]
/// )
///
/// // Logger custom
/// let customLogger = OSLoggerFactory.custom(
///     globalLevel: .info,
///     subsystem: "com.myapp.custom"
/// )
/// ```
public enum OSLoggerFactory {

    // MARK: - Preset Factories

    /// Crea un logger configurado para desarrollo.
    ///
    /// - Nivel global: `.debug`
    /// - Metadata: Habilitado
    /// - Environment: `.development`
    ///
    /// - Parameters:
    ///   - categoryOverrides: Overrides opcionales por categoría
    /// - Returns: Logger configurado para desarrollo
    public static func development(
        categoryOverrides: [String: LogLevel] = [:]
    ) -> OSLoggerAdapter {
        let config = LogConfiguration(
            globalLevel: .debug,
            environment: .development,
            categoryOverrides: categoryOverrides,
            includeMetadata: true
        )
        return OSLoggerAdapter(configuration: config)
    }

    /// Crea un logger configurado para staging.
    ///
    /// - Nivel global: `.info`
    /// - Metadata: Habilitado
    /// - Environment: `.staging`
    ///
    /// - Parameters:
    ///   - categoryOverrides: Overrides opcionales por categoría
    /// - Returns: Logger configurado para staging
    public static func staging(
        categoryOverrides: [String: LogLevel] = [:]
    ) -> OSLoggerAdapter {
        let config = LogConfiguration(
            globalLevel: .info,
            environment: .staging,
            categoryOverrides: categoryOverrides,
            includeMetadata: true
        )
        return OSLoggerAdapter(configuration: config)
    }

    /// Crea un logger configurado para producción.
    ///
    /// - Nivel global: `.warning`
    /// - Metadata: Deshabilitado (performance)
    /// - Environment: `.production`
    ///
    /// - Parameters:
    ///   - categoryOverrides: Overrides opcionales por categoría
    /// - Returns: Logger configurado para producción
    public static func production(
        categoryOverrides: [String: LogLevel] = [:]
    ) -> OSLoggerAdapter {
        let config = LogConfiguration(
            globalLevel: .warning,
            environment: .production,
            categoryOverrides: categoryOverrides,
            includeMetadata: false
        )
        return OSLoggerAdapter(configuration: config)
    }

    /// Crea un logger configurado para testing.
    ///
    /// - Nivel global: `.error`
    /// - Logging: Deshabilitado
    /// - Metadata: Deshabilitado
    ///
    /// Útil para tests unitarios donde se quiere silenciar logging.
    ///
    /// - Returns: Logger configurado para testing (silenciado)
    public static func testing() -> OSLoggerAdapter {
        let config = LogConfiguration(
            globalLevel: .error,
            isEnabled: false,
            environment: .development,
            includeMetadata: false
        )
        return OSLoggerAdapter(configuration: config)
    }

    // MARK: - Custom Factories

    /// Crea un logger con configuración personalizada.
    ///
    /// - Parameters:
    ///   - globalLevel: Nivel mínimo global
    ///   - isEnabled: Si el logging está habilitado
    ///   - environment: Entorno de ejecución
    ///   - subsystem: Identificador del subsistema
    ///   - categoryOverrides: Overrides por categoría
    ///   - includeMetadata: Si incluir metadata de origen
    /// - Returns: Logger configurado según parámetros
    public static func custom(
        globalLevel: LogLevel,
        isEnabled: Bool = true,
        environment: LogConfiguration.Environment = .development,
        subsystem: String = "com.edugo.apple",
        categoryOverrides: [String: LogLevel] = [:],
        includeMetadata: Bool = true
    ) -> OSLoggerAdapter {
        let config = LogConfiguration(
            globalLevel: globalLevel,
            isEnabled: isEnabled,
            environment: environment,
            subsystem: subsystem,
            categoryOverrides: categoryOverrides,
            includeMetadata: includeMetadata
        )
        return OSLoggerAdapter(configuration: config)
    }

    /// Crea un logger basado en la configuración detectada automáticamente.
    ///
    /// Usa `#if DEBUG` para determinar si crear logger de desarrollo o producción.
    ///
    /// - Returns: Logger configurado automáticamente
    public static func automatic() -> OSLoggerAdapter {
        #if DEBUG
        return development()
        #else
        return production()
        #endif
    }

    // MARK: - Builder Pattern

    /// Builder para crear loggers con configuración fluida.
    ///
    /// Permite construir configuraciones complejas de forma legible.
    ///
    /// ## Ejemplo de uso:
    /// ```swift
    /// let logger = OSLoggerFactory.builder()
    ///     .globalLevel(.info)
    ///     .environment(.production)
    ///     .override(level: .debug, for: "com.edugo.auth")
    ///     .override(level: .error, for: "com.edugo.network")
    ///     .includeMetadata(false)
    ///     .build()
    /// ```
    public static func builder() -> LoggerBuilder {
        LoggerBuilder()
    }
}

// MARK: - Logger Builder

/// Builder pattern inmutable para crear loggers con configuración fluida.
///
/// Este builder es `Sendable` porque es inmutable: cada método de configuración
/// retorna una nueva instancia del builder en lugar de mutar el estado interno.
/// Esto garantiza thread-safety sin necesidad de `@unchecked Sendable`.
///
/// ## Thread Safety
/// El builder puede ser compartido de forma segura entre threads porque:
/// - Todas las propiedades son `let` (inmutables)
/// - Cada método retorna una nueva instancia
/// - No hay estado compartido mutable
///
/// ## Ejemplo de uso:
/// ```swift
/// let logger = OSLoggerFactory.builder()
///     .globalLevel(.info)
///     .environment(.production)
///     .override(level: .debug, for: "com.edugo.auth")
///     .build()
/// ```
public struct LoggerBuilder: Sendable {

    private let globalLevel: LogLevel
    private let isEnabled: Bool
    private let environment: LogConfiguration.Environment
    private let subsystem: String
    private let categoryOverrides: [String: LogLevel]
    private let includeMetadata: Bool

    /// Crea un nuevo builder con configuración por defecto.
    public init() {
        self.globalLevel = .info
        self.isEnabled = true
        self.environment = .development
        self.subsystem = "com.edugo.apple"
        self.categoryOverrides = [:]
        self.includeMetadata = true
    }

    /// Inicializador interno para crear nuevas instancias con configuración específica.
    private init(
        globalLevel: LogLevel,
        isEnabled: Bool,
        environment: LogConfiguration.Environment,
        subsystem: String,
        categoryOverrides: [String: LogLevel],
        includeMetadata: Bool
    ) {
        self.globalLevel = globalLevel
        self.isEnabled = isEnabled
        self.environment = environment
        self.subsystem = subsystem
        self.categoryOverrides = categoryOverrides
        self.includeMetadata = includeMetadata
    }

    /// Establece el nivel global mínimo.
    ///
    /// - Parameter level: El nivel mínimo de logging
    /// - Returns: Una nueva instancia del builder con el nivel configurado
    public func globalLevel(_ level: LogLevel) -> LoggerBuilder {
        LoggerBuilder(
            globalLevel: level,
            isEnabled: self.isEnabled,
            environment: self.environment,
            subsystem: self.subsystem,
            categoryOverrides: self.categoryOverrides,
            includeMetadata: self.includeMetadata
        )
    }

    /// Habilita o deshabilita el logging.
    ///
    /// - Parameter isEnabled: `true` para habilitar, `false` para deshabilitar
    /// - Returns: Una nueva instancia del builder con la configuración actualizada
    public func enabled(_ isEnabled: Bool) -> LoggerBuilder {
        LoggerBuilder(
            globalLevel: self.globalLevel,
            isEnabled: isEnabled,
            environment: self.environment,
            subsystem: self.subsystem,
            categoryOverrides: self.categoryOverrides,
            includeMetadata: self.includeMetadata
        )
    }

    /// Establece el entorno de ejecución.
    ///
    /// - Parameter env: El entorno (development, staging, production)
    /// - Returns: Una nueva instancia del builder con el entorno configurado
    public func environment(_ env: LogConfiguration.Environment) -> LoggerBuilder {
        LoggerBuilder(
            globalLevel: self.globalLevel,
            isEnabled: self.isEnabled,
            environment: env,
            subsystem: self.subsystem,
            categoryOverrides: self.categoryOverrides,
            includeMetadata: self.includeMetadata
        )
    }

    /// Establece el subsistema.
    ///
    /// - Parameter subsystem: Identificador del subsistema (ej: "com.edugo.apple")
    /// - Returns: Una nueva instancia del builder con el subsistema configurado
    public func subsystem(_ subsystem: String) -> LoggerBuilder {
        LoggerBuilder(
            globalLevel: self.globalLevel,
            isEnabled: self.isEnabled,
            environment: self.environment,
            subsystem: subsystem,
            categoryOverrides: self.categoryOverrides,
            includeMetadata: self.includeMetadata
        )
    }

    /// Añade un override de nivel para una categoría específica por su identifier.
    ///
    /// - Parameters:
    ///   - level: El nivel a establecer para esta categoría
    ///   - categoryId: El identifier de la categoría
    /// - Returns: Una nueva instancia del builder con el override añadido
    public func override(level: LogLevel, for categoryId: String) -> LoggerBuilder {
        var newOverrides = self.categoryOverrides
        newOverrides[categoryId] = level
        return LoggerBuilder(
            globalLevel: self.globalLevel,
            isEnabled: self.isEnabled,
            environment: self.environment,
            subsystem: self.subsystem,
            categoryOverrides: newOverrides,
            includeMetadata: self.includeMetadata
        )
    }

    /// Añade un override de nivel para una categoría específica.
    ///
    /// - Parameters:
    ///   - level: El nivel a establecer para esta categoría
    ///   - category: La categoría (debe conformar a `LogCategory`)
    /// - Returns: Una nueva instancia del builder con el override añadido
    public func override(level: LogLevel, for category: LogCategory) -> LoggerBuilder {
        override(level: level, for: category.identifier)
    }

    /// Habilita o deshabilita la inclusión de metadata.
    ///
    /// - Parameter include: `true` para incluir metadata, `false` para omitirla
    /// - Returns: Una nueva instancia del builder con la configuración actualizada
    public func includeMetadata(_ include: Bool) -> LoggerBuilder {
        LoggerBuilder(
            globalLevel: self.globalLevel,
            isEnabled: self.isEnabled,
            environment: self.environment,
            subsystem: self.subsystem,
            categoryOverrides: self.categoryOverrides,
            includeMetadata: include
        )
    }

    /// Construye el logger con la configuración establecida.
    ///
    /// - Returns: Un `OSLoggerAdapter` configurado según los parámetros del builder
    public func build() -> OSLoggerAdapter {
        let config = LogConfiguration(
            globalLevel: globalLevel,
            isEnabled: isEnabled,
            environment: environment,
            subsystem: subsystem,
            categoryOverrides: categoryOverrides,
            includeMetadata: includeMetadata
        )
        return OSLoggerAdapter(configuration: config)
    }
}
