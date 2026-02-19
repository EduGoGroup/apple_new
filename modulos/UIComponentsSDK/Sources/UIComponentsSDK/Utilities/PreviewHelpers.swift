import SwiftUI
import DesignSystemSDK

// MARK: - Platform Wrappers

/// Helper para simular diferentes plataformas en Xcode Previews.
///
/// Uso:
/// ```swift
/// #Preview("iPhone 15 Pro") {
///     MyView()
///         .previewDevice(.iPhone15Pro)
/// }
/// ```
@MainActor
public struct PreviewDevice {
    public let name: String
    public let displayName: String

    private init(name: String, displayName: String) {
        self.name = name
        self.displayName = displayName
    }

    // MARK: - iOS Devices

    public static let iPhone15Pro = PreviewDevice(
        name: "iPhone 15 Pro",
        displayName: "iPhone 15 Pro"
    )

    public static let iPhone15ProMax = PreviewDevice(
        name: "iPhone 15 Pro Max",
        displayName: "iPhone 15 Pro Max"
    )

    public static let iPhoneSE = PreviewDevice(
        name: "iPhone SE (3rd generation)",
        displayName: "iPhone SE"
    )

    public static let iPadPro13 = PreviewDevice(
        name: "iPad Pro (12.9-inch) (6th generation)",
        displayName: "iPad Pro 12.9\""
    )

    public static let iPadAir = PreviewDevice(
        name: "iPad Air (5th generation)",
        displayName: "iPad Air"
    )

    // MARK: - macOS

    public static let macOS = PreviewDevice(
        name: "Mac",
        displayName: "macOS"
    )

    // MARK: - visionOS

    public static let appleVisionPro = PreviewDevice(
        name: "Apple Vision Pro",
        displayName: "Apple Vision Pro"
    )

    // MARK: - watchOS

    public static let appleWatchSeries9_41mm = PreviewDevice(
        name: "Apple Watch Series 9 (41mm)",
        displayName: "Watch 41mm"
    )

    public static let appleWatchSeries9_45mm = PreviewDevice(
        name: "Apple Watch Series 9 (45mm)",
        displayName: "Watch 45mm"
    )

    public static let appleWatchUltra2 = PreviewDevice(
        name: "Apple Watch Ultra 2",
        displayName: "Watch Ultra 2"
    )

    // MARK: - tvOS

    public static let appleTV4K = PreviewDevice(
        name: "Apple TV 4K (3rd generation)",
        displayName: "Apple TV 4K"
    )

    // MARK: - All Platforms Collection

    /// Colección de dispositivos representativos de cada plataforma
    public static let allPlatforms: [PreviewDevice] = [
        .iPhone15Pro,
        .iPadPro13,
        .macOS,
        .appleVisionPro,
        .appleWatchSeries9_45mm,
        .appleTV4K
    ]
}

extension View {
    /// Aplica una configuración de dispositivo específica para previews.
    public func previewDevice(_ device: PreviewDevice) -> some View {
        #if os(iOS)
        self.previewDevice(PreviewDevice(rawValue: device.name))
            .previewDisplayName(device.displayName)
        #elseif os(macOS)
        self.previewDisplayName(device.displayName)
        #else
        self
        #endif
    }
}

// MARK: - Color Scheme Helpers

extension View {
    /// Wrapper conveniente para probar modo claro y oscuro simultáneamente.
    public func previewAllColorSchemes() -> some View {
        ForEach(ColorScheme.allCases, id: \.self) { scheme in
            self.preferredColorScheme(scheme)
                .previewDisplayName(scheme == .light ? "Light Mode" : "Dark Mode")
        }
    }
}

// MARK: - Layout Helpers

@MainActor
public struct PreviewContainer<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let backgroundColor: Color

    public init(
        padding: CGFloat = 16,
        backgroundColor: Color = Color(white: 0.95),
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.backgroundColor = backgroundColor
    }

    public var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(backgroundColor.ignoresSafeArea())
    }
}

// MARK: - Size Class Helpers

#if os(iOS)
extension View {
    /// Simula diferentes size classes para previews de iOS.
    public func previewSizeClasses(
        horizontal: UserInterfaceSizeClass = .regular,
        vertical: UserInterfaceSizeClass = .regular
    ) -> some View {
        self.environment(\.horizontalSizeClass, horizontal)
            .environment(\.verticalSizeClass, vertical)
    }

