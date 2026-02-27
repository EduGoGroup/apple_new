import SwiftUI
import DesignSystemSDK
import FormsSDK

/// SecureField para contraseñas con toggle show/hide y validación integrada.
///
/// Características:
/// - Toggle para mostrar/ocultar contraseña (iOS, macOS, visionOS)
/// - Validación de seguridad integrada
/// - Estados: normal, error, disabled, focused
/// - Integración con FormState
/// - Feedback visual de fortaleza de contraseña
///
/// ## ⚠️ CONSIDERACIONES DE SEGURIDAD
///
/// **Clipboard:**
/// Cuando `showPasswordToggle` está activado y el usuario muestra la contraseña,
/// el texto puede ser copiado al clipboard. Para contextos de alta seguridad,
/// considera desactivar `showPasswordToggle`.
///
/// **Screen Recording y Screenshots:**
/// iOS y macOS pueden capturar pantalla cuando la contraseña está visible.
/// Para datos extremadamente sensibles, mantén `showPasswordToggle = false`.
///
/// **Almacenamiento Persistente:**
/// `EduSecureField` NO almacena contraseñas automáticamente. Para persistencia
/// segura, integra con Keychain (ver ejemplo más abajo).
///
/// **Mejores Prácticas por Contexto:**
/// - Para login: `showPasswordToggle = true` (mejor UX)
/// - Para confirmación de password: `showPasswordToggle = false`
/// - Para cambio de password: `showPasswordToggle = true` con validación fuerte
/// - Para transacciones financieras: considerar biometría en lugar de password
///
/// **Ejemplo de validación recomendada:**
/// ```swift
/// EduSecureField(
///     "Contraseña",
///     text: $password,
///     validation: Validators.password(
///         minLength: 12,
///         requireUppercase: true,
///         requireNumbers: true,
///         requireSymbols: true
///     ),
///     showStrengthIndicator: true
/// )
/// ```
///
/// **Ejemplo de integración con Keychain:**
/// ```swift
/// import Security
///
/// // Guardar contraseña en Keychain
/// func saveToKeychain(password: String, account: String) {
///     let data = password.data(using: .utf8)!
///     let query: [String: Any] = [
///         kSecClass as String: kSecClassGenericPassword,
///         kSecAttrAccount as String: account,
///         kSecValueData as String: data,
///         kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
///     ]
///
///     // Eliminar entrada anterior si existe
///     SecItemDelete(query as CFDictionary)
///
///     // Agregar nueva entrada
///     let status = SecItemAdd(query as CFDictionary, nil)
///     if status != errSecSuccess {
///         print("Error guardando en Keychain: \(status)")
///     }
/// }
///
/// // Recuperar contraseña de Keychain
/// func retrieveFromKeychain(account: String) -> String? {
///     let query: [String: Any] = [
///         kSecClass as String: kSecClassGenericPassword,
///         kSecAttrAccount as String: account,
///         kSecReturnData as String: true,
///         kSecMatchLimit as String: kSecMatchLimitOne
///     ]
///
///     var result: AnyObject?
///     let status = SecItemCopyMatching(query as CFDictionary, &result)
///
///     guard status == errSecSuccess,
///           let data = result as? Data,
///           let password = String(data: data, encoding: .utf8) else {
///         return nil
///     }
///
///     return password
/// }
/// ```
///
/// - SeeAlso: `Validators.password(minLength:requireUppercase:requireNumbers:requireSymbols:)`
/// - SeeAlso: [OWASP Mobile Security Testing Guide](https://owasp.org/www-project-mobile-security-testing-guide/)
/// - SeeAlso: [iOS Keychain Services](https://developer.apple.com/documentation/security/keychain_services)
public struct EduSecureField: View {
    // MARK: - Properties

    private let title: String
    private let placeholder: String
    @Binding private var text: String
    private let helperText: String?
    private let validation: (@Sendable (String) -> ValidationResult)?
    private let formState: FormState?
    private let fieldKey: String?
    private let showPasswordToggle: Bool
    private let showStrengthIndicator: Bool
    private let onCommit: (() -> Void)?

    @State private var validationState: ValidationState
    @State private var isFocused: Bool = false
    @State private var isPasswordVisible: Bool = false
    @State private var originalText: String = ""

    private var isDisabled: Bool

    // MARK: - Initializers

