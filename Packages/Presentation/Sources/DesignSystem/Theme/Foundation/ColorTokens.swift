import SwiftUI

/// Sistema de tokens de color base organizados por categoría.
///
/// Este sistema define todos los colores base utilizados en el theme system,
/// organizados en paletas semánticas (primary, secondary, error, warning, success, info, neutral).
/// Cada token tiene variantes para light y dark mode, siguiendo la nomenclatura Material Design.
///
/// ## Uso
/// ```swift
/// let buttonColor = ColorTokens.primary500
/// let backgroundColor = ColorTokens.neutral50
/// ```
///
/// ## Nomenclatura
/// - 50-100: Tonos muy claros
/// - 200-400: Tonos claros a medios
/// - 500: Tono base (color principal de la paleta)
/// - 600-800: Tonos oscuros
/// - 900: Tono muy oscuro
public enum ColorTokens: Sendable {

    // MARK: - Primary Colors

    /// Primary 50 - Tono más claro de primary
    public static let primary50 = ColorToken(
        light: Color(red: 0.93, green: 0.95, blue: 1.00),  // #EDF2FF
        dark: Color(red: 0.08, green: 0.11, blue: 0.20)    // #141C33
    )

    public static let primary100 = ColorToken(
        light: Color(red: 0.82, green: 0.88, blue: 1.00),  // #D1E0FF
        dark: Color(red: 0.12, green: 0.16, blue: 0.28)    // #1F2947
    )

    public static let primary200 = ColorToken(
        light: Color(red: 0.64, green: 0.76, blue: 1.00),  // #A3C2FF
        dark: Color(red: 0.18, green: 0.25, blue: 0.42)    // #2E406B
    )

    public static let primary300 = ColorToken(
        light: Color(red: 0.40, green: 0.60, blue: 1.00),  // #6699FF
        dark: Color(red: 0.26, green: 0.37, blue: 0.60)    // #425F99
    )

    public static let primary400 = ColorToken(
        light: Color(red: 0.20, green: 0.47, blue: 0.98),  // #3378FA
        dark: Color(red: 0.35, green: 0.50, blue: 0.80)    // #5980CC
    )

    /// Primary 500 - Color base de primary
    public static let primary500 = ColorToken(
        light: Color(red: 0.00, green: 0.35, blue: 0.95),  // #0059F2
        dark: Color(red: 0.40, green: 0.60, blue: 1.00)    // #6699FF
    )

    public static let primary600 = ColorToken(
        light: Color(red: 0.00, green: 0.31, blue: 0.85),  // #004FD9
        dark: Color(red: 0.50, green: 0.68, blue: 1.00)    // #80ADFF
    )

    public static let primary700 = ColorToken(
        light: Color(red: 0.00, green: 0.26, blue: 0.71),  // #0042B5
        dark: Color(red: 0.60, green: 0.76, blue: 1.00)    // #99C2FF
    )

    public static let primary800 = ColorToken(
        light: Color(red: 0.00, green: 0.20, blue: 0.56),  // #00338F
        dark: Color(red: 0.71, green: 0.84, blue: 1.00)    // #B5D6FF
    )

    public static let primary900 = ColorToken(
        light: Color(red: 0.00, green: 0.13, blue: 0.38),  // #002161
        dark: Color(red: 0.82, green: 0.91, blue: 1.00)    // #D1E9FF
    )

    // MARK: - Secondary Colors

    public static let secondary50 = ColorToken(
        light: Color(red: 0.98, green: 0.94, blue: 1.00),  // #FAF0FF
        dark: Color(red: 0.12, green: 0.08, blue: 0.16)    // #1F1429
    )

    public static let secondary100 = ColorToken(
        light: Color(red: 0.93, green: 0.85, blue: 1.00),  // #EDD9FF
        dark: Color(red: 0.18, green: 0.12, blue: 0.24)    // #2E1F3D
    )

    public static let secondary200 = ColorToken(
        light: Color(red: 0.85, green: 0.69, blue: 1.00),  // #D9B0FF
        dark: Color(red: 0.27, green: 0.18, blue: 0.36)    // #452E5C
    )

