import Foundation
import OSLog

/// Implementación concreta de `LoggerProtocol` usando `os.Logger` de Apple.
///
/// Gestiona múltiples instancias de `os.Logger` por categoría y aplica
/// configuración de niveles mínimos. Thread-safe mediante actor isolation.
///
/// ## Ejemplo de uso:
/// ```swift
/// let config = LogConfiguration(subsystem: "com.myapp.ios")
/// let logger = OSLoggerAdapter(configuration: config)
/// await logger.info("Usuario autenticado", category: AuthCategory.login)
/// ```
public actor OSLoggerAdapter: LoggerProtocol {

    // MARK: - Properties

    private let configuration: LogConfiguration
    private var loggerCache: [String: os.Logger] = [:]
    private let defaultLogger: os.Logger

    // MARK: - Initialization

    public init(configuration: LogConfiguration) {
        self.configuration = configuration
        self.defaultLogger = os.Logger(
            subsystem: configuration.subsystem,
            category: "default"
        )
    }

    public init() {
        #if DEBUG
        let config = LogConfiguration.development
        #else
        let config = LogConfiguration.production
        #endif

        self.configuration = config
        self.defaultLogger = os.Logger(
            subsystem: config.subsystem,
            category: "default"
        )
    }

    // MARK: - LoggerProtocol Implementation

    public func debug(
        _ message: String,
        category: LogCategory?,
        file: String,
        function: String,
        line: Int
    ) async {
        await log(message: message, level: .debug, category: category, file: file, function: function, line: line)
    }

    public func info(
        _ message: String,
        category: LogCategory?,
        file: String,
        function: String,
        line: Int
    ) async {
        await log(message: message, level: .info, category: category, file: file, function: function, line: line)
    }

    public func warning(
        _ message: String,
        category: LogCategory?,
        file: String,
        function: String,
        line: Int
    ) async {
        await log(message: message, level: .warning, category: category, file: file, function: function, line: line)
    }

    public func error(
        _ message: String,
        category: LogCategory?,
        file: String,
        function: String,
        line: Int
    ) async {
        await log(message: message, level: .error, category: category, file: file, function: function, line: line)
    }

    // MARK: - Private Methods

    private func log(
        message: String,
        level: LogLevel,
        category: LogCategory?,
        file: String,
        function: String,
        line: Int
    ) async {
        guard configuration.shouldLog(level: level, for: category) else {
            return
        }

        let logger = getOrCreateLogger(for: category)
        let formattedMessage = formatMessage(message, file: file, function: function, line: line)
        logToOSLogger(logger: logger, message: formattedMessage, level: level)
    }

    private func getOrCreateLogger(for category: LogCategory?) -> os.Logger {
        guard let category = category else {
            return defaultLogger
        }

        let categoryId = category.identifier

        if let cachedLogger = loggerCache[categoryId] {
            return cachedLogger
        }

        let newLogger = os.Logger(
            subsystem: configuration.subsystem,
            category: categoryId
        )
        loggerCache[categoryId] = newLogger

        return newLogger
    }

    private func formatMessage(
        _ message: String,
        file: String,
        function: String,
        line: Int
    ) -> String {
        guard configuration.includeMetadata else {
            return message
        }

        let fileName = (file as NSString).lastPathComponent
        return "[\(fileName):\(line)] \(function) - \(message)"
    }

    private func logToOSLogger(
        logger: os.Logger,
        message: String,
        level: LogLevel
    ) {
        switch level {
        case .debug:
            logger.debug("\(message)")
        case .info:
            logger.info("\(message)")
        case .warning:
            logger.notice("\(message)")
        case .error:
            logger.error("\(message)")
        }
    }
}

// MARK: - Public API Extensions

public extension OSLoggerAdapter {

    func clearCache() {
        loggerCache.removeAll()
    }

    var cachedLoggerCount: Int {
        loggerCache.count
    }
}
