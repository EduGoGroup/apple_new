import SwiftUI

/// Extensiones para SwiftUI.Color que proporcionan acceso fácil a semantic colors del theme.
///
/// Estas extensiones permiten usar semantic colors directamente en componentes SwiftUI
/// de forma limpia y autodescriptiva.
///
/// ## Uso
/// ```swift
/// Text("Hello")
///     .foregroundStyle(Color.theme.textPrimary)
///
/// Rectangle()
///     .fill(Color.theme.background)
/// ```
///
/// ## Nota
/// Los colores se resuelven automáticamente según el @Environment(\.colorScheme) del view.
extension Color {

    /// Namespace para acceder a colores del theme system
    
    public struct ThemeColors {

        // MARK: - Background Colors

        /// Background principal de la aplicación
        public var background: Color {
            SemanticColors.background.adaptiveColor
        }

        /// Background secundario (secciones, cards elevados)
        public var backgroundSecondary: Color {
            SemanticColors.backgroundSecondary.adaptiveColor
        }

        /// Background terciario (inputs, áreas interactivas)
        public var backgroundTertiary: Color {
            SemanticColors.backgroundTertiary.adaptiveColor
        }

        // MARK: - Surface Colors

        /// Surface base para cards y contenedores
        public var surface: Color {
            SemanticColors.surface.adaptiveColor
        }

        /// Surface elevado (modals, popovers)
        public var surfaceElevated: Color {
            SemanticColors.surfaceElevated.adaptiveColor
        }

        /// Overlay oscuro para modals y sheets
        public var surfaceOverlay: Color {
            SemanticColors.surfaceOverlay.adaptiveColor
        }

        // MARK: - Text Colors

        /// Texto principal (títulos, contenido importante)
        public var textPrimary: Color {
            SemanticColors.textPrimary.adaptiveColor
        }

        /// Texto secundario (subtítulos, descripciones)
        public var textSecondary: Color {
            SemanticColors.textSecondary.adaptiveColor
        }

        /// Texto terciario (placeholders, hints)
        public var textTertiary: Color {
            SemanticColors.textTertiary.adaptiveColor
        }

        /// Texto deshabilitado
        public var textDisabled: Color {
            SemanticColors.textDisabled.adaptiveColor
        }

        /// Texto sobre fondos primary
        public var textOnPrimary: Color {
            SemanticColors.textOnPrimary.adaptiveColor
        }

        /// Texto sobre fondos de error
        public var textOnError: Color {
            SemanticColors.textOnError.adaptiveColor
        }

        /// Texto sobre fondos de warning
        public var textOnWarning: Color {
            SemanticColors.textOnWarning.adaptiveColor
        }

        /// Texto sobre fondos de success
        public var textOnSuccess: Color {
            SemanticColors.textOnSuccess.adaptiveColor
        }

        /// Texto sobre fondos de info
        public var textOnInfo: Color {
            SemanticColors.textOnInfo.adaptiveColor
        }

        // MARK: - Border Colors

        /// Border por defecto
        public var border: Color {
            SemanticColors.border.adaptiveColor
        }

        /// Border en estado focused
        public var borderFocused: Color {
            SemanticColors.borderFocused.adaptiveColor
        }

        /// Border en estado error
        public var borderError: Color {
            SemanticColors.borderError.adaptiveColor
        }

        /// Border en estado disabled
        public var borderDisabled: Color {
            SemanticColors.borderDisabled.adaptiveColor
        }

        // MARK: - State Colors

        /// Color para estados de error
        public var error: Color {
            SemanticColors.error.adaptiveColor
        }

        /// Background para banners/alerts de error
        public var errorBackground: Color {
            SemanticColors.errorBackground.adaptiveColor
        }

        /// Color para estados de warning
        public var warning: Color {
            SemanticColors.warning.adaptiveColor
        }

        /// Background para banners/alerts de warning
        public var warningBackground: Color {
            SemanticColors.warningBackground.adaptiveColor
        }

        /// Color para estados de success
        public var success: Color {
            SemanticColors.success.adaptiveColor
        }

        /// Background para banners/alerts de success
        public var successBackground: Color {
            SemanticColors.successBackground.adaptiveColor
        }

        /// Color para estados informativos
        public var info: Color {
            SemanticColors.info.adaptiveColor
        }

        /// Background para banners/alerts informativos
        public var infoBackground: Color {
            SemanticColors.infoBackground.adaptiveColor
        }

        // MARK: - Interactive Colors

        /// Color principal para elementos interactivos
        public var interactive: Color {
            SemanticColors.interactive.adaptiveColor
        }

        /// Color para estado hover
        public var interactiveHovered: Color {
            SemanticColors.interactiveHovered.adaptiveColor
        }