    public static let secondary300 = ColorToken(
        light: Color(red: 0.73, green: 0.47, blue: 1.00),  // #BA78FF
        dark: Color(red: 0.40, green: 0.27, blue: 0.53)    // #664587
    )

    public static let secondary400 = ColorToken(
        light: Color(red: 0.64, green: 0.27, blue: 0.98),  // #A345FA
        dark: Color(red: 0.53, green: 0.36, blue: 0.71)    // #875CB5
    )

    public static let secondary500 = ColorToken(
        light: Color(red: 0.55, green: 0.12, blue: 0.89),  // #8C1FE3
        dark: Color(red: 0.73, green: 0.47, blue: 1.00)    // #BA78FF
    )

    public static let secondary600 = ColorToken(
        light: Color(red: 0.49, green: 0.10, blue: 0.80),  // #7D1ACC
        dark: Color(red: 0.82, green: 0.60, blue: 1.00)    // #D199FF
    )

    public static let secondary700 = ColorToken(
        light: Color(red: 0.41, green: 0.08, blue: 0.67),  // #6814AB
        dark: Color(red: 0.88, green: 0.69, blue: 1.00)    // #E0B0FF
    )

    public static let secondary800 = ColorToken(
        light: Color(red: 0.32, green: 0.06, blue: 0.53),  // #520F87
        dark: Color(red: 0.93, green: 0.80, blue: 1.00)    // #EDCCFF
    )

    public static let secondary900 = ColorToken(
        light: Color(red: 0.22, green: 0.04, blue: 0.36),  // #380A5C
        dark: Color(red: 0.96, green: 0.88, blue: 1.00)    // #F5E0FF
    )

    // MARK: - Error Colors

    public static let error50 = ColorToken(
        light: Color(red: 1.00, green: 0.95, blue: 0.95),  // #FFF2F2
        dark: Color(red: 0.20, green: 0.08, blue: 0.08)    // #331414
    )

    public static let error100 = ColorToken(
        light: Color(red: 1.00, green: 0.88, blue: 0.88),  // #FFE0E0
        dark: Color(red: 0.28, green: 0.12, blue: 0.12)    // #471F1F
    )

    public static let error200 = ColorToken(
        light: Color(red: 1.00, green: 0.73, blue: 0.73),  // #FFBABA
        dark: Color(red: 0.42, green: 0.18, blue: 0.18)    // #6B2E2E
    )

    public static let error300 = ColorToken(
        light: Color(red: 1.00, green: 0.53, blue: 0.53),  // #FF8787
        dark: Color(red: 0.60, green: 0.26, blue: 0.26)    // #994242
    )

    public static let error400 = ColorToken(
        light: Color(red: 0.90, green: 0.20, blue: 0.20),  // #E63333 - Ajustado para dark mode
        dark: Color(red: 1.00, green: 0.45, blue: 0.45)    // #FF7373 - Más claro para contraste en dark
    )

    public static let error500 = ColorToken(
        light: Color(red: 0.80, green: 0.10, blue: 0.10),  // #CC1919 - Más oscuro para mejor contraste
        dark: Color(red: 1.00, green: 0.53, blue: 0.53)    // #FF8787
    )

    public static let error600 = ColorToken(
        light: Color(red: 0.83, green: 0.14, blue: 0.14),  // #D42424
        dark: Color(red: 1.00, green: 0.65, blue: 0.65)    // #FFA6A6
    )

    public static let error700 = ColorToken(
        light: Color(red: 0.70, green: 0.12, blue: 0.12),  // #B31E1E
        dark: Color(red: 1.00, green: 0.76, blue: 0.76)    // #FFC2C2
    )

    public static let error800 = ColorToken(
        light: Color(red: 0.56, green: 0.09, blue: 0.09),  // #8F1717
        dark: Color(red: 1.00, green: 0.85, blue: 0.85)    // #FFD9D9
    )

    public static let error900 = ColorToken(
        light: Color(red: 0.38, green: 0.06, blue: 0.06),  // #610F0F
        dark: Color(red: 0.15, green: 0.05, blue: 0.05)    // #260D0D - Más oscuro para dark mode backgrounds
    )

