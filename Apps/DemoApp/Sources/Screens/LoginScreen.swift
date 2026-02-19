import SwiftUI
import EduPresentation
import EduNetwork

/// Pantalla de login para la DemoApp.
///
/// Usa los componentes del Design System (`EduTextField`, `EduSecureField`, `EduButton`)
/// y delega la autenticación al `AuthService`.
@MainActor
public struct LoginScreen: View {

    // MARK: - State

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    // MARK: - Dependencies

    private let authService: AuthService
    private let onLoginSuccess: () -> Void

    // MARK: - Initialization

    public init(authService: AuthService, onLoginSuccess: @escaping () -> Void) {
        self.authService = authService
        self.onLoginSuccess = onLoginSuccess
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("EduGo")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(spacing: 16) {
                EduTextField(
                    "Email",
                    text: $email,
                    placeholder: "tu@email.com"
                )

                EduSecureField(
                    "Contrasena",
                    text: $password,
                    placeholder: "Ingresa tu contrasena"
                )
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            EduButton.primary(
                "Iniciar Sesion",
                isLoading: isLoading,
                isDisabled: email.isEmpty || password.isEmpty
            ) {
                performLogin()
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Actions

    private func performLogin() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                _ = try await authService.login(email: email, password: password)
                isLoading = false
                onLoginSuccess()
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
