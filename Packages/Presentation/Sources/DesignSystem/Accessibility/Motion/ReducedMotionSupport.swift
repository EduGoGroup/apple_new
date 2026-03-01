//
//  ReducedMotionSupport.swift
//  EduAccessibility
//
//  System support for Reduce Motion preference detection and handling.
//
//  Features:
//  - Cross-platform detection (iOS, macOS, tvOS, watchOS, visionOS)
//  - Pure functions that read directly from system APIs
//  - Conditional execution helpers (ifMotionAllowed, ifMotionReduced)
//  - Value selection based on motion preference
//
//  Architecture:
//  - No singletons with mutable state
//  - All functions are @MainActor (access UIAccessibility/NSWorkspace)
//  - Swift 6.2 strict concurrency compliant
//
//  Swift 6.2 strict concurrency compliant
//

import SwiftUI

/// Sistema de soporte para Reduce Motion preference del sistema.
///
/// Arquitectura correcta para Swift 6.2:
/// - No usa singletons con estado mutable
/// - Funciones puras que leen del sistema directamente
/// - Compatible con strict concurrency
///
/// ## Ejemplo
/// ```swift
/// if ReducedMotionSupport.isEnabled {
///     // Usar fade en vez de slide
///     view.transition(.opacity)
/// } else {
///     view.transition(.move(edge: .bottom))
/// }
/// ```
public enum ReducedMotionSupport {

    /// Indica si Reduce Motion está habilitado en el sistema
    /// Función pura que lee directamente del sistema operativo
    @MainActor
    public static var isEnabled: Bool {
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        return UIAccessibility.isReduceMotionEnabled
        #elseif os(macOS)
        return NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        #else
        return false
        #endif
    }

    /// Ejecuta una acción solo si Reduce Motion NO está habilitado
    /// - Parameter action: Acción a ejecutar
    @MainActor
    public static func ifMotionAllowed(_ action: () -> Void) {
        guard !isEnabled else { return }
        action()
    }

    /// Ejecuta una acción solo si Reduce Motion está habilitado
    /// - Parameter action: Acción a ejecutar
    @MainActor
    public static func ifMotionReduced(_ action: () -> Void) {
        guard isEnabled else { return }
        action()
    }

    /// Elige entre dos valores según la preferencia de Reduce Motion
    /// - Parameters:
    ///   - reduced: Valor a retornar si Reduce Motion está habilitado
    ///   - normal: Valor a retornar si Reduce Motion NO está habilitado
    /// - Returns: El valor apropiado según la preferencia
    @MainActor
    public static func choose<T>(reduced: T, normal: T) -> T {
        isEnabled ? reduced : normal
    }
}

// MARK: - Environment Values

extension EnvironmentValues {
    /// Indica si Reduce Motion está habilitado
    /// Se actualiza automáticamente por SwiftUI
    @Entry public var accessibilityReduceMotion: Bool = false
}

// MARK: - View Extensions

extension View {
    /// Aplica un modifier solo si Reduce Motion NO está habilitado
    /// - Parameter modifier: Modifier a aplicar
    /// - Returns: View con el modifier aplicado condicionalmente
    public func ifMotionAllowed<Content: View>(
        @ViewBuilder _ modifier: (Self) -> Content
    ) -> some View {
        Group {
            if ReducedMotionSupport.isEnabled {
                self
            } else {
                modifier(self)
            }
        }
    }

    /// Aplica un modifier solo si Reduce Motion está habilitado
    /// - Parameter modifier: Modifier a aplicar
    /// - Returns: View con el modifier aplicado condicionalmente
    public func ifMotionReduced<Content: View>(
        @ViewBuilder _ modifier: (Self) -> Content
    ) -> some View {
        Group {
            if ReducedMotionSupport.isEnabled {
                modifier(self)
            } else {
                self
            }
        }
    }
}

// MARK: - AccessibilityReduceMotionModifier

/// Modifier que sincroniza el environment value con el sistema
private struct AccessibilityReduceMotionModifier: ViewModifier {
    @State private var isReduceMotionEnabled: Bool = false

    func body(content: Content) -> some View {
        content
            .environment(\.accessibilityReduceMotion, isReduceMotionEnabled)
            .onAppear {
                Task { @MainActor in
                    isReduceMotionEnabled = ReducedMotionSupport.isEnabled
                }
            }
            .task {
                for await _ in NotificationCenter.default.notifications(named: reduceMotionNotificationName) {
                    await MainActor.run {
                        isReduceMotionEnabled = ReducedMotionSupport.isEnabled
                    }
                }
            }
    }

    private var reduceMotionNotificationName: Notification.Name {
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        return UIAccessibility.reduceMotionStatusDidChangeNotification
        #elseif os(macOS)
        return NSWorkspace.accessibilityDisplayOptionsDidChangeNotification
        #else
        return Notification.Name("ReduceMotionDidChange")
        #endif
    }
}

extension View {
    /// Sincroniza el environment value con el sistema
    /// Agregar a la raíz de la app
    public func syncAccessibilityReduceMotion() -> some View {
        modifier(AccessibilityReduceMotionModifier())
    }
}
