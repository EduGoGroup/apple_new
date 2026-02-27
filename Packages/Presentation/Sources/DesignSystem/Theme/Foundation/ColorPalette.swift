import SwiftUI

/// Define paletas de color completas para diferentes temas de la aplicación.
///
/// Cada paleta define todos los ColorTokens necesarios para construir un theme completo.
/// Esto permite cambiar fácilmente entre temas (default, highContrast, grayscale) o
/// crear temas personalizados.
///
/// ## Uso
/// ```swift
/// let defaultPalette = ColorPalette.default
/// let customPalette = ColorPalette.custom(primary: myPrimaryColors, ...)
/// ```
public struct ColorPalette: Sendable {

    // MARK: - Properties

    /// Tokens de color primary (50-900)
    public let primary: PaletteScale

    /// Tokens de color secondary (50-900)
    public let secondary: PaletteScale

    /// Tokens de color error (50-900)
    public let error: PaletteScale

    /// Tokens de color warning (50-900)
    public let warning: PaletteScale

    /// Tokens de color success (50-900)
    public let success: PaletteScale

    /// Tokens de color info (50-900)
    public let info: PaletteScale

    /// Tokens de color neutral/gray (50-900)
    public let neutral: PaletteScale

    // MARK: - Initializer

    /// Crea una paleta de color personalizada
    public init(
        primary: PaletteScale,
        secondary: PaletteScale,
        error: PaletteScale,
        warning: PaletteScale,
        success: PaletteScale,
        info: PaletteScale,
        neutral: PaletteScale
    ) {
        self.primary = primary
        self.secondary = secondary
        self.error = error
        self.warning = warning
        self.success = success
        self.info = info
        self.neutral = neutral
    }
}

// MARK: - PaletteScale

/// Escala completa de colores (50-900) para una categoría de color.
public struct PaletteScale: Sendable {
    public let c50: ColorToken
    public let c100: ColorToken
    public let c200: ColorToken
    public let c300: ColorToken
    public let c400: ColorToken
    public let c500: ColorToken
    public let c600: ColorToken
    public let c700: ColorToken
    public let c800: ColorToken
    public let c900: ColorToken

    public init(
        c50: ColorToken,
        c100: ColorToken,
        c200: ColorToken,
        c300: ColorToken,
        c400: ColorToken,
        c500: ColorToken,
        c600: ColorToken,
        c700: ColorToken,
        c800: ColorToken,
        c900: ColorToken
    ) {
        self.c50 = c50
        self.c100 = c100
        self.c200 = c200
        self.c300 = c300
        self.c400 = c400
        self.c500 = c500
        self.c600 = c600
        self.c700 = c700
        self.c800 = c800
        self.c900 = c900
    }
}

// MARK: - Predefined Palettes

extension ColorPalette {

    /// Paleta por defecto (basada en ColorTokens actuales)
    public static let `default` = ColorPalette(
        primary: PaletteScale(
            c50: ColorTokens.primary50,
            c100: ColorTokens.primary100,
            c200: ColorTokens.primary200,
            c300: ColorTokens.primary300,
            c400: ColorTokens.primary400,
            c500: ColorTokens.primary500,
            c600: ColorTokens.primary600,
            c700: ColorTokens.primary700,
            c800: ColorTokens.primary800,
            c900: ColorTokens.primary900
        ),
        secondary: PaletteScale(
            c50: ColorTokens.secondary50,
            c100: ColorTokens.secondary100,
            c200: ColorTokens.secondary200,
            c300: ColorTokens.secondary300,
            c400: ColorTokens.secondary400,
            c500: ColorTokens.secondary500,
            c600: ColorTokens.secondary600,
            c700: ColorTokens.secondary700,
            c800: ColorTokens.secondary800,
            c900: ColorTokens.secondary900
        ),
        error: PaletteScale(
            c50: ColorTokens.error50,
            c100: ColorTokens.error100,
            c200: ColorTokens.error200,
            c300: ColorTokens.error300,
            c400: ColorTokens.error400,
            c500: ColorTokens.error500,
            c600: ColorTokens.error600,
            c700: ColorTokens.error700,
            c800: ColorTokens.error800,
            c900: ColorTokens.error900
        ),
        warning: PaletteScale(
            c50: ColorTokens.warning50,
            c100: ColorTokens.warning100,
            c200: ColorTokens.warning200,
            c300: ColorTokens.warning300,
            c400: ColorTokens.warning400,
            c500: ColorTokens.warning500,
            c600: ColorTokens.warning600,
            c700: ColorTokens.warning700,
            c800: ColorTokens.warning800,
            c900: ColorTokens.warning900
        ),
        success: PaletteScale(
            c50: ColorTokens.success50,
            c100: ColorTokens.success100,
            c200: ColorTokens.success200,
            c300: ColorTokens.success300,
            c400: ColorTokens.success400,
            c500: ColorTokens.success500,
            c600: ColorTokens.success600,
            c700: ColorTokens.success700,
            c800: ColorTokens.success800,
            c900: ColorTokens.success900
        ),
        info: PaletteScale(
            c50: ColorTokens.info50,
            c100: ColorTokens.info100,
            c200: ColorTokens.info200,
            c300: ColorTokens.info300,
            c400: ColorTokens.info400,
            c500: ColorTokens.info500,
            c600: ColorTokens.info600,
            c700: ColorTokens.info700,
            c800: ColorTokens.info800,
            c900: ColorTokens.info900
        ),
        neutral: PaletteScale(
            c50: ColorTokens.neutral50,
            c100: ColorTokens.neutral100,
            c200: ColorTokens.neutral200,
            c300: ColorTokens.neutral300,
            c400: ColorTokens.neutral400,
            c500: ColorTokens.neutral500,
            c600: ColorTokens.neutral600,
            c700: ColorTokens.neutral700,
            c800: ColorTokens.neutral800,
            c900: ColorTokens.neutral900
        )
    )

