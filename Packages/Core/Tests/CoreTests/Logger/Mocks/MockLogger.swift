//
// MockLogger.swift
// LoggerTests
//
// Created by EduGo Team on 27/01/2026.
// Copyright © 2026 EduGo. All rights reserved.
//

import Foundation
@testable import EduLogger

/// Mock logger para testing que captura todas las llamadas de logging.
///
/// Permite verificar que los logs se registran correctamente sin depender
/// de os.Logger. Thread-safe mediante actor isolation.
///
/// ## Ejemplo de uso:
/// ```swift
/// let mock = MockLogger()
/// await mock.info("Test message", category: nil)
///
/// let entries = await mock.entries
/// #expect(entries.count == 1)
/// #expect(entries[0].level == .info)
/// #expect(entries[0].message == "Test message")
/// ```
public actor MockLogger: LoggerProtocol {

    // MARK: - Log Entry

    /// Entrada de log capturada.
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

    /// Todas las entradas capturadas.
    private(set) var entries: [LogEntry] = []

    /// Configuración para simular comportamiento.
    public var shouldLog: Bool = true

    // MARK: - Initialization

    public init() {}

    // MARK: - LoggerProtocol

    public func debug(
        _ message: String,
        category: LogCategory?,
        file: String,
        function: String,
        line: Int
    ) async {
        await log(level: .debug, message: message, category: category, file: file, function: function, line: line)
    }

    public func info(
        _ message: String,
        category: LogCategory?,
        file: String,
        function: String,
        line: Int
    ) async {
        await log(level: .info, message: message, category: category, file: file, function: function, line: line)
    }

    public func warning(
        _ message: String,
        category: LogCategory?,
        file: String,
        function: String,
        line: Int
    ) async {
        await log(level: .warning, message: message, category: category, file: file, function: function, line: line)
    }

    public func error(
        _ message: String,
        category: LogCategory?,
        file: String,
        function: String,
        line: Int
    ) async {
        await log(level: .error, message: message, category: category, file: file, function: function, line: line)
    }

    // MARK: - Private

    private func log(
        level: LogLevel,
        message: String,
        category: LogCategory?,
        file: String,
        function: String,
        line: Int
    ) async {
        guard shouldLog else { return }

        let entry = LogEntry(
            level: level,
            message: message,
            category: category?.identifier,
            file: file,
            function: function,
            line: line
        )

        entries.append(entry)
    }

    // MARK: - Test Helpers

    /// Limpia todas las entradas capturadas.
    public func clear() {
        entries.removeAll()
    }

    /// Número de entradas capturadas.
    public var count: Int {
        entries.count
    }

    /// Última entrada capturada.
    public var lastEntry: LogEntry? {
        entries.last
    }

    /// Primera entrada capturada.
    public var firstEntry: LogEntry? {
        entries.first
    }

    /// Filtra entradas por nivel.
    public func entries(level: LogLevel) -> [LogEntry] {
        entries.filter { $0.level == level }
    }

    /// Filtra entradas por categoría.
    public func entries(category: LogCategory) -> [LogEntry] {
        entries.filter { $0.category == category.identifier }
    }

    /// Filtra entradas que contienen un mensaje.
    public func entries(containing text: String) -> [LogEntry] {
        entries.filter { $0.message.contains(text) }
    }

    /// Verifica que se registró un log específico.
    public func contains(
        level: LogLevel,
        message: String,
        category: LogCategory? = nil
    ) -> Bool {
        entries.contains { entry in
            entry.level == level &&
            entry.message == message &&
            (category == nil || entry.category == category?.identifier)
        }
    }

    /// Verifica que se registró un log con mensaje parcial.
    public func containsMessage(
        level: LogLevel,
        containing text: String,
        category: LogCategory? = nil
    ) -> Bool {
        entries.contains { entry in
            entry.level == level &&
            entry.message.contains(text) &&
            (category == nil || entry.category == category?.identifier)
        }
    }
}

// MARK: - CustomStringConvertible

extension MockLogger.LogEntry: CustomStringConvertible {
    public var description: String {
        let categoryStr = category.map { " [\($0)]" } ?? ""
        let fileStr = (file as NSString).lastPathComponent
        return "[\(level.displayName)]\(categoryStr) \(message) (\(fileStr):\(line))"
    }
}
