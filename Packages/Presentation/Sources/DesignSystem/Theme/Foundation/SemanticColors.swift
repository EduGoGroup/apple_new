import SwiftUI

/// Sistema de colores semánticos que mapean tokens de color a propósitos específicos de UI.
///
/// Los semantic colors proporcionan una capa de abstracción sobre ColorTokens,
/// permitiendo que los componentes usen nombres descriptivos (background, textPrimary, error)
/// en lugar de referencias directas a tokens (primary500, neutral900).
///
/// ## Uso
/// ```swift
/// Text("Hello")
///     .foregroundStyle(SemanticColors.textPrimary.resolve(for: colorScheme))
/// ```
///
/// ## Categorías
/// - Background: Colores de fondo para diferentes niveles de elevación
/// - Surface: Colores para superficies y contenedores
/// - Text: Colores de texto con diferentes niveles de énfasis
/// - Border: Colores para bordes en diferentes estados
/// - State: Colores para estados de validación (error, warning, success, info)
/// - Interactive: Colores para elementos interactivos
public enum SemanticColors {

    // MARK: - Background Colors

    /// Background principal de la aplicación
    public static let background = ColorToken(
        light: ColorTokens.neutral50.light,
        dark: ColorTokens.neutral900.dark
    )

    /// Background secundario (secciones, cards elevados)
    public static let backgroundSecondary = ColorToken(
        light: ColorTokens.neutral100.light,
        dark: ColorTokens.neutral800.dark
    )

    /// Background terciario (inputs, áreas interactivas)
    public static let backgroundTertiary = ColorToken(
        light: ColorTokens.neutral200.light,
        dark: ColorTokens.neutral700.dark
    )

    // MARK: - Surface Colors

    /// Surface base para cards y contenedores
    public static let surface = ColorToken(
        light: Color.white,
        dark: ColorTokens.neutral800.dark
    )

    /// Surface elevado (modals, popovers)
    public static let surfaceElevated = ColorToken(
        light: Color.white,
        dark: ColorTokens.neutral700.dark
    )

    /// Overlay oscuro para modals y sheets
    public static let surfaceOverlay = ColorToken(
        light: Color.black.opacity(0.4),
        dark: Color.black.opacity(0.6)
    )

    // MARK: - Text Colors

    /// Texto principal (títulos, contenido importante)
    public static let textPrimary = ColorToken(
        light: ColorTokens.neutral900.light,
        dark: ColorTokens.neutral50.dark
    )

    /// Texto secundario (subtítulos, descripciones)
    public static let textSecondary = ColorToken(
        light: ColorTokens.neutral700.light,  // Mejorar contraste (era neutral600)
        dark: ColorTokens.neutral300.dark      // Mejorar contraste (era neutral400)
    )

    /// Texto terciario (placeholders, hints)
    public static let textTertiary = ColorToken(
        light: ColorTokens.neutral500.light,
        dark: ColorTokens.neutral500.dark
    )

    /// Texto deshabilitado
    public static let textDisabled = ColorToken(
        light: ColorTokens.neutral400.light,
        dark: ColorTokens.neutral600.dark
    )

    /// Texto sobre fondos primary (botones primary)
    public static let textOnPrimary = ColorToken(
        light: Color.white,
        dark: ColorTokens.neutral900.dark
    )

    /// Texto sobre fondos de error
    public static let textOnError = ColorToken(
        light: Color.white,
        dark: ColorTokens.neutral900.dark
    )

    /// Texto sobre fondos de warning
    public static let textOnWarning = ColorToken(
        light: ColorTokens.neutral900.light,
        dark: ColorTokens.neutral900.dark
    )

    /// Texto sobre fondos de success
    public static let textOnSuccess = ColorToken(
        light: Color.white,
        dark: ColorTokens.neutral900.dark
    )

    /// Texto sobre fondos de info
    public static let textOnInfo = ColorToken(
        light: Color.white,
        dark: ColorTokens.neutral900.dark
    )

    // MARK: - Border Colors

    /// Border por defecto (inputs, cards)
    public static let border = ColorToken(
        light: ColorTokens.neutral300.light,
        dark: ColorTokens.neutral600.dark
    )

    /// Border en estado focused
    public static let borderFocused = ColorToken(
        light: ColorTokens.primary500.light,
        dark: ColorTokens.primary500.dark
    )

    /// Border en estado error
    public static let borderError = ColorToken(
        light: ColorTokens.error500.light,
        dark: ColorTokens.error500.dark
    )

