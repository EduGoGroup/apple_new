# Registration Example

Formulario de registro con validación cruzada entre campos.

## Overview

Este ejemplo muestra cómo implementar un formulario de registro completo con:
- Validación de múltiples campos
- Validación cruzada (confirmación de contraseña)
- Campos condicionales
- Términos y condiciones

## ViewModel

```swift
import Foundation
import Observation
import Binding

@MainActor
@Observable
public final class RegistrationViewModel {
    
    // MARK: - Basic Fields
    
    @BindableProperty(validation: Validators.nonEmpty(fieldName: "Nombre"))
    public var firstName: String = ""
    
    @BindableProperty(validation: Validators.nonEmpty(fieldName: "Apellido"))
    public var lastName: String = ""
    
    @BindableProperty(validation: Validators.email())
    public var email: String = ""
    
    // MARK: - Password Fields
    
    @BindableProperty(
        validation: Validators.all(
            Validators.password(minLength: 8),
            Validators.pattern(
                ".*[A-Z]+.*",
                message: "Debe contener al menos una mayúscula"
            ),
            Validators.pattern(
                ".*[0-9]+.*",
                message: "Debe contener al menos un número"
            )
        )
    )
    public var password: String = ""
    
    @BindableProperty(validation: Validators.nonEmpty(fieldName: "Confirmación"))
    public var passwordConfirmation: String = ""
    
    // MARK: - Optional Fields
    
    public var wantsNewsletter: Bool = false
    
    @BindableProperty(
        validation: Validators.when(
            { !$0.isEmpty },
            then: Validators.pattern(
                "^\\+?[0-9]{10,15}$",
                message: "Número de teléfono inválido"
            )
        )
    )
    public var phone: String = ""
    
    // MARK: - Terms
    
    public var acceptsTerms: Bool = false
    
    // MARK: - Form State
    
    public let formState = FormState()
    
    // MARK: - Dependencies
    
    private let userService: UserServiceProtocol
    private let onRegistrationSuccess: (User) -> Void
    
    // MARK: - Init
    
    public init(
        userService: UserServiceProtocol,
        onRegistrationSuccess: @escaping (User) -> Void
    ) {
        self.userService = userService
        self.onRegistrationSuccess = onRegistrationSuccess
        
        setupCrossValidation()
    }
    
    // MARK: - Cross Validation
    
    private func setupCrossValidation() {
        // Passwords deben coincidir
        formState.registerCrossValidator { [weak self] in
            guard let self else { return .valid() }
            return CrossValidators.passwordMatch(password, passwordConfirmation)
        }
        
        // Teléfono requerido si quiere newsletter
        formState.registerCrossValidator { [weak self] in
            guard let self else { return .valid() }
            return CrossValidators.conditionalRequired(
                value: phone,
                condition: wantsNewsletter,
                fieldName: "Teléfono"
            )
        }
        
        // Debe aceptar términos
        formState.registerCrossValidator { [weak self] in
            guard let self else { return .valid() }
            if !acceptsTerms {
                return .invalid("Debe aceptar los términos y condiciones")
            }
            return .valid()
        }
    }
    
    // MARK: - Computed Properties
    
    public var isFormValid: Bool {
        $firstName.validationState.isValid &&
        $lastName.validationState.isValid &&
        $email.validationState.isValid &&
        $password.validationState.isValid &&
        $passwordConfirmation.validationState.isValid &&
        $phone.validationState.isValid
    }
    
    public var canSubmit: Bool {
        isFormValid && acceptsTerms && !formState.isSubmitting
    }
    
    public var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
    
    // MARK: - Actions
    
    public func register() async {
        // Validar todos los campos
        validateAllFields()
        formState.validate()
        
        guard isFormValid && formState.isValid else { return }
        
        let success = await formState.submit { [weak self] in
            guard let self else { return }
            
            let user = try await userService.register(
                firstName: firstName,
                lastName: lastName,
                email: email,
                password: password,
                phone: phone.isEmpty ? nil : phone,
                wantsNewsletter: wantsNewsletter
            )
            
            await MainActor.run {
                onRegistrationSuccess(user)
            }
        }
        
        if !success {
            // El error ya está en formState.errors["form"]
        }
    }
    
    private func validateAllFields() {
        $firstName.validate()
        $lastName.validate()
        $email.validate()
        $password.validate()
        $passwordConfirmation.validate()
        $phone.validate()
    }
}
```

## View

