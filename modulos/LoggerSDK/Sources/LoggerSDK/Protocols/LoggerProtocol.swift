import Foundation

/// Protocolo base para sistemas de logging.
///
/// Define la interfaz común que deben implementar todos los adaptadores de logging.
/// Soporta cuatro niveles de severidad y está diseñado para Swift 6 Strict Concurrency.
///
/// - Note: Todas las implementaciones deben ser thread-safe y conformar Sendable.
public protocol LoggerProtocol: Sendable {

    func debug(
        _ message: String,
        category: LogCategory?,
        file: String,
        function: String,
        line: Int
    ) async

    func info(
        _ message: String,
        category: LogCategory?,
        file: String,
        function: String,
        line: Int
    ) async

    func warning(
        _ message: String,
        category: LogCategory?,
        file: String,
        function: String,
        line: Int
    ) async

    func error(
        _ message: String,
        category: LogCategory?,
        file: String,
        function: String,
        line: Int
    ) async
}

// MARK: - Default Parameters

public extension LoggerProtocol {

    func debug(
        _ message: String,
        category: LogCategory? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        await debug(message, category: category, file: file, function: function, line: line)
    }

    func info(
        _ message: String,
        category: LogCategory? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        await info(message, category: category, file: file, function: function, line: line)
    }

    func warning(
        _ message: String,
        category: LogCategory? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        await warning(message, category: category, file: file, function: function, line: line)
    }

    func error(
        _ message: String,
        category: LogCategory? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        await error(message, category: category, file: file, function: function, line: line)
    }
}
