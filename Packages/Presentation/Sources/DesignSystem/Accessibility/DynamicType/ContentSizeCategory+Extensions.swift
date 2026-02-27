//
//  ContentSizeCategory+Extensions.swift
//  EduAccessibility
//
//  Extensions for ContentSizeCategory to simplify working with Dynamic Type.
//
//  Features:
//  - Scaling level property (0-11, where 3 is large/base)
//  - Convenience scaling methods for all metric types
//  - Layout direction and stacking recommendations
//  - Grid column, line limit, and truncation helpers
//  - Category comparison methods
//  - Human-readable names (full and short forms)
//  - Categorized lists (standard vs accessibility)
//
//  Swift 6.2 strict concurrency compliant
//

import SwiftUI

/// Extensiones para ContentSizeCategory que facilitan el trabajo con Dynamic Type
extension ContentSizeCategory {

    // MARK: - Category Information

    // Nota: isAccessibilityCategory ya está disponible nativamente en SwiftUI desde iOS 13.4+

    /// Nivel de escalado (0-11, donde 3 es "large" - el base)
    public var scalingLevel: Int {
        DynamicTypeSupport.scalingLevel(for: self)
    }

    /// Indica si se debe usar un layout alternativo para esta categoría
    public var shouldUseAlternativeLayout: Bool {
        DynamicTypeSupport.shouldUseAlternativeLayout(for: self)
    }

    // MARK: - Scaling Helpers

    /// Escala un valor usando la curva especificada
    /// - Parameters:
    ///   - value: Valor base a escalar
    ///   - curve: Curva de escalado a aplicar
    /// - Returns: Valor escalado
    public func scaled(_ value: CGFloat, curve: ScalingCurve = .linear) -> CGFloat {
        DynamicTypeSupport.scaled(value, for: self, curve: curve)
    }

    /// Escala un spacing usando curva logarítmica
    /// - Parameter spacing: Valor base de spacing
    /// - Returns: Spacing escalado
    public func scaledSpacing(_ spacing: CGFloat) -> CGFloat {
        ScalingMetrics.scaledSpacing(spacing, for: self)
    }

    /// Escala un padding usando curva logarítmica
    /// - Parameter padding: Valor base de padding
    /// - Returns: Padding escalado
    public func scaledPadding(_ padding: CGFloat) -> CGFloat {
        ScalingMetrics.scaledPadding(padding, for: self)
    }

    /// Escala un corner radius con límites
    /// - Parameter radius: Valor base del radio
    /// - Returns: Radio escalado con límites
    public func scaledCornerRadius(_ radius: CGFloat) -> CGFloat {
        ScalingMetrics.scaledCornerRadius(radius, for: self)
    }

    /// Escala un tamaño de icono linealmente
    /// - Parameter size: Tamaño base del icono
    /// - Returns: Tamaño escalado
    public func scaledIconSize(_ size: CGFloat) -> CGFloat {
        ScalingMetrics.scaledIconSize(size, for: self)
    }

    /// Escala un ancho de borde por pasos
    /// - Parameter width: Ancho base del borde
    /// - Returns: Ancho escalado
    public func scaledBorderWidth(_ width: CGFloat) -> CGFloat {
        ScalingMetrics.scaledBorderWidth(width, for: self)
    }

    // MARK: - Layout Helpers

    /// Dirección óptima del layout para esta categoría
    public var optimalLayoutDirection: Axis {
        AdaptiveLayout.optimalDirection(for: self)
    }

    /// Indica si se debe usar un layout apilado (vertical)
    /// - Parameter threshold: Nivel mínimo para apilar
    /// - Returns: `true` si se debe apilar
    public func shouldStack(threshold: Int = 7) -> Bool {
        AdaptiveLayout.shouldStack(for: self, threshold: threshold)
    }

    /// Número de columnas recomendado para un grid
    /// - Parameters:
    ///   - defaultColumns: Número de columnas por defecto
    ///   - minColumns: Número mínimo de columnas
    /// - Returns: Número de columnas recomendado
    public func gridColumns(default defaultColumns: Int, minimum minColumns: Int = 1) -> Int {
        AdaptiveLayout.gridColumns(for: self, default: defaultColumns, minimum: minColumns)
    }

    /// Límite de líneas recomendado
    /// - Parameter defaultLimit: Límite por defecto
    /// - Returns: Límite recomendado (nil = sin límite)
    public func lineLimit(default defaultLimit: Int) -> Int? {
        AdaptiveLayout.lineLimit(for: self, default: defaultLimit)
    }

