// EduShadow.swift
// Effects
//
// Shadow system for glass-aware components - iOS 26+ and macOS 26+

import SwiftUI

// MARK: - Shadow Level

/// Predefined shadow levels with consistent styling
@available(iOS 26.0, macOS 26.0, *)
public enum EduShadowLevel: String, CaseIterable, Sendable {
    case none
    case sm
    case md
    case lg
    case xl
    case xxl

    public var configuration: EduShadowConfiguration {
        switch self {
        case .none:
            return EduShadowConfiguration(color: .clear, radius: 0, x: 0, y: 0)
        case .sm:
            return EduShadowConfiguration(
                color: .black.opacity(0.05),
                radius: 2,
                x: 0,
                y: 1
            )
        case .md:
            return EduShadowConfiguration(
                color: .black.opacity(0.1),
                radius: 4,
                x: 0,
                y: 2
            )
        case .lg:
            return EduShadowConfiguration(
                color: .black.opacity(0.15),
                radius: 8,
                x: 0,
                y: 4
            )
        case .xl:
            return EduShadowConfiguration(
                color: .black.opacity(0.2),
                radius: 16,
                x: 0,
                y: 8
            )
        case .xxl:
            return EduShadowConfiguration(
                color: .black.opacity(0.25),
                radius: 24,
                x: 0,
                y: 12
            )
        }
    }
}

// MARK: - Shadow Configuration

/// Configuration for shadow effects
@available(iOS 26.0, macOS 26.0, *)
public struct EduShadowConfiguration: Sendable, Equatable {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat

    public init(
        color: Color,
        radius: CGFloat,
        x: CGFloat = 0,
        y: CGFloat = 0
    ) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }

    /// Creates a glass-aware shadow configuration
    public static func glassAware(
        level: EduShadowLevel,
        glassIntensity: EduLiquidGlassIntensity
    ) -> EduShadowConfiguration {
        let base = level.configuration
        let multiplier = glassAwareMultiplier(for: glassIntensity)

        return EduShadowConfiguration(
            color: base.color.opacity(multiplier),
            radius: base.radius * multiplier,
            x: base.x,
            y: base.y * multiplier
        )
    }

    private static func glassAwareMultiplier(
        for intensity: EduLiquidGlassIntensity
    ) -> Double {
        switch intensity {
        case .subtle: return 0.6
        case .standard: return 0.8
        case .prominent: return 1.0
        case .immersive: return 1.2
        case .desktop: return 0.7
        }
    }
}

// MARK: - Glass Aware Shadow Modifier

/// Modifier that applies glass-aware shadows
@available(iOS 26.0, macOS 26.0, *)
public struct EduGlassAwareShadowModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    public let level: EduShadowLevel
    public let glassIntensity: EduLiquidGlassIntensity?

    public init(
        level: EduShadowLevel,
        glassIntensity: EduLiquidGlassIntensity? = nil
    ) {
        self.level = level
        self.glassIntensity = glassIntensity
    }

    public func body(content: Content) -> some View {
        let config = effectiveConfiguration

        content
            .shadow(
                color: adjustedColor(config.color),
                radius: config.radius,
                x: config.x,
                y: config.y
            )
    }

    private var effectiveConfiguration: EduShadowConfiguration {
        if let glassIntensity {
            return .glassAware(level: level, glassIntensity: glassIntensity)
        }
        return level.configuration
    }

    private func adjustedColor(_ color: Color) -> Color {
        colorScheme == .dark
            ? color.opacity(0.7)
            : color
    }
}

// MARK: - Layered Shadow Modifier

/// Modifier that applies multiple layered shadows for depth
@available(iOS 26.0, macOS 26.0, *)
public struct EduLayeredShadowModifier: ViewModifier {
    public let levels: [EduShadowLevel]

    public init(levels: [EduShadowLevel]) {
        self.levels = levels
    }

    public func body(content: Content) -> some View {
        levels.reduce(AnyView(content)) { view, level in
            let config = level.configuration
            return AnyView(
                view.shadow(
                    color: config.color,
                    radius: config.radius,
                    x: config.x,
                    y: config.y
                )
            )
        }
    }
}

// MARK: - Elevation Modifier

/// Modifier that creates elevation effect with combined shadow and scale
@available(iOS 26.0, macOS 26.0, *)
public struct EduElevationModifier: ViewModifier {
    @Binding public var isElevated: Bool

    public let elevatedLevel: EduShadowLevel
    public let restingLevel: EduShadowLevel
    public let scaleAmount: CGFloat

    public init(
        isElevated: Binding<Bool>,
        elevatedLevel: EduShadowLevel = .lg,
        restingLevel: EduShadowLevel = .sm,
        scaleAmount: CGFloat = 1.02
    ) {
        self._isElevated = isElevated
        self.elevatedLevel = elevatedLevel
        self.restingLevel = restingLevel
        self.scaleAmount = scaleAmount
    }

    public func body(content: Content) -> some View {
        let config = isElevated
            ? elevatedLevel.configuration
            : restingLevel.configuration

        content
            .scaleEffect(isElevated ? scaleAmount : 1.0)
            .shadow(
                color: config.color,
                radius: config.radius,
                x: config.x,
                y: config.y
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isElevated)
    }
}

// MARK: - View Extensions

@available(iOS 26.0, macOS 26.0, *)
public extension View {
    /// Applies a shadow with a predefined level
    func eduShadow(_ level: EduShadowLevel) -> some View {
        let config = level.configuration
        return shadow(
            color: config.color,
            radius: config.radius,
            x: config.x,
            y: config.y
        )
    }

    /// Applies a glass-aware shadow
    func eduGlassAwareShadow(
        level: EduShadowLevel,
        glassIntensity: EduLiquidGlassIntensity? = nil
    ) -> some View {
        modifier(EduGlassAwareShadowModifier(
            level: level,
            glassIntensity: glassIntensity
        ))
    }

    /// Applies layered shadows for enhanced depth
    func eduLayeredShadow(_ levels: EduShadowLevel...) -> some View {
        modifier(EduLayeredShadowModifier(levels: levels))
    }

    /// Applies elevation effect with interactive state
    func eduElevation(
        isElevated: Binding<Bool>,
        elevated: EduShadowLevel = .lg,
        resting: EduShadowLevel = .sm,
        scale: CGFloat = 1.02
    ) -> some View {
        modifier(EduElevationModifier(
            isElevated: isElevated,
            elevatedLevel: elevated,
            restingLevel: resting,
            scaleAmount: scale
        ))
    }
}