        /// Color para estado pressed
        public var interactivePressed: Color {
            SemanticColors.interactivePressed.adaptiveColor
        }

        /// Color para elementos interactivos deshabilitados
        public var interactiveDisabled: Color {
            SemanticColors.interactiveDisabled.adaptiveColor
        }

        /// Background para botones secondary
        public var interactiveSecondary: Color {
            SemanticColors.interactiveSecondary.adaptiveColor
        }

        /// Border para botones secondary
        public var interactiveSecondaryBorder: Color {
            SemanticColors.interactiveSecondaryBorder.adaptiveColor
        }

        // MARK: - Icon Colors

        /// Icono principal
        public var iconPrimary: Color {
            SemanticColors.iconPrimary.adaptiveColor
        }

        /// Icono secundario
        public var iconSecondary: Color {
            SemanticColors.iconSecondary.adaptiveColor
        }

        /// Icono deshabilitado
        public var iconDisabled: Color {
            SemanticColors.iconDisabled.adaptiveColor
        }

        // MARK: - Shadow Colors

        /// Sombra ligera
        public var shadowLight: Color {
            SemanticColors.shadowLight.adaptiveColor
        }

        /// Sombra media
        public var shadowMedium: Color {
            SemanticColors.shadowMedium.adaptiveColor
        }

        /// Sombra fuerte
        public var shadowStrong: Color {
            SemanticColors.shadowStrong.adaptiveColor
        }

        // MARK: - Divider Colors

        /// Color para separadores
        public var divider: Color {
            SemanticColors.divider.adaptiveColor
        }

        /// Color para separadores fuertes
        public var dividerStrong: Color {
            SemanticColors.dividerStrong.adaptiveColor
        }
    }

    /// Acceso a semantic colors del theme
    
    public static var theme: ThemeColors {
        ThemeColors()
    }
}

// MARK: - ColorToken Adaptive Extension

extension ColorToken {
    /// Retorna un Color que se adapta automáticamente al color scheme del environment.
    ///
    /// Esta propiedad usa SwiftUI's adaptive color system para cambiar automáticamente
    /// entre light y dark según el @Environment(\.colorScheme) del view.
    
    var adaptiveColor: Color {
        Color(light: light, dark: dark)
    }
}

// MARK: - SwiftUI Color Adaptive Init

extension Color {
    /// Inicializa un Color adaptativo que cambia según el color scheme.
    ///
    /// - Parameters:
    ///   - light: Color para light mode
    ///   - dark: Color para dark mode
    
    init(light: Color, dark: Color) {
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        self.init(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #elseif os(macOS)
        self.init(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? NSColor(dark) : NSColor(light)
        })
        #else
        self = light
        #endif
    }
}

// MARK: - Convenience Accessors for ColorTokens

extension Color {

    /// Namespace para acceder a ColorTokens directamente (uso avanzado)
    
    public struct TokenColors {

        // MARK: - Primary Tokens

        public var primary50: Color { ColorTokens.primary50.adaptiveColor }
        public var primary100: Color { ColorTokens.primary100.adaptiveColor }
        public var primary200: Color { ColorTokens.primary200.adaptiveColor }
        public var primary300: Color { ColorTokens.primary300.adaptiveColor }
        public var primary400: Color { ColorTokens.primary400.adaptiveColor }
        public var primary500: Color { ColorTokens.primary500.adaptiveColor }
        public var primary600: Color { ColorTokens.primary600.adaptiveColor }
        public var primary700: Color { ColorTokens.primary700.adaptiveColor }
        public var primary800: Color { ColorTokens.primary800.adaptiveColor }
        public var primary900: Color { ColorTokens.primary900.adaptiveColor }

        // MARK: - Neutral Tokens (más usados)

        public var neutral50: Color { ColorTokens.neutral50.adaptiveColor }
        public var neutral100: Color { ColorTokens.neutral100.adaptiveColor }
        public var neutral200: Color { ColorTokens.neutral200.adaptiveColor }
        public var neutral300: Color { ColorTokens.neutral300.adaptiveColor }
        public var neutral400: Color { ColorTokens.neutral400.adaptiveColor }
        public var neutral500: Color { ColorTokens.neutral500.adaptiveColor }
        public var neutral600: Color { ColorTokens.neutral600.adaptiveColor }
        public var neutral700: Color { ColorTokens.neutral700.adaptiveColor }
        public var neutral800: Color { ColorTokens.neutral800.adaptiveColor }
        public var neutral900: Color { ColorTokens.neutral900.adaptiveColor }
    }

    /// Acceso directo a ColorTokens (uso avanzado, preferir Color.theme)
    
    public static var tokens: TokenColors {
        TokenColors()
    }
}