    /// Preview con todas las combinaciones de size classes.
    public func previewAllSizeClasses() -> some View {
        Group {
            self.previewSizeClasses(horizontal: .compact, vertical: .regular)
                .previewDisplayName("Compact Width, Regular Height (iPhone Portrait)")

            self.previewSizeClasses(horizontal: .regular, vertical: .compact)
                .previewDisplayName("Regular Width, Compact Height (iPhone Landscape)")

            self.previewSizeClasses(horizontal: .regular, vertical: .regular)
                .previewDisplayName("Regular Width & Height (iPad)")
        }
    }
}
#endif

// MARK: - Dynamic Type Helpers

extension View {
    /// Preview con un tamaño de fuente específico de Dynamic Type.
    public func previewDynamicTypeSize(_ size: DynamicTypeSize) -> some View {
        self.environment(\.dynamicTypeSize, size)
            .previewDisplayName("Dynamic Type: \(size.description)")
    }

    /// Preview con todos los tamaños comunes de Dynamic Type.
    public func previewCommonDynamicTypeSizes() -> some View {
        ForEach([DynamicTypeSize.small, .medium, .large, .xLarge, .xxLarge, .accessibility2, .accessibility4], id: \.self) { size in
            self.previewDynamicTypeSize(size)
        }
    }

    /// Preview con una categoría de tamaño específica de ContentSizeCategory.
    public func previewContentSizeCategory(_ category: ContentSizeCategory) -> some View {
        self.environment(\.sizeCategory, category)
            .previewDisplayName("Size Category: \(category.shortName)")
    }

    /// Preview con todas las categorías de tamaño de ContentSizeCategory.
    public func previewAllContentSizeCategories() -> some View {
        let allCases: [ContentSizeCategory] = ContentSizeCategory.allCases
        return ForEach(allCases, id: \.self) { category in
            self.previewContentSizeCategory(category)
        }
    }

    /// Preview con categorías estándar (no accesibilidad) de ContentSizeCategory.
    public func previewStandardSizeCategories() -> some View {
        ForEach(ContentSizeCategory.eduStandardCases, id: \.self) { category in
            self.previewContentSizeCategory(category)
        }
    }

    /// Preview con categorías de accesibilidad de ContentSizeCategory.
    public func previewAccessibilitySizeCategories() -> some View {
        ForEach(ContentSizeCategory.eduAccessibilityCases, id: \.self) { category in
            self.previewContentSizeCategory(category)
        }
    }

    /// Preview comparando una vista en tamaño normal vs accesibilidad grande.
    public func previewDynamicTypeComparison() -> some View {
        Group {
            self.environment(\.sizeCategory, .large)
                .previewDisplayName("Normal (L)")

            self.environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
                .previewDisplayName("Accessibility (AX-XXXL)")
        }
    }
}

extension DynamicTypeSize {
    var description: String {
        switch self {
        case .xSmall: return "XS"
        case .small: return "S"
        case .medium: return "M"
        case .large: return "L"
        case .xLarge: return "XL"
        case .xxLarge: return "XXL"
        case .xxxLarge: return "XXXL"
        case .accessibility1: return "A1"
        case .accessibility2: return "A2"
        case .accessibility3: return "A3"
        case .accessibility4: return "A4"
        case .accessibility5: return "A5"
        @unknown default: return "Unknown"
        }
    }
}

// MARK: - Adaptive Layout Preview Helpers

extension View {
    /// Preview demostrando layouts adaptativos en diferentes tamaños.
    public func previewAdaptiveLayout() -> some View {
        Group {
            self.environment(\.sizeCategory, .large)
                .previewDisplayName("Adaptive: Normal (Horizontal)")

            self.environment(\.sizeCategory, .accessibilityMedium)
                .previewDisplayName("Adaptive: Stacked (Vertical)")
        }
    }
}

// MARK: - Scaling Metrics Preview Helpers

/// Container para visualizar métricas de escalado en previews.
@MainActor
public struct ScalingMetricsPreview: View {
    let sizeCategory: ContentSizeCategory

