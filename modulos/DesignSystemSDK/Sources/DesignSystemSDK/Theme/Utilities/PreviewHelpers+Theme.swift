import SwiftUI

// MARK: - Theme Preview Modifiers

extension View {

    /// Aplica un tema específico para previews.
    ///
    /// - Parameter theme: Theme a aplicar en el preview
    /// - Returns: Vista con el theme aplicado
    ///
    /// ## Uso
    /// ```swift
    /// #Preview("Con Tema Oscuro") {
    ///     MyView()
    ///         .previewTheme(.dark)
    /// }
    /// ```
    @MainActor
    public func previewTheme(_ theme: Theme) -> some View {
        self.environment(\.theme, theme)
    }

    /// Aplica un tema específico con un esquema de color.
    ///
    /// - Parameters:
    ///   - theme: Theme a aplicar
    ///   - colorScheme: Esquema de color (.light o .dark)
    /// - Returns: Vista con theme y color scheme aplicados
    ///
    /// ## Uso
    /// ```swift
    /// #Preview("Dark con High Contrast") {
    ///     MyView()
    ///         .previewTheme(.highContrast, colorScheme: .dark)
    /// }
    /// ```
    @MainActor
    public func previewTheme(_ theme: Theme, colorScheme: ColorScheme) -> some View {
        self
            .environment(\.theme, theme)
            .preferredColorScheme(colorScheme)
    }

    /// Genera previews para todos los temas disponibles.
    ///
    /// Crea un preview por cada tema predefinido en ambos modos (light y dark).
    ///
    /// - Returns: Vista con previews de todos los temas
    ///
    /// ## Uso
    /// ```swift
    /// #Preview("Todos los Temas") {
    ///     MyView()
    ///         .previewAllThemes()
    /// }
    /// ```
    @MainActor
    public func previewAllThemes() -> some View {
        ForEach([Theme.default, .dark, .highContrast, .grayscale], id: \.id) { theme in
            ForEach([ColorScheme.light, .dark], id: \.self) { scheme in
                self
                    .previewTheme(theme, colorScheme: scheme)
                    .previewDisplayName("\(theme.name) - \(scheme == .light ? "Light" : "Dark")")
            }
        }
    }

    /// Compara dos temas lado a lado.
    ///
    /// - Parameters:
    ///   - theme1: Primer tema a comparar
    ///   - theme2: Segundo tema a comparar
    /// - Returns: Vista con ambos temas lado a lado
    ///
    /// ## Uso
    /// ```swift
    /// #Preview("Comparar Temas") {
    ///     MyView()
    ///         .compareThemes(.default, .highContrast)
    /// }
    /// ```
    @MainActor
    public func compareThemes(_ theme1: Theme, _ theme2: Theme) -> some View {
        HStack(spacing: 0) {
            self
                .previewTheme(theme1)
                .frame(maxWidth: .infinity)

            Divider()

            self
                .previewTheme(theme2)
                .frame(maxWidth: .infinity)
        }
    }

    /// Compara light y dark mode del mismo tema lado a lado.
    ///
    /// - Parameter theme: Theme a comparar en ambos modos
    /// - Returns: Vista con light y dark mode lado a lado
    ///
    /// ## Uso
    /// ```swift
    /// #Preview("Light vs Dark") {
    ///     MyView()
    ///         .compareLightDark(theme: .default)
    /// }
    /// ```
    @MainActor
    public func compareLightDark(theme: Theme = .default) -> some View {
        HStack(spacing: 0) {
            self
                .previewTheme(theme, colorScheme: .light)
                .frame(maxWidth: .infinity)

            Divider()

            self
                .previewTheme(theme, colorScheme: .dark)
                .frame(maxWidth: .infinity)
        }
    }

    /// Muestra información de debug del theme actual.
    ///
    /// - Parameter position: Posición del overlay (default: .topTrailing)
    /// - Returns: Vista con overlay de debug
    ///
    /// ## Uso
    /// ```swift
    /// #Preview("Con Debug Info") {
    ///     MyView()
    ///         .previewTheme(.default)
    ///         .debugTheme()
    /// }
    /// ```
    @MainActor
    public func debugTheme(position: Alignment = .topTrailing) -> some View {
        self.overlay(alignment: position) {
            ThemeDebugOverlay()
        }
    }

    /// Aplica un tamaño específico para preview (útil para componentes pequeños).
    ///
    /// - Parameters:
    ///   - width: Ancho del preview
    ///   - height: Alto del preview
    /// - Returns: Vista con tamaño fijo
    @MainActor
    public func previewSize(width: CGFloat, height: CGFloat) -> some View {
        self
            .frame(width: width, height: height)
            .previewLayout(.sizeThatFits)
    }
}

// MARK: - Theme Debug Overlay

@MainActor
private struct ThemeDebugOverlay: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Theme: \(theme.name)")
                .font(.caption2)
            Text("Mode: \(colorScheme == .dark ? "Dark" : "Light")")
                .font(.caption2)
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
        .padding(8)
    }
}

// MARK: - Preview Containers for Theming

/// Container para previsualizar componentes con diferentes temas.
@MainActor
public struct ThemePreviewContainer<Content: View>: View {
    let themes: [Theme]
    let content: () -> Content

    /// Crea un container de preview con múltiples temas.
    /// - Parameters:
    ///   - themes: Array de temas a previsualizar. Por defecto todos los temas.
    ///   - content: Contenido a previsualizar
    public init(
        themes: [Theme] = [.default, .dark, .highContrast, .grayscale],
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.themes = themes
        self.content = content
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                ForEach(themes) { theme in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(theme.name)
                            .font(.headline)

                        HStack(spacing: 20) {
                            // Light mode
                            VStack {
                                Text("Light")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                content()
                                    .previewTheme(theme, colorScheme: .light)
                            }

                            // Dark mode
                            VStack {
                                Text("Dark")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                content()
                                    .previewTheme(theme, colorScheme: .dark)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Example Usage in Comments

/*
 EJEMPLOS DE USO:

 1. Preview con un tema específico:
 ```swift
 #Preview("Tema Oscuro") {
     MyButton(title: "Click Me")
         .previewTheme(.dark)
 }
 ```

 2. Preview con todos los temas:
 ```swift
 #Preview("Todos los Temas") {
     MyButton(title: "Click Me")
         .previewAllThemes()
 }
 ```

 3. Comparar dos temas:
 ```swift
 #Preview("Comparar Default vs High Contrast") {
     MyForm()
         .compareThemes(.default, .highContrast)
 }
 ```

 4. Comparar light vs dark:
 ```swift
 #Preview("Light vs Dark") {
     MyCard()
         .compareLightDark(theme: .default)
 }
 ```

 5. Container con múltiples temas:
 ```swift
 #Preview("Grid de Temas") {
     ThemePreviewContainer {
         MyComponent()
     }
 }
 ```

 6. Preview con debug info:
 ```swift
 #Preview("Con Debug") {
     MyView()
         .previewTheme(.default)
         .debugTheme()
 }
 ```
 */
