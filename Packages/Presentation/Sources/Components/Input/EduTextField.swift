import SwiftUI

/// TextField genérico con validación integrada y soporte multi-plataforma.
///
/// Características:
/// - Binding bidireccional con validación en tiempo real
/// - Estados: normal, error, disabled, focused
/// - Placeholder dinámico
/// - Helper text y error messages
/// - Integración con FormState y ValidationFieldModifier
/// - Soporte para iOS y macOS
@MainActor
public struct EduTextField: View {
    // MARK: - Properties

    private let title: String
    private let placeholder: String
    @Binding private var text: String
    private let helperText: String?
    private let validation: (@Sendable (String) -> ValidationResult)?
    private let formState: FormState?
    private let fieldKey: String?
    private let onCommit: (() -> Void)?

    @State private var validationState: ValidationState
    @State private var isFocused: Bool = false
    @State private var originalText: String = ""
    @FocusState private var fieldIsFocused: Bool

    private var isDisabled: Bool

    // MARK: - Initializers

    /// Inicializa un EduTextField con validación completa.
    ///
    /// - Parameters:
    ///   - title: Título del campo (label)
    ///   - text: Binding al texto del campo
    ///   - placeholder: Texto placeholder cuando está vacío
    ///   - helperText: Texto de ayuda opcional debajo del campo
    ///   - validation: Closure de validación opcional
    ///   - formState: FormState opcional para integración con formularios
    ///   - fieldKey: Clave única para registro en FormState
    ///   - isDisabled: Si el campo está deshabilitado
    ///   - onCommit: Closure que se ejecuta al presionar return/enter
    public init(
        _ title: String,
        text: Binding<String>,
        placeholder: String = "",
        helperText: String? = nil,
        validation: (@Sendable (String) -> ValidationResult)? = nil,
        formState: FormState? = nil,
        fieldKey: String? = nil,
        isDisabled: Bool = false,
        onCommit: (() -> Void)? = nil
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.helperText = helperText
        self.validation = validation
        self.formState = formState
        self.fieldKey = fieldKey
        self.isDisabled = isDisabled
        self.onCommit = onCommit
        self._validationState = State(initialValue: ValidationState())

        // Registrar en FormState si está disponible
        if let formState = formState, let fieldKey = fieldKey, let validation = validation {
            formState.registerField(fieldKey) { [text] in
                validation(text.wrappedValue)
            }
        }
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            // Label
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(isDisabled ? .secondary : .primary)

            // TextField
            TextField(placeholder, text: $text)
            .textFieldStyle(.roundedBorder)
            #if os(iOS)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            #endif
            .disabled(isDisabled)
            .focused($fieldIsFocused)
            .onSubmit {
                validateField()
                onCommit?()
            }
            .onChange(of: text) { _, newValue in
                validateField()
            }
            .onChange(of: fieldIsFocused) { _, focused in
                isFocused = focused
                if focused {
                    originalText = text
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                    .stroke(borderColor, lineWidth: isFocused ? DesignTokens.BorderWidth.medium : DesignTokens.BorderWidth.thin)
                    .allowsHitTesting(false)
            )

            // Helper text o error message
            if let error = validationState.errorMessage {
                Label(error, systemImage: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            } else if let helper = helperText {
                Text(helper)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .opacity(isDisabled ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: validationState.errorMessage)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        // MARK: - Accessibility
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityValue(text.isEmpty ? "empty" : text)
        .accessibleIdentifier(.textField(module: "ui", screen: "input", context: title.lowercased().replacingOccurrences(of: " ", with: "_")))
        .onChange(of: validationState.errorMessage) { oldValue, newValue in
            if let error = newValue, oldValue != newValue {
                AccessibilityAnnouncements.announceError(error)
            }
        }
        // MARK: - Keyboard Navigation
        .tabPriority(20)
        .cancelEditingOnEscape(text: $text, originalValue: originalText)
    }

    // MARK: - Accessibility Helpers

    private var accessibilityLabelText: String {
        var label = "Text field, \(title)"
        if !validationState.isValid, let error = validationState.errorMessage {
            label += ", error: \(error)"
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
        if !validationState.isValid {
            return .red
        }
        if isFocused {
            return .accentColor
        }
        return .secondary.opacity(0.5)
    }

    private func validateField() {
        guard let validation = validation else {
            validationState.isValid = true
            validationState.errorMessage = nil
            return
        }

        let result = validation(text)
        validationState.isValid = result.isValid
        validationState.errorMessage = result.errorMessage

        // Actualizar FormState si está disponible
        if let formState = formState, let fieldKey = fieldKey {
            formState.validateField(fieldKey)
        }
    }
}

// MARK: - ValidationState

@MainActor
@Observable
final class ValidationState {
    var isValid: Bool = true
    var errorMessage: String? = nil
}

// MARK: - Previews

#Preview("Basic TextField") {
    @Previewable @State var text = ""

    EduTextField(
        "Email",
        text: $text,
        placeholder: "tu@email.com",
        helperText: "Ingresa tu correo electrónico"
    )
    .padding()
}

#Preview("TextField con Validación") {
    @Previewable @State var email = "invalid"

    EduTextField(
        "Email",
        text: $email,
        placeholder: "tu@email.com",
        validation: Validators.email()
    )
    .padding()
}

#Preview("TextField Deshabilitado") {
    @Previewable @State var text = "Texto deshabilitado"

    EduTextField(
        "Campo Bloqueado",
        text: $text,
        placeholder: "No editable",
        isDisabled: true
    )
    .padding()
}

#Preview("TextField con FormState") {
    @Previewable @State var email = ""
    @Previewable @State var formState = FormState()

    VStack(spacing: 16) {
        EduTextField(
            "Email",
            text: $email,
            placeholder: "tu@email.com",
            validation: Validators.email(),
            formState: formState,
            fieldKey: "email"
        )

        Text("Formulario válido: \(formState.isValid ? "Sí" : "No")")
            .foregroundStyle(formState.isValid ? .green : .red)
    }
    .padding()
}
