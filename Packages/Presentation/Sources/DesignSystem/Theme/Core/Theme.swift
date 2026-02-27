import SwiftUI

/// Configuración completa de un tema de la aplicación.
///
/// Theme encapsula todos los aspectos visuales de la aplicación:
/// colores, tipografía, espaciado, radios de esquina y sombras.
///
/// ## Uso
/// ```swift
/// let theme = Theme.default
/// let darkTheme = Theme.dark
/// let customTheme = Theme.custom(palette: myPalette)
/// ```
///
/// ## Temas Predefinidos
/// - `.default`: Tema principal con colores vibrantes
/// - `.dark`: Tema optimizado para dark mode
/// - `.highContrast`: Tema de alto contraste para accesibilidad
/// - `.grayscale`: Tema monocromático para accesibilidad
public struct Theme: Sendable, Equatable, Identifiable {

    // MARK: - Properties

    /// Identificador único del tema
    public let id: String

    /// Nombre del tema
    public let name: String

    /// Paleta de colores del tema
    public let colorPalette: ColorPalette

    /// Configuración de tipografía
    public let typography: Typography

    /// Configuración de espaciado
    public let spacing: Spacing

    /// Configuración de radios de esquina
    public let cornerRadius: CornerRadius

    /// Configuración de sombras
    public let shadows: Shadows

    // MARK: - Initializer

    /// Crea un tema personalizado
    public init(
        id: String,
        name: String,
        colorPalette: ColorPalette,
        typography: Typography = .default,
        spacing: Spacing = .default,
        cornerRadius: CornerRadius = .default,
        shadows: Shadows = .default
    ) {
        self.id = id
        self.name = name
        self.colorPalette = colorPalette
        self.typography = typography
        self.spacing = spacing
        self.cornerRadius = cornerRadius
        self.shadows = shadows
    }

    // MARK: - Equatable

    public static func == (lhs: Theme, rhs: Theme) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Predefined Themes

extension Theme {

    /// Tema por defecto con colores vibrantes
    public static let `default` = Theme(
        id: "default",
        name: "Default",
        colorPalette: .default
    )

    /// Tema optimizado para dark mode
    public static let dark = Theme(
        id: "dark",
        name: "Dark",
        colorPalette: .default  // Usa la misma paleta, los colores se adaptan automáticamente
    )

    /// Tema de alto contraste para accesibilidad
    public static let highContrast = Theme(
        id: "highContrast",
        name: "High Contrast",
        colorPalette: .highContrast
    )

    /// Tema monocromático para accesibilidad
    public static let grayscale = Theme(
        id: "grayscale",
        name: "Grayscale",
        colorPalette: .grayscale
    )

    /// Crea un tema personalizado con una paleta específica
    public static func custom(
        id: String = "custom",
        name: String = "Custom",
        palette: ColorPalette,
        typography: Typography = .default,
        spacing: Spacing = .default,
        cornerRadius: CornerRadius = .default,
        shadows: Shadows = .default
    ) -> Theme {
        Theme(
            id: id,
            name: name,
            colorPalette: palette,
            typography: typography,
            spacing: spacing,
            cornerRadius: cornerRadius,
            shadows: shadows
        )
    }
}

// MARK: - Typography

/// Configuración de tipografía del tema
public struct Typography: Sendable, Equatable {

    /// Font family principal
    public let fontFamily: String

    /// Font family para código
    public let monospaceFontFamily: String

    /// Escala de tamaños base
    public let baseSize: CGFloat

    /// Line height multiplier
    public let lineHeightMultiplier: CGFloat

    /// Letter spacing
    public let letterSpacing: CGFloat

    public init(
        fontFamily: String = "System",
        monospaceFontFamily: String = "SF Mono",
        baseSize: CGFloat = 16,
        lineHeightMultiplier: CGFloat = 1.5,
        letterSpacing: CGFloat = 0
    ) {
        self.fontFamily = fontFamily
        self.monospaceFontFamily = monospaceFontFamily
        self.baseSize = baseSize
        self.lineHeightMultiplier = lineHeightMultiplier
        self.letterSpacing = letterSpacing
    }

    /// Configuración de tipografía por defecto
    public static let `default` = Typography()

    /// Configuración de tipografía compacta
    public static let compact = Typography(
        baseSize: 14,
        lineHeightMultiplier: 1.4
    )

    /// Configuración de tipografía grande (accesibilidad)
    public static let large = Typography(
        baseSize: 18,
        lineHeightMultiplier: 1.6
    )
}

// MARK: - Spacing

/// Configuración de espaciado del tema
public struct Spacing: Sendable, Equatable {

    /// Espaciado extra pequeño (4pt)
    public let xs: CGFloat

    /// Espaciado pequeño (8pt)
    public let sm: CGFloat

    /// Espaciado medio (16pt)
    public let md: CGFloat

    /// Espaciado grande (24pt)
    public let lg: CGFloat

    /// Espaciado extra grande (32pt)
    public let xl: CGFloat