```swift
import SwiftUI
import Binding

public struct RegistrationView: View {
    
    @State private var viewModel: RegistrationViewModel
    @State private var showValidation = false
    @State private var showTerms = false
    
    public init(viewModel: RegistrationViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                personalInfoSection
                credentialsSection
                optionalSection
                termsSection
                submitSection
            }
            .formErrorBanner(viewModel.formState)
            .loadingOverlay(
                isLoading: viewModel.formState.isSubmitting,
                message: "Creando cuenta..."
            )
            .navigationTitle("Crear Cuenta")
            .sheet(isPresented: $showTerms) {
                TermsAndConditionsView()
            }
        }
    }
    
    // MARK: - Sections
    
    private var personalInfoSection: some View {
        Section("Información Personal") {
            TextField("Nombre", text: $viewModel.firstName)
                .textContentType(.givenName)
                .validated(
                    viewModel.$firstName.validationState,
                    showValidation: showValidation
                )
            
            TextField("Apellido", text: $viewModel.lastName)
                .textContentType(.familyName)
                .validated(
                    viewModel.$lastName.validationState,
                    showValidation: showValidation
                )
            
            TextField("Email", text: $viewModel.email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .validated(
                    viewModel.$email.validationState,
                    showValidation: showValidation
                )
        }
    }
    
    private var credentialsSection: some View {
        Section {
            SecureField("Contraseña", text: $viewModel.password)
                .textContentType(.newPassword)
                .validated(
                    viewModel.$password.validationState,
                    showValidation: showValidation
                )
            
            SecureField("Confirmar Contraseña", text: $viewModel.passwordConfirmation)
                .textContentType(.newPassword)
                .validated(
                    viewModel.$passwordConfirmation.validationState,
                    showValidation: showValidation
                )
        } header: {
            Text("Contraseña")
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                Text("La contraseña debe tener:")
                Text("• Al menos 8 caracteres")
                Text("• Al menos una mayúscula")
                Text("• Al menos un número")
            }
            .font(.caption)
        }
    }
    
    private var optionalSection: some View {
        Section("Opcional") {
            Toggle("Recibir newsletter", isOn: $viewModel.wantsNewsletter)
            
            if viewModel.wantsNewsletter {
                TextField("Teléfono", text: $viewModel.phone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
                    .validated(
                        viewModel.$phone.validationState,
                        showValidation: showValidation
                    )
            }
        }
    }
    
    private var termsSection: some View {
        Section {
            Toggle(isOn: $viewModel.acceptsTerms) {
                HStack {
                    Text("Acepto los ")
                    Button("términos y condiciones") {
                        showTerms = true
                    }
                    .foregroundColor(.accentColor)
                }
            }
        }
    }
    
    private var submitSection: some View {
        Section {
            Button {
                showValidation = true
                Task {
                    await viewModel.register()
                }
            } label: {
                HStack {
                    Spacer()
                    Text("Crear Cuenta")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
            .disabled(!viewModel.canSubmit && showValidation)
            .disabledDuringSubmit(viewModel.formState)
        }
    }
}
```

## Testing

```swift
import Testing
@testable import Binding

@Suite("RegistrationViewModel Tests")
@MainActor
struct RegistrationViewModelTests {
    
    @Test("Password confirmation must match")
    func passwordMismatch() {
        let viewModel = makeViewModel()
        
        viewModel.password = "Password123"
        viewModel.passwordConfirmation = "DifferentPassword"
        viewModel.formState.validate()
        
        #expect(!viewModel.formState.isValid)
        #expect(viewModel.formState.errors["form"]?.contains("coincidir") == true)
    }
    
    @Test("Phone required when newsletter enabled")
    func phoneRequiredForNewsletter() {
        let viewModel = makeViewModel()
        
        viewModel.wantsNewsletter = true
        viewModel.phone = ""
        viewModel.formState.validate()
        
        #expect(!viewModel.formState.isValid)
    }
    
    @Test("Phone optional when newsletter disabled")
    func phoneOptionalWithoutNewsletter() {
        let viewModel = makeViewModel()
        
        viewModel.wantsNewsletter = false
        viewModel.phone = ""
        viewModel.formState.validate()
        
        // Phone no causa error
        #expect(viewModel.formState.errors["form"]?.contains("Teléfono") != true)
    }
    
    @Test("Terms must be accepted")
    func termsRequired() {
        let viewModel = makeViewModel()
        
        viewModel.acceptsTerms = false
        viewModel.formState.validate()
        
        #expect(!viewModel.formState.isValid)
        #expect(viewModel.formState.errors["form"]?.contains("términos") == true)
    }
    
    private func makeViewModel() -> RegistrationViewModel {
        RegistrationViewModel(
            userService: MockUserService(),
            onRegistrationSuccess: { _ in }
        )
    }
}
```

## Ver También

- <doc:LoginExample>
- <doc:SearchExample>
- <doc:CrossFieldValidation>
