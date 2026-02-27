//
// TestHelpers.swift
// LoggerTests
//
// Created by EduGo Team on 27/01/2026.
// Copyright © 2026 EduGo. All rights reserved.
//

import Foundation
import Testing
@testable import EduLogger

// MARK: - Assertions

/// Verifica que un MockLogger contiene un log específico.
func expectLog(
    in mock: MockLogger,
    level: LogLevel,
    message: String,
    category: LogCategory? = nil,
    sourceLocation: SourceLocation = #_sourceLocation
) async {
    let contains = await mock.contains(level: level, message: message, category: category)
    #expect(contains, "Expected log not found: [\(level)] \(message)", sourceLocation: sourceLocation)
}

/// Verifica que un MockLogger contiene un log con mensaje parcial.
func expectLogContaining(
    in mock: MockLogger,
    level: LogLevel,
    text: String,
    category: LogCategory? = nil,
    sourceLocation: SourceLocation = #_sourceLocation
) async {
    let contains = await mock.containsMessage(level: level, containing: text, category: category)
    #expect(contains, "Expected log containing '\(text)' not found", sourceLocation: sourceLocation)
}

/// Verifica el número de logs capturados.
func expectLogCount(
    in mock: MockLogger,
    expected: Int,
    sourceLocation: SourceLocation = #_sourceLocation
) async {
    let count = await mock.count
    #expect(count == expected, "Expected \(expected) logs, got \(count)", sourceLocation: sourceLocation)
}

/// Verifica que no se registraron logs.
func expectNoLogs(
    in mock: MockLogger,
    sourceLocation: SourceLocation = #_sourceLocation
) async {
    await expectLogCount(in: mock, expected: 0, sourceLocation: sourceLocation)
}

// MARK: - Test Data Builders

/// Builder para crear configuraciones de prueba.
struct TestConfigurationBuilder {
    private var globalLevel: LogLevel = .debug
    private var isEnabled: Bool = true
    private var environment: LogConfiguration.Environment = .development
    private var subsystem: String = "com.test.app"
    private var overrides: [String: LogLevel] = [:]
    private var includeMetadata: Bool = true

    func level(_ level: LogLevel) -> TestConfigurationBuilder {
        var builder = self
        builder.globalLevel = level
        return builder
    }

    func enabled(_ enabled: Bool) -> TestConfigurationBuilder {
        var builder = self
        builder.isEnabled = enabled
        return builder
    }

    func environment(_ env: LogConfiguration.Environment) -> TestConfigurationBuilder {
        var builder = self
        builder.environment = env
        return builder
    }

    func subsystem(_ sub: String) -> TestConfigurationBuilder {
        var builder = self
        builder.subsystem = sub
        return builder
    }

    func override(level: LogLevel, for category: String) -> TestConfigurationBuilder {
        var builder = self
        builder.overrides[category] = level
        return builder
    }

    func metadata(_ include: Bool) -> TestConfigurationBuilder {
        var builder = self
        builder.includeMetadata = include
        return builder
    }

    func build() -> LogConfiguration {
        LogConfiguration(
            globalLevel: globalLevel,
            isEnabled: isEnabled,
            environment: environment,
            subsystem: subsystem,
            categoryOverrides: overrides,
            includeMetadata: includeMetadata
        )
    }
}

/// Builder para crear categorías de prueba.
struct TestCategoryBuilder {
    private let identifier: String
    private let displayName: String?

    init(_ identifier: String, displayName: String? = nil) {
        self.identifier = identifier
        self.displayName = displayName
    }

    func build() -> DynamicLogCategory {
        DynamicLogCategory(identifier: identifier, displayName: displayName)
    }

    static func tier0(_ module: String, _ component: String) -> TestCategoryBuilder {
        TestCategoryBuilder("com.edugo.tier0.\(module).\(component)")
    }

    static func tier1(_ module: String, _ component: String) -> TestCategoryBuilder {
        TestCategoryBuilder("com.edugo.tier1.\(module).\(component)")
    }
}

// MARK: - Logger Test Fixtures

enum LoggerTestFixtures {

    /// Configuración de prueba básica.
    static var defaultConfig: LogConfiguration {
        TestConfigurationBuilder()
            .level(.debug)
            .enabled(true)
            .build()
    }

    /// Configuración con logging deshabilitado.
    static var disabledConfig: LogConfiguration {
        TestConfigurationBuilder()
            .enabled(false)
            .build()
    }

    /// Configuración con nivel alto.
    static var highLevelConfig: LogConfiguration {
        TestConfigurationBuilder()
            .level(.error)
            .build()
    }

    /// Categoría de prueba genérica.
    static var testCategory: DynamicLogCategory {
        DynamicLogCategory(identifier: "com.edugo.tier0.test.category")
    }

    /// Logger mock pre-configurado.
    static func mockLogger() -> MockLogger {
        MockLogger()
    }
}

// MARK: - Performance Helpers

/// Mide el tiempo de ejecución de un bloque.
func measureTime(_ block: () async throws -> Void) async rethrows -> TimeInterval {
    let start = Date()
    try await block()
    return Date().timeIntervalSince(start)
}

/// Verifica que una operación es rápida (< threshold).
func expectFast(
    _ threshold: TimeInterval = 0.1,
    sourceLocation: SourceLocation = #_sourceLocation,
    _ block: () async throws -> Void
) async rethrows {
    let time = try await measureTime(block)
    #expect(time < threshold, "Operation too slow: \(time)s (threshold: \(threshold)s)", sourceLocation: sourceLocation)
}

// MARK: - Concurrency Helpers

/// Ejecuta un bloque múltiples veces concurrentemente.
func runConcurrently(
    times: Int,
    _ block: @Sendable @escaping (Int) async -> Void
) async {
    await withTaskGroup(of: Void.self) { group in
        for i in 0..<times {
            group.addTask {
                await block(i)
            }
        }
    }
}

/// Ejecuta un bloque con delay aleatorio para simular condiciones de carrera.
func runConcurrentlyWithJitter(
    times: Int,
    maxJitterMs: UInt64 = 10,
    _ block: @Sendable @escaping (Int) async -> Void
) async {
    await withTaskGroup(of: Void.self) { group in
        for i in 0..<times {
            group.addTask {
                let jitter = UInt64.random(in: 0...maxJitterMs)
                try? await Task.sleep(for: .milliseconds(jitter))
                await block(i)
            }
        }
    }
}

// MARK: - Environment Helpers

/// Ejecuta un bloque con variables de entorno temporales.
func withEnvironment(
    _ environment: [String: String],
    _ block: () throws -> Void
) rethrows {
    let processInfo = ProcessInfo.processInfo
    let original: [String: String?] = environment.keys.reduce(into: [:]) { dict, key in
        dict[key] = processInfo.environment[key]
    }

    // Note: No podemos modificar environment en runtime en Swift
    // Este helper es principalmente para documentación
    // En tests reales usamos EnvironmentConfiguration.load(from:)

    defer {
        // Restore would go here if possible
    }

    try block()
}