    /// Border en estado disabled
    public static let borderDisabled = ColorToken(
        light: ColorTokens.neutral200.light,
        dark: ColorTokens.neutral700.dark
    )

    // MARK: - State Colors

    /// Color para estados de error
    public static let error = ColorToken(
        light: ColorTokens.error500.light,
        dark: ColorTokens.error400.dark
    )

    /// Background para banners/alerts de error
    public static let errorBackground = ColorToken(
        light: ColorTokens.error50.light,
        dark: ColorTokens.error900.dark
    )

    /// Color para estados de warning
    public static let warning = ColorToken(
        light: ColorTokens.warning500.light,
        dark: ColorTokens.warning400.dark
    )

    /// Background para banners/alerts de warning
    public static let warningBackground = ColorToken(
        light: ColorTokens.warning50.light,
        dark: ColorTokens.warning900.dark
    )

    /// Color para estados de success
    public static let success = ColorToken(
        light: ColorTokens.success500.light,
        dark: ColorTokens.success400.dark
    )

    /// Background para banners/alerts de success
    public static let successBackground = ColorToken(
        light: ColorTokens.success50.light,
        dark: ColorTokens.success900.dark
    )

    /// Color para estados informativos
    public static let info = ColorToken(
        light: ColorTokens.info500.light,
        dark: ColorTokens.info400.dark
    )

    /// Background para banners/alerts informativos
    public static let infoBackground = ColorToken(
        light: ColorTokens.info50.light,
        dark: ColorTokens.info900.dark
    )

    // MARK: - Interactive Colors

    /// Color principal para elementos interactivos (botones, links)
    public static let interactive = ColorToken(
        light: ColorTokens.primary500.light,
        dark: ColorTokens.primary500.dark
    )

    /// Color para estado hover de elementos interactivos
    public static let interactiveHovered = ColorToken(
        light: ColorTokens.primary600.light,
        dark: ColorTokens.primary400.dark
    )

    /// Color para estado pressed de elementos interactivos
    public static let interactivePressed = ColorToken(
        light: ColorTokens.primary700.light,
        dark: ColorTokens.primary300.dark
    )

    /// Color para elementos interactivos deshabilitados
    public static let interactiveDisabled = ColorToken(
        light: ColorTokens.neutral300.light,
        dark: ColorTokens.neutral600.dark
    )

    /// Background para botones secondary
    public static let interactiveSecondary = ColorToken(
        light: Color.clear,
        dark: Color.clear
    )

    /// Border para botones secondary
    public static let interactiveSecondaryBorder = ColorToken(
        light: ColorTokens.primary500.light,
        dark: ColorTokens.primary500.dark
    )

    // MARK: - Icon Colors

    /// Icono principal (mismo énfasis que textPrimary)
    public static let iconPrimary = ColorToken(
        light: ColorTokens.neutral700.light,
        dark: ColorTokens.neutral300.dark
    )

    /// Icono secundario
    public static let iconSecondary = ColorToken(
        light: ColorTokens.neutral500.light,
        dark: ColorTokens.neutral500.dark
    )

    /// Icono deshabilitado
    public static let iconDisabled = ColorToken(
        light: ColorTokens.neutral400.light,
        dark: ColorTokens.neutral600.dark
    )

    // MARK: - Shadow Colors

    /// Sombra ligera (elevación 1-2)
    public static let shadowLight = ColorToken(
        light: Color.black.opacity(0.05),
        dark: Color.black.opacity(0.20)
    )

    /// Sombra media (elevación 3-4)
    public static let shadowMedium = ColorToken(
        light: Color.black.opacity(0.10),
        dark: Color.black.opacity(0.30)
    )

    /// Sombra fuerte (elevación 5+)
    public static let shadowStrong = ColorToken(
        light: Color.black.opacity(0.15),
        dark: Color.black.opacity(0.40)
    )

    // MARK: - Divider Colors

    /// Color para separadores/dividers
    public static let divider = ColorToken(
        light: ColorTokens.neutral200.light,
        dark: ColorTokens.neutral700.dark
    )

    /// Color para separadores fuertes (mayor contraste)
    public static let dividerStrong = ColorToken(
        light: ColorTokens.neutral300.light,
        dark: ColorTokens.neutral600.dark
    )
}

// MARK: - Convenience Extensions

extension ColorToken {
    /// Resuelve el color apropiado usando @Environment(\.colorScheme)
    /// - Parameter colorScheme: El esquema de color del environment
    /// - Returns: El color resuelto
    public func color(for colorScheme: ColorScheme) -> Color {
        resolve(for: colorScheme)
    }
}
