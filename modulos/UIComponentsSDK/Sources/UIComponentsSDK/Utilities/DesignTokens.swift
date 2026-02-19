import Foundation
import CoreGraphics
import SwiftUI

/// Sistema centralizado de design tokens para EduUI.
///
/// Proporciona valores consistentes para spacing, sizing, corner radius,
/// shadows y otros valores de diseno reutilizables.
///
/// ## Uso
/// ```swift
/// .padding(.horizontal, DesignTokens.Spacing.large)
/// .padding(.vertical, DesignTokens.Spacing.medium)
/// .cornerRadius(DesignTokens.CornerRadius.medium)
/// .shadow(radius: DesignTokens.Shadow.medium)
/// ```
///
/// ## Beneficios
/// - Consistencia visual en toda la aplicacion
/// - Facilita theming y personalizacion
/// - Evita magic numbers dispersos
/// - Un solo punto de cambio para ajustes de diseno
public enum DesignTokens {

    // MARK: - Spacing

    /// Valores de espaciado (padding, spacing entre elementos).
    public enum Spacing {
        /// 4pt - Espaciado extra pequeno
        public static let xs: CGFloat = 4

        /// 8pt - Espaciado pequeno
        public static let small: CGFloat = 8

        /// 12pt - Espaciado mediano
        public static let medium: CGFloat = 12

        /// 16pt - Espaciado grande
        public static let large: CGFloat = 16

        /// 20pt - Espaciado extra grande
        public static let xl: CGFloat = 20

        /// 24pt - Espaciado extra extra grande
        public static let xxl: CGFloat = 24
    }

    // MARK: - Corner Radius

    /// Valores de radio de esquinas para componentes.
    public enum CornerRadius {
        /// 6pt - Radio pequeno (botones small)
        public static let small: CGFloat = 6

        /// 8pt - Radio mediano (botones medium, text fields)
        public static let medium: CGFloat = 8

        /// 10pt - Radio grande (botones large)
        public static let large: CGFloat = 10

        /// 12pt - Radio extra grande (cards)
        public static let xl: CGFloat = 12
    }

    // MARK: - Shadow

    /// Valores de sombra para elevacion de componentes.
    public enum Shadow {
        /// 0pt - Sin sombra
        public static let none: CGFloat = 0

        /// 2pt - Sombra pequena (elevation low)
        public static let small: CGFloat = 2

        /// 4pt - Sombra mediana (elevation medium)
        public static let medium: CGFloat = 4

        /// 8pt - Sombra grande (elevation high)
        public static let large: CGFloat = 8
    }

    // MARK: - Border Width

    /// Valores de ancho de borde.
    public enum BorderWidth {
        /// 1pt - Borde delgado (default)
        public static let thin: CGFloat = 1

        /// 2pt - Borde mediano (borders destacados, focus states)
        public static let medium: CGFloat = 2

        /// 3pt - Borde grueso (enfasis extra)
        public static let thick: CGFloat = 3
    }

    // MARK: - Icon Size

    /// Valores de tamano de iconos.
    public enum IconSize {
        /// 16pt - Icono pequeno
        public static let small: CGFloat = 16

        /// 24pt - Icono mediano
        public static let medium: CGFloat = 24

        /// 32pt - Icono grande
        public static let large: CGFloat = 32

        /// 48pt - Icono extra grande
        public static let xl: CGFloat = 48
    }
}

// MARK: - Glass-Aware Spacing

extension DesignTokens.Spacing {
    /// 16pt - Espaciado para bordes de elementos glass
    public static let glassEdge: CGFloat = 16

    /// 20pt - Espaciado para flujo entre elementos glass
    public static let glassFlow: CGFloat = 20

    /// 16pt - Padding interno para contenedores glass
    public static let glassInternalPadding: CGFloat = 16

    /// 20pt - Margen externo para contenedores glass
    public static let glassExternalMargin: CGFloat = 20
}

// MARK: - Touch Targets

extension DesignTokens {
    /// Valores de tamaño mínimo para targets táctiles (accesibilidad).
    public enum TouchTarget {
        /// 44pt - Tamaño mínimo recomendado por Apple
        public static let minimum: CGFloat = 44

        /// 48pt - Tamaño estándar para mejor usabilidad
        public static let standard: CGFloat = 48

        /// 56pt - Tamaño grande para acciones prominentes
        public static let large: CGFloat = 56
    }
}

// MARK: - Desktop Margins

extension DesignTokens.Spacing {
    /// 20pt - Margen de ventana en desktop
    public static let desktopWindowMargin: CGFloat = 20

    /// 24pt - Margen de contenido en desktop
    public static let desktopContentMargin: CGFloat = 24

    /// 32pt - Espaciado entre columnas en desktop
    public static let desktopColumnGap: CGFloat = 32
}

// MARK: - Glass Corner Radius

extension DesignTokens.CornerRadius {
    /// 16pt - Radio para contenedores glass estándar
    public static let glass: CGFloat = 16

    /// 20pt - Radio para contenedores glass prominentes
    public static let glassLarge: CGFloat = 20

    /// 24pt - Radio para contenedores glass hero
    public static let glassHero: CGFloat = 24
}

// MARK: - EdgeInsets Convenience

extension DesignTokens {
    /// EdgeInsets predefinidos para casos comunes.
    public enum Insets {
        /// EdgeInsets(6, 12, 6, 12) - Padding para botones small
        public static let buttonSmall = EdgeInsets(
            top: 6,
            leading: 12,
            bottom: 6,
            trailing: 12
        )

        /// EdgeInsets(10, 16, 10, 16) - Padding para botones medium
        public static let buttonMedium = EdgeInsets(
            top: 10,
            leading: 16,
            bottom: 10,
            trailing: 16
        )

        /// EdgeInsets(14, 20, 14, 20) - Padding para botones large
        public static let buttonLarge = EdgeInsets(
            top: 14,
            leading: 20,
            bottom: 14,
            trailing: 20
        )

        /// EdgeInsets(16, 16, 16, 16) - Padding estandar para cards
        public static let cardDefault = EdgeInsets(
            top: Spacing.large,
            leading: Spacing.large,
            bottom: Spacing.large,
            trailing: Spacing.large
        )

        /// EdgeInsets(24, 24, 24, 24) - Padding generoso para hero cards
        public static let cardHero = EdgeInsets(
            top: Spacing.xxl,
            leading: Spacing.xxl,
            bottom: Spacing.xxl,
            trailing: Spacing.xxl
        )

        /// EdgeInsets(12, 16, 12, 16) - Padding compacto para list cards
        public static let cardList = EdgeInsets(
            top: Spacing.medium,
            leading: Spacing.large,
            bottom: Spacing.medium,
            trailing: Spacing.large
        )

        /// EdgeInsets(16, 16, 16, 16) - Padding interno para glass containers
        public static let glassInternal = EdgeInsets(
            top: Spacing.glassInternalPadding,
            leading: Spacing.glassInternalPadding,
            bottom: Spacing.glassInternalPadding,
            trailing: Spacing.glassInternalPadding
        )

        /// EdgeInsets(20, 20, 20, 20) - Margen externo para glass containers
        public static let glassExternal = EdgeInsets(
            top: Spacing.glassExternalMargin,
            leading: Spacing.glassExternalMargin,
            bottom: Spacing.glassExternalMargin,
            trailing: Spacing.glassExternalMargin
        )
    }
}
