# Login Example

Implementación completa de un formulario de login con validación.

## Overview

Este ejemplo muestra cómo implementar un formulario de login con:
- Validación en tiempo real
- Feedback visual
- Estados de carga
- Manejo de errores

## ViewModel

```swift
import Foundation
import Observation
import Binding

@MainActor
@Observable
public final class LoginViewModel {
    
    // MARK: - Properties
    
    @BindableProperty(validation: Validators.email())
    public var email: String = ""
    
    @BindableProperty(validation: Validators.password(minLength: 8))
    public var password: String = ""
    
    public let formState = FormState()
    
    // MARK: - Computed Properties
    
    public var isFormValid: Bool {
        $email.validationState.isValid && $password.validationState.isValid
    }
    
    public var canSubmit: Bool {
        isFormValid && !formState.isSubmitting
    }
    
    // MARK: - Dependencies
    
    private let authService: AuthServiceProtocol
    private let onLoginSuccess: () -> Void
    
    // MARK: - Init
    
    public init(
        authService: AuthServiceProtocol,
        onLoginSuccess: @escaping () -> Void
    ) {
        self.authService = authService
        self.onLoginSuccess = onLoginSuccess
    }
    
    // MARK: - Actions
    
    public func login() async {
        // Validar todos los campos
        $email.validate()
        $password.validate()
        
        guard isFormValid else { return }
        
        let success = await formState.submit { [weak self] in
            guard let self else { return }
            try await authService.login(email: email, password: password)
        }
        
        if success {
            onLoginSuccess()
        }
    }
    
    public func clearForm() {
        email = ""
        password = ""
        $email.resetValidation()
        $password.resetValidation()
        formState.reset()
    }
}
```

## View

```swift
import SwiftUI
import Binding

public struct LoginView: View {
    
    // MARK: - State
    
    @State private var viewModel: LoginViewModel
    @State private var showValidation = false
    
    // MARK: - Init
    
    public init(viewModel: LoginViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    // MARK: - Body
    
    public var body: some View {
        NavigationStack {
            Form {
                credentialsSection
                submitSection
                forgotPasswordSection
            }
            .formErrorBanner(viewModel.formState)
            .loadingOverlay(
                isLoading: viewModel.formState.isSubmitting,
                message: "Iniciando sesión..."
            )
            .navigationTitle("Iniciar Sesión")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        viewModel.clearForm()
                    }
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var credentialsSection: some View {
        Section {
            TextField("Email", text: $viewModel.email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .validated(
                    viewModel.$email.validationState,
                    showValidation: showValidation
                )
            
            SecureField("Contraseña", text: $viewModel.password)
                .textContentType(.password)
                .validated(
                    viewModel.$password.validationState,
                    showValidation: showValidation
                )
        } header: {
            Text("Credenciales")
        } footer: {
            Text("La contraseña debe tener al menos 8 caracteres.")
                .font(.caption)
        }
    }
    
    private var submitSection: some View {
        Section {
            Button {
                showValidation = true
                Task {
                    await viewModel.login()
                }
            } label: {
                HStack {
                    Spacer()
                    Text("Iniciar Sesión")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
            .disabled(!viewModel.canSubmit && showValidation)
            .disabledDuringSubmit(viewModel.formState)
        }
    }
    
    private var forgotPasswordSection: some View {
        Section {
            NavigationLink("¿Olvidaste tu contraseña?") {
                ForgotPasswordView()
            }
            .foregroundColor(.accentColor)
        }
    }
}

// MARK: - Preview

#Preview {
    LoginView(
        viewModel: LoginViewModel(
            authService: MockAuthService(),
            onLoginSuccess: { print("Login successful!") }
        )
    )
}
```

## Testing

```swift
import Testing
@testable import Binding
@testable import YourApp

@Suite("LoginViewModel Tests")
@MainActor
struct LoginViewModelTests {
    
    @Test("Valid form with correct credentials")
    func validForm() {
        let viewModel = LoginViewModel(
            authService: MockAuthService(),
            onLoginSuccess: { }
        )
        
        viewModel.email = "user@example.com"
        viewModel.password = "password123"
        
        #expect(viewModel.isFormValid)
        #expect(viewModel.canSubmit)
    }
    
    @Test("Invalid email shows error")
    func invalidEmail() {
        let viewModel = LoginViewModel(
            authService: MockAuthService(),
            onLoginSuccess: { }
        )
        
        viewModel.email = "invalid-email"
        viewModel.$email.validate()
        
        #expect(!viewModel.$email.validationState.isValid)
        #expect(viewModel.$email.validationState.errorMessage != nil)
    }
    
    @Test("Short password shows error")
    func shortPassword() {
        let viewModel = LoginViewModel(
            authService: MockAuthService(),
            onLoginSuccess: { }
        )
        
        viewModel.password = "short"
        viewModel.$password.validate()
        
        #expect(!viewModel.$password.validationState.isValid)
    }
    
    @Test("Login success calls callback")
    func loginSuccess() async {
        var callbackCalled = false
        
        let viewModel = LoginViewModel(
            authService: MockAuthService(shouldSucceed: true),
            onLoginSuccess: { callbackCalled = true }
        )
        
        viewModel.email = "user@example.com"
        viewModel.password = "password123"
        
        await viewModel.login()
        
        #expect(callbackCalled)
    }
    
    @Test("Login failure shows error")
    func loginFailure() async {
        let viewModel = LoginViewModel(
            authService: MockAuthService(shouldSucceed: false),
            onLoginSuccess: { }
        )
        
        viewModel.email = "user@example.com"
        viewModel.password = "password123"
        
        await viewModel.login()
        
        #expect(viewModel.formState.errors["form"] != nil)
    }
}

// Mock
class MockAuthService: AuthServiceProtocol {
    let shouldSucceed: Bool
    
    init(shouldSucceed: Bool = true) {
        self.shouldSucceed = shouldSucceed
    }
    
    func login(email: String, password: String) async throws {
        if !shouldSucceed {
            throw NSError(domain: "Auth", code: 401)
        }
    }
}
```

## Ver También

- <doc:RegistrationExample>
- <doc:RealTimeValidation>
- <doc:ViewModifiersGuide>