    /// Paleta de alto contraste (para accesibilidad)
    public static let highContrast = ColorPalette(
        primary: PaletteScale(
            c50: ColorToken(light: Color(red: 0.90, green: 0.93, blue: 1.00), dark: Color(red: 0.00, green: 0.00, blue: 0.15)),
            c100: ColorToken(light: Color(red: 0.75, green: 0.82, blue: 1.00), dark: Color(red: 0.05, green: 0.05, blue: 0.25)),
            c200: ColorToken(light: Color(red: 0.50, green: 0.65, blue: 1.00), dark: Color(red: 0.10, green: 0.15, blue: 0.40)),
            c300: ColorToken(light: Color(red: 0.25, green: 0.48, blue: 1.00), dark: Color(red: 0.20, green: 0.30, blue: 0.60)),
            c400: ColorToken(light: Color(red: 0.00, green: 0.33, blue: 0.95), dark: Color(red: 0.30, green: 0.45, blue: 0.80)),
            c500: ColorToken(light: Color(red: 0.00, green: 0.20, blue: 0.80), dark: Color(red: 0.50, green: 0.70, blue: 1.00)),
            c600: ColorToken(light: Color(red: 0.00, green: 0.15, blue: 0.65), dark: Color(red: 0.60, green: 0.80, blue: 1.00)),
            c700: ColorToken(light: Color(red: 0.00, green: 0.10, blue: 0.50), dark: Color(red: 0.70, green: 0.85, blue: 1.00)),
            c800: ColorToken(light: Color(red: 0.00, green: 0.05, blue: 0.35), dark: Color(red: 0.80, green: 0.90, blue: 1.00)),
            c900: ColorToken(light: Color(red: 0.00, green: 0.00, blue: 0.20), dark: Color(red: 0.90, green: 0.95, blue: 1.00))
        ),
        secondary: PaletteScale(
            c50: ColorToken(light: Color(red: 0.95, green: 0.90, blue: 1.00), dark: Color(red: 0.10, green: 0.00, blue: 0.15)),
            c100: ColorToken(light: Color(red: 0.88, green: 0.75, blue: 1.00), dark: Color(red: 0.15, green: 0.05, blue: 0.25)),
            c200: ColorToken(light: Color(red: 0.75, green: 0.50, blue: 1.00), dark: Color(red: 0.25, green: 0.10, blue: 0.40)),
            c300: ColorToken(light: Color(red: 0.60, green: 0.25, blue: 1.00), dark: Color(red: 0.40, green: 0.20, blue: 0.60)),
            c400: ColorToken(light: Color(red: 0.50, green: 0.00, blue: 0.90), dark: Color(red: 0.55, green: 0.30, blue: 0.80)),
            c500: ColorToken(light: Color(red: 0.40, green: 0.00, blue: 0.70), dark: Color(red: 0.75, green: 0.50, blue: 1.00)),
            c600: ColorToken(light: Color(red: 0.30, green: 0.00, blue: 0.55), dark: Color(red: 0.85, green: 0.60, blue: 1.00)),
            c700: ColorToken(light: Color(red: 0.20, green: 0.00, blue: 0.40), dark: Color(red: 0.90, green: 0.70, blue: 1.00)),
            c800: ColorToken(light: Color(red: 0.10, green: 0.00, blue: 0.25), dark: Color(red: 0.95, green: 0.80, blue: 1.00)),
            c900: ColorToken(light: Color(red: 0.05, green: 0.00, blue: 0.15), dark: Color(red: 0.98, green: 0.90, blue: 1.00))
        ),
        error: ColorPalette.default.error,        // Mantener error colors iguales
        warning: ColorPalette.default.warning,    // Mantener warning colors iguales
        success: ColorPalette.default.success,    // Mantener success colors iguales
        info: ColorPalette.default.info,          // Mantener info colors iguales
        neutral: PaletteScale(
            c50: ColorToken(light: Color.white, dark: Color.black),
            c100: ColorToken(light: Color(white: 0.98), dark: Color(white: 0.05)),
            c200: ColorToken(light: Color(white: 0.95), dark: Color(white: 0.10)),
            c300: ColorToken(light: Color(white: 0.85), dark: Color(white: 0.20)),
            c400: ColorToken(light: Color(white: 0.70), dark: Color(white: 0.30)),
            c500: ColorToken(light: Color(white: 0.50), dark: Color(white: 0.50)),
            c600: ColorToken(light: Color(white: 0.40), dark: Color(white: 0.60)),
            c700: ColorToken(light: Color(white: 0.25), dark: Color(white: 0.75)),
            c800: ColorToken(light: Color(white: 0.10), dark: Color(white: 0.90)),
            c900: ColorToken(light: Color.black, dark: Color.white)
        )
    )

