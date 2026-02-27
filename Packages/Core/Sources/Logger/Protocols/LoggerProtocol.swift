//
// LoggerProtocol.swift
// Logger
//
// Created by EduGo Team on 27/01/2026.
// Copyright © 2026 EduGo. All rights reserved.
//

import Foundation

/// Protocolo base para sistemas de logging.
///
/// Define la interfaz común que deben implementar todos los adaptadores de logging
/// en el sistema EduGo. Soporta cuatro niveles de severidad y está diseñado para
/// cumplir con Swift 6.2 Strict Concurrency.
///
/// - Note: Todas las implementaciones deben ser thread-safe y conformar Sendable.
public protocol LoggerProtocol: Sendable {

    /// Registra un mensaje de nivel debug.
    ///
    /// Usado para información detallada de desarrollo, generalmente deshabilitado en producción.
    ///
    /// - Parameters:
    ///   - message: El mensaje a registrar
    ///   - category: La categoría del log (por defecto: subsistema del logger)
    ///   - file: El archivo desde donde se originó el log (automático)
    ///   - function: La función desde donde se originó el log (automático)
    ///   - line: La línea desde donde se originó el log (automático)
    func debug(
        _ message: String,
        category: LogCategory?,
        file: String,
        function: String,
        line: Int
    ) async

    /// Registra un mensaje de nivel info.
    ///
    /// Usado para eventos informativos generales del sistema.
    ///
    /// - Parameters:
    ///   - message: El mensaje a registrar
    ///   - category: La categoría del log (por defecto: subsistema del logger)
    ///   - file: El archivo desde donde se originó el log (automático)
    ///   - function: La función desde donde se originó el log (automático)
    ///   - line: La línea desde donde se originó el log (automático)
    func info(
        _ message: String,
        category: LogCategory?,
        file: String,
        function: String,
        line: Int
    ) async

    /// Registra un mensaje de nivel warning.
    ///
    /// Usado para situaciones anómalas que no impiden el funcionamiento pero requieren atención.
    ///
    /// - Parameters:
    ///   - message: El mensaje a registrar
    ///   - category: La categoría del log (por defecto: subsistema del logger)
    ///   - file: El archivo desde donde se originó el log (automático)
    ///   - function: La función desde donde se originó el log (automático)
    ///   - line: La línea desde donde se originó el log (automático)
    func warning(
        _ message: String,
        category: LogCategory?,
        file: String,
        function: String,
        line: Int
    ) async

    /// Registra un mensaje de nivel error.
    ///
    /// Usado para errores que afectan funcionalidad pero no causan crash.
    ///
    /// - Parameters:
    ///   - message: El mensaje a registrar
    ///   - category: La categoría del log (por defecto: subsistema del logger)
    ///   - file: El archivo desde donde se originó el log (automático)
    ///   - function: La función desde donde se originó el log (automático)
    ///   - line: La línea desde donde se originó el log (automático)
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

    /// Registra un mensaje de nivel debug con parámetros por defecto.
    func debug(
        _ message: String,
        category: LogCategory? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        await debug(message, category: category, file: file, function: function, line: line)
    }

    /// Registra un mensaje de nivel info con parámetros por defecto.
    func info(
        _ message: String,
        category: LogCategory? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        await info(message, category: category, file: file, function: function, line: line)
    }

    /// Registra un mensaje de nivel warning con parámetros por defecto.
    func warning(
        _ message: String,
        category: LogCategory? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        await warning(message, category: category, file: file, function: function, line: line)
    }

    /// Registra un mensaje de nivel error con parámetros por defecto.
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