    /// Inicializa un EduSecureField con validación completa.
    ///
    /// - Parameters:
    ///   - title: Título del campo (label)
    ///   - text: Binding al texto de la contraseña
    ///   - placeholder: Texto placeholder cuando está vacío
    ///   - helperText: Texto de ayuda opcional debajo del campo
    ///   - validation: Closure de validación opcional
    ///   - formState: FormState opcional para integración con formularios
    ///   - fieldKey: Clave única para registro en FormState
    ///   - showPasswordToggle: Mostrar botón para revelar contraseña (default: true)
    ///   - showStrengthIndicator: Mostrar indicador de fortaleza (default: false)
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
        showPasswordToggle: Bool = true,
        showStrengthIndicator: Bool = false,
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
        self.showPasswordToggle = showPasswordToggle
        self.showStrengthIndicator = showStrengthIndicator
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

            // Campo de contraseña con toggle
            HStack(spacing: DesignTokens.Spacing.small) {
                Group {
                    if isPasswordVisible {
                        TextField(placeholder, text: $text, onCommit: {
                            validateField()
                            onCommit?()
                        })
                    } else {
                        SecureField(placeholder, text: $text, onCommit: {
                            validateField()
                            onCommit?()
                        })
                    }
                }
                .textFieldStyle(.roundedBorder)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                #endif
                .disabled(isDisabled)
                .onChange(of: text) { _, newValue in
                    validateField()
                }
                .onFocusChange { focused in
                    isFocused = focused
                    if focused {
                        originalText = text
                    }
                }

                // Toggle button (solo en plataformas aplicables)
                #if os(iOS) || os(macOS) || os(visionOS)
                if showPasswordToggle {
                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundStyle(.secondary)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                    .disabled(isDisabled)
                    .accessibilityLabel(isPasswordVisible ? "Ocultar contraseña" : "Mostrar contraseña")
                }
                #endif
            }
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                    .stroke(borderColor, lineWidth: isFocused ? DesignTokens.BorderWidth.medium : DesignTokens.BorderWidth.thin)
            )

            // Indicador de fortaleza
            if showStrengthIndicator && !text.isEmpty {
                PasswordStrengthIndicator(password: text)
            }

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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityValue("Hidden")
        .accessibleIdentifier(.secureField(module: "ui", screen: "input", context: title.lowercased().replacingOccurrences(of: " ", with: "_")))
        .onChange(of: isPasswordVisible) { _, newValue in
            let announcement = newValue ? "Password visible" : "Password hidden"
            AccessibilityAnnouncements.announce(announcement, priority: .medium)
        }
        .onChange(of: validationState.errorMessage) { oldValue, newValue in
            if let error = newValue, oldValue != newValue {
                AccessibilityAnnouncements.announceError(error)
            }
        }
        // MARK: - Keyboard Navigation
        .tabPriority(25)
        .cancelEditingOnEscape(text: $text, originalValue: originalText)
    }

    // MARK: - Accessibility Helpers

    private var accessibilityLabelText: String {
        var label = "Secure text field for \(title)"
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

// MARK: - Password Strength Indicator

private struct PasswordStrengthIndicator: View {
    let password: String

    private var strength: PasswordStrength {
        calculateStrength(password)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                ForEach(0..<4, id: \.self) { index in
                    Rectangle()
                        .fill(index < strength.level ? strength.color : Color.secondary.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                }
            }

            Text(strength.text)
                .font(.caption)
                .foregroundStyle(strength.color)
        }
    }

    private func calculateStrength(_ password: String) -> PasswordStrength {
        var score = 0

        if password.count >= 8 { score += 1 }
        if password.count >= 12 { score += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .lowercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
        if password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil { score += 1 }

        switch score {
        case 0...2:
            return PasswordStrength(level: 1, text: "Débil", color: .red)
        case 3...4:
            return PasswordStrength(level: 2, text: "Media", color: .orange)
        case 5:
            return PasswordStrength(level: 3, text: "Buena", color: .yellow)
        default:
            return PasswordStrength(level: 4, text: "Fuerte", color: .green)
        }
    }
}

private struct PasswordStrength {
    let level: Int
    let text: String
    let color: Color
}

// MARK: - Previews

#Preview("Basic SecureField") {
    @Previewable @State var password = ""

    EduSecureField(
        "Contraseña",
        text: $password,
        placeholder: "Ingresa tu contraseña",
        helperText: "Mínimo 8 caracteres"
    )
    .padding()
}

#Preview("SecureField con Validación") {
    @Previewable @State var password = "123"

    EduSecureField(
        "Contraseña",
        text: $password,
        placeholder: "Mínimo 8 caracteres",
        validation: Validators.password(minLength: 8)
    )
    .padding()
}

