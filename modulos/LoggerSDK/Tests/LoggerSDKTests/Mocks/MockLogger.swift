import Foundation
@testable import LoggerSDK

/// Mock logger para testing que captura todas las llamadas de logging.
public actor MockLogger: LoggerProtocol {

    // MARK: - Log Entry

    public struct LogEntry: Sendable, Equatable {
        public let level: LogLevel
        public let message: String
        public let category: String?
        public let file: String
        public let function: String
        public let line: Int
        public let timestamp: Date

        public init(
            level: LogLevel,
            message: String,
            category: String?,
            file: String,
            function: String,
            line: Int,
            timestamp: Date = Date()
        ) {
            self.level = level
            self.message = message
            self.category = category
            self.file = file
            self.function = function
            self.line = line
            self.timestamp = timestamp
        }
    }

    // MARK: - Properties

    private(set) var entries: [LogEntry] = []
    public var shouldLog: Bool = true

    // MARK: - Initialization

    public init() {}

    // MARK: - LoggerProtocol

    public func debug(_ message: String, category: LogCategory?, file: String, function: String, line: Int) async {
        await log(level: .debug, message: message, category: category, file: file, function: function, line: line)
    }

    public func info(_ message: String, category: LogCategory?, file: String, function: String, line: Int) async {
        await log(level: .info, message: message, category: category, file: file, function: function, line: line)
    }

    public func warning(_ message: String, category: LogCategory?, file: String, function: String, line: Int) async {
        await log(level: .warning, message: message, category: category, file: file, function: function, line: line)
    }

    public func error(_ message: String, category: LogCategory?, file: String, function: String, line: Int) async {
        await log(level: .error, message: message, category: category, file: file, function: function, line: line)
    }

    // MARK: - Private

    private func log(level: LogLevel, message: String, category: LogCategory?, file: String, function: String, line: Int) async {
        guard shouldLog else { return }
        let entry = LogEntry(level: level, message: message, category: category?.identifier, file: file, function: function, line: line)
        entries.append(entry)
    }

    // MARK: - Test Helpers

    public func clear() { entries.removeAll() }
    public var count: Int { entries.count }
    public var lastEntry: LogEntry? { entries.last }
    public var firstEntry: LogEntry? { entries.first }

    public func entries(level: LogLevel) -> [LogEntry] {
        entries.filter { $0.level == level }
    }

    public func entries(category: LogCategory) -> [LogEntry] {
        entries.filter { $0.category == category.identifier }
    }

    public func contains(level: LogLevel, message: String, category: LogCategory? = nil) -> Bool {
        entries.contains { entry in
            entry.level == level && entry.message == message &&
            (category == nil || entry.category == category?.identifier)
        }
    }

    public func containsMessage(level: LogLevel, containing text: String, category: LogCategory? = nil) -> Bool {
        entries.contains { entry in
            entry.level == level && entry.message.contains(text) &&
            (category == nil || entry.category == category?.identifier)
        }
    }
}

extension MockLogger {
    func setShouldLog(_ value: Bool) {
        self.shouldLog = value
    }
}

extension MockLogger.LogEntry: CustomStringConvertible {
    public var description: String {
        let categoryStr = category.map { " [\($0)]" } ?? ""
        let fileStr = (file as NSString).lastPathComponent
        return "[\(level.displayName)]\(categoryStr) \(message) (\(fileStr):\(line))"
    }
}
