// EduVisualEffects.swift
// Effects
//
// Visual effects system for iOS 26+ and macOS 26+

import SwiftUI

// MARK: - Visual Effect Protocol

/// Protocol defining the contract for visual effects
@available(iOS 26.0, macOS 26.0, *)
public protocol EduVisualEffect: Sendable {
    func apply<Content: View>(to content: Content) -> AnyView
}

// MARK: - Visual Effect Style

/// Predefined visual effect styles
@available(iOS 26.0, macOS 26.0, *)
public enum EduVisualEffectStyle: String, CaseIterable, Sendable {
    case ultraThin
    case thin
    case regular
    case thick
    case ultraThick
    case chrome
    case material

    public var material: Material {
        switch self {
        case .ultraThin: return .ultraThinMaterial
        case .thin: return .thinMaterial
        case .regular: return .regularMaterial
        case .thick: return .thickMaterial
        case .ultraThick: return .ultraThickMaterial
        case .chrome: return .bar
        case .material: return .regularMaterial
        }
    }
}

// MARK: - Effect Shape

/// Shape options for visual effects
@available(iOS 26.0, macOS 26.0, *)
public enum EduEffectShape: Sendable {
    case rectangle
    case roundedRectangle(cornerRadius: CGFloat)
    case capsule
    case circle
    case custom(any Shape & Sendable)

    @ViewBuilder
    public func clipShape<Content: View>(_ content: Content) -> some View {
        switch self {
        case .rectangle:
            content.clipShape(Rectangle())
        case .roundedRectangle(let cornerRadius):
            content.clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        case .capsule:
            content.clipShape(Capsule())
        case .circle:
            content.clipShape(Circle())
        case .custom(let shape):
            content.clipShape(AnyShape(shape))
        }
    }
}

// MARK: - Modern Visual Effect

/// A modern implementation of visual effects using iOS 26+ features
@available(iOS 26.0, macOS 26.0, *)
public struct EduVisualEffectModern: EduVisualEffect {
    public let style: EduVisualEffectStyle
    public let shape: EduEffectShape
    public let opacity: Double
    public let intensity: Double

    public init(
        style: EduVisualEffectStyle = .regular,
        shape: EduEffectShape = .roundedRectangle(cornerRadius: 16),
        opacity: Double = 1.0,
        intensity: Double = 1.0
    ) {
        self.style = style
        self.shape = shape
        self.opacity = opacity
        self.intensity = intensity
    }

    public func apply<Content: View>(to content: Content) -> AnyView {
        AnyView(
            content
                .background {
                    shape.clipShape(
                        Rectangle()
                            .fill(style.material)
                            .opacity(opacity * intensity)
                    )
                }
        )
    }
}

// MARK: - Visual Effect Factory

/// Factory for creating visual effects
@available(iOS 26.0, macOS 26.0, *)
public enum EduVisualEffectFactory {
    public static func glass(
        cornerRadius: CGFloat = 16,
        opacity: Double = 0.8
    ) -> EduVisualEffectModern {
        EduVisualEffectModern(
            style: .thin,
            shape: .roundedRectangle(cornerRadius: cornerRadius),
            opacity: opacity
        )
    }

    public static func frosted(
        cornerRadius: CGFloat = 12
    ) -> EduVisualEffectModern {
        EduVisualEffectModern(
            style: .ultraThin,
            shape: .roundedRectangle(cornerRadius: cornerRadius),
            opacity: 0.9,
            intensity: 1.2
        )
    }

    public static func blur(
        intensity: Double = 1.0
    ) -> EduVisualEffectModern {
        EduVisualEffectModern(
            style: .regular,
            shape: .rectangle,
            opacity: 1.0,
            intensity: intensity
        )
    }

    public static func prominent(
        shape: EduEffectShape = .roundedRectangle(cornerRadius: 20)
    ) -> EduVisualEffectModern {
        EduVisualEffectModern(
            style: .thick,
            shape: shape,
            opacity: 0.95,
            intensity: 1.0
        )
    }
}

// MARK: - View Extension

@available(iOS 26.0, macOS 26.0, *)
public extension View {
    /// Applies a visual effect to the view
    func eduVisualEffect(_ effect: some EduVisualEffect) -> AnyView {
        effect.apply(to: self)
    }

    /// Applies a predefined visual effect style
    func eduVisualEffect(
        style: EduVisualEffectStyle,
        shape: EduEffectShape = .roundedRectangle(cornerRadius: 16),
        opacity: Double = 1.0
    ) -> AnyView {
        EduVisualEffectModern(
            style: style,
            shape: shape,
            opacity: opacity
        ).apply(to: self)
    }
}
