//
//  DynamicTypeSupport.swift
//  EduAccessibility
//
//  Provides comprehensive Dynamic Type support with adaptive scaling curves.
//  Enables text and UI elements to scale automatically based on user preferences,
//  with multiple scaling strategies (linear, logarithmic, exponential, stepped, clamped).
//
//  Features:
//  - Text style to base size mapping
//  - Scaled font creation (system and custom)
//  - Multiple scaling curves for different use cases
//  - Size category detection and classification
//  - Alternative layout recommendations
//
//  Swift 6.2 strict concurrency compliant
//

import SwiftUI

/// Proporciona soporte completo para Dynamic Type con escalado adaptativo
/// y curvas de escalado personalizadas.
public struct DynamicTypeSupport: Sendable {

    // MARK: - Text Style Mapping

    /// Mapea estilos de texto de SwiftUI a tamaños base
    public static func baseSize(for textStyle: Font.TextStyle) -> CGFloat {
        switch textStyle {
        case .largeTitle: return 34
        case .title: return 28
        case .title2: return 22
        case .title3: return 20
        case .headline: return 17
        case .body: return 17
        case .callout: return 16
        case .subheadline: return 15
        case .footnote: return 13
        case .caption: return 12
        case .caption2: return 11
        @unknown default: return 17
        }
    }

    // MARK: - Font Scaling

    /// Crea una fuente que escala automáticamente con Dynamic Type
    /// - Parameters:
    ///   - textStyle: El estilo de texto de SwiftUI
    ///   - weight: El peso de la fuente
    ///   - design: El diseño de la fuente
    /// - Returns: Una fuente que responde a Dynamic Type
    public static func scaledFont(
        _ textStyle: Font.TextStyle,
        weight: Font.Weight = .regular,
        design: Font.Design = .default
    ) -> Font {
        return Font.system(textStyle, design: design, weight: weight)
    }

    /// Crea una fuente personalizada que escala con Dynamic Type
    /// - Parameters:
    ///   - name: Nombre de la fuente personalizada
    ///   - textStyle: Estilo de texto de referencia para el escalado
    ///   - relativeTo: Tamaño relativo al estilo base
    /// - Returns: Una fuente personalizada que escala automáticamente
    public static func scaledCustomFont(
        _ name: String,
        textStyle: Font.TextStyle,
        relativeTo: CGFloat = 1.0
    ) -> Font {
        let baseSize = baseSize(for: textStyle)
        return Font.custom(name, size: baseSize * relativeTo, relativeTo: textStyle)
    }

    // MARK: - Scaling Curves

    /// Aplica una curva de escalado personalizada a un valor
    /// - Parameters:
    ///   - baseValue: Valor base sin escalar
    ///   - sizeCategory: Categoría de tamaño actual
    ///   - curve: Tipo de curva de escalado
    /// - Returns: Valor escalado según la curva
    public static func scaled(
        _ baseValue: CGFloat,
        for sizeCategory: ContentSizeCategory,
        curve: ScalingCurve = .linear
    ) -> CGFloat {
        let scaleFactor = scaleFactor(for: sizeCategory)

        switch curve {
        case .linear:
            return baseValue * scaleFactor

        case .logarithmic:
            // Escalado logarítmico: crece más lento en tamaños grandes
            let logScale = 1.0 + log(scaleFactor) / log(2.0)
            return baseValue * logScale

        case .exponential:
            // Escalado exponencial: crece más rápido en tamaños grandes
            let expScale = pow(scaleFactor, 1.2)
            return baseValue * expScale

        case .stepped(let steps):
            // Escalado por pasos discretos
            let stepIndex = min(Int((scaleFactor - 1.0) * CGFloat(steps.count)), steps.count - 1)
            return baseValue * steps[max(0, stepIndex)]

        case .clamped(let min, let max):
            // Escalado con límites mínimo y máximo
            let scaled = baseValue * scaleFactor
            return Swift.max(min, Swift.min(max, scaled))
        }
    }

    /// Factor de escalado para una categoría de tamaño
    private static func scaleFactor(for sizeCategory: ContentSizeCategory) -> CGFloat {
        switch sizeCategory {
        case .extraSmall: return 0.82
        case .small: return 0.88
        case .medium: return 0.95
        case .large: return 1.0  // Base
        case .extraLarge: return 1.12
        case .extraExtraLarge: return 1.24
        case .extraExtraExtraLarge: return 1.35
        case .accessibilityMedium: return 1.6
        case .accessibilityLarge: return 1.9
        case .accessibilityExtraLarge: return 2.35
        case .accessibilityExtraExtraLarge: return 2.75
        case .accessibilityExtraExtraExtraLarge: return 3.1
        @unknown default: return 1.0
        }
    }