    // MARK: - Warning Colors

    public static let warning50 = ColorToken(
        light: Color(red: 1.00, green: 0.98, blue: 0.93),  // #FFF9ED
        dark: Color(red: 0.20, green: 0.16, blue: 0.08)    // #332914
    )

    public static let warning100 = ColorToken(
        light: Color(red: 1.00, green: 0.95, blue: 0.82),  // #FFF2D1
        dark: Color(red: 0.28, green: 0.23, blue: 0.12)    // #473B1F
    )

    public static let warning200 = ColorToken(
        light: Color(red: 1.00, green: 0.89, blue: 0.64),  // #FFE3A3
        dark: Color(red: 0.42, green: 0.35, blue: 0.18)    // #6B592E
    )

    public static let warning300 = ColorToken(
        light: Color(red: 1.00, green: 0.80, blue: 0.40),  // #FFCC66
        dark: Color(red: 0.60, green: 0.50, blue: 0.26)    // #998042
    )

    public static let warning400 = ColorToken(
        light: Color(red: 0.98, green: 0.71, blue: 0.20),  // #FAB533
        dark: Color(red: 0.80, green: 0.67, blue: 0.35)    // #CCAB59
    )

    public static let warning500 = ColorToken(
        light: Color(red: 0.95, green: 0.62, blue: 0.00),  // #F29F00
        dark: Color(red: 1.00, green: 0.80, blue: 0.40)    // #FFCC66
    )

    public static let warning600 = ColorToken(
        light: Color(red: 0.85, green: 0.55, blue: 0.00),  // #D98C00
        dark: Color(red: 1.00, green: 0.87, blue: 0.53)    // #FFDE87
    )

    public static let warning700 = ColorToken(
        light: Color(red: 0.71, green: 0.46, blue: 0.00),  // #B57500
        dark: Color(red: 1.00, green: 0.92, blue: 0.64)    // #FFEBA3
    )

    public static let warning800 = ColorToken(
        light: Color(red: 0.56, green: 0.36, blue: 0.00),  // #8F5C00
        dark: Color(red: 1.00, green: 0.96, blue: 0.76)    // #FFF5C2
    )

    public static let warning900 = ColorToken(
        light: Color(red: 0.38, green: 0.25, blue: 0.00),  // #613F00
        dark: Color(red: 1.00, green: 0.98, blue: 0.85)    // #FFFAD9
    )

    // MARK: - Success Colors

    public static let success50 = ColorToken(
        light: Color(red: 0.94, green: 0.99, blue: 0.95),  // #F0FDF2
        dark: Color(red: 0.08, green: 0.16, blue: 0.10)    // #14291A
    )

    public static let success100 = ColorToken(
        light: Color(red: 0.86, green: 0.98, blue: 0.89),  // #DBF9E3
        dark: Color(red: 0.12, green: 0.24, blue: 0.15)    // #1F3D26
    )

    public static let success200 = ColorToken(
        light: Color(red: 0.69, green: 0.95, blue: 0.76),  // #B0F2C2
        dark: Color(red: 0.18, green: 0.36, blue: 0.22)    // #2E5C38
    )

    public static let success300 = ColorToken(
        light: Color(red: 0.47, green: 0.89, blue: 0.60),  // #78E399
        dark: Color(red: 0.27, green: 0.53, blue: 0.33)    // #458754
    )

    public static let success400 = ColorToken(
        light: Color(red: 0.27, green: 0.80, blue: 0.45),  // #45CC73
        dark: Color(red: 0.36, green: 0.71, blue: 0.45)    // #5CB571
    )

    public static let success500 = ColorToken(
        light: Color(red: 0.13, green: 0.70, blue: 0.33),  // #21B354
        dark: Color(red: 0.47, green: 0.89, blue: 0.60)    // #78E399
    )

    public static let success600 = ColorToken(
        light: Color(red: 0.11, green: 0.62, blue: 0.29),  // #1C9E4A
        dark: Color(red: 0.60, green: 0.95, blue: 0.71)    // #99F2B5
    )

