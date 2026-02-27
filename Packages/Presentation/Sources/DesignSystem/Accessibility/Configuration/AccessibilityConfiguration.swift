import SwiftUI
import os.log

/// Configuración global de accesibilidad para toda la aplicación.
///
/// Permite habilitar/deshabilitar features, configurar logging, y ajustar comportamiento
/// de accesibilidad para testing y debugging.
///
/// ## Uso
/// ```swift
/// // En el app startup
/// AccessibilityConfiguration.shared.configure {
///     $0.isLoggingEnabled = true
///     $0.shouldValidateIdentifiers = true
/// }
/// ```
@MainActor
@Observable
public final class AccessibilityConfiguration: Sendable {

    // MARK: - Singleton

    public static let shared = AccessibilityConfiguration()

    // MARK: - Configuration Properties

    /// Si el logging de accessibility está habilitado
    public var isLoggingEnabled: Bool = false

    /// Si se debe validar que los identifiers sean únicos
    public var shouldValidateIdentifiers: Bool = true

    /// Si se debe validar que labels y hints cumplan las best practices
    public var shouldValidateLabelsAndHints: Bool = true

    /// Si accessibility está globalmente habilitado (útil para testing)
    public var isAccessibilityEnabled: Bool = true

    /// Nivel de detalle del logging
    public var logLevel: LogLevel = .warning

    /// Si se debe lanzar assertion en caso de errores de validación (solo en DEBUG)
    public var shouldAssertOnValidationErrors: Bool = false

    // MARK: - Logger

    private let logger = Logger(subsystem: "com.edugo.accessibility", category: "Configuration")

    // MARK: - Initializer

    private init() {}

    // MARK: - Configuration Methods

    /// Configura las opciones de accesibilidad
    ///
    /// Ejemplo:
    /// ```swift
    /// AccessibilityConfiguration.shared.configure {
    ///     $0.isLoggingEnabled = true
    ///     $0.logLevel = .debug
    /// }
    /// ```
    public func configure(_ configurator: (inout AccessibilityConfiguration) -> Void) {
        var copy = self
        configurator(&copy)

        self.isLoggingEnabled = copy.isLoggingEnabled
        self.shouldValidateIdentifiers = copy.shouldValidateIdentifiers
        self.shouldValidateLabelsAndHints = copy.shouldValidateLabelsAndHints
        self.isAccessibilityEnabled = copy.isAccessibilityEnabled
        self.logLevel = copy.logLevel
        self.shouldAssertOnValidationErrors = copy.shouldAssertOnValidationErrors

        log("Accessibility configuration updated", level: .info)
    }

    /// Restaura la configuración a valores por defecto
    public func reset() {
        isLoggingEnabled = false
        shouldValidateIdentifiers = true
        shouldValidateLabelsAndHints = true
        isAccessibilityEnabled = true
        logLevel = .warning
        shouldAssertOnValidationErrors = false

        log("Accessibility configuration reset to defaults", level: .info)
    }

    // MARK: - Logging

    /// Registra un mensaje de log si el logging está habilitado
    public func log(_ message: String, level: LogLevel = .debug) {
        guard isLoggingEnabled, level.rawValue >= logLevel.rawValue else { return }

        switch level {
        case .debug:
            logger.debug("\(message, privacy: .public)")
        case .info:
            logger.info("\(message, privacy: .public)")
        case .warning:
            logger.warning("\(message, privacy: .public)")
        case .error:
            logger.error("\(message, privacy: .public)")
        }
    }

    /// Registra un error de validación
    public func logValidationError(_ message: String, component: String? = nil) {
        let fullMessage = component != nil
            ? "[\(component!)] Validation error: \(message)"
            : "Validation error: \(message)"

        log(fullMessage, level: .error)

        #if DEBUG
        if shouldAssertOnValidationErrors {
            assertionFailure(fullMessage)
        }
        #endif
    }

    /// Registra el uso de un identifier duplicado
    public func logDuplicateIdentifier(_ identifier: String, component: String? = nil) {
        let message = component != nil
            ? "[\(component!)] Duplicate accessibility identifier: \(identifier)"
            : "Duplicate accessibility identifier: \(identifier)"

        log(message, level: .warning)
    }

    // MARK: - Validation

    /// Valida un AccessibilityLabel según las best practices
    ///
    /// - Returns: `true` si el label es válido, `false` si no
    public func validate(label: AccessibilityLabel, component: String? = nil) -> Bool {
        guard shouldValidateLabelsAndHints else { return true }

        if !label.isValid {
            logValidationError(
                "Invalid accessibility label: '\(label.value)'",
                component: component
            )
            return false
        }

        if !label.hasRecommendedLength {
            log(
                "Accessibility label length not recommended: '\(label.value)' (\(label.value.count) characters)",
                level: .warning
            )
        }

        return true
    }