    /// Paleta en escala de grises (para accesibilidad monocromática)
    public static let grayscale = ColorPalette(
        primary: PaletteScale(
            c50: ColorToken(light: Color(white: 0.95), dark: Color(white: 0.15)),
            c100: ColorToken(light: Color(white: 0.90), dark: Color(white: 0.20)),
            c200: ColorToken(light: Color(white: 0.80), dark: Color(white: 0.30)),
            c300: ColorToken(light: Color(white: 0.70), dark: Color(white: 0.40)),
            c400: ColorToken(light: Color(white: 0.60), dark: Color(white: 0.50)),
            c500: ColorToken(light: Color(white: 0.40), dark: Color(white: 0.60)),
            c600: ColorToken(light: Color(white: 0.35), dark: Color(white: 0.65)),
            c700: ColorToken(light: Color(white: 0.25), dark: Color(white: 0.75)),
            c800: ColorToken(light: Color(white: 0.15), dark: Color(white: 0.85)),
            c900: ColorToken(light: Color(white: 0.05), dark: Color(white: 0.95))
        ),
        secondary: PaletteScale(
            c50: ColorToken(light: Color(white: 0.93), dark: Color(white: 0.17)),
            c100: ColorToken(light: Color(white: 0.87), dark: Color(white: 0.23)),
            c200: ColorToken(light: Color(white: 0.77), dark: Color(white: 0.33)),
            c300: ColorToken(light: Color(white: 0.67), dark: Color(white: 0.43)),
            c400: ColorToken(light: Color(white: 0.57), dark: Color(white: 0.53)),
            c500: ColorToken(light: Color(white: 0.43), dark: Color(white: 0.57)),
            c600: ColorToken(light: Color(white: 0.38), dark: Color(white: 0.62)),
            c700: ColorToken(light: Color(white: 0.28), dark: Color(white: 0.72)),
            c800: ColorToken(light: Color(white: 0.18), dark: Color(white: 0.82)),
            c900: ColorToken(light: Color(white: 0.08), dark: Color(white: 0.92))
        ),
        error: PaletteScale(
            c50: ColorToken(light: Color(white: 0.97), dark: Color(white: 0.13)),
            c100: ColorToken(light: Color(white: 0.92), dark: Color(white: 0.18)),
            c200: ColorToken(light: Color(white: 0.82), dark: Color(white: 0.28)),
            c300: ColorToken(light: Color(white: 0.72), dark: Color(white: 0.38)),
            c400: ColorToken(light: Color(white: 0.62), dark: Color(white: 0.48)),
            c500: ColorToken(light: Color(white: 0.38), dark: Color(white: 0.62)),
            c600: ColorToken(light: Color(white: 0.33), dark: Color(white: 0.67)),
            c700: ColorToken(light: Color(white: 0.23), dark: Color(white: 0.77)),
            c800: ColorToken(light: Color(white: 0.13), dark: Color(white: 0.87)),
            c900: ColorToken(light: Color(white: 0.03), dark: Color(white: 0.97))
        ),
        warning: PaletteScale(
            c50: ColorToken(light: Color(white: 0.98), dark: Color(white: 0.12)),
            c100: ColorToken(light: Color(white: 0.94), dark: Color(white: 0.16)),
            c200: ColorToken(light: Color(white: 0.84), dark: Color(white: 0.26)),
            c300: ColorToken(light: Color(white: 0.74), dark: Color(white: 0.36)),
            c400: ColorToken(light: Color(white: 0.64), dark: Color(white: 0.46)),
            c500: ColorToken(light: Color(white: 0.46), dark: Color(white: 0.64)),
            c600: ColorToken(light: Color(white: 0.41), dark: Color(white: 0.69)),
            c700: ColorToken(light: Color(white: 0.31), dark: Color(white: 0.79)),
            c800: ColorToken(light: Color(white: 0.21), dark: Color(white: 0.89)),
            c900: ColorToken(light: Color(white: 0.11), dark: Color(white: 0.99))
        ),
        success: PaletteScale(
            c50: ColorToken(light: Color(white: 0.97), dark: Color(white: 0.13)),
            c100: ColorToken(light: Color(white: 0.92), dark: Color(white: 0.18)),
            c200: ColorToken(light: Color(white: 0.82), dark: Color(white: 0.28)),
            c300: ColorToken(light: Color(white: 0.72), dark: Color(white: 0.38)),
            c400: ColorToken(light: Color(white: 0.62), dark: Color(white: 0.48)),
            c500: ColorToken(light: Color(white: 0.38), dark: Color(white: 0.62)),
            c600: ColorToken(light: Color(white: 0.33), dark: Color(white: 0.67)),
            c700: ColorToken(light: Color(white: 0.23), dark: Color(white: 0.77)),
            c800: ColorToken(light: Color(white: 0.13), dark: Color(white: 0.87)),
            c900: ColorToken(light: Color(white: 0.03), dark: Color(white: 0.97))
        ),
        info: PaletteScale(
            c50: ColorToken(light: Color(white: 0.98), dark: Color(white: 0.12)),
            c100: ColorToken(light: Color(white: 0.94), dark: Color(white: 0.16)),
            c200: ColorToken(light: Color(white: 0.84), dark: Color(white: 0.26)),
            c300: ColorToken(light: Color(white: 0.74), dark: Color(white: 0.36)),
            c400: ColorToken(light: Color(white: 0.64), dark: Color(white: 0.46)),
            c500: ColorToken(light: Color(white: 0.46), dark: Color(white: 0.64)),
            c600: ColorToken(light: Color(white: 0.41), dark: Color(white: 0.69)),
            c700: ColorToken(light: Color(white: 0.31), dark: Color(white: 0.79)),
            c800: ColorToken(light: Color(white: 0.21), dark: Color(white: 0.89)),
            c900: ColorToken(light: Color(white: 0.11), dark: Color(white: 0.99))
        ),
        neutral: PaletteScale(
            c50: ColorToken(light: Color(white: 0.99), dark: Color(white: 0.05)),
            c100: ColorToken(light: Color(white: 0.96), dark: Color(white: 0.10)),
            c200: ColorToken(light: Color(white: 0.92), dark: Color(white: 0.15)),
            c300: ColorToken(light: Color(white: 0.85), dark: Color(white: 0.22)),
            c400: ColorToken(light: Color(white: 0.75), dark: Color(white: 0.32)),
            c500: ColorToken(light: Color(white: 0.50), dark: Color(white: 0.50)),
            c600: ColorToken(light: Color(white: 0.40), dark: Color(white: 0.60)),
            c700: ColorToken(light: Color(white: 0.27), dark: Color(white: 0.73)),
            c800: ColorToken(light: Color(white: 0.17), dark: Color(white: 0.83)),
            c900: ColorToken(light: Color(white: 0.07), dark: Color(white: 0.93))
        )
    )
}
