import Foundation

/// Representa los niveles de severidad de logging disponibles.
///
/// Los niveles están ordenados de menor a mayor severidad, permitiendo filtrado
/// por nivel mínimo.
public enum LogLevel: String, Sendable, Comparable, CaseIterable {

    /// Nivel debug: información detallada para desarrollo.
    case debug

    /// Nivel info: eventos informativos generales.
    case info

    /// Nivel warning: situaciones anómalas que no impiden el funcionamiento.
    case warning

    /// Nivel error: errores que afectan funcionalidad.
    case error

    // MARK: - Comparable Conformance

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
