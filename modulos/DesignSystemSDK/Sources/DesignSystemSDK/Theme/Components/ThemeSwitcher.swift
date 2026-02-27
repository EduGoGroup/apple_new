import SwiftUI

/// Componente UI para cambiar el tema de la aplicación.
///
/// ThemeSwitcher proporciona una interfaz visual para que los usuarios
/// seleccionen el tema y el esquema de color de la aplicación.
///
/// ## Uso
/// ```swift
/// ThemeSwitcher()
///     .environment(\.themeManager, ThemeManager.shared)
/// ```
///
/// ## Adaptación por Plataforma
/// - iOS: Sheet con opciones completas
/// - macOS: Preferences panel
/// - watchOS: Picker simplificado
/// - tvOS: Selector enfocable
/// - visionOS: Panel espacial
public struct ThemeSwitcher: View {

    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var systemColorScheme

    public init() {}

    public var body: some View {
        #if os(iOS)
        iOSView
        #elseif os(macOS)
        macOSView
        #elseif os(watchOS)
        watchOSView
        #elseif os(tvOS)
        tvOSView
        #elseif os(visionOS)
        visionOSView
        #else
        defaultView
        #endif
    }

    // MARK: - iOS View

    #if os(iOS)
    private var iOSView: some View {
        VStack(spacing: 24) {
            // Color Scheme Selector
            VStack(alignment: .leading, spacing: 12) {
                Text("Apariencia")
                    .font(.headline)

                Picker("Esquema de Color", selection: Binding(
                    get: { themeManager.colorSchemePreference },
                    set: { themeManager.setColorScheme($0) }
                )) {
                    Text("Claro").tag(ColorSchemePreference.light)
                    Text("Oscuro").tag(ColorSchemePreference.dark)
                    Text("Automático").tag(ColorSchemePreference.auto)
                }
                .pickerStyle(.segmented)
            }

            Divider()

            // Theme Selector
            VStack(alignment: .leading, spacing: 12) {
                Text("Tema")
                    .font(.headline)

                ForEach(themeManager.availableThemes) { theme in
                    ThemeOptionRow(
                        theme: theme,
                        isSelected: theme.id == themeManager.currentTheme.id
                    ) {
                        themeManager.setTheme(theme)
                    }
                }
            }
        }
        .padding()
    }
    #endif

    // MARK: - macOS View