    public init(sizeCategory: ContentSizeCategory = .large) {
        self.sizeCategory = sizeCategory
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Size Category: \(sizeCategory.name)")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Scaling Level: \(sizeCategory.scalingLevel)")
                Text("Is Accessibility: \(sizeCategory.isAccessibilityCategory ? "Yes" : "No")")
                Text("Should Stack: \(sizeCategory.shouldStack() ? "Yes" : "No")")
            }
            .font(.caption)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Spacing SM: \(String(format: "%.1f", sizeCategory.scaledSpacing(ScalingMetrics.spacingSM)))")
                Text("Padding MD: \(String(format: "%.1f", sizeCategory.scaledPadding(ScalingMetrics.paddingMD)))")
                Text("Corner Radius LG: \(String(format: "%.1f", sizeCategory.scaledCornerRadius(ScalingMetrics.cornerRadiusLG)))")
                Text("Icon Size MD: \(String(format: "%.1f", sizeCategory.scaledIconSize(ScalingMetrics.iconMD)))")
                Text("Min Touch Target: \(String(format: "%.1f", sizeCategory.minimumTouchTarget))")
            }
            .font(.caption.monospaced())
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(white: 1.0).opacity(0.001)) // Transparent background for preview
        .environment(\.sizeCategory, sizeCategory)
    }
}

extension View {
    /// Preview visualizando métricas de escalado para diferentes tamaños.
    public func previewScalingMetrics() -> some View {
        ForEach([ContentSizeCategory.small, .large, .extraExtraExtraLarge, .accessibilityMedium, .accessibilityExtraExtraExtraLarge], id: \.self) { category in
            ScalingMetricsPreview(sizeCategory: category)
                .previewDisplayName("Metrics: \(category.shortName)")
        }
    }
}

// MARK: - State Helpers

/// Wrapper para crear estados visuales en previews.
@MainActor
@Observable
public final class PreviewState<T> {
    public var value: T

    public init(_ initialValue: T) {
        self.value = initialValue
    }
}

// MARK: - Platform Detection

public enum Platform {
    case iOS
    case macOS
    case watchOS
    case tvOS
    case visionOS

    public static var current: Platform {
        #if os(iOS)
        return .iOS
        #elseif os(macOS)
        return .macOS
        #elseif os(watchOS)
        return .watchOS
        #elseif os(tvOS)
        return .tvOS
        #elseif os(visionOS)
        return .visionOS
        #else
        return .iOS
        #endif
    }

    public var displayName: String {
        switch self {
        case .iOS: return "iOS"
        case .macOS: return "macOS"
        case .watchOS: return "watchOS"
        case .tvOS: return "tvOS"
        case .visionOS: return "visionOS"
        }
    }
}

// MARK: - Locale Helpers

extension View {
    /// Preview con un locale específico.
    public func previewLocale(_ identifier: String) -> some View {
        self.environment(\.locale, Locale(identifier: identifier))
            .previewDisplayName("Locale: \(identifier)")
    }

    /// Preview con locales comunes.
    public func previewCommonLocales() -> some View {
        Group {
            self.previewLocale("en_US")
            self.previewLocale("es_ES")
            self.previewLocale("es_MX")
            self.previewLocale("pt_BR")
            self.previewLocale("fr_FR")
        }
    }
}

// MARK: - Grid Layout Helper para Previews

@MainActor
public struct PreviewGrid<Content: View>: View {
    let columns: Int
    let spacing: CGFloat
    let content: Content

    public init(
        columns: Int = 2,
        spacing: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.columns = columns
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns),
                spacing: spacing
            ) {
                content
            }
            .padding()
        }
    }
}

// MARK: - Accessibility Preferences Helpers (Reduce Motion & High Contrast)

extension View {
    /// Preview con Reduce Motion habilitado
    public func previewReducedMotion(_ isEnabled: Bool = true) -> some View {
        self.environment(\.accessibilityReduceMotion, isEnabled)
            .previewDisplayName(isEnabled ? "Reduce Motion: ON" : "Reduce Motion: OFF")
    }

    /// Preview comparando Reduce Motion ON vs OFF
    public func previewReducedMotionComparison() -> some View {
        Group {
            self.environment(\.accessibilityReduceMotion, false)
                .previewDisplayName("Motion: Normal")

            self.environment(\.accessibilityReduceMotion, true)
                .previewDisplayName("Motion: Reduced")
        }
    }

    /// Preview con High Contrast habilitado
    public func previewHighContrast(_ isEnabled: Bool = true) -> some View {
        self.environment(\.accessibilityHighContrast, isEnabled)
            .previewDisplayName(isEnabled ? "High Contrast: ON" : "High Contrast: OFF")
    }

