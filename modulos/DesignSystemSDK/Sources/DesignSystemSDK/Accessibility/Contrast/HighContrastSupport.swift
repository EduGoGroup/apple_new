//
//  HighContrastSupport.swift
//  EduAccessibility
//
//  System support for High Contrast mode detection and handling.
//
//  Features:
//  - High Contrast / Increase Contrast detection
//  - Differentiate Without Color detection
//  - Cross-platform support (iOS, macOS, tvOS, watchOS, visionOS)
//  - Environment key integration
//
//  Use Cases:
//  - Adjust colors for better contrast
//  - Increase border thickness
//  - Add visual indicators beyond color
//
//  Architecture:
//  - Pure functions reading directly from system APIs
//  - All functions are @MainActor
//  - Swift 6.2 strict concurrency compliant
//
//  Swift 6.2 strict concurrency compliant
//

import SwiftUI

/// Sistema de soporte para High Contrast mode del sistema.
///
/// Arquitectura correcta para Swift 6.2:
/// - No usa singletons con estado mutable
/// - Funciones puras que leen del sistema directamente
/// - Compatible con strict concurrency
///
/// ## Ejemplo
/// ```swift
/// let textColor = color.adjustedForContrast(
///     against: backgroundColor,
///     minimumRatio: .wcagAAA
/// )
/// ```
public enum HighContrastSupport {

    /// Indica si High Contrast está habilitado en el sistema
    @MainActor
    public static var isEnabled: Bool {
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        return UIAccessibility.isDarkerSystemColorsEnabled
        #elseif os(macOS)
        return NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
        #else
        return false
        #endif
    }

    /// Indica si Increase Contrast está habilitado (iOS/macOS)
    @MainActor
    public static var isIncreaseContrastEnabled: Bool {
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        return UIAccessibility.isDarkerSystemColorsEnabled
        #elseif os(macOS)
        return NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
        #else
        return false
        #endif
    }

    /// Indica si Differentiate Without Color está habilitado
    @MainActor
    public static var isDifferentiateWithoutColorEnabled: Bool {
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        return UIAccessibility.shouldDifferentiateWithoutColor
        #elseif os(macOS)
        return NSWorkspace.shared.accessibilityDisplayShouldDifferentiateWithoutColor
        #else
        return false
        #endif
    }

    /// Ejecuta una acción solo si High Contrast está habilitado
    /// - Parameter action: Acción a ejecutar
    @MainActor
    public static func ifHighContrast(_ action: () -> Void) {
        guard isEnabled else { return }
        action()
    }

    /// Ejecuta una acción solo si High Contrast NO está habilitado
    /// - Parameter action: Acción a ejecutar
    @MainActor
    public static func ifNormalContrast(_ action: () -> Void) {
        guard !isEnabled else { return }
        action()
    }

    /// Elige entre dos valores según la preferencia de High Contrast
    /// - Parameters:
    ///   - highContrast: Valor a retornar si High Contrast está habilitado
    ///   - normal: Valor a retornar si High Contrast NO está habilitado
    /// - Returns: El valor apropiado según la preferencia
    @MainActor
    public static func choose<T>(highContrast: T, normal: T) -> T {
        isEnabled ? highContrast : normal
    }
}

// MARK: - High Contrast State

/// Estado de las preferencias de High Contrast
public struct HighContrastState: Sendable, Equatable {
    public let isEnabled: Bool
    public let isIncreaseContrastEnabled: Bool
    public let isDifferentiateWithoutColorEnabled: Bool

    public init(
        isEnabled: Bool,
        isIncreaseContrastEnabled: Bool,
        isDifferentiateWithoutColorEnabled: Bool
    ) {
        self.isEnabled = isEnabled
        self.isIncreaseContrastEnabled = isIncreaseContrastEnabled
        self.isDifferentiateWithoutColorEnabled = isDifferentiateWithoutColorEnabled
    }

    @MainActor
    public static var current: HighContrastState {
        HighContrastState(
            isEnabled: HighContrastSupport.isEnabled,
            isIncreaseContrastEnabled: HighContrastSupport.isIncreaseContrastEnabled,
            isDifferentiateWithoutColorEnabled: HighContrastSupport.isDifferentiateWithoutColorEnabled
        )
    }
}

// MARK: - Environment Values

extension EnvironmentValues {
    /// Indica si High Contrast está habilitado
    @Entry public var accessibilityHighContrast: Bool = false

    /// Indica si Increase Contrast está habilitado
    @Entry public var accessibilityIncreaseContrast: Bool = false

    /// Indica si Differentiate Without Color está habilitado
    @Entry public var accessibilityDifferentiateWithoutColor: Bool = false
}

// MARK: - View Extensions

extension View {
    /// Aplica un modifier solo si High Contrast está habilitado
    /// - Parameter modifier: Modifier a aplicar
    /// - Returns: View con el modifier aplicado condicionalmente
    public func ifHighContrast<Content: View>(
        @ViewBuilder _ modifier: (Self) -> Content
    ) -> some View {
        Group {
            if HighContrastSupport.isEnabled {
                modifier(self)
            } else {
                self
            }
        }
    }

    /// Aplica un modifier solo si High Contrast NO está habilitado
    /// - Parameter modifier: Modifier a aplicar
    /// - Returns: View con el modifier aplicado condicionalmente
    public func ifNormalContrast<Content: View>(
        @ViewBuilder _ modifier: (Self) -> Content
    ) -> some View {
        Group {
            if HighContrastSupport.isEnabled {
                self
            } else {
                modifier(self)
            }
        }
    }
}

// MARK: - AccessibilityHighContrastModifier

/// Modifier que sincroniza los environment values con el sistema
private struct AccessibilityHighContrastModifier: ViewModifier {
    @State private var isHighContrastEnabled: Bool = false
    @State private var isIncreaseContrastEnabled: Bool = false
    @State private var isDifferentiateWithoutColorEnabled: Bool = false

    func body(content: Content) -> some View {
        content
            .environment(\.accessibilityHighContrast, isHighContrastEnabled)
            .environment(\.accessibilityIncreaseContrast, isIncreaseContrastEnabled)
            .environment(\.accessibilityDifferentiateWithoutColor, isDifferentiateWithoutColorEnabled)
            .onAppear {
                updateHighContrastState()
            }
            .task {
                for await _ in NotificationCenter.default.notifications(named: contrastNotificationName) {
                    updateHighContrastState()
                }
            }
    }

    @MainActor
    private func updateHighContrastState() {
        isHighContrastEnabled = HighContrastSupport.isEnabled
        isIncreaseContrastEnabled = HighContrastSupport.isIncreaseContrastEnabled
        isDifferentiateWithoutColorEnabled = HighContrastSupport.isDifferentiateWithoutColorEnabled
    }

    private var contrastNotificationName: Notification.Name {
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        return UIAccessibility.darkerSystemColorsStatusDidChangeNotification
        #elseif os(macOS)
        return NSWorkspace.accessibilityDisplayOptionsDidChangeNotification
        #else
        return Notification.Name("HighContrastDidChange")
        #endif
    }
}

extension View {
    /// Sincroniza los environment values con el sistema
    /// Agregar a la raíz de la app
    public func syncAccessibilityHighContrast() -> some View {
        modifier(AccessibilityHighContrastModifier())
    }
}