    #if os(macOS)
    private var macOSView: some View {
        Form {
            Section("Apariencia") {
                Picker("Esquema de Color:", selection: Binding(
                    get: { themeManager.colorSchemePreference },
                    set: { themeManager.setColorScheme($0) }
                )) {
                    Text("Claro").tag(ColorSchemePreference.light)
                    Text("Oscuro").tag(ColorSchemePreference.dark)
                    Text("Automático").tag(ColorSchemePreference.auto)
                }
                .pickerStyle(.radioGroup)
            }

            Section("Tema") {
                Picker("Seleccionar Tema:", selection: Binding(
                    get: { themeManager.currentTheme.id },
                    set: { id in
                        if let theme = themeManager.availableThemes.first(where: { $0.id == id }) {
                            themeManager.setTheme(theme)
                        }
                    }
                )) {
                    ForEach(themeManager.availableThemes) { theme in
                        Text(theme.name).tag(theme.id)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 400, minHeight: 300)
    }
    #endif

    // MARK: - watchOS View

    #if os(watchOS)
    private var watchOSView: some View {
        List {
            Section("Apariencia") {
                Picker("", selection: Binding(
                    get: { themeManager.colorSchemePreference },
                    set: { themeManager.setColorScheme($0) }
                )) {
                    Label("Claro", systemImage: "sun.max").tag(ColorSchemePreference.light)
                    Label("Oscuro", systemImage: "moon").tag(ColorSchemePreference.dark)
                    Label("Auto", systemImage: "sparkles").tag(ColorSchemePreference.auto)
                }
            }

            Section("Tema") {
                ForEach(themeManager.availableThemes) { theme in
                    Button(theme.name) {
                        themeManager.setTheme(theme)
                    }
                }
            }
        }
    }
    #endif

    // MARK: - tvOS View

    #if os(tvOS)
    private var tvOSView: some View {
        ScrollView {
            VStack(spacing: 60) {
                // Color Scheme
                VStack(spacing: 20) {
                    Text("Apariencia")
                        .font(.title)

                    HStack(spacing: 40) {
                        ForEach([ColorSchemePreference.light, .dark, .auto], id: \.self) { preference in
                            Button {
                                themeManager.setColorScheme(preference)
                            } label: {
                                VStack {
                                    Image(systemName: iconName(for: preference))
                                        .font(.system(size: 60))
                                    Text(preference.displayName)
                                        .font(.headline)
                                }
                                .frame(width: 200, height: 200)
                                .background(themeManager.colorSchemePreference == preference ? Color.blue : Color.clear)
                                .cornerRadius(20)
                            }
                            .buttonStyle(.card)
                        }
                    }
                }

                // Themes
                VStack(spacing: 20) {
                    Text("Tema")
                        .font(.title)

                    HStack(spacing: 40) {
                        ForEach(themeManager.availableThemes) { theme in
                            Button(theme.name) {
                                themeManager.setTheme(theme)
                            }
                            .frame(width: 200, height: 120)
                            .background(theme.id == themeManager.currentTheme.id ? Color.blue : Color.gray.opacity(0.3))
                            .cornerRadius(20)
                            .buttonStyle(.card)
                        }
                    }
                }
            }
            .padding(80)
        }
    }
    #endif

    // MARK: - visionOS View

    #if os(visionOS)
    private var visionOSView: some View {
        VStack(spacing: 30) {
            Text("Preferencias de Tema")
                .font(.largeTitle)

            // Color Scheme Selector
            VStack(alignment: .leading, spacing: 16) {
                Text("Apariencia")
                    .font(.title2)

                Picker("Esquema de Color", selection: Binding(
                    get: { themeManager.colorSchemePreference },
                    set: { themeManager.setColorScheme($0) }
                )) {
                    Text("Claro").tag(ColorSchemePreference.light)
                    Text("Oscuro").tag(ColorSchemePreference.dark)
                    Text("Automático").tag(ColorSchemePreference.auto)
                }
                .pickerStyle(.segmented)
            }

            Divider()

            // Theme Selector
            VStack(alignment: .leading, spacing: 16) {
                Text("Tema")
                    .font(.title2)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
                    ForEach(themeManager.availableThemes) { theme in
                        Button {
                            themeManager.setTheme(theme)
                        } label: {
                            VStack {
                                Text(theme.name)
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(theme.id == themeManager.currentTheme.id ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(40)
        .frame(maxWidth: 600)
    }
    #endif

    // MARK: - Default View

    private var defaultView: some View {
        VStack(spacing: 20) {
            Text("Theme Switcher")
                .font(.title)

            Picker("Color Scheme", selection: Binding(
                get: { themeManager.colorSchemePreference },
                set: { themeManager.setColorScheme($0) }
            )) {
                Text("Light").tag(ColorSchemePreference.light)
                Text("Dark").tag(ColorSchemePreference.dark)
                Text("Auto").tag(ColorSchemePreference.auto)
            }

            Picker("Theme", selection: Binding(
                get: { themeManager.currentTheme.id },
                set: { id in
                    if let theme = themeManager.availableThemes.first(where: { $0.id == id }) {
                        themeManager.setTheme(theme)
                    }
                }
            )) {
                ForEach(themeManager.availableThemes) { theme in
                    Text(theme.name).tag(theme.id)
                }
            }
        }
        .padding()
    }

    // MARK: - Helper Functions

    private func iconName(for preference: ColorSchemePreference) -> String {
        switch preference {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .auto: return "sparkles"
        }
    }
}

// MARK: - Theme Option Row (iOS)

#if os(iOS)
private struct ThemeOptionRow: View {
    let theme: Theme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.name)
                        .font(.headline)

                    Text(themeDescription(for: theme))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }

    private func themeDescription(for theme: Theme) -> String {
        switch theme.id {
        case "default":
            return "Tema estándar con colores vibrantes"
        case "dark":
            return "Optimizado para modo oscuro"
        case "highContrast":
            return "Alto contraste para accesibilidad"
        case "grayscale":
            return "Escala de grises monocromática"
        default:
            return "Tema personalizado"
        }
    }
}
#endif

// MARK: - Previews

#Preview("iOS") {
    ThemeSwitcher()
        .environment(\.themeManager, ThemeManager.shared)
}

#Preview("macOS") {
    ThemeSwitcher()
        .environment(\.themeManager, ThemeManager.shared)
        .frame(width: 500, height: 400)
}