    // MARK: - Size Category Detection

    /// Determina si una categoría de tamaño es de accesibilidad
    public static func isAccessibilityCategory(_ sizeCategory: ContentSizeCategory) -> Bool {
        switch sizeCategory {
        case .accessibilityMedium,
             .accessibilityLarge,
             .accessibilityExtraLarge,
             .accessibilityExtraExtraLarge,
             .accessibilityExtraExtraExtraLarge:
            return true
        default:
            return false
        }
    }

    /// Obtiene el nivel de escalado (0-11, siendo 3 el base "large")
    public static func scalingLevel(for sizeCategory: ContentSizeCategory) -> Int {
        switch sizeCategory {
        case .extraSmall: return 0
        case .small: return 1
        case .medium: return 2
        case .large: return 3  // Base
        case .extraLarge: return 4
        case .extraExtraLarge: return 5
        case .extraExtraExtraLarge: return 6
        case .accessibilityMedium: return 7
        case .accessibilityLarge: return 8
        case .accessibilityExtraLarge: return 9
        case .accessibilityExtraExtraLarge: return 10
        case .accessibilityExtraExtraExtraLarge: return 11
        @unknown default: return 3
        }
    }

    /// Determina si se debe usar un layout alternativo para tamaños grandes
    public static func shouldUseAlternativeLayout(for sizeCategory: ContentSizeCategory) -> Bool {
        return scalingLevel(for: sizeCategory) >= 7  // Accessibility sizes
    }
}

// MARK: - Scaling Curve Types

/// Define diferentes tipos de curvas de escalado
public enum ScalingCurve: Sendable {
    /// Escalado lineal proporcional
    case linear

    /// Escalado logarítmico (crece más lento en tamaños grandes)
    case logarithmic

    /// Escalado exponencial (crece más rápido en tamaños grandes)
    case exponential

    /// Escalado por pasos discretos
    case stepped([CGFloat])

    /// Escalado con límites mínimo y máximo
    case clamped(min: CGFloat, max: CGFloat)
}

// MARK: - View Extensions

extension View {
    /// Aplica escalado dinámico a un modificador de frame
    /// - Parameters:
    ///   - width: Ancho base
    ///   - height: Alto base
    ///   - curve: Curva de escalado
    /// - Returns: Vista con frame escalado
    public func dynamicFrame(
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        curve: ScalingCurve = .linear
    ) -> some View {
        modifier(DynamicFrameModifier(
            width: width,
            height: height,
            curve: curve
        ))
    }

    /// Aplica padding dinámico que escala con Dynamic Type
    /// - Parameters:
    ///   - edges: Bordes a los que aplicar padding
    ///   - baseValue: Valor base de padding
    ///   - curve: Curva de escalado
    /// - Returns: Vista con padding escalado
    public func dynamicPadding(
        _ edges: Edge.Set = .all,
        _ baseValue: CGFloat,
        curve: ScalingCurve = .linear
    ) -> some View {
        modifier(DynamicPaddingModifier(
            edges: edges,
            baseValue: baseValue,
            curve: curve
        ))
    }
}

// MARK: - View Modifiers

private struct DynamicFrameModifier: ViewModifier {
    let width: CGFloat?
    let height: CGFloat?
    let curve: ScalingCurve

    @Environment(\.sizeCategory) private var sizeCategory

    func body(content: Content) -> some View {
        let scaledWidth = width.map { DynamicTypeSupport.scaled($0, for: sizeCategory, curve: curve) }
        let scaledHeight = height.map { DynamicTypeSupport.scaled($0, for: sizeCategory, curve: curve) }

        content.frame(width: scaledWidth, height: scaledHeight)
    }
}

private struct DynamicPaddingModifier: ViewModifier {
    let edges: Edge.Set
    let baseValue: CGFloat
    let curve: ScalingCurve

    @Environment(\.sizeCategory) private var sizeCategory

    func body(content: Content) -> some View {
        let scaledValue = DynamicTypeSupport.scaled(baseValue, for: sizeCategory, curve: curve)
        content.padding(edges, scaledValue)
    }
}
