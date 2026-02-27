//
// LogLevel.swift
// Logger
//
// Created by EduGo Team on 27/01/2026.
// Copyright © 2026 EduGo. All rights reserved.
//

import Foundation

/// Representa los niveles de severidad de logging disponibles en el sistema.
///
/// Los niveles están ordenados de menor a mayor severidad, permitiendo filtrado
/// por nivel mínimo. Por ejemplo, si el nivel mínimo es `.warning`, solo se
/// registrarán mensajes de warning y error.
///
/// - Note: Conforma `Comparable` para permitir comparaciones de severidad.
public enum LogLevel: String, Sendable, Comparable, CaseIterable {

    /// Nivel debug: información detallada para desarrollo.
    ///
    /// Generalmente deshabilitado en producción. Usado para tracing detallado
    /// y diagnóstico de problemas durante el desarrollo.
    case debug

    /// Nivel info: eventos informativos generales.
    ///
    /// Usado para registrar eventos normales del sistema como inicio de
    /// operaciones, cambios de estado, etc.
    case info

    /// Nivel warning: situaciones anómalas que no impiden el funcionamiento.
    ///
    /// Usado para condiciones que requieren atención pero no causan fallas,
    /// como datos inesperados, configuraciones subóptimas, etc.
    case warning

    /// Nivel error: errores que afectan funcionalidad.
    ///
    /// Usado para errores que impiden completar una operación pero no causan
    /// crash de la aplicación.
    case error

    // MARK: - Comparable Conformance

    /// Orden de severidad para comparación.
    private var severityOrder: Int {
        switch self {
        case .debug: return 0
        case .info: return 1
        case .warning: return 2
        case .error: return 3
        }
    }

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.severityOrder < rhs.severityOrder
    }

    // MARK: - Utility

    /// Representación legible del nivel.
    public var displayName: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        }
    }

    /// Emoji visual para el nivel (útil en desarrollo).
    public var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
}
