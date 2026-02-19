import SwiftUI
import DesignSystemSDK

/// Campo de búsqueda con clear button y debounce integrado.
///
/// Características:
/// - Clear button para limpiar rápidamente
/// - Debounce integrado usando DebouncedProperty
/// - Icono de búsqueda
/// - Estados: normal, searching, disabled
/// - Feedback visual durante búsqueda
@MainActor
public struct EduSearchField: View {
    // MARK: - Properties

    private let placeholder: String
    @Binding private var text: String
    private let debounceInterval: TimeInterval
    private let onSearch: ((String) async -> Void)?
    private let isSearching: Bool
    private let resultsCount: Int?

    @State private var isFocused: Bool = false
    @State private var debouncedText: String = ""
    @State private var searchTask: Task<Void, Never>?

    private var isDisabled: Bool

    // MARK: - Initializers

    /// Inicializa un EduSearchField con debounce integrado.
    ///
    /// - Parameters:
    ///   - placeholder: Texto placeholder cuando está vacío
    ///   - text: Binding al texto de búsqueda
    ///   - debounceInterval: Intervalo de debounce en segundos (default: 0.5)
    ///   - isSearching: Indica si hay una búsqueda en progreso
    ///   - resultsCount: Número de resultados encontrados (para VoiceOver)
    ///   - isDisabled: Si el campo está deshabilitado
    ///   - onSearch: Closure async que se ejecuta después del debounce
    public init(
        placeholder: String = "Buscar...",
        text: Binding<String>,
        debounceInterval: TimeInterval = 0.5,
        isSearching: Bool = false,
        resultsCount: Int? = nil,
        isDisabled: Bool = false,
        onSearch: ((String) async -> Void)? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.debounceInterval = debounceInterval
        self.isSearching = isSearching
        self.resultsCount = resultsCount
        self.isDisabled = isDisabled
        self.onSearch = onSearch
    }

    // MARK: - Body