    /// Preview comparando High Contrast ON vs OFF
    public func previewHighContrastComparison() -> some View {
        Group {
            self.environment(\.accessibilityHighContrast, false)
                .previewDisplayName("Contrast: Normal")

            self.environment(\.accessibilityHighContrast, true)
                .previewDisplayName("Contrast: High")
        }
    }

    /// Preview con Differentiate Without Color habilitado
    public func previewDifferentiateWithoutColor(_ isEnabled: Bool = true) -> some View {
        self.environment(\.accessibilityDifferentiateWithoutColor, isEnabled)
            .previewDisplayName(isEnabled ? "Differentiate Without Color: ON" : "Differentiate Without Color: OFF")
    }

    /// Preview con todas las combinaciones de accesibilidad importantes
    public func previewAccessibilityCombinations() -> some View {
        Group {
            // Normal
            self
                .previewDisplayName("Normal")

            // Reduce Motion only
            self.environment(\.accessibilityReduceMotion, true)
                .previewDisplayName("Reduce Motion")

            // High Contrast only
            self.environment(\.accessibilityHighContrast, true)
                .previewDisplayName("High Contrast")

            // Large Text only
            self.environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
                .previewDisplayName("Large Text (XXXL)")

            // All combined
            self.environment(\.accessibilityReduceMotion, true)
                .environment(\.accessibilityHighContrast, true)
                .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
                .previewDisplayName("All Accessibility ON")
        }
    }

    /// Preview con estado completo de accesibilidad
    public func previewAccessibilityState(_ state: AccessibilityState) -> some View {
        self.environment(\.accessibilityReduceMotion, state.reduceMotion)
            .environment(\.accessibilityHighContrast, state.highContrast)
            .environment(\.accessibilityIncreaseContrast, state.increaseContrast)
            .environment(\.accessibilityDifferentiateWithoutColor, state.differentiateWithoutColor)
            .environment(\.sizeCategory, state.contentSizeCategory)
            .previewDisplayName("Custom Accessibility State")
    }
}

// MARK: - Example Usage in Comments

/*
 EJEMPLOS DE USO:

 1. Preview con dispositivo específico:
 ```swift
 #Preview("iPhone 15 Pro") {
     MyView()
         .previewDevice(.iPhone15Pro)
 }
 ```

 2. Preview en modo claro y oscuro:
 ```swift
 #Preview("All Color Schemes") {
     MyView()
         .previewAllColorSchemes()
 }
 ```

 3. Preview con container:
 ```swift
 #Preview("Con Container") {
     PreviewContainer {
         MyView()
     }
 }
 ```

 4. Preview con Dynamic Type:
 ```swift
 #Preview("Dynamic Type Sizes") {
     MyView()
         .previewCommonDynamicTypeSizes()
 }
 ```

 5. Preview con diferentes size classes (iOS):
 ```swift
 #Preview("Size Classes") {
     MyView()
         .previewAllSizeClasses()
 }
 ```

 6. Preview con locale:
 ```swift
 #Preview("Spanish Locale") {
     MyView()
         .previewLocale("es_ES")
 }
 ```

 7. Grid de componentes:
 ```swift
 #Preview("Grid de Botones") {
     PreviewGrid(columns: 3) {
         ForEach(ButtonStyle.allCases, id: \.self) { style in
             MyButton(style: style)
         }
     }
 }
 ```

 8. Preview con Reduce Motion:
 ```swift
 #Preview("Reduce Motion Comparison") {
     MyAnimatedView()
         .previewReducedMotionComparison()
 }
 ```

 9. Preview con High Contrast:
 ```swift
 #Preview("High Contrast") {
     MyView()
         .previewHighContrast(true)
 }
 ```

 10. Preview con todas las combinaciones de accesibilidad:
 ```swift
 #Preview("Accessibility Combinations") {
     MyView()
         .previewAccessibilityCombinations()
 }
 ```

 11. Preview con estado personalizado de accesibilidad:
 ```swift
 #Preview("Custom Accessibility") {
     let state = AccessibilityState(
         reduceMotion: true,
         highContrast: true,
         increaseContrast: true,
         differentiateWithoutColor: false,
         contentSizeCategory: .accessibilityLarge
     )
     MyView()
         .previewAccessibilityState(state)
 }
 ```
 */