    /// Espaciado doble extra grande (48pt)
    public let xxl: CGFloat

    public init(
        xs: CGFloat = 4,
        sm: CGFloat = 8,
        md: CGFloat = 16,
        lg: CGFloat = 24,
        xl: CGFloat = 32,
        xxl: CGFloat = 48
    ) {
        self.xs = xs
        self.sm = sm
        self.md = md
        self.lg = lg
        self.xl = xl
        self.xxl = xxl
    }

    /// Configuración de espaciado por defecto
    public static let `default` = Spacing()

    /// Configuración de espaciado compacto
    public static let compact = Spacing(
        xs: 2,
        sm: 4,
        md: 8,
        lg: 12,
        xl: 16,
        xxl: 24
    )

    /// Configuración de espaciado amplio
    public static let generous = Spacing(
        xs: 8,
        sm: 12,
        md: 20,
        lg: 32,
        xl: 48,
        xxl: 64
    )
}

// MARK: - CornerRadius

/// Configuración de radios de esquina del tema
public struct CornerRadius: Sendable, Equatable {

    /// Radio extra pequeño (2pt)
    public let xs: CGFloat

    /// Radio pequeño (4pt)
    public let sm: CGFloat

    /// Radio medio (8pt)
    public let md: CGFloat

    /// Radio grande (12pt)
    public let lg: CGFloat

    /// Radio extra grande (16pt)
    public let xl: CGFloat

    /// Radio completo (pill/circle)
    public let full: CGFloat

    public init(
        xs: CGFloat = 2,
        sm: CGFloat = 4,
        md: CGFloat = 8,
        lg: CGFloat = 12,
        xl: CGFloat = 16,
        full: CGFloat = 9999
    ) {
        self.xs = xs
        self.sm = sm
        self.md = md
        self.lg = lg
        self.xl = xl
        self.full = full
    }

    /// Configuración de radios por defecto
    public static let `default` = CornerRadius()

    /// Sin radios (cuadrado)
    public static let square = CornerRadius(
        xs: 0,
        sm: 0,
        md: 0,
        lg: 0,
        xl: 0,
        full: 0
    )

    /// Radios suaves
    public static let soft = CornerRadius(
        xs: 4,
        sm: 8,
        md: 12,
        lg: 16,
        xl: 24
    )
}

// MARK: - Shadows

/// Configuración de sombras del tema
public struct Shadows: Sendable, Equatable {

    /// Sombra pequeña (elevación 1)
    public let sm: Shadow

    /// Sombra media (elevación 2-3)
    public let md: Shadow

    /// Sombra grande (elevación 4-5)
    public let lg: Shadow

    /// Sombra extra grande (elevación 6+)
    public let xl: Shadow

    public init(
        sm: Shadow = Shadow(radius: 2, y: 1, opacity: 0.1),
        md: Shadow = Shadow(radius: 4, y: 2, opacity: 0.12),
        lg: Shadow = Shadow(radius: 8, y: 4, opacity: 0.15),
        xl: Shadow = Shadow(radius: 16, y: 8, opacity: 0.18)
    ) {
        self.sm = sm
        self.md = md
        self.lg = lg
        self.xl = xl
    }

    /// Configuración de sombras por defecto
    public static let `default` = Shadows()

    /// Sin sombras
    public static let none = Shadows(
        sm: Shadow(radius: 0, y: 0, opacity: 0),
        md: Shadow(radius: 0, y: 0, opacity: 0),
        lg: Shadow(radius: 0, y: 0, opacity: 0),
        xl: Shadow(radius: 0, y: 0, opacity: 0)
    )

    /// Sombras pronunciadas
    public static let strong = Shadows(
        sm: Shadow(radius: 4, y: 2, opacity: 0.15),
        md: Shadow(radius: 8, y: 4, opacity: 0.18),
        lg: Shadow(radius: 16, y: 8, opacity: 0.22),
        xl: Shadow(radius: 24, y: 12, opacity: 0.25)
    )
}

// MARK: - Shadow

/// Configuración individual de una sombra
public struct Shadow: Sendable, Equatable {

    /// Radio de difuminado
    public let radius: CGFloat

    /// Offset horizontal
    public let x: CGFloat

    /// Offset vertical
    public let y: CGFloat

    /// Opacidad de la sombra
    public let opacity: Double

    public init(
        radius: CGFloat,
        x: CGFloat = 0,
        y: CGFloat,
        opacity: Double
    ) {
        self.radius = radius
        self.x = x
        self.y = y
        self.opacity = opacity
    }
}

// MARK: - Theme Access Helpers

extension Theme {

    /// Acceso conveniente a semantic colors del tema
    public var colors: SemanticColorsAccessor {
        SemanticColorsAccessor()
    }
}

/// Accessor para semantic colors (simplifica acceso en componentes)
public struct SemanticColorsAccessor: Sendable {
    // Los colores se acceden via Color.theme.* que ya implementamos en Task 1
    // Este accessor está aquí para consistencia con la API de Theme
}
