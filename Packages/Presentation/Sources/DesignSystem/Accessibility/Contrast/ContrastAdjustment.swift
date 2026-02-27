//
//  ContrastAdjustment.swift
//  EduAccessibility
//
//  Color contrast adjustment algorithms following WCAG 2.1 AAA standards.
//
//  Features:
//  - Contrast ratio calculation (WCAG 2.1 formula)
//  - Automatic color adjustment to meet minimum ratios
//  - WCAG compliance levels (AAA, AA for normal and large text)
//  - Enhanced contrast mode (10:1 ratio)
//  - Border thickness adjustment for High Contrast
//
//  WCAG 2.1 Ratios:
//  - AAA Normal Text: 7:1
//  - AAA Large Text: 4.5:1
//  - AA Normal Text: 4.5:1
//  - AA Large Text: 3:1
//  - Enhanced: 10:1
//
//  Swift 6.2 strict concurrency compliant
//

import SwiftUI

/// Algoritmos para ajustar contraste de colores según WCAG 2.1 AAA.
///
/// Provee funciones para:
/// - Calcular contrast ratio entre colores
/// - Ajustar colores para cumplir WCAG AAA (7:1 para texto normal, 4.5:1 para texto grande)
/// - Aumentar border thickness en High Contrast mode
///
/// ## Ejemplo
/// ```swift
/// let adjustedColor = ContrastAdjustment.ensureContrast(
///     foreground: .blue,
///     background: .white,
///     minimumRatio: .wcagAAA
/// )
/// ```
public enum ContrastAdjustment {

    // MARK: - WCAG Ratios

    /// Ratios de contraste según WCAG 2.1
    public enum WCAGRatio: Double, Sendable {
        /// WCAG AAA para texto normal (7:1)
        case wcagAAA = 7.0

        /// WCAG AAA para texto grande (4.5:1)
        /// Nota: Mismo ratio que wcagAA por especificación WCAG
        case wcagAAALarge = 4.5

        /// WCAG AA para texto normal (4.5:1)
        /// Usamos 4.51 para evitar raw value duplicado en Swift
        case wcagAA = 4.51

        /// WCAG AA para texto grande (3:1)
        case wcagAALarge = 3.0

        /// Enhanced contrast para High Contrast mode (10:1)
        case enhanced = 10.0
    }

    // MARK: - Contrast Ratio Calculation

    /// Calcula el contrast ratio entre dos colores según WCAG 2.1
    /// - Parameters:
    ///   - foreground: Color de primer plano
    ///   - background: Color de fondo
    /// - Returns: Contrast ratio (1:1 a 21:1)
    public static func contrastRatio(
        between foreground: Color,
        and background: Color
    ) -> Double {
        let fgLuminance = relativeLuminance(of: foreground)
        let bgLuminance = relativeLuminance(of: background)

        let lighter = max(fgLuminance, bgLuminance)
        let darker = min(fgLuminance, bgLuminance)

        return (lighter + 0.05) / (darker + 0.05)
    }

    /// Calcula la luminancia relativa de un color según WCAG 2.1
    /// - Parameter color: Color a analizar
    /// - Returns: Luminancia relativa (0.0 a 1.0)
    private static func relativeLuminance(of color: Color) -> Double {
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        let uiColor = UIColor(color)
        #elseif os(macOS)
        let uiColor = NSColor(color)
        #endif

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let adjustedRed = adjustColorComponent(red)
        let adjustedGreen = adjustColorComponent(green)
        let adjustedBlue = adjustColorComponent(blue)

        return 0.2126 * adjustedRed + 0.7152 * adjustedGreen + 0.0722 * adjustedBlue
    }

    private static func adjustColorComponent(_ component: CGFloat) -> Double {
        let value = Double(component)
        if value <= 0.03928 {
            return value / 12.92
        } else {
            return pow((value + 0.055) / 1.055, 2.4)
        }
    }

    // MARK: - Contrast Adjustment

    /// Asegura que un color tenga suficiente contraste contra un fondo
    /// - Parameters:
    ///   - foreground: Color de primer plano a ajustar
    ///   - background: Color de fondo
    ///   - minimumRatio: Ratio mínimo requerido
    ///   - preferDarker: Si preferir oscurecer vs aclarar
    /// - Returns: Color ajustado que cumple el ratio mínimo
    public static func ensureContrast(
        foreground: Color,
        background: Color,
        minimumRatio: WCAGRatio = .wcagAAA,
        preferDarker: Bool = true
    ) -> Color {
        let currentRatio = contrastRatio(between: foreground, and: background)

        guard currentRatio < minimumRatio.rawValue else {
            return foreground
        }

        // Intentar ajustar el color
        return adjustColorForContrast(
            foreground,
            against: background,
            targetRatio: minimumRatio.rawValue,
            preferDarker: preferDarker
        )
    }