    /// Modo de truncado recomendado
    public var truncationMode: Text.TruncationMode {
        AdaptiveLayout.truncationMode(for: self)
    }

    /// Factor de escala mínimo para texto
    public var minimumScaleFactor: CGFloat {
        AdaptiveLayout.minimumScaleFactor(for: self)
    }

    /// Tamaño mínimo de touch target
    public var minimumTouchTarget: CGFloat {
        ScalingMetrics.minimumTouchTarget(for: self)
    }

    // MARK: - Comparison

    /// Compara esta categoría con otra
    /// - Parameter other: Otra categoría
    /// - Returns: Resultado de la comparación
    public func compare(to other: ContentSizeCategory) -> ComparisonResult {
        let thisLevel = self.scalingLevel
        let otherLevel = other.scalingLevel

        if thisLevel < otherLevel {
            return .orderedAscending
        } else if thisLevel > otherLevel {
            return .orderedDescending
        } else {
            return .orderedSame
        }
    }

    /// Indica si esta categoría es más pequeña que otra
    public func isSmaller(than other: ContentSizeCategory) -> Bool {
        self.scalingLevel < other.scalingLevel
    }

    /// Indica si esta categoría es más grande que otra
    public func isLarger(than other: ContentSizeCategory) -> Bool {
        self.scalingLevel > other.scalingLevel
    }

    /// Indica si esta categoría es igual o más grande que otra
    public func isAtLeast(_ other: ContentSizeCategory) -> Bool {
        self.scalingLevel >= other.scalingLevel
    }

    /// Indica si esta categoría es igual o más pequeña que otra
    public func isAtMost(_ other: ContentSizeCategory) -> Bool {
        self.scalingLevel <= other.scalingLevel
    }

    // MARK: - String Representation

    /// Nombre descriptivo de la categoría
    public var name: String {
        switch self {
        case .extraSmall: return "Extra Small"
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large (Default)"
        case .extraLarge: return "Extra Large"
        case .extraExtraLarge: return "Extra Extra Large"
        case .extraExtraExtraLarge: return "Extra Extra Extra Large"
        case .accessibilityMedium: return "Accessibility Medium"
        case .accessibilityLarge: return "Accessibility Large"
        case .accessibilityExtraLarge: return "Accessibility Extra Large"
        case .accessibilityExtraExtraLarge: return "Accessibility Extra Extra Large"
        case .accessibilityExtraExtraExtraLarge: return "Accessibility Extra Extra Extra Large"
        @unknown default: return "Unknown"
        }
    }

    /// Nombre corto de la categoría
    public var shortName: String {
        switch self {
        case .extraSmall: return "XS"
        case .small: return "S"
        case .medium: return "M"
        case .large: return "L"
        case .extraLarge: return "XL"
        case .extraExtraLarge: return "XXL"
        case .extraExtraExtraLarge: return "XXXL"
        case .accessibilityMedium: return "AX-M"
        case .accessibilityLarge: return "AX-L"
        case .accessibilityExtraLarge: return "AX-XL"
        case .accessibilityExtraExtraLarge: return "AX-XXL"
        case .accessibilityExtraExtraExtraLarge: return "AX-XXXL"
        @unknown default: return "?"
        }
    }

    // MARK: - Category Lists

    // Nota: allCases ya está disponible nativamente en SwiftUI

    /// Categorías de tamaño estándar (no accesibilidad)
    public static var eduStandardCases: [ContentSizeCategory] {
        [
            .extraSmall,
            .small,
            .medium,
            .large,
            .extraLarge,
            .extraExtraLarge,
            .extraExtraExtraLarge
        ]
    }

    /// Categorías de tamaño de accesibilidad
    public static var eduAccessibilityCases: [ContentSizeCategory] {
        [
            .accessibilityMedium,
            .accessibilityLarge,
            .accessibilityExtraLarge,
            .accessibilityExtraExtraLarge,
            .accessibilityExtraExtraExtraLarge
        ]
    }
}

// MARK: - CustomStringConvertible

extension ContentSizeCategory: @retroactive CustomStringConvertible {
    public var description: String {
        name
    }
}

// MARK: - Environment Key

/// Environment key para acceder fácilmente a la categoría de tamaño
public struct DynamicTypeCategoryKey: EnvironmentKey {
    public static let defaultValue: ContentSizeCategory = .large
}

extension EnvironmentValues {
    /// Acceso directo a la categoría de tamaño
    public var dynamicTypeCategory: ContentSizeCategory {
        get { self.sizeCategory }
    }
}
