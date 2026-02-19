import Foundation

/// Factory para crear instancias de OSLoggerAdapter con configuraciones predefinidas.
///
/// ## Ejemplo de uso:
/// ```swift
/// let devLogger = OSLoggerFactory.development()
///
/// let customLogger = OSLoggerFactory.custom(
///     globalLevel: .info,
///     subsystem: "com.myapp.custom"
/// )
///
/// let logger = OSLoggerFactory.builder()
///     .globalLevel(.info)
///     .subsystem("com.myapp.ios")
///     .override(level: .debug, for: "com.myapp.auth")
///     .build()
/// ```
public enum OSLoggerFactory {

    // MARK: - Preset Factories

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

    public static func custom(
        globalLevel: LogLevel,
        isEnabled: Bool = true,
        environment: LogConfiguration.Environment = .development,
        subsystem: String = "com.app.default",
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

    public static func automatic() -> OSLoggerAdapter {
        #if DEBUG
        return development()
        #else
        return production()
        #endif
    }

    // MARK: - Builder Pattern

    public static func builder() -> LoggerBuilder {
        LoggerBuilder()
    }
}

// MARK: - Logger Builder

/// Builder pattern inmutable para crear loggers con configuración fluida.
/// Sendable porque es inmutable: cada método retorna una nueva instancia.
public struct LoggerBuilder: Sendable {

    private let globalLevel: LogLevel
    private let isEnabled: Bool
    private let environment: LogConfiguration.Environment
    private let subsystem: String
    private let categoryOverrides: [String: LogLevel]
    private let includeMetadata: Bool

    public init() {
        self.globalLevel = .info
        self.isEnabled = true
        self.environment = .development
        self.subsystem = "com.app.default"
        self.categoryOverrides = [:]
        self.includeMetadata = true
    }

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

    public func globalLevel(_ level: LogLevel) -> LoggerBuilder {
        LoggerBuilder(globalLevel: level, isEnabled: isEnabled, environment: environment, subsystem: subsystem, categoryOverrides: categoryOverrides, includeMetadata: includeMetadata)
    }

    public func enabled(_ isEnabled: Bool) -> LoggerBuilder {
        LoggerBuilder(globalLevel: globalLevel, isEnabled: isEnabled, environment: environment, subsystem: subsystem, categoryOverrides: categoryOverrides, includeMetadata: includeMetadata)
    }

    public func environment(_ env: LogConfiguration.Environment) -> LoggerBuilder {
        LoggerBuilder(globalLevel: globalLevel, isEnabled: isEnabled, environment: env, subsystem: subsystem, categoryOverrides: categoryOverrides, includeMetadata: includeMetadata)
    }

    public func subsystem(_ subsystem: String) -> LoggerBuilder {
        LoggerBuilder(globalLevel: globalLevel, isEnabled: isEnabled, environment: environment, subsystem: subsystem, categoryOverrides: categoryOverrides, includeMetadata: includeMetadata)
    }

    public func override(level: LogLevel, for categoryId: String) -> LoggerBuilder {
        var newOverrides = categoryOverrides
        newOverrides[categoryId] = level
        return LoggerBuilder(globalLevel: globalLevel, isEnabled: isEnabled, environment: environment, subsystem: subsystem, categoryOverrides: newOverrides, includeMetadata: includeMetadata)
    }

    public func override(level: LogLevel, for category: LogCategory) -> LoggerBuilder {
        override(level: level, for: category.identifier)
    }

    public func includeMetadata(_ include: Bool) -> LoggerBuilder {
        LoggerBuilder(globalLevel: globalLevel, isEnabled: isEnabled, environment: environment, subsystem: subsystem, categoryOverrides: categoryOverrides, includeMetadata: include)
    }

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