    public var body: some View {
        HStack(spacing: DesignTokens.Spacing.small) {
            // Icono de búsqueda
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .frame(width: 20, height: 20)

            // Campo de texto
            TextField(placeholder, text: $text)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                #endif
                .disabled(isDisabled)
                .onChange(of: text) { oldValue, newValue in
                    handleTextChange(newValue)
                }
                .onFocusChange { focused in
                    isFocused = focused
                }

            // Indicador de búsqueda o botón clear
            if isSearching {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 20, height: 20)
            } else if !text.isEmpty {
                Button(action: {
                    text = ""
                    searchTask?.cancel()
                    Task {
                        await onSearch?("")
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                .disabled(isDisabled)
                .accessibilityLabel("Limpiar búsqueda")
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.medium)
        .padding(.vertical, DesignTokens.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large)
                .fill(Color(white: 0.98))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large)
                .stroke(borderColor, lineWidth: isFocused ? DesignTokens.BorderWidth.medium : DesignTokens.BorderWidth.thin)
        )
        .opacity(isDisabled ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: isSearching)
        // MARK: - Accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityValue(text.isEmpty ? "empty" : text)
        .accessibleIdentifier(.searchField(module: "ui", screen: "input", context: "search"))
        .onChange(of: resultsCount) { _, newCount in
            if let count = newCount {
                let announcement = count == 0
                    ? "No results found"
                    : "\(count) result\(count == 1 ? "" : "s") found"
                AccessibilityAnnouncements.announce(announcement, priority: .medium)
            }
        }
        .onChange(of: isSearching) { _, newValue in
            if newValue {
                AccessibilityAnnouncements.announce("Searching", priority: .low)
            }
        }
        // MARK: - Keyboard Navigation
        .tabPriority(80)
        .clearSearchOnEscape(searchText: $text)
    }

    // MARK: - Accessibility Helpers

    private var accessibilityLabelText: String {
        var label = "Search field"
        if isSearching {
            label += ", searching"
        }
        if let count = resultsCount {
            label += ", \(count) result\(count == 1 ? "" : "s")"
        }
        if isDisabled {
            label += ", disabled"
        }
        return label
    }

    // MARK: - Helper Methods

    private var borderColor: Color {
        if isDisabled {
            return .secondary.opacity(0.3)
        }
        if isFocused {
            return .accentColor
        }
        return .secondary.opacity(0.5)
    }

    private func handleTextChange(_ newValue: String) {
        // Cancelar tarea anterior
        searchTask?.cancel()

        // Crear nueva tarea con debounce
        searchTask = Task {
            do {
                try await Task.sleep(for: .seconds(debounceInterval))

                // Verificar que no se canceló
                guard !Task.isCancelled else { return }

                // Ejecutar búsqueda
                await onSearch?(newValue)
            } catch {
                // Task cancelada, no hacer nada
            }
        }
    }
}

// MARK: - Convenience Initializer con @DebouncedProperty

extension EduSearchField {
    /// Inicializa un EduSearchField usando DebouncedProperty del módulo Binding.
    ///
    /// Este inicializador facilita la integración con ViewModels que usan @DebouncedProperty.
    ///
    /// - Parameters:
    ///   - placeholder: Texto placeholder cuando está vacío
    ///   - text: Binding al texto de búsqueda
    ///   - isSearching: Indica si hay una búsqueda en progreso
    ///   - resultsCount: Número de resultados encontrados (para VoiceOver)
    ///   - isDisabled: Si el campo está deshabilitado
    public init(
        placeholder: String = "Buscar...",
        text: Binding<String>,
        isSearching: Bool = false,
        resultsCount: Int? = nil,
        isDisabled: Bool = false
    ) {
        self.init(
            placeholder: placeholder,
            text: text,
            debounceInterval: 0.5,
            isSearching: isSearching,
            resultsCount: resultsCount,
            isDisabled: isDisabled,
            onSearch: nil
        )
    }
}

// MARK: - Previews

#Preview("Basic SearchField") {
    @Previewable @State var searchText = ""

    EduSearchField(
        placeholder: "Buscar cursos...",
        text: $searchText
    )
    .padding()
}

#Preview("SearchField con Texto") {
    @Previewable @State var searchText = "Swift programming"

    EduSearchField(
        placeholder: "Buscar...",
        text: $searchText
    )
    .padding()
}

#Preview("SearchField Buscando") {
    @Previewable @State var searchText = "React"

    EduSearchField(
        placeholder: "Buscar...",
        text: $searchText,
        isSearching: true
    )
    .padding()
}

#Preview("SearchField Deshabilitado") {
    @Previewable @State var searchText = "No disponible"

    EduSearchField(
        placeholder: "Buscar...",
        text: $searchText,
        isDisabled: true
    )
    .padding()
}

#Preview("SearchField con Debounce Action") {
    @Previewable @State var searchText = ""
    @Previewable @State var isSearching = false
    @Previewable @State var results: [String] = []

    VStack(spacing: 16) {
        EduSearchField(
            placeholder: "Buscar usuarios...",
            text: $searchText,
            debounceInterval: 0.8,
            isSearching: isSearching
        ) { query in
            isSearching = true
            // Simular búsqueda async
            try? await Task.sleep(for: .seconds(1))
            results = query.isEmpty ? [] : ["Resultado 1", "Resultado 2", "Resultado 3"]
            isSearching = false
        }

        if !results.isEmpty {
            VStack(alignment: .leading) {
                Text("Resultados:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(results, id: \.self) { result in
                    Text(result)
                        .padding(.vertical, 4)
                }
            }
        }
    }
    .padding()
}

#Preview("SearchField en Dark Mode") {
    @Previewable @State var searchText = "Dark theme"

    EduSearchField(
        placeholder: "Buscar...",
        text: $searchText
    )
    .padding()
    .preferredColorScheme(.dark)
}
