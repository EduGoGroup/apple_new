//
//  AdaptiveLayout.swift
//  EduAccessibility
//
//  Provides adaptive layouts that automatically adjust based on size category
//  to optimize readability and usability at all text sizes.
//
//  Features:
//  - Automatic HStack ↔ VStack switching for accessibility sizes
//  - Dynamic grid column calculation (reduces columns for large text)
//  - Adaptive line limits (unlimited for accessibility sizes)
//  - Smart truncation modes (middle for accessibility, tail for standard)
//  - Minimum scale factor recommendations
//  - Minimum touch target enforcement
//
//  Layout Strategy:
//  - Standard sizes (XS-XXXL): Horizontal layouts preferred
//  - Accessibility sizes (AX-M and above): Vertical layouts preferred
//  - Grid columns reduce progressively as text size increases
//
//  Swift 6.2 strict concurrency compliant
//

import SwiftUI

/// Proporciona layouts adaptativos que cambian automáticamente
/// según la categoría de tamaño para optimizar legibilidad.
public struct AdaptiveLayout {

    // MARK: - Layout Direction

    /// Determina la dirección óptima del layout según el tamaño
    /// - Parameter sizeCategory: Categoría de tamaño actual
    /// - Returns: `.vertical` para tamaños de accesibilidad, `.horizontal` para otros
    public static func optimalDirection(
        for sizeCategory: ContentSizeCategory
    ) -> Axis {
        DynamicTypeSupport.isAccessibilityCategory(sizeCategory) ? .vertical : .horizontal
    }

    /// Determina si se debe usar un layout apilado (vertical)
    /// - Parameters:
    ///   - sizeCategory: Categoría de tamaño actual
    ///   - threshold: Nivel mínimo para usar layout apilado (por defecto: 7 = accessibilityMedium)
    /// - Returns: `true` si se debe usar layout vertical
    public static func shouldStack(
        for sizeCategory: ContentSizeCategory,
        threshold: Int = 7
    ) -> Bool {
        DynamicTypeSupport.scalingLevel(for: sizeCategory) >= threshold
    }

    // MARK: - Adaptive Stacks

    /// Crea un stack adaptativo que cambia entre horizontal y vertical
    /// según la categoría de tamaño
    @ViewBuilder
    public static func adaptiveStack<Content: View>(
        sizeCategory: ContentSizeCategory,
        horizontalAlignment: HorizontalAlignment = .center,
        verticalAlignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        if shouldStack(for: sizeCategory) {
            VStack(alignment: horizontalAlignment, spacing: spacing) {
                content()
            }
        } else {
            HStack(alignment: verticalAlignment, spacing: spacing) {
                content()
            }
        }
    }

    // MARK: - Grid Columns

    /// Calcula el número óptimo de columnas para un grid según el tamaño
    /// - Parameters:
    ///   - sizeCategory: Categoría de tamaño actual
    ///   - defaultColumns: Número de columnas por defecto
    ///   - minColumns: Número mínimo de columnas (por defecto: 1)
    /// - Returns: Número de columnas recomendado
    public static func gridColumns(
        for sizeCategory: ContentSizeCategory,
        default defaultColumns: Int,
        minimum minColumns: Int = 1
    ) -> Int {
        let level = DynamicTypeSupport.scalingLevel(for: sizeCategory)

        if level >= 9 {  // accessibilityExtraLarge y superiores
            return minColumns
        } else if level >= 7 {  // accessibilityMedium y accessibilityLarge
            return max(minColumns, defaultColumns / 2)
        } else if level >= 5 {  // extraExtraLarge y superiores
            return max(minColumns, (defaultColumns * 2) / 3)
        }

        return defaultColumns
    }

    // MARK: - Line Limit

    /// Calcula el límite de líneas óptimo según el tamaño
    /// - Parameters:
    ///   - sizeCategory: Categoría de tamaño actual
    ///   - defaultLimit: Límite por defecto
    /// - Returns: Límite de líneas recomendado (puede ser mayor para accesibilidad)
    public static func lineLimit(
        for sizeCategory: ContentSizeCategory,
        default defaultLimit: Int
    ) -> Int? {
        if DynamicTypeSupport.isAccessibilityCategory(sizeCategory) {
            return nil  // Sin límite para tamaños de accesibilidad
        }
        return defaultLimit
    }

    // MARK: - Truncation Mode

    /// Determina el modo de truncado óptimo según el tamaño
    /// - Parameter sizeCategory: Categoría de tamaño actual
    /// - Returns: `.tail` para tamaños normales, `.middle` para accesibilidad
    public static func truncationMode(
        for sizeCategory: ContentSizeCategory
    ) -> Text.TruncationMode {
        DynamicTypeSupport.isAccessibilityCategory(sizeCategory) ? .middle : .tail
    }

    // MARK: - Minimum Scale Factor

