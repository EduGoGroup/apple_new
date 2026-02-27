//
//  ScalingMetrics.swift
//  EduAccessibility
//
//  Provides adaptive metrics that scale with Dynamic Type to maintain
//  consistent visual proportions across all size categories.
//
//  Features:
//  - Predefined spacing, padding, corner radius, icon sizes, and border widths
//  - Automatic scaling with appropriate curves for each metric type
//  - Environment integration for reactive updates
//  - Minimum touch target calculations (44pt standard, 48pt accessibility)
//
//  Scaling strategies:
//  - Spacing/Padding: Logarithmic curve (moderate growth)
//  - Corner Radius: Clamped curve (limited growth)
//  - Icon Sizes: Linear curve (proportional growth)
//  - Border Width: Stepped curve (discrete increments)
//
//  Swift 6.2 strict concurrency compliant
//

import SwiftUI

/// Proporciona métricas adaptativas que escalan con Dynamic Type
/// para mantener proporciones visuales coherentes.
public struct ScalingMetrics: Sendable {

    // MARK: - Spacing

    /// Espaciado extra pequeño (base: 4pt)
    public static let spacingXS: CGFloat = 4

    /// Espaciado pequeño (base: 8pt)
    public static let spacingSM: CGFloat = 8

    /// Espaciado mediano (base: 12pt)
    public static let spacingMD: CGFloat = 12

    /// Espaciado grande (base: 16pt)
    public static let spacingLG: CGFloat = 16

    /// Espaciado extra grande (base: 24pt)
    public static let spacingXL: CGFloat = 24

    /// Espaciado extra extra grande (base: 32pt)
    public static let spacing2XL: CGFloat = 32

    /// Espaciado extra extra extra grande (base: 48pt)
    public static let spacing3XL: CGFloat = 48

    // MARK: - Padding

    /// Padding extra pequeño (base: 4pt)
    public static let paddingXS: CGFloat = 4

    /// Padding pequeño (base: 8pt)
    public static let paddingSM: CGFloat = 8

    /// Padding mediano (base: 12pt)
    public static let paddingMD: CGFloat = 12

    /// Padding grande (base: 16pt)
    public static let paddingLG: CGFloat = 16

    /// Padding extra grande (base: 24pt)
    public static let paddingXL: CGFloat = 24

    /// Padding extra extra grande (base: 32pt)
    public static let padding2XL: CGFloat = 32

    // MARK: - Corner Radius

    /// Radio de esquina extra pequeño (base: 4pt)
    public static let cornerRadiusXS: CGFloat = 4

    /// Radio de esquina pequeño (base: 8pt)
    public static let cornerRadiusSM: CGFloat = 8

    /// Radio de esquina mediano (base: 12pt)
    public static let cornerRadiusMD: CGFloat = 12

    /// Radio de esquina grande (base: 16pt)
    public static let cornerRadiusLG: CGFloat = 16

    /// Radio de esquina extra grande (base: 20pt)
    public static let cornerRadiusXL: CGFloat = 20

    /// Radio de esquina extra extra grande (base: 24pt)
    public static let cornerRadius2XL: CGFloat = 24

    // MARK: - Icon Sizes

    /// Tamaño de icono extra pequeño (base: 12pt)
    public static let iconXS: CGFloat = 12

    /// Tamaño de icono pequeño (base: 16pt)
    public static let iconSM: CGFloat = 16

    /// Tamaño de icono mediano (base: 20pt)
    public static let iconMD: CGFloat = 20

    /// Tamaño de icono grande (base: 24pt)
    public static let iconLG: CGFloat = 24

    /// Tamaño de icono extra grande (base: 32pt)
    public static let iconXL: CGFloat = 32

    /// Tamaño de icono extra extra grande (base: 48pt)
    public static let icon2XL: CGFloat = 48

    // MARK: - Border Width

    /// Ancho de borde fino (base: 1pt)
    public static let borderThin: CGFloat = 1

    /// Ancho de borde mediano (base: 2pt)
    public static let borderMedium: CGFloat = 2

    /// Ancho de borde grueso (base: 3pt)
    public static let borderThick: CGFloat = 3

    // MARK: - Minimum Touch Target

    /// Tamaño mínimo de touch target según HIG (44pt)
    public static let minTouchTarget: CGFloat = 44

    /// Tamaño mínimo de touch target para accesibilidad (48pt)
    public static let minAccessibilityTouchTarget: CGFloat = 48

    // MARK: - Scaling Functions

