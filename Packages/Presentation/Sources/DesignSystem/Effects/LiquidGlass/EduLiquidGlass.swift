// EduLiquidGlass.swift
// Effects
//
// Liquid Glass effects system for iOS 26+ and macOS 26+

import SwiftUI

// MARK: - Liquid Glass Intensity

/// Defines the intensity levels for liquid glass effects
@available(iOS 26.0, macOS 26.0, *)
public enum EduLiquidGlassIntensity: String, CaseIterable, Sendable {
    case subtle
    case standard
    case prominent
    case immersive
    case desktop

    public var blurRadius: CGFloat {
        switch self {
        case .subtle: return 8
        case .standard: return 16
        case .prominent: return 24
        case .immersive: return 32
        case .desktop: return 12
        }
    }

    public var opacity: Double {
        switch self {
        case .subtle: return 0.6
        case .standard: return 0.75
        case .prominent: return 0.85
        case .immersive: return 0.92
        case .desktop: return 0.8
        }
    }

    public var saturation: Double {
        switch self {
        case .subtle: return 1.2
        case .standard: return 1.4
        case .prominent: return 1.6
        case .immersive: return 1.8
        case .desktop: return 1.3
        }
    }
}

// MARK: - Liquid Animation

/// Animation styles for liquid glass transitions
@available(iOS 26.0, macOS 26.0, *)
public enum EduLiquidAnimation: Sendable {
    case smooth
    case ripple
    case pour
    case wave
    case morph

    public var animation: Animation {
        switch self {
        case .smooth:
            return .smooth(duration: 0.3)
        case .ripple:
            return .spring(response: 0.4, dampingFraction: 0.7)
        case .pour:
            return .easeInOut(duration: 0.5)
        case .wave:
            return .spring(response: 0.5, dampingFraction: 0.6)
        case .morph:
            return .spring(response: 0.35, dampingFraction: 0.8)
        }
    }
}

// MARK: - Glass State

/// Represents the interactive state of a glass element
@available(iOS 26.0, macOS 26.0, *)
public enum EduGlassState: String, CaseIterable, Sendable {
    case normal
    case hovered
    case focused
    case pressed
    case disabled

    public var scale: CGFloat {
        switch self {
        case .normal: return 1.0
        case .hovered: return 1.02
        case .focused: return 1.0
        case .pressed: return 0.98
        case .disabled: return 1.0
        }
    }

    public var opacityMultiplier: Double {
        switch self {
        case .normal: return 1.0
        case .hovered: return 1.1
        case .focused: return 1.05
        case .pressed: return 0.95
        case .disabled: return 0.5
        }
    }

    public var shadowMultiplier: Double {
        switch self {
        case .normal: return 1.0
        case .hovered: return 1.3
        case .focused: return 1.2
        case .pressed: return 0.7
        case .disabled: return 0.3
        }
    }
}

// MARK: - Liquid Transition Style

/// Defines transition styles for liquid glass effects
@available(iOS 26.0, macOS 26.0, *)
public enum EduLiquidTransitionStyle: Sendable {
    case fade
    case slide(edge: Edge)
    case scale
    case liquid
    case dissolve

    public func transition() -> AnyTransition {
        switch self {
        case .fade:
            return .opacity
        case .slide(let edge):
            return .move(edge: edge).combined(with: .opacity)
        case .scale:
            return .scale.combined(with: .opacity)
        case .liquid:
            return .asymmetric(
                insertion: .scale(scale: 0.8).combined(with: .opacity),
                removal: .scale(scale: 1.1).combined(with: .opacity)
            )
        case .dissolve:
            return .opacity.animation(.easeInOut(duration: 0.4))
        }
    }
}

// MARK: - Liquid Glass Configuration

/// Configuration for liquid glass effects
@available(iOS 26.0, macOS 26.0, *)
public struct EduLiquidGlassConfiguration: Sendable {
    public let intensity: EduLiquidGlassIntensity
    public let animation: EduLiquidAnimation
    public let cornerRadius: CGFloat
    public let borderWidth: CGFloat
    public let borderOpacity: Double

    public init(
        intensity: EduLiquidGlassIntensity = .standard,
        animation: EduLiquidAnimation = .smooth,
        cornerRadius: CGFloat = 16,
        borderWidth: CGFloat = 0.5,
        borderOpacity: Double = 0.2
    ) {
        self.intensity = intensity
        self.animation = animation
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.borderOpacity = borderOpacity
    }

    public static let `default` = EduLiquidGlassConfiguration()
    public static let subtle = EduLiquidGlassConfiguration(intensity: .subtle)
    public static let prominent = EduLiquidGlassConfiguration(intensity: .prominent)
    public static let immersive = EduLiquidGlassConfiguration(intensity: .immersive)
    public static let desktop = EduLiquidGlassConfiguration(intensity: .desktop)
}

// MARK: - View Extension

@available(iOS 26.0, macOS 26.0, *)
public extension View {
    /// Applies a liquid glass effect to the view
    func eduLiquidGlass(
        configuration: EduLiquidGlassConfiguration = .default
    ) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: configuration.cornerRadius)
                    .fill(.ultraThinMaterial)
                    .opacity(configuration.intensity.opacity)
                    .saturation(configuration.intensity.saturation)
            }
            .clipShape(RoundedRectangle(cornerRadius: configuration.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: configuration.cornerRadius)
                    .strokeBorder(
                        .white.opacity(configuration.borderOpacity),
                        lineWidth: configuration.borderWidth
                    )
            }
    }

    /// Applies liquid glass with a specific intensity
    func eduLiquidGlass(
        intensity: EduLiquidGlassIntensity,
        cornerRadius: CGFloat = 16
    ) -> some View {
        eduLiquidGlass(
            configuration: EduLiquidGlassConfiguration(
                intensity: intensity,
                cornerRadius: cornerRadius
            )
        )
    }
}