    /// Calcula el factor de escala mínimo para texto según el tamaño
    /// - Parameter sizeCategory: Categoría de tamaño actual
    /// - Returns: Factor de escala mínimo (1.0 = no comprimir para accesibilidad)
    public static func minimumScaleFactor(
        for sizeCategory: ContentSizeCategory
    ) -> CGFloat {
        if DynamicTypeSupport.isAccessibilityCategory(sizeCategory) {
            return 1.0  // No comprimir texto en tamaños de accesibilidad
        }
        return 0.8  // Permitir hasta 20% de compresión en tamaños normales
    }
}

// MARK: - View Extensions

extension View {
    /// Aplica un layout adaptativo que cambia según el tamaño de categoría
    /// - Parameters:
    ///   - horizontalAlignment: Alineación horizontal cuando está en VStack
    ///   - verticalAlignment: Alineación vertical cuando está en HStack
    ///   - spacing: Espaciado entre elementos
    /// - Returns: Vista con layout adaptativo
    public func adaptiveLayoutModifier(
        horizontalAlignment: HorizontalAlignment = .center,
        verticalAlignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil
    ) -> some View {
        modifier(AdaptiveLayoutModifier(
            horizontalAlignment: horizontalAlignment,
            verticalAlignment: verticalAlignment,
            spacing: spacing
        ))
    }

    /// Aplica configuración de texto adaptativa según el tamaño
    /// - Parameter defaultLineLimit: Límite de líneas por defecto
    /// - Returns: Vista con configuración de texto adaptativa
    public func adaptiveText(
        lineLimit defaultLineLimit: Int = 3
    ) -> some View {
        modifier(AdaptiveTextModifier(defaultLineLimit: defaultLineLimit))
    }

    /// Asegura que la vista cumpla con el tamaño mínimo de touch target
    /// - Returns: Vista con tamaño mínimo de touch target garantizado
    public func minimumTouchTarget() -> some View {
        modifier(MinimumTouchTargetModifier())
    }
}

// MARK: - View Modifiers

/// Modifier que adapta el layout según la categoría de tamaño
private struct AdaptiveLayoutModifier: ViewModifier {
    let horizontalAlignment: HorizontalAlignment
    let verticalAlignment: VerticalAlignment
    let spacing: CGFloat?

    @Environment(\.sizeCategory) private var sizeCategory

    func body(content: Content) -> some View {
        Group {
            if AdaptiveLayout.shouldStack(for: sizeCategory) {
                VStack(alignment: horizontalAlignment, spacing: spacing) {
                    content
                }
            } else {
                HStack(alignment: verticalAlignment, spacing: spacing) {
                    content
                }
            }
        }
    }
}

/// Modifier que adapta la configuración de texto según la categoría de tamaño
private struct AdaptiveTextModifier: ViewModifier {
    let defaultLineLimit: Int

    @Environment(\.sizeCategory) private var sizeCategory

    func body(content: Content) -> some View {
        let lineLimit = AdaptiveLayout.lineLimit(for: sizeCategory, default: defaultLineLimit)
        let truncationMode = AdaptiveLayout.truncationMode(for: sizeCategory)
        let minimumScaleFactor = AdaptiveLayout.minimumScaleFactor(for: sizeCategory)

        content
            .lineLimit(lineLimit)
            .truncationMode(truncationMode)
            .minimumScaleFactor(minimumScaleFactor)
    }
}

/// Modifier que asegura el tamaño mínimo de touch target
private struct MinimumTouchTargetModifier: ViewModifier {
    @Environment(\.sizeCategory) private var sizeCategory

    func body(content: Content) -> some View {
        let minSize = ScalingMetrics.minimumTouchTarget(for: sizeCategory)

        content
            .frame(minWidth: minSize, minHeight: minSize)
    }
}

// MARK: - Adaptive Container

/// Container que proporciona un layout completamente adaptativo
public struct AdaptiveContainer<Content: View>: View {
    let horizontalAlignment: HorizontalAlignment
    let verticalAlignment: VerticalAlignment
    let spacing: CGFloat?
    let content: Content

    @Environment(\.sizeCategory) private var sizeCategory

    public init(
        horizontalAlignment: HorizontalAlignment = .center,
        verticalAlignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        Group {
            if AdaptiveLayout.shouldStack(for: sizeCategory) {
                VStack(alignment: horizontalAlignment, spacing: spacing) {
                    content
                }
            } else {
                HStack(alignment: verticalAlignment, spacing: spacing) {
                    content
                }
            }
        }
    }
}

// MARK: - Adaptive Grid

/// Grid que adapta su número de columnas según la categoría de tamaño
public struct AdaptiveGrid<Content: View>: View {
    let defaultColumns: Int
    let minColumns: Int
    let spacing: CGFloat?
    let content: Content

    @Environment(\.sizeCategory) private var sizeCategory

    public init(
        columns defaultColumns: Int,
        minimum minColumns: Int = 1,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.defaultColumns = defaultColumns
        self.minColumns = minColumns
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        let columns = AdaptiveLayout.gridColumns(
            for: sizeCategory,
            default: defaultColumns,
            minimum: minColumns
        )

        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns),
            spacing: spacing
        ) {
            content
        }
    }
}
