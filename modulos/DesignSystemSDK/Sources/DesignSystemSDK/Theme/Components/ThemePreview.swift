import SwiftUI

/// Componente para previsualizar todos los colores y estilos de un tema.
///
/// ThemePreview es útil para:
/// - Debugging del sistema de theming
/// - Documentación visual de temas
/// - Testing de accesibilidad y contraste
///
/// ## Uso
/// ```swift
/// ThemePreview(theme: .default)
/// ```
@MainActor
public struct ThemePreview: View {

    let theme: Theme
    let showLabels: Bool

    @Environment(\.colorScheme) private var colorScheme

    /// Crea un preview de theme.
    /// - Parameters:
    ///   - theme: Theme a previsualizar. Por defecto usa el theme default.
    ///   - showLabels: Si mostrar etiquetas con nombres de colores. Por defecto true.
    public init(theme: Theme = .default, showLabels: Bool = true) {
        self.theme = theme
        self.showLabels = showLabels
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                header

                Divider()

                // Semantic Colors
                semanticColorsSection

                Divider()

                // Color Palettes
                colorPalettesSection

                Divider()

                // Component Samples
                componentSamplesSection
            }
            .padding()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Text(theme.name)
                .font(.largeTitle)
                .bold()

            Text("Color Scheme: \(colorScheme == .dark ? "Dark" : "Light")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Semantic Colors

    private var semanticColorsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Semantic Colors")
                .font(.title2)
                .bold()

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 12) {
                ColorSwatch(name: "Error", color: Color.theme.error)
                ColorSwatch(name: "Warning", color: Color.theme.warning)
                ColorSwatch(name: "Success", color: Color.theme.success)
                ColorSwatch(name: "Info", color: Color.theme.info)
                ColorSwatch(name: "Interactive", color: Color.theme.interactive)
                ColorSwatch(name: "Text Primary", color: Color.theme.textPrimary)
                ColorSwatch(name: "Text Secondary", color: Color.theme.textSecondary)
                ColorSwatch(name: "Border", color: Color.theme.border)
            }
        }
    }

    // MARK: - Color Palettes

    private var colorPalettesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Color Palettes")
                .font(.title2)
                .bold()

            // Primary Palette
            PaletteRow(name: "Primary", scale: theme.colorPalette.primary)

            // Secondary Palette
            PaletteRow(name: "Secondary", scale: theme.colorPalette.secondary)

            // Error Palette
            PaletteRow(name: "Error", scale: theme.colorPalette.error)

            // Success Palette
            PaletteRow(name: "Success", scale: theme.colorPalette.success)

            // Neutral Palette
            PaletteRow(name: "Neutral", scale: theme.colorPalette.neutral)
        }
    }

    // MARK: - Component Samples

    private var componentSamplesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Component Samples")
                .font(.title2)
                .bold()

            VStack(spacing: 20) {
                // Text Samples
                textSamplesRow

                // Button Samples
                buttonSamplesRow

                // State Messages
                stateMessagesRow
            }
        }
    }

    private var textSamplesRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Texto Primary")
                .font(.body)
                .foregroundStyle(Color.theme.textPrimary)

            Text("Texto Secondary")
                .font(.body)
                .foregroundStyle(Color.theme.textSecondary)

            Text("Texto Tertiary")
                .font(.body)
                .foregroundStyle(Color.theme.textTertiary)

            Text("Texto Disabled")
                .font(.body)
                .foregroundStyle(Color.theme.textDisabled)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.theme.background)
        .cornerRadius(8)
    }

    private var buttonSamplesRow: some View {
        HStack(spacing: 12) {
            Button("Primary") {}
                .buttonStyle(.borderedProminent)
                .tint(Color.theme.interactive)

            Button("Secondary") {}
                .buttonStyle(.bordered)
                .tint(Color.theme.interactive)

            Button("Tertiary") {}
                .buttonStyle(.borderless)
                .tint(Color.theme.interactive)
        }
    }

    private var stateMessagesRow: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Success message")
                Spacer()
            }
            .padding()
            .background(Color.theme.successBackground)
            .foregroundStyle(Color.theme.success)
            .cornerRadius(8)

            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                Text("Warning message")
                Spacer()
            }
            .padding()
            .background(Color.theme.warningBackground)
            .foregroundStyle(Color.theme.warning)
            .cornerRadius(8)

            HStack {
                Image(systemName: "xmark.circle.fill")
                Text("Error message")
                Spacer()
            }
            .padding()
            .background(Color.theme.errorBackground)
            .foregroundStyle(Color.theme.error)
            .cornerRadius(8)

            HStack {
                Image(systemName: "info.circle.fill")
                Text("Info message")
                Spacer()
            }
            .padding()
            .background(Color.theme.infoBackground)
            .foregroundStyle(Color.theme.info)
            .cornerRadius(8)
        }
    }
}

// MARK: - Color Swatch

@MainActor
private struct ColorSwatch: View {
    let name: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                )

            Text(name)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Palette Row

@MainActor
private struct PaletteRow: View {
    let name: String
    let scale: PaletteScale

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.headline)

            HStack(spacing: 4) {
                ColorChip(color: scale.c50.resolve(for: colorScheme), label: "50")
                ColorChip(color: scale.c100.resolve(for: colorScheme), label: "100")
                ColorChip(color: scale.c200.resolve(for: colorScheme), label: "200")
                ColorChip(color: scale.c300.resolve(for: colorScheme), label: "300")
                ColorChip(color: scale.c400.resolve(for: colorScheme), label: "400")
                ColorChip(color: scale.c500.resolve(for: colorScheme), label: "500")
                ColorChip(color: scale.c600.resolve(for: colorScheme), label: "600")
                ColorChip(color: scale.c700.resolve(for: colorScheme), label: "700")
                ColorChip(color: scale.c800.resolve(for: colorScheme), label: "800")
                ColorChip(color: scale.c900.resolve(for: colorScheme), label: "900")
            }
        }
    }
}

// MARK: - Color Chip

@MainActor
private struct ColorChip: View {
    let color: Color
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Rectangle()
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay(
                    Rectangle()
                        .strokeBorder(Color.gray.opacity(0.3), lineWidth: 0.5)
                )

            Text(label)
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Previews

#Preview("Default Theme - Light") {
    ThemePreview(theme: .default)
        .preferredColorScheme(.light)
}

#Preview("Default Theme - Dark") {
    ThemePreview(theme: .default)
        .preferredColorScheme(.dark)
}

#Preview("High Contrast Theme") {
    ThemePreview(theme: .highContrast)
}

#Preview("Grayscale Theme") {
    ThemePreview(theme: .grayscale)
}
