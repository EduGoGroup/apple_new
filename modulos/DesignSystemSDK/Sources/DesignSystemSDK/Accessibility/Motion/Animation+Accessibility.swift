//
//  Animation+Accessibility.swift
//  EduAccessibility
//
//  Animation extensions for accessibility support with automatic adaptation
//  based on Reduce Motion preference.
//
//  Adaptation Strategy:
//  - Long animations → Short (duration * 0.25)
//  - Scale/rotation → Fade
//  - Spring → Fast easeOut
//  - Slide → Fade
//
//  Features:
//  - .accessible() wrapper for automatic adaptation
//  - Accessible variants of common animations (spring, easeOut, easeIn)
//  - Transition extensions with automatic fallbacks
//
//  Architecture:
//  - All functions are @MainActor (access UIAccessibility)
//  - No singletons, reads directly from system
//  - Swift 6.2 strict concurrency compliant
//
//  Swift 6.2 strict concurrency compliant
//

import SwiftUI

/// Extensiones de Animation para soporte de accesibilidad.
///
/// Arquitectura correcta para Swift 6.2:
/// - Todas las funciones son @MainActor (acceden a UIAccessibility)
/// - No usan singletons, leen directamente del sistema
/// - Sin referencias a .instant (no existe en SwiftUI)
///
/// ## Estrategia de Adaptación
/// - Animaciones largas → cortas (duration * 0.25)
/// - Scale/rotation → fade
/// - Spring → easeOut rápido
/// - Slide → fade
///
/// ## Ejemplo
/// ```swift
/// withAnimation(.accessible(.spring())) {
///     isExpanded.toggle()
/// }
/// ```
extension Animation {

    // MARK: - Accessible Animation

    /// Crea una animación que se adapta automáticamente según Reduce Motion
    /// - Parameters:
    ///   - animation: Animación normal
    ///   - fallback: Animación alternativa (default: easeOut muy rápido)
    /// - Returns: Animación adaptada
    @MainActor
    public static func accessible(
        _ animation: Animation,
        fallback: Animation? = nil
    ) -> Animation {
        if ReducedMotionSupport.isEnabled {
            return fallback ?? .easeOut(duration: 0.1)
        } else {
            return animation
        }
    }

    /// Animación spring accesible
    /// - Parameters:
    ///   - response: Respuesta del spring (normal mode)
    ///   - dampingFraction: Damping fraction
    ///   - blendDuration: Blend duration
    /// - Returns: Spring animation que se adapta a Reduce Motion
    @MainActor
    public static func accessibleSpring(
        response: Double = 0.55,
        dampingFraction: Double = 0.825,
        blendDuration: Double = 0
    ) -> Animation {
        if ReducedMotionSupport.isEnabled {
            // En Reduce Motion, usar easeOut rápido
            return .easeOut(duration: 0.15)
        } else {
            return .spring(response: response, dampingFraction: dampingFraction, blendDuration: blendDuration)
        }
    }

    /// Animación easeInOut accesible
    /// - Parameter duration: Duración (se reduce significativamente en Reduce Motion)
    /// - Returns: EaseInOut animation adaptada
    @MainActor
    public static func accessibleEaseInOut(duration: Double = 0.3) -> Animation {
        if ReducedMotionSupport.isEnabled {
            // Reducir duración a 25% del original
            return .easeInOut(duration: duration * 0.25)
        } else {
            return .easeInOut(duration: duration)
        }
    }

    /// Animación easeOut accesible
    /// - Parameter duration: Duración (se reduce en Reduce Motion)
    /// - Returns: EaseOut animation adaptada
    @MainActor
    public static func accessibleEaseOut(duration: Double = 0.3) -> Animation {
        if ReducedMotionSupport.isEnabled {
            return .easeOut(duration: duration * 0.25)
        } else {
            return .easeOut(duration: duration)
        }
    }

    /// Animación easeIn accesible
    /// - Parameter duration: Duración (se reduce en Reduce Motion)
    /// - Returns: EaseIn animation adaptada
    @MainActor
    public static func accessibleEaseIn(duration: Double = 0.3) -> Animation {
        if ReducedMotionSupport.isEnabled {
            return .easeIn(duration: duration * 0.25)
        } else {
            return .easeIn(duration: duration)
        }
    }

