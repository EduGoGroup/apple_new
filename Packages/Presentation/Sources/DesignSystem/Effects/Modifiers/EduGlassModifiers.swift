// EduGlassModifiers.swift
// Effects
//
// Glass effect modifiers for iOS 26+ and macOS 26+

import SwiftUI

// MARK: - Glass Adaptive Modifier

/// Modifier that adapts glass effects based on environment
@available(iOS 26.0, macOS 26.0, *)
public struct EduGlassAdaptiveModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    public let intensity: EduLiquidGlassIntensity
    public let cornerRadius: CGFloat

    public init(
        intensity: EduLiquidGlassIntensity = .standard,
        cornerRadius: CGFloat = 16
    ) {
        self.intensity = intensity
        self.cornerRadius = cornerRadius
    }

    public func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .opacity(adaptiveOpacity)
                    .saturation(intensity.saturation)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private var adaptiveOpacity: Double {
        colorScheme == .dark
            ? intensity.opacity * 0.9
            : intensity.opacity
    }
}

// MARK: - Glass Depth Mapping Modifier

/// Modifier that creates depth perception in glass effects
@available(iOS 26.0, macOS 26.0, *)
public struct EduGlassDepthMappingModifier: ViewModifier {
    public let depth: CGFloat
    public let cornerRadius: CGFloat

    public init(depth: CGFloat = 4, cornerRadius: CGFloat = 16) {
        self.depth = depth
        self.cornerRadius = cornerRadius
    }

    public func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    // Back layer - darker, offset
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                        .opacity(0.3)
                        .offset(y: depth)

                    // Front layer - main glass
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.thinMaterial)
                        .opacity(0.8)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Glass Refraction Modifier

/// Modifier that simulates light refraction through glass
@available(iOS 26.0, macOS 26.0, *)
public struct EduGlassRefractionModifier: ViewModifier {
    public let refractionAmount: Double
    public let cornerRadius: CGFloat

    public init(refractionAmount: Double = 0.5, cornerRadius: CGFloat = 16) {
        self.refractionAmount = refractionAmount
        self.cornerRadius = cornerRadius
    }

    public func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.thinMaterial)
                    .overlay {
                        LinearGradient(
                            colors: [
                                .white.opacity(0.3 * refractionAmount),
                                .clear,
                                .white.opacity(0.1 * refractionAmount)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Liquid Animation Modifier

/// Modifier that applies liquid-like animations to glass
@available(iOS 26.0, macOS 26.0, *)
public struct EduLiquidAnimationModifier: ViewModifier {
    public let animationStyle: EduLiquidAnimation
    @Binding public var isActive: Bool

    public init(style: EduLiquidAnimation, isActive: Binding<Bool>) {
        self.animationStyle = style
        self._isActive = isActive
    }

    public func body(content: Content) -> some View {
        content
            .scaleEffect(isActive ? 1.02 : 1.0)
            .animation(animationStyle.animation, value: isActive)
    }
}

// MARK: - Glass State Modifier

/// Modifier that handles interactive state changes for glass elements
@available(iOS 26.0, macOS 26.0, *)
public struct EduGlassStateModifier: ViewModifier {
    @Binding public var state: EduGlassState
    public let cornerRadius: CGFloat

    public init(state: Binding<EduGlassState>, cornerRadius: CGFloat = 16) {
        self._state = state
        self.cornerRadius = cornerRadius
    }

    public func body(content: Content) -> some View {
        content
            .scaleEffect(state.scale)
            .opacity(state.opacityMultiplier)
            .shadow(
                color: .black.opacity(0.1 * state.shadowMultiplier),
                radius: 8 * state.shadowMultiplier,
                y: 4 * state.shadowMultiplier
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: state)
    }
}

// MARK: - macOS Specific Modifiers

#if os(macOS)

/// Optimized glass effect for macOS desktop windows
@available(macOS 26.0, *)
public struct EduGlassDesktopOptimizedModifier: ViewModifier {
    @Environment(\.controlActiveState) private var controlActiveState

    public let cornerRadius: CGFloat

    public init(cornerRadius: CGFloat = 12) {
        self.cornerRadius = cornerRadius
    }

    public func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.regularMaterial)
                    .opacity(controlActiveState == .key ? 1.0 : 0.8)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

/// Mouse tracking modifier for hover effects on glass
@available(macOS 26.0, *)
public struct EduGlassMouseTrackingModifier: ViewModifier {
    @State private var isHovered = false

    public let cornerRadius: CGFloat
    public let hoverScale: CGFloat

    public init(cornerRadius: CGFloat = 12, hoverScale: CGFloat = 1.01) {
        self.cornerRadius = cornerRadius
        self.hoverScale = hoverScale
    }

    public func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? hoverScale : 1.0)
            .onHover { hovering in
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    isHovered = hovering
                }
            }
    }
}

/// Window vibrancy modifier for native macOS appearance
@available(macOS 26.0, *)
public struct EduGlassWindowVibrancyModifier: ViewModifier {
    public let material: Material

    public init(material: Material = .regularMaterial) {
        self.material = material
    }

    public func body(content: Content) -> some View {
        content
            .background(material)
    }
}

#endif

// MARK: - View Extensions

@available(iOS 26.0, macOS 26.0, *)
public extension View {
    /// Applies adaptive glass effect
    func eduGlassAdaptive(
        intensity: EduLiquidGlassIntensity = .standard,
        cornerRadius: CGFloat = 16
    ) -> some View {
        modifier(EduGlassAdaptiveModifier(
            intensity: intensity,
            cornerRadius: cornerRadius
        ))
    }

    /// Applies glass depth mapping effect
    func eduGlassDepth(
        depth: CGFloat = 4,
        cornerRadius: CGFloat = 16
    ) -> some View {
        modifier(EduGlassDepthMappingModifier(
            depth: depth,
            cornerRadius: cornerRadius
        ))
    }

    /// Applies glass refraction effect
    func eduGlassRefraction(
        amount: Double = 0.5,
        cornerRadius: CGFloat = 16
    ) -> some View {
        modifier(EduGlassRefractionModifier(
            refractionAmount: amount,
            cornerRadius: cornerRadius
        ))
    }

    /// Applies liquid animation to the view
    func eduLiquidAnimation(
        style: EduLiquidAnimation,
        isActive: Binding<Bool>
    ) -> some View {
        modifier(EduLiquidAnimationModifier(style: style, isActive: isActive))
    }

    /// Applies interactive glass state handling
    func eduGlassState(
        _ state: Binding<EduGlassState>,
        cornerRadius: CGFloat = 16
    ) -> some View {
        modifier(EduGlassStateModifier(state: state, cornerRadius: cornerRadius))
    }
}

#if os(macOS)
@available(macOS 26.0, *)
public extension View {
    /// Applies desktop-optimized glass effect
    func eduGlassDesktop(cornerRadius: CGFloat = 12) -> some View {
        modifier(EduGlassDesktopOptimizedModifier(cornerRadius: cornerRadius))
    }

    /// Applies mouse tracking with hover effects
    func eduGlassMouseTracking(
        cornerRadius: CGFloat = 12,
        hoverScale: CGFloat = 1.01
    ) -> some View {
        modifier(EduGlassMouseTrackingModifier(
            cornerRadius: cornerRadius,
            hoverScale: hoverScale
        ))
    }

    /// Applies window vibrancy effect
    func eduGlassVibrancy(material: Material = .regularMaterial) -> some View {
        modifier(EduGlassWindowVibrancyModifier(material: material))
    }
}
#endif
