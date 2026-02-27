//
// OSLoggerAdapter.swift
// Logger
//
// Created by EduGo Team on 27/01/2026.
// Copyright © 2026 EduGo. All rights reserved.
//

import Foundation
import OSLog

/// Implementación concreta de `LoggerProtocol` usando `os.Logger` de Apple.
///
/// Este adapter envuelve el sistema de logging unificado de Apple, proporcionando
/// una interfaz consistente a través del protocolo `LoggerProtocol`. Gestiona
/// múltiples instancias de `os.Logger` por categoría y aplica configuración
/// de niveles mínimos.
///
/// ## Características:
/// - Thread-safe mediante actor isolation
/// - Lazy initialization de loggers por categoría
/// - Configuración dinámica de niveles mínimos
/// - Formateo de mensajes con metadata opcional
/// - Integración completa con Unified Logging System
///
/// ## Ejemplo de uso:
/// ```swift
/// let config = LogConfiguration.production
/// let logger = OSLoggerAdapter(configuration: config)
///
/// await logger.info("Usuario autenticado", category: AuthCategory.login)
/// ```
public actor OSLoggerAdapter: LoggerProtocol {

    // MARK: - Properties

    /// Configuración del logger.
    private let configuration: LogConfiguration

    /// Cache de instancias de os.Logger por categoría.
    /// Key: category identifier, Value: os.Logger instance
    private var loggerCache: [String: os.Logger] = [:]

    /// Logger por defecto para cuando no se especifica categoría.
    private let defaultLogger: os.Logger

    // MARK: - Initialization

    /// Inicializa el adapter con una configuración específica.
    ///
    /// - Parameter configuration: La configuración a aplicar
    public init(configuration: LogConfiguration) {
        self.configuration = configuration
        self.defaultLogger = os.Logger(
            subsystem: configuration.subsystem,
            category: "default"
        )
    }

    /// Inicializa el adapter con configuración automática según el entorno.
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
        await log(
            message: message,
            level: .debug,
            category: category,
            file: file,
            function: function,
            line: line
        )
    }

    public func info(
        _ message: String,
        category: LogCategory?,
        file: String,
        function: String,
        line: Int
    ) async {
        await log(
            message: message,
            level: .info,
            category: category,
            file: file,
            function: function,
            line: line
        )
    }

    public func warning(
        _ message: String,
        category: LogCategory?,
        file: String,
        function: String,
        line: Int
    ) async {
        await log(
            message: message,
            level: .warning,
            category: category,
            file: file,
            function: function,
            line: line
        )
    }

    public func error(
        _ message: String,
        category: LogCategory?,
        file: String,
        function: String,
        line: Int
    ) async {
        await log(
            message: message,
            level: .error,
            category: category,
            file: file,
            function: function,
            line: line
        )
    }

    // MARK: - Private Methods

    /// Método centralizado para logging con filtrado de nivel.
    private func log(
        message: String,
        level: LogLevel,
        category: LogCategory?,
        file: String,
        function: String,
        line: Int
    ) async {
        // Early exit si el nivel no cumple con el mínimo configurado
        guard configuration.shouldLog(level: level, for: category) else {
            return
        }

        // Obtener o crear logger para la categoría
        let logger = getOrCreateLogger(for: category)

        // Formatear mensaje con metadata si está habilitado
        let formattedMessage = formatMessage(
            message,
            file: file,
            function: function,
            line: line
        )

        // Delegar al os.Logger con el nivel apropiado
        logToOSLogger(
            logger: logger,
            message: formattedMessage,
            level: level
        )
    }

    /// Obtiene un logger existente del cache o crea uno nuevo.
    ///
    /// - Parameter category: La categoría del log (puede ser nil)
    /// - Returns: Instancia de os.Logger configurada para la categoría
    private func getOrCreateLogger(for category: LogCategory?) -> os.Logger {
        guard let category = category else {
            return defaultLogger
        }

        let categoryId = category.identifier

        // Retornar del cache si existe
        if let cachedLogger = loggerCache[categoryId] {
            return cachedLogger
        }

        // Crear nuevo logger y guardarlo en cache
        let newLogger = os.Logger(
            subsystem: configuration.subsystem,
            category: categoryId
        )
        loggerCache[categoryId] = newLogger

        return newLogger
    }

    /// Formatea el mensaje con metadata si está habilitado en la configuración.
    ///
    /// - Parameters:
    ///   - message: El mensaje base
    ///   - file: Archivo de origen
    ///   - function: Función de origen
    ///   - line: Línea de origen
    /// - Returns: Mensaje formateado
    private func formatMessage(
        _ message: String,
        file: String,
        function: String,
        line: Int
    ) -> String {
        guard configuration.includeMetadata else {
            return message
        }

        // Extraer solo el nombre del archivo (sin path completo)
        let fileName = (file as NSString).lastPathComponent

        return "[\(fileName):\(line)] \(function) - \(message)"
    }

    /// Envía el mensaje al os.Logger con el nivel apropiado.
    ///
    /// - Parameters:
    ///   - logger: La instancia de os.Logger
    ///   - message: El mensaje a registrar
    ///   - level: El nivel de log
    private func logToOSLogger(
        logger: os.Logger,
        message: String,
        level: LogLevel
    ) {
        // Mapear LogLevel a OSLogType
        switch level {
        case .debug:
            logger.debug("\(message)")
        case .info:
            logger.info("\(message)")
        case .warning:
            // os.Logger no tiene .warning, usamos .notice que es el más cercano
            logger.notice("\(message)")
        case .error:
            logger.error("\(message)")
        }
    }
}

// MARK: - Public API Extensions

public extension OSLoggerAdapter {

    /// Limpia el cache de loggers.
    ///
    /// Útil en situaciones donde se necesita forzar recreación de loggers,
    /// por ejemplo después de cambiar configuración de subsystem.
    func clearCache() {
        loggerCache.removeAll()
    }

    /// Retorna el número de loggers actualmente en cache.
    ///
    /// Útil para debugging y monitoring.
    var cachedLoggerCount: Int {
        loggerCache.count
    }
}
