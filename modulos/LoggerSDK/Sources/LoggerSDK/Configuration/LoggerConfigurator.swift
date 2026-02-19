import Foundation

/// Configurador centralizado para gestión dinámica del sistema de logging.
///
/// Proporciona una API de alto nivel para configurar el sistema de logging,
/// leyendo configuración desde variables de entorno, aplicando cambios en runtime,
/// y propagando actualizaciones al registry global.
///
/// ## Ejemplo de uso:
/// ```swift
/// // Configuración inicial desde environment
/// await LoggerConfigurator.shared.configureFromEnvironment(prefix: "MYAPP")
///
/// // Cambiar nivel global en runtime
/// await LoggerConfigurator.shared.setGlobalLevel(.debug)
/// ```
public actor LoggerConfigurator {

    // MARK: - Singleton

    public static let shared = LoggerConfigurator()

    // MARK: - Properties

    private let registry: LoggerRegistry
    private var currentConfiguration: LogConfiguration

    // MARK: - Initialization

    init(registry: LoggerRegistry = .shared) {
        self.registry = registry
        #if DEBUG
        self.currentConfiguration = .development
        #else
        self.currentConfiguration = .production
        #endif
    }

    // MARK: - Environment Configuration

    /// Configura el logger leyendo variables de entorno.
    ///
    /// - Parameter prefix: Prefijo para variables de entorno (por defecto: "APP")
    /// - Returns: `true` si se encontró configuración en el environment
    @discardableResult
    public func configureFromEnvironment(prefix: String = "APP") async -> Bool {
        let envConfig = EnvironmentConfiguration.load(prefix: prefix)

        guard envConfig.hasAnyConfiguration else {
            return false
        }

        let config = LogConfiguration(
            globalLevel: envConfig.logLevel ?? currentConfiguration.globalLevel,
            isEnabled: envConfig.isEnabled ?? currentConfiguration.isEnabled,
            environment: envConfig.environment ?? currentConfiguration.environment,
            subsystem: envConfig.subsystem ?? currentConfiguration.subsystem,
            categoryOverrides: [:],
            includeMetadata: envConfig.includeMetadata ?? currentConfiguration.includeMetadata
        )

        await registry.configure(with: config)
        self.currentConfiguration = config

        return true
    }

    // MARK: - Runtime Configuration

    /// Establece el nivel de log global.
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
    public func setEnabled(_ enabled: Bool) async {
        let newConfig = currentConfiguration.withEnabled(enabled)
        await registry.configure(with: newConfig)
        self.currentConfiguration = newConfig
    }

    /// Habilita o deshabilita la inclusión de metadata.
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

    /// Establece un nivel específico para una categoría por identifier.
    public func setLevel(_ level: LogLevel, for categoryId: String) async {
        let dynamicCategory = DynamicLogCategory(identifier: categoryId)
        await registry.setLevel(level, for: dynamicCategory)
    }

    /// Establece un nivel específico para una categoría.
    public func setLevel(_ level: LogLevel, for category: LogCategory) async {
        await registry.setLevel(level, for: category)
    }

    /// Resetea la configuración de una categoría a los defaults globales.
    public func resetCategory(_ category: LogCategory) async {
        await registry.resetConfiguration(for: category)
    }

    // MARK: - Preset Configuration

    /// Aplica un preset de configuración.
    public func applyPreset(_ preset: LogConfigurationPreset) async {
        await registry.configure(preset: preset)

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

    func configureDevelopment() async {
        await applyPreset(.development)
    }

    func configureStaging() async {
        await applyPreset(.staging)
    }

    func configureProduction() async {
        await applyPreset(.production)
    }

    func configureTesting() async {
        await applyPreset(.testing)
    }
}