    /// Animación linear accesible
    /// - Parameter duration: Duración (se reduce en Reduce Motion)
    /// - Returns: Linear animation adaptada
    @MainActor
    public static func accessibleLinear(duration: Double = 0.3) -> Animation {
        if ReducedMotionSupport.isEnabled {
            return .linear(duration: duration * 0.25)
        } else {
            return .linear(duration: duration)
        }
    }
}

// MARK: - Transition Extensions

extension AnyTransition {

    /// Transition accesible que adapta automáticamente según Reduce Motion
    /// - Parameters:
    ///   - normal: Transition para modo normal
    ///   - reduced: Transition para Reduce Motion (default: opacity)
    /// - Returns: Transition adaptada
    @MainActor
    public static func accessible(
        normal: AnyTransition,
        reduced: AnyTransition = .opacity
    ) -> AnyTransition {
        if ReducedMotionSupport.isEnabled {
            return reduced
        } else {
            return normal
        }
    }

    /// Slide transition accesible (se convierte en fade si Reduce Motion)
    /// - Parameter edge: Edge desde donde hacer slide
    /// - Returns: Slide o opacity según preferencia
    @MainActor
    public static func accessibleSlide(from edge: Edge) -> AnyTransition {
        if ReducedMotionSupport.isEnabled {
            return .opacity
        } else {
            return .move(edge: edge)
        }
    }

    /// Scale transition accesible (se convierte en fade si Reduce Motion)
    /// - Parameter scale: Factor de scale
    /// - Returns: Scale o opacity según preferencia
    @MainActor
    public static func accessibleScale(scale: CGFloat = 0.8) -> AnyTransition {
        if ReducedMotionSupport.isEnabled {
            return .opacity
        } else {
            return .scale(scale: scale).combined(with: .opacity)
        }
    }

    /// Push transition accesible (se convierte en fade si Reduce Motion)
    /// - Parameter edge: Edge desde donde hacer push
    /// - Returns: Push o opacity según preferencia
    @MainActor
    public static func accessiblePush(from edge: Edge) -> AnyTransition {
        if ReducedMotionSupport.isEnabled {
            return .opacity
        } else {
            return .push(from: edge)
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Aplica una animación que se adapta automáticamente a Reduce Motion
    /// - Parameters:
    ///   - animation: Animación a aplicar
    ///   - value: Valor que dispara la animación
    /// - Returns: View con animación adaptada
    @MainActor
    public func accessibleAnimation<V: Equatable>(
        _ animation: Animation,
        value: V
    ) -> some View {
        self.animation(
            ReducedMotionSupport.isEnabled ? .easeOut(duration: 0.1) : animation,
            value: value
        )
    }

    /// Aplica una transición accesible
    /// - Parameters:
    ///   - normal: Transición para modo normal
    ///   - reduced: Transición para Reduce Motion (default: opacity)
    /// - Returns: View con transición adaptada
    @MainActor
    public func accessibleTransition(
        normal: AnyTransition,
        reduced: AnyTransition = .opacity
    ) -> some View {
        self.transition(
            ReducedMotionSupport.isEnabled ? reduced : normal
        )
    }
}

// MARK: - withAccessibleAnimation Helpers

/// Ejecuta un bloque con animación accesible
/// - Parameters:
///   - animation: Animación a usar (se adapta según Reduce Motion)
///   - body: Bloque a ejecutar
@MainActor
public func withAccessibleAnimation<Result>(
    _ animation: Animation = .default,
    _ body: () throws -> Result
) rethrows -> Result {
    let adaptedAnimation = ReducedMotionSupport.isEnabled
        ? .easeOut(duration: 0.1)
        : animation

    return try withAnimation(adaptedAnimation, body)
}

/// Ejecuta un bloque con animación accesible spring
/// - Parameters:
///   - response: Respuesta del spring
///   - dampingFraction: Damping fraction
///   - body: Bloque a ejecutar
@MainActor
public func withAccessibleSpring<Result>(
    response: Double = 0.55,
    dampingFraction: Double = 0.825,
    _ body: () throws -> Result
) rethrows -> Result {
    let animation: Animation = ReducedMotionSupport.isEnabled
        ? .easeOut(duration: 0.15)
        : .spring(response: response, dampingFraction: dampingFraction)

    return try withAnimation(animation, body)
}