    public static let success700 = ColorToken(
        light: Color(red: 0.09, green: 0.52, blue: 0.25),  // #17853F
        dark: Color(red: 0.69, green: 0.98, blue: 0.80)    // #B0F9CC
    )

    public static let success800 = ColorToken(
        light: Color(red: 0.07, green: 0.42, blue: 0.20),  // #126B32
        dark: Color(red: 0.80, green: 1.00, blue: 0.87)    // #CCFFDE
    )

    public static let success900 = ColorToken(
        light: Color(red: 0.05, green: 0.28, blue: 0.13),  // #0D4721
        dark: Color(red: 0.88, green: 1.00, blue: 0.93)    // #E0FFED
    )

    // MARK: - Info Colors

    public static let info50 = ColorToken(
        light: Color(red: 0.94, green: 0.98, blue: 1.00),  // #F0FAFF
        dark: Color(red: 0.08, green: 0.14, blue: 0.20)    // #142433
    )

    public static let info100 = ColorToken(
        light: Color(red: 0.85, green: 0.95, blue: 1.00),  // #D9F2FF
        dark: Color(red: 0.12, green: 0.21, blue: 0.28)    // #1F3547
    )

    public static let info200 = ColorToken(
        light: Color(red: 0.69, green: 0.89, blue: 1.00),  // #B0E3FF
        dark: Color(red: 0.18, green: 0.31, blue: 0.42)    // #2E4F6B
    )

    public static let info300 = ColorToken(
        light: Color(red: 0.47, green: 0.80, blue: 1.00),  // #78CCFF
        dark: Color(red: 0.27, green: 0.47, blue: 0.60)    // #457899
    )

    public static let info400 = ColorToken(
        light: Color(red: 0.27, green: 0.69, blue: 0.98),  // #45B0FA
        dark: Color(red: 0.36, green: 0.62, blue: 0.80)    // #5C9ECC
    )

    public static let info500 = ColorToken(
        light: Color(red: 0.13, green: 0.59, blue: 0.95),  // #2196F2
        dark: Color(red: 0.47, green: 0.80, blue: 1.00)    // #78CCFF
    )

    public static let info600 = ColorToken(
        light: Color(red: 0.11, green: 0.52, blue: 0.85),  // #1C85D9
        dark: Color(red: 0.60, green: 0.87, blue: 1.00)    // #99DEFF
    )

    public static let info700 = ColorToken(
        light: Color(red: 0.09, green: 0.44, blue: 0.71),  // #1770B5
        dark: Color(red: 0.69, green: 0.92, blue: 1.00)    // #B0EBFF
    )

    public static let info800 = ColorToken(
        light: Color(red: 0.07, green: 0.35, blue: 0.56),  // #12598F
        dark: Color(red: 0.80, green: 0.96, blue: 1.00)    // #CCF5FF
    )

    public static let info900 = ColorToken(
        light: Color(red: 0.05, green: 0.23, blue: 0.38),  // #0D3B61
        dark: Color(red: 0.88, green: 0.98, blue: 1.00)    // #E0FAFF
    )

    // MARK: - Neutral/Gray Colors

    public static let neutral50 = ColorToken(
        light: Color(red: 0.98, green: 0.98, blue: 0.99),  // #FAFBFC
        dark: Color(red: 0.07, green: 0.08, blue: 0.09)    // #121416
    )

    public static let neutral100 = ColorToken(
        light: Color(red: 0.96, green: 0.97, blue: 0.98),  // #F5F7F9
        dark: Color(red: 0.11, green: 0.12, blue: 0.14)    // #1C1F23
    )

    public static let neutral200 = ColorToken(
        light: Color(red: 0.93, green: 0.94, blue: 0.96),  // #EDF0F5
        dark: Color(red: 0.15, green: 0.17, blue: 0.20)    // #262B33
    )

    public static let neutral300 = ColorToken(
        light: Color(red: 0.87, green: 0.89, blue: 0.92),  // #DEE3EB
        dark: Color(red: 0.22, green: 0.25, blue: 0.29)    // #38404A
    )

    public static let neutral400 = ColorToken(
        light: Color(red: 0.76, green: 0.79, blue: 0.85),  // #C2C9D9
        dark: Color(red: 0.31, green: 0.35, blue: 0.40)    // #4F5966
    )