    /// Escala un valor de spacing según la categoría de tamaño
    /// - Parameters:
    ///   - baseSpacing: Valor base de spacing
    ///   - sizeCategory: Categoría de tamaño actual
    /// - Returns: Valor escalado usando curva logarítmica (crece menos agresivamente)
    public static func scaledSpacing(
        _ baseSpacing: CGFloat,
        for sizeCategory: ContentSizeCategory
    ) -> CGFloat {
        DynamicTypeSupport.scaled(baseSpacing, for: sizeCategory, curve: .logarithmic)
    }

    /// Escala un valor de padding según la categoría de tamaño
    /// - Parameters:
    ///   - basePadding: Valor base de padding
    ///   - sizeCategory: Categoría de tamaño actual
    /// - Returns: Valor escalado usando curva logarítmica
    public static func scaledPadding(
        _ basePadding: CGFloat,
        for sizeCategory: ContentSizeCategory
    ) -> CGFloat {
        DynamicTypeSupport.scaled(basePadding, for: sizeCategory, curve: .logarithmic)
    }

    /// Escala un corner radius según la categoría de tamaño
    /// - Parameters:
    ///   - baseRadius: Valor base del radio
    ///   - sizeCategory: Categoría de tamaño actual
    /// - Returns: Valor escalado usando curva clamped (con límites)
    public static func scaledCornerRadius(
        _ baseRadius: CGFloat,
        for sizeCategory: ContentSizeCategory
    ) -> CGFloat {
        let maxRadius = baseRadius * 1.5  // No crece más del 150%
        return DynamicTypeSupport.scaled(
            baseRadius,
            for: sizeCategory,
            curve: .clamped(min: baseRadius * 0.8, max: maxRadius)
        )
    }

    /// Escala un tamaño de icono según la categoría de tamaño
    /// - Parameters:
    ///   - baseSize: Tamaño base del icono
    ///   - sizeCategory: Categoría de tamaño actual
    /// - Returns: Tamaño escalado usando curva lineal
    public static func scaledIconSize(
        _ baseSize: CGFloat,
        for sizeCategory: ContentSizeCategory
    ) -> CGFloat {
        DynamicTypeSupport.scaled(baseSize, for: sizeCategory, curve: .linear)
    }

    /// Escala un ancho de borde según la categoría de tamaño
    /// - Parameters:
    ///   - baseWidth: Ancho base del borde
    ///   - sizeCategory: Categoría de tamaño actual
    /// - Returns: Ancho escalado por pasos discretos (1pt, 2pt, 3pt)
    public static func scaledBorderWidth(
        _ baseWidth: CGFloat,
        for sizeCategory: ContentSizeCategory
    ) -> CGFloat {
        let steps: [CGFloat] = [1.0, 1.0, 1.0, 1.0, 1.5, 1.5, 2.0, 2.0, 2.5, 2.5, 3.0, 3.0]
        return DynamicTypeSupport.scaled(baseWidth, for: sizeCategory, curve: .stepped(steps))
    }

    /// Calcula el tamaño mínimo de touch target según la categoría de tamaño
    /// - Parameter sizeCategory: Categoría de tamaño actual
    /// - Returns: Tamaño mínimo recomendado para touch targets
    public static func minimumTouchTarget(for sizeCategory: ContentSizeCategory) -> CGFloat {
        if DynamicTypeSupport.isAccessibilityCategory(sizeCategory) {
            return minAccessibilityTouchTarget
        }
        return minTouchTarget
    }
}

// MARK: - Environment Integration

/// Environment key para almacenar métricas de escalado
public struct ScalingMetricsKey: EnvironmentKey {
    public static let defaultValue = ScalingMetricsEnvironment()
}

extension EnvironmentValues {
    /// Métricas de escalado actuales basadas en el tamaño de categoría
    public var scalingMetrics: ScalingMetricsEnvironment {
        get { self[ScalingMetricsKey.self] }
        set { self[ScalingMetricsKey.self] = newValue }
    }
}

/// Environment wrapper para métricas de escalado
public struct ScalingMetricsEnvironment: Sendable {
    public let sizeCategory: ContentSizeCategory

    public init(sizeCategory: ContentSizeCategory = .large) {
        self.sizeCategory = sizeCategory
    }

    // MARK: - Computed Scaled Values

    public var spacingXS: CGFloat {
        ScalingMetrics.scaledSpacing(ScalingMetrics.spacingXS, for: sizeCategory)
    }