    private static func adjustColorForContrast(
        _ color: Color,
        against background: Color,
        targetRatio: Double,
        preferDarker: Bool
    ) -> Color {
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        var uiColor = UIColor(color)
        #elseif os(macOS)
        var uiColor = NSColor(color)
        #endif

        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        // Binary search para encontrar el brightness correcto
        var minBrightness: CGFloat = 0.0
        var maxBrightness: CGFloat = 1.0
        var iterations = 0
        let maxIterations = 20

        while iterations < maxIterations {
            let testBrightness = (minBrightness + maxBrightness) / 2.0

            #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
            let testColor = UIColor(hue: hue, saturation: saturation, brightness: testBrightness, alpha: alpha)
            #elseif os(macOS)
            let testColor = NSColor(hue: hue, saturation: saturation, brightness: testBrightness, alpha: alpha)
            #endif

            let ratio = contrastRatio(between: Color(testColor), and: background)

            if abs(ratio - targetRatio) < 0.1 {
                return Color(testColor)
            }

            if ratio < targetRatio {
                if preferDarker {
                    maxBrightness = testBrightness
                } else {
                    minBrightness = testBrightness
                }
            } else {
                if preferDarker {
                    minBrightness = testBrightness
                } else {
                    maxBrightness = testBrightness
                }
            }

            iterations += 1
        }

        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        uiColor = UIColor(hue: hue, saturation: saturation, brightness: (minBrightness + maxBrightness) / 2.0, alpha: alpha)
        #elseif os(macOS)
        uiColor = NSColor(hue: hue, saturation: saturation, brightness: (minBrightness + maxBrightness) / 2.0, alpha: alpha)
        #endif

        return Color(uiColor)
    }

    // MARK: - Border Thickness Adjustment

    /// Calcula el grosor de borde apropiado según High Contrast mode
    /// - Parameter baseThickness: Grosor base
    /// - Returns: Grosor ajustado
    @MainActor
    public static func adjustedBorderThickness(_ baseThickness: CGFloat) -> CGFloat {
        if HighContrastSupport.isEnabled {
            return baseThickness * 1.5
        } else {
            return baseThickness
        }
    }

    /// Calcula el grosor de borde mínimo recomendado
    /// - Returns: Grosor mínimo (1.0 normal, 1.5 High Contrast)
    @MainActor
    public static var minimumBorderThickness: CGFloat {
        HighContrastSupport.isEnabled ? 1.5 : 1.0
    }

    // MARK: - Color Utilities

    /// Verifica si un color es considerado "claro"
    /// - Parameter color: Color a verificar
    /// - Returns: true si es claro (luminancia > 0.5)
    public static func isLightColor(_ color: Color) -> Bool {
        relativeLuminance(of: color) > 0.5
    }

    /// Verifica si un color es considerado "oscuro"
    /// - Parameter color: Color a verificar
    /// - Returns: true si es oscuro (luminancia <= 0.5)
    public static func isDarkColor(_ color: Color) -> Bool {
        !isLightColor(color)
    }

    /// Obtiene un color de texto apropiado para un fondo
    /// - Parameters:
    ///   - background: Color de fondo
    ///   - lightText: Color de texto claro (default: white)
    ///   - darkText: Color de texto oscuro (default: black)
    /// - Returns: Color de texto con suficiente contraste
    public static func appropriateTextColor(
        for background: Color,
        lightText: Color = .white,
        darkText: Color = .black
    ) -> Color {
        let lightRatio = contrastRatio(between: lightText, and: background)
        let darkRatio = contrastRatio(between: darkText, and: background)

        return lightRatio > darkRatio ? lightText : darkText
    }
}

// MARK: - Color Extensions

extension Color {
    /// Ajusta este color para tener suficiente contraste contra un fondo
    /// - Parameters:
    ///   - background: Color de fondo
    ///   - minimumRatio: Ratio mínimo requerido
    /// - Returns: Color ajustado
    public func adjustedForContrast(
        against background: Color,
        minimumRatio: ContrastAdjustment.WCAGRatio = .wcagAAA
    ) -> Color {
        ContrastAdjustment.ensureContrast(
            foreground: self,
            background: background,
            minimumRatio: minimumRatio
        )
    }

    /// Calcula el contrast ratio de este color contra otro
    /// - Parameter other: Otro color
    /// - Returns: Contrast ratio
    public func contrastRatio(against other: Color) -> Double {
        ContrastAdjustment.contrastRatio(between: self, and: other)
    }

    /// Verifica si este color cumple WCAG AAA contra un fondo
    /// - Parameter background: Color de fondo
    /// - Returns: true si cumple WCAG AAA (7:1)
    public func meetsWCAGAAA(against background: Color) -> Bool {
        contrastRatio(against: background) >= ContrastAdjustment.WCAGRatio.wcagAAA.rawValue
    }

    /// Verifica si este color cumple WCAG AA contra un fondo
    /// - Parameter background: Color de fondo
    /// - Returns: true si cumple WCAG AA (4.5:1)
    public func meetsWCAGAA(against background: Color) -> Bool {
        contrastRatio(against: background) >= ContrastAdjustment.WCAGRatio.wcagAA.rawValue
    }
}