    public static let neutral500 = ColorToken(
        light: Color(red: 0.61, green: 0.65, blue: 0.73),  // #9CA6BA
        dark: Color(red: 0.42, green: 0.47, blue: 0.54)    // #6B788A
    )

    public static let neutral600 = ColorToken(
        light: Color(red: 0.49, green: 0.54, blue: 0.63),  // #7D8AA1
        dark: Color(red: 0.54, green: 0.60, blue: 0.69)    // #8A99B0
    )

    public static let neutral700 = ColorToken(
        light: Color(red: 0.38, green: 0.43, blue: 0.52),  // #616E85
        dark: Color(red: 0.69, green: 0.75, blue: 0.85)    // #B0BFD9
    )

    public static let neutral800 = ColorToken(
        light: Color(red: 0.27, green: 0.32, blue: 0.40),  // #455166
        dark: Color(red: 0.83, green: 0.87, blue: 0.93)    // #D4DDED
    )

    public static let neutral900 = ColorToken(
        light: Color(red: 0.16, green: 0.20, blue: 0.27),  // #293345
        dark: Color(red: 0.92, green: 0.94, blue: 0.97)    // #EBF0F7
    )
}

// MARK: - Glass-Enhanced Colors

extension ColorTokens {
    /// Color base para efectos Glass subtle
    public static let glassSubtle = Color.white.opacity(0.05)

    /// Color base para efectos Glass standard
    public static let glassStandard = Color.white.opacity(0.1)

    /// Color base para efectos Glass prominent
    public static let glassProminent = Color.white.opacity(0.15)

    /// Color base para efectos Glass immersive
    public static let glassImmersive = Color.white.opacity(0.2)

    /// Color base para efectos Glass desktop (macOS específico)
    public static let glassDesktop = Color.white.opacity(0.12)

    /// Color de highlight para Glass effects
    public static let glassHighlight = Color.white.opacity(0.25)

    /// Color de shadow para Glass effects
    public static let glassShadow = Color.black.opacity(0.15)

    /// Color de overlay para Glass backgrounds
    public static let glassOverlay = Color.white.opacity(0.06)

    /// Color de refraction para Glass effects
    public static let glassRefraction = Color.white.opacity(0.18)

    /// Superficie con efecto Glass para cards
    public static let surfaceGlass = Color.white.opacity(0.08)

    /// Superficie con efecto Glass subtle para backgrounds
    public static let surfaceGlassSubtle = Color.white.opacity(0.04)

    /// Superficie con efecto Glass prominent para modales
    public static let surfaceGlassProminent = Color.white.opacity(0.12)

    /// Superficie con efecto Glass para overlays
    public static let surfaceGlassOverlay = Color.black.opacity(0.3)

    /// Color de Glass para modo oscuro (inverso)
    public static let glassDark = Color.black.opacity(0.3)

    /// Color de highlight para modo oscuro
    public static let glassHighlightDark = Color.white.opacity(0.15)
}

// MARK: - Glass Status Containers

extension ColorTokens {
    /// Background para success con Glass
    public static let successGlassBackground = Color.green.opacity(0.12)

    /// Background para error con Glass
    public static let errorGlassBackground = Color.red.opacity(0.12)

    /// Background para warning con Glass
    public static let warningGlassBackground = Color.orange.opacity(0.12)

    /// Background para info con Glass
    public static let infoGlassBackground = Color.blue.opacity(0.12)
}

// MARK: - ColorToken

/// Representa un token de color con variantes para light y dark mode.
public struct ColorToken: Sendable {
    /// Color para light mode
    public let light: Color

    /// Color para dark mode
    public let dark: Color

    /// Inicializa un ColorToken con colores para light y dark mode
    public init(light: Color, dark: Color) {
        self.light = light
        self.dark = dark
    }

    /// Resuelve el color apropiado según el esquema de color actual
    /// - Parameter colorScheme: El esquema de color actual (.light o .dark)
    /// - Returns: El color apropiado para el esquema de color
    public func resolve(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? dark : light
    }
}
