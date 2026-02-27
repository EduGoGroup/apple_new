import Foundation
import SwiftUI
import EduDomain
import EduCore
import EduFoundation

/// ViewModel para Login usando CQRS Mediator.
///
/// Este ViewModel se refactorizó para usar el patrón CQRS en lugar de
/// llamar use cases directamente. La autenticación se ejecuta a través
/// de LoginCommand con validación automática y eventos de dominio.
///
/// ## Responsabilidades
/// - Gestionar estado del formulario de login (email, password)
/// - Ejecutar LoginCommand via Mediator
/// - Gestionar estado de carga y errores con feedback específico
/// - Publicar LoginSuccessEvent automáticamente después de login exitoso
///
/// ## Integración con CQRS
/// - **Commands**: LoginCommand (con validación pre-ejecución)
/// - **Events**: LoginSuccessEvent (publicado automáticamente por handler)
///
/// ## Manejo de Errores
/// - ValidationError: Errores de formato (email, password)
/// - ExecutionError: Errores de autenticación (credenciales incorrectas)
/// - HandlerNotFoundError: Error de configuración del sistema
///
/// ## Ejemplo de uso
/// ```swift
/// @StateObject private var viewModel = LoginViewModel(mediator: mediator)
///
/// TextField("Email", text: $viewModel.email)
/// SecureField("Password", text: $viewModel.password)
/// Button("Login") {
///     await viewModel.login()
/// }
/// ```
@MainActor
@Observable
public final class LoginViewModel {

    // MARK: - Published State

    /// Email del usuario
    public var email: String = ""

    /// Contraseña del usuario
    public var password: String = ""

    /// Indica si está autenticando
    public var isLoading: Bool = false

    /// Error actual si lo hay
    public var error: Error?

    /// Usuario autenticado exitosamente
    public var authenticatedUser: User?

    /// Indica si el login fue exitoso
    public var isAuthenticated: Bool = false

    // MARK: - Dependencies

    /// Mediator CQRS para dispatch de commands
    private let mediator: Mediator

    // MARK: - Initialization

    /// Crea un nuevo LoginViewModel.
    ///
    /// - Parameter mediator: Mediator CQRS para ejecutar commands
    public init(mediator: Mediator) {
        self.mediator = mediator
    }

    // MARK: - Public Methods

    /// Ejecuta el login del usuario.
    ///
    /// Crea un LoginCommand y lo ejecuta via Mediator. El command incluye
    /// validación automática (email formato válido, password mínimo 8 caracteres).
    /// Si la autenticación es exitosa, se publica LoginSuccessEvent automáticamente.
    public func login() async {
        isLoading = true
        error = nil

        do {
            // Crear command con credenciales
            let command = LoginCommand(
                email: email,
                password: password,
                metadata: [
                    "source": "LoginViewModel",
                    "timestamp": ISO8601DateFormatter().string(from: Date())
                ]
            )

            // Ejecutar command via Mediator (con validación automática)
            let result = try await mediator.execute(command)

            // Verificar resultado del command
            if result.isSuccess, let loginOutput = result.getValue() {
                // Login exitoso
                self.authenticatedUser = loginOutput.user
                self.isAuthenticated = true
                self.isLoading = false

                // Limpiar password por seguridad
                self.password = ""

                // Log de eventos publicados
                print("✅ Login exitoso. Eventos publicados: \(result.events)")

            } else if let error = result.getError() {
                // Login falló (credenciales incorrectas)
                self.error = error
                self.isLoading = false
                self.password = ""

                print("❌ Login falló: \(error.localizedDescription)")
            }

        } catch {
            // Manejar errores de validación o ejecución
            self.error = error
            self.isLoading = false
            self.password = ""

            print("❌ Error en login: \(error.localizedDescription)")
        }
    }

    /// Limpia el error actual.
    public func clearError() {
        error = nil
    }

    /// Cierra sesión y limpia el estado.
    public func logout() {
        authenticatedUser = nil
        isAuthenticated = false
        email = ""
        password = ""
        error = nil
    }

    // MARK: - Validation

    /// Valida el formulario localmente antes de enviar.
    ///
    /// Esta validación es opcional y permite dar feedback inmediato
    /// al usuario antes de ejecutar el command (que también valida).
    public func validateForm() -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty else {
            error = ValidationError.emptyField(fieldName: "email")
            return false
        }

        guard !password.isEmpty else {
            error = ValidationError.emptyField(fieldName: "password")
            return false
        }

        guard password.count >= 8 else {
            error = ValidationError.invalidLength(
                fieldName: "password",
                expected: "mínimo 8 caracteres",
                actual: password.count
            )
            return false
        }

        return true
    }
}

// MARK: - Convenience Computed Properties

extension LoginViewModel {
    /// Indica si el formulario es válido para enviar
    public var isFormValid: Bool {
        !email.isEmpty && password.count >= 8
    }

    /// Indica si hay un error
    public var hasError: Bool {
        error != nil
    }

    /// Mensaje de error legible
    public var errorMessage: String? {
        guard let error = error else { return nil }

        // Personalizar mensajes según tipo de error
        if let validationError = error as? ValidationError {
            return validationError.localizedDescription
        }

        if let mediatorError = error as? MediatorError {
            switch mediatorError {
            case .handlerNotFound:
                return "Error de configuración del sistema. Contacte soporte."
            case .validationError(let message, _):
                return message
            case .executionError(let message, _):
                // Probablemente credenciales incorrectas
                if message.contains("credentials") || message.contains("authentication") {
                    return "Email o contraseña incorrectos"
                }
                return message
            case .registrationError:
                return "Error de configuración del sistema."
            }
        }

        if let useCaseError = error as? UseCaseError {
            return useCaseError.localizedDescription
        }

        return error.localizedDescription
    }

    /// Indica si se debe mostrar el botón de login deshabilitado
    public var isLoginButtonDisabled: Bool {
        isLoading || !isFormValid
    }
}
