import Foundation

/// Registry centralizado para gestionar instancias de logger por categoría.
///
/// Actúa como punto único de acceso al sistema de logging, gestionando la configuración
/// global, overrides por categoría, y el ciclo de vida de las instancias de logger.
public actor LoggerRegistry {

    // MARK: - Singleton

    public static let shared = LoggerRegistry()

    // MARK: - Properties

    private var globalConfiguration: LogConfiguration
    private var loggerCache: [String: OSLoggerAdapter] = [:]
    private var registeredCategories: Set<String> = []
    private var categoryConfigurations: [String: LogConfiguration] = [:]

    // MARK: - Initialization

    init() {
        #if DEBUG
        self.globalConfiguration = .development
        #else
        self.globalConfiguration = .production
        #endif
    }

    // MARK: - Configuration

    public func configure(with configuration: LogConfiguration) {
        self.globalConfiguration = configuration
        loggerCache.removeAll()
    }

    public var configuration: LogConfiguration {
        globalConfiguration
    }

    public func setConfiguration(_ configuration: LogConfiguration, for category: LogCategory) {
        categoryConfigurations[category.identifier] = configuration
        loggerCache.removeValue(forKey: category.identifier)
    }

    public func setLevel(_ level: LogLevel, for category: LogCategory) {
        let newConfig = globalConfiguration.withOverride(level: level, for: category.identifier)
        setConfiguration(newConfig, for: category)
    }

    public func resetConfiguration(for category: LogCategory) {
        categoryConfigurations.removeValue(forKey: category.identifier)
        loggerCache.removeValue(forKey: category.identifier)
    }

    // MARK: - Category Management

    @discardableResult
    public func register(category: LogCategory) -> Bool {
        registeredCategories.insert(category.identifier).inserted
    }

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

    public func isRegistered(category: LogCategory) -> Bool {
        registeredCategories.contains(category.identifier)
    }

    public var allRegisteredCategories: Set<String> {
        registeredCategories
    }

    // MARK: - Logger Factory

    public func logger(for category: LogCategory? = nil) -> OSLoggerAdapter {
        guard let category = category else {
            return OSLoggerAdapter(configuration: globalConfiguration)
        }

        let categoryId = category.identifier

        if let cachedLogger = loggerCache[categoryId] {
            return cachedLogger
        }

        let config = categoryConfigurations[categoryId] ?? globalConfiguration
        let newLogger = OSLoggerAdapter(configuration: config)
        loggerCache[categoryId] = newLogger

        return newLogger
    }

    public func logger(forCategoryId categoryId: String) -> OSLoggerAdapter {
        if let cachedLogger = loggerCache[categoryId] {
            return cachedLogger
        }

        let config = categoryConfigurations[categoryId] ?? globalConfiguration
        let newLogger = OSLoggerAdapter(configuration: config)
        loggerCache[categoryId] = newLogger

        return newLogger
    }

    // MARK: - Cache Management

    public func clearCache() {
        loggerCache.removeAll()
    }

    public func clearCache(for category: LogCategory) {
        loggerCache.removeValue(forKey: category.identifier)
    }

    public var cachedLoggerCount: Int {
        loggerCache.count
    }

    public var registeredCategoryCount: Int {
        registeredCategories.count
    }

    /// Resetea completamente el registry a estado inicial.
    public func reset() {
        loggerCache.removeAll()
        registeredCategories.removeAll()
        categoryConfigurations.removeAll()
    }
}

// MARK: - Convenience Methods

public extension LoggerRegistry {

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

public enum LogConfigurationPreset: Sendable {
    case development
    case staging
    case production
    case testing
}