#Preview("SecureField con Indicador de Fortaleza") {
    @Previewable @State var password = "MyP@ssw0rd!"

    EduSecureField(
        "Contraseña",
        text: $password,
        placeholder: "Ingresa contraseña segura",
        showStrengthIndicator: true
    )
    .padding()
}

#Preview("SecureField sin Toggle") {
    @Previewable @State var password = "secreto"

    EduSecureField(
        "PIN Seguro",
        text: $password,
        placeholder: "****",
        showPasswordToggle: false
    )
    .padding()
}

#Preview("SecureField con FormState") {
    @Previewable @State var password = ""
    @Previewable @State var formState = FormState()

    VStack(spacing: 16) {
        EduSecureField(
            "Contraseña",
            text: $password,
            placeholder: "Mínimo 8 caracteres",
            validation: Validators.password(minLength: 8),
            formState: formState,
            fieldKey: "password",
            showStrengthIndicator: true
        )

        Text("Formulario válido: \(formState.isValid ? "Sí" : "No")")
            .foregroundStyle(formState.isValid ? .green : .red)
    }
    .padding()
}

// MARK: - Security Examples Previews

#Preview("Seguridad Alta - Transacciones Financieras") {
    @Previewable @State var password = ""

    VStack(alignment: .leading, spacing: 16) {
        Text("Contexto: Transacción financiera")
            .font(.headline)

        Text("showPasswordToggle = false para máxima seguridad")
            .font(.caption)
            .foregroundStyle(.secondary)

        EduSecureField(
            "PIN de Seguridad",
            text: $password,
            placeholder: "Mínimo 12 caracteres",
            validation: Validators.password(
                minLength: 12,
                requireUppercase: true,
                requireNumbers: true,
                requireSymbols: true
            ),
            showPasswordToggle: false,
            showStrengthIndicator: true
        )
    }
    .padding()
}

#Preview("Seguridad Media - Login Usuario") {
    @Previewable @State var password = ""

    VStack(alignment: .leading, spacing: 16) {
        Text("Contexto: Login de usuario")
            .font(.headline)

        Text("showPasswordToggle = true para mejor UX")
            .font(.caption)
            .foregroundStyle(.secondary)

        EduSecureField(
            "Contraseña",
            text: $password,
            placeholder: "Ingresa tu contraseña",
            helperText: "Mínimo 8 caracteres, incluye mayúsculas y números",
            validation: Validators.password(
                minLength: 8,
                requireUppercase: true,
                requireNumbers: true
            ),
            showPasswordToggle: true,
            showStrengthIndicator: true
        )
    }
    .padding()
}

#Preview("Confirmación de Contraseña") {
    @Previewable @State var password = "MyP@ssw0rd123"
    @Previewable @State var confirmPassword = ""

    VStack(alignment: .leading, spacing: 16) {
        Text("Contexto: Confirmación de contraseña")
            .font(.headline)

        Text("showPasswordToggle = false para evitar errores visuales")
            .font(.caption)
            .foregroundStyle(.secondary)

        EduSecureField(
            "Contraseña Nueva",
            text: $password,
            validation: Validators.password(
                minLength: 12,
                requireUppercase: true,
                requireNumbers: true,
                requireSymbols: true
            ),
            showPasswordToggle: false,
            showStrengthIndicator: true
        )

        EduSecureField(
            "Confirmar Contraseña",
            text: $confirmPassword,
            validation: { value in
                if value != password {
                    return .invalid("Las contraseñas no coinciden")
                }
                return .valid()
            },
            showPasswordToggle: false
        )
    }
    .padding()
}

#Preview("Ejemplo Keychain - Flujo Completo") {
    @Previewable @State var password = ""
    @Previewable @State var savedMessage = ""

    VStack(alignment: .leading, spacing: 16) {
        Text("Ejemplo: Integración con Keychain")
            .font(.headline)

        EduSecureField(
            "Contraseña",
            text: $password,
            placeholder: "Ingresa contraseña para guardar",
            validation: Validators.password(
                minLength: 8,
                requireUppercase: true,
                requireNumbers: true
            ),
            showPasswordToggle: true,
            showStrengthIndicator: true
        )

        Button("Guardar en Keychain") {
            // Simulación - en producción usar código Keychain real
            if !password.isEmpty {
                savedMessage = "Contraseña guardada de forma segura en Keychain"
            }
        }
        .disabled(password.isEmpty)

        if !savedMessage.isEmpty {
            Text(savedMessage)
                .font(.caption)
                .foregroundStyle(.green)
        }

        Text("Nota: Este preview simula el guardado. Ver documentación para implementación real con Security framework.")
            .font(.caption2)
            .foregroundStyle(.secondary)
    }
    .padding()
}