    /// Valida un AccessibilityHint según las best practices
    public func validate(hint: AccessibilityHint, component: String? = nil) -> Bool {
        guard shouldValidateLabelsAndHints else { return true }

        if !hint.isValid {
            logValidationError(
                "Invalid accessibility hint: '\(hint.value)'",
                component: component
            )
            return false
        }

        if !hint.hasRecommendedLength {
            log(
                "Accessibility hint length not recommended: '\(hint.value)' (\(hint.value.count) characters)",
                level: .warning
            )
        }

        if !hint.describesResult {
            log(
                "Accessibility hint should describe result, not activation: '\(hint.value)'",
                level: .warning
            )
        }

        return true
    }

    /// Valida un AccessibilityIdentifier según las naming conventions
    public func validate(identifier: AccessibilityIdentifier, component: String? = nil) -> Bool {
        guard shouldValidateIdentifiers else { return true }

        if !identifier.isValid {
            logValidationError(
                "Invalid accessibility identifier: '\(identifier.id)'",
                component: component
            )
            return false
        }

        // Validar que no sea duplicado
        if AccessibilityIdentifierRegistry.shared.isRegistered(identifier) {
            logDuplicateIdentifier(identifier.id, component: component)
        }

        return true
    }
}

// MARK: - Log Level

/// Nivel de detalle del logging de accesibilidad
public enum LogLevel: Int, Sendable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
}

// MARK: - Testing Support

#if DEBUG
extension AccessibilityConfiguration {
    /// Configuración preset para testing automatizado
    public static var testing: AccessibilityConfiguration {
        let config = AccessibilityConfiguration.shared
        config.isLoggingEnabled = false
        config.shouldValidateIdentifiers = false
        config.shouldValidateLabelsAndHints = false
        config.shouldAssertOnValidationErrors = false
        return config
    }

    /// Configuración preset para debugging
    public static var debugging: AccessibilityConfiguration {
        let config = AccessibilityConfiguration.shared
        config.isLoggingEnabled = true
        config.logLevel = .debug
        config.shouldValidateIdentifiers = true
        config.shouldValidateLabelsAndHints = true
        config.shouldAssertOnValidationErrors = true
        return config
    }
}
#endif

// MARK: - View Extension

// Nota: AccessibilityConfiguration no usa EnvironmentValues debido a restricciones de Swift 6.2
// con @MainActor y EnvironmentKey. En su lugar, se accede directamente via .shared
// Para testing, se puede configurar directamente antes de las pruebas.

// MARK: - Accessibility Feature Flags

extension AccessibilityConfiguration {
    /// Feature flags para controlar qué features de accesibilidad están activas
    @MainActor
    @Observable
    public final class FeatureFlags: Sendable {
        /// Si VoiceOver announcements están habilitados
        public var isVoiceOverAnnouncementsEnabled: Bool = true

        /// Si custom rotors están habilitados
        public var areCustomRotorsEnabled: Bool = true

        /// Si focus management automático está habilitado
        public var isAutoFocusManagementEnabled: Bool = true

        /// Si Dynamic Type scaling está habilitado
        public var isDynamicTypeEnabled: Bool = true

        /// Si Reduced Motion adaptations están habilitadas
        public var isReducedMotionAdaptationEnabled: Bool = true

        /// Si High Contrast adaptations están habilitadas
        public var isHighContrastAdaptationEnabled: Bool = true

        /// Si accessibility hints deben mostrarse (algunos users los deshabilitan)
        public var shouldShowHints: Bool = true
    }

    /// Feature flags globales de accesibilidad
    public static let featureFlags = FeatureFlags()
}

// MARK: - Statistics

extension AccessibilityConfiguration {
    /// Estadísticas de uso de accesibilidad (para debugging y análisis)
    @MainActor
    @Observable
    public final class Statistics: Sendable {
        /// Total de identifiers registrados
        public var totalIdentifiersRegistered: Int {
            AccessibilityIdentifierRegistry.shared.allIdentifiers.count
        }

        /// Total de identifiers duplicados detectados
        public var totalDuplicatesDetected: Int = 0

        /// Total de validation errors detectados
        public var totalValidationErrors: Int = 0

        /// Resetea las estadísticas
        public func reset() {
            totalDuplicatesDetected = 0
            totalValidationErrors = 0
        }

        /// Genera un reporte de estadísticas
        public var report: String {
            """
            Accessibility Statistics:
            - Total Identifiers: \(totalIdentifiersRegistered)
            - Duplicates Detected: \(totalDuplicatesDetected)
            - Validation Errors: \(totalValidationErrors)
            """
        }
    }

    /// Estadísticas globales de accesibilidad
    public static let statistics = Statistics()
}