    public var spacingSM: CGFloat {
        ScalingMetrics.scaledSpacing(ScalingMetrics.spacingSM, for: sizeCategory)
    }

    public var spacingMD: CGFloat {
        ScalingMetrics.scaledSpacing(ScalingMetrics.spacingMD, for: sizeCategory)
    }

    public var spacingLG: CGFloat {
        ScalingMetrics.scaledSpacing(ScalingMetrics.spacingLG, for: sizeCategory)
    }

    public var spacingXL: CGFloat {
        ScalingMetrics.scaledSpacing(ScalingMetrics.spacingXL, for: sizeCategory)
    }

    public var spacing2XL: CGFloat {
        ScalingMetrics.scaledSpacing(ScalingMetrics.spacing2XL, for: sizeCategory)
    }

    public var spacing3XL: CGFloat {
        ScalingMetrics.scaledSpacing(ScalingMetrics.spacing3XL, for: sizeCategory)
    }

    public var paddingXS: CGFloat {
        ScalingMetrics.scaledPadding(ScalingMetrics.paddingXS, for: sizeCategory)
    }

    public var paddingSM: CGFloat {
        ScalingMetrics.scaledPadding(ScalingMetrics.paddingSM, for: sizeCategory)
    }

    public var paddingMD: CGFloat {
        ScalingMetrics.scaledPadding(ScalingMetrics.paddingMD, for: sizeCategory)
    }

    public var paddingLG: CGFloat {
        ScalingMetrics.scaledPadding(ScalingMetrics.paddingLG, for: sizeCategory)
    }

    public var paddingXL: CGFloat {
        ScalingMetrics.scaledPadding(ScalingMetrics.paddingXL, for: sizeCategory)
    }

    public var padding2XL: CGFloat {
        ScalingMetrics.scaledPadding(ScalingMetrics.padding2XL, for: sizeCategory)
    }

    public var cornerRadiusXS: CGFloat {
        ScalingMetrics.scaledCornerRadius(ScalingMetrics.cornerRadiusXS, for: sizeCategory)
    }

    public var cornerRadiusSM: CGFloat {
        ScalingMetrics.scaledCornerRadius(ScalingMetrics.cornerRadiusSM, for: sizeCategory)
    }

    public var cornerRadiusMD: CGFloat {
        ScalingMetrics.scaledCornerRadius(ScalingMetrics.cornerRadiusMD, for: sizeCategory)
    }

    public var cornerRadiusLG: CGFloat {
        ScalingMetrics.scaledCornerRadius(ScalingMetrics.cornerRadiusLG, for: sizeCategory)
    }

    public var cornerRadiusXL: CGFloat {
        ScalingMetrics.scaledCornerRadius(ScalingMetrics.cornerRadiusXL, for: sizeCategory)
    }

    public var cornerRadius2XL: CGFloat {
        ScalingMetrics.scaledCornerRadius(ScalingMetrics.cornerRadius2XL, for: sizeCategory)
    }

    public var iconXS: CGFloat {
        ScalingMetrics.scaledIconSize(ScalingMetrics.iconXS, for: sizeCategory)
    }

    public var iconSM: CGFloat {
        ScalingMetrics.scaledIconSize(ScalingMetrics.iconSM, for: sizeCategory)
    }

    public var iconMD: CGFloat {
        ScalingMetrics.scaledIconSize(ScalingMetrics.iconMD, for: sizeCategory)
    }

    public var iconLG: CGFloat {
        ScalingMetrics.scaledIconSize(ScalingMetrics.iconLG, for: sizeCategory)
    }

    public var iconXL: CGFloat {
        ScalingMetrics.scaledIconSize(ScalingMetrics.iconXL, for: sizeCategory)
    }

    public var icon2XL: CGFloat {
        ScalingMetrics.scaledIconSize(ScalingMetrics.icon2XL, for: sizeCategory)
    }

    public var minTouchTarget: CGFloat {
        ScalingMetrics.minimumTouchTarget(for: sizeCategory)
    }
}

// MARK: - View Extensions

extension View {
    /// Inyecta las métricas de escalado en el environment
    /// - Parameter sizeCategory: Categoría de tamaño a usar
    /// - Returns: Vista con métricas de escalado configuradas
    public func withScalingMetrics(_ sizeCategory: ContentSizeCategory) -> some View {
        environment(\.scalingMetrics, ScalingMetricsEnvironment(sizeCategory: sizeCategory))
    }
}
