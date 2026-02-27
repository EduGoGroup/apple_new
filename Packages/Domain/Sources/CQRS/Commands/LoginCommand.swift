import Foundation
import EduFoundation
import EduCore

// MARK: - LoginCommand

/// Command para autenticar un usuario en el sistema.
///
/// Este command encapsula las credenciales del usuario e implementa
/// validación pre-ejecución para asegurar que los datos sean válidos
/// antes de intentar la autenticación.
///
/// ## Validaciones
/// - Email: Formato RFC 5322 válido, no vacío
/// - Password: Longitud mínima de 8 caracteres, no vacío
///
/// ## Eventos Emitidos
/// - `LoginSuccessEvent`: Cuando la autenticación es exitosa
/// - `UserContextInvalidatedEvent`: Para invalidar cache de UserContext
///
/// ## Ejemplo de Uso
/// ```swift
/// let command = LoginCommand(
///     email: "user@edugo.com",
///     password: "securePassword123"
/// )
///
/// let result = try await mediator.execute(command)
/// if result.isSuccess, let output = result.getValue() {
///     print("Usuario autenticado: \(output.user.fullName)")
///     print("Eventos: \(result.events)") // ["LoginSuccessEvent", "UserContextInvalidatedEvent"]
/// }
/// ```
public struct LoginCommand: Command {

    public typealias Result = LoginOutput

    // MARK: - Properties

    /// Email del usuario
    public let email: String

    /// Contraseña del usuario
    public let password: String

    /// Metadata opcional para tracing
    public let metadata: [String: String]?

    // MARK: - Initialization

    /// Crea un nuevo command de login.
    ///
    /// - Parameters:
    ///   - email: Email del usuario
    ///   - password: Contraseña del usuario
    ///   - metadata: Metadata opcional para tracing
    public init(
        email: String,
        password: String,
        metadata: [String: String]? = nil
    ) {
        self.email = email
        self.password = password
        self.metadata = metadata
    }

    // MARK: - Command Protocol

    /// Valida el command antes de la ejecución.
    ///
    /// Verifica que:
    /// - El email no esté vacío y tenga formato válido (RFC 5322)
    /// - La contraseña no esté vacía y tenga al menos 8 caracteres
    ///
    /// - Throws: `ValidationError` si alguna validación falla
    public func validate() throws {
        // Validar email no vacío
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            throw ValidationError.emptyField(fieldName: "email")
        }

        // Validar formato de email (RFC 5322)
        do {
            try EmailValidator.validate(trimmedEmail)
        } catch {
            throw ValidationError.invalidFormat(
                fieldName: "email",
                reason: "Formato de email inválido"
            )
        }

        // Validar password no vacío
        guard !password.isEmpty else {
            throw ValidationError.emptyField(fieldName: "password")
        }

        // Validar longitud mínima de password
        guard password.count >= 8 else {
            throw ValidationError.invalidLength(
                fieldName: "password",
                expected: "mínimo 8 caracteres",
                actual: password.count
            )
        }
    }
}

// MARK: - LoginCommandHandler

/// Handler que procesa LoginCommand usando LoginUseCase.
///
/// Coordina el proceso de autenticación, gestiona eventos de dominio
/// e invalida caches relacionados después de un login exitoso.
///
/// ## Responsabilidades
/// 1. Ejecutar LoginUseCase internamente
/// 2. Emitir eventos de dominio (LoginSuccessEvent)
/// 3. Invalidar cache de UserContext
/// 4. Envolver resultado en CommandResult
///
/// ## Integración con Queries
/// Después de un login exitoso, este handler invalida el cache de
/// `GetUserContextQuery` para forzar una recarga del contexto del usuario.
///
/// ## Ejemplo de Uso
/// ```swift
/// let handler = LoginCommandHandler(
///     useCase: loginUseCase,
///     userContextHandler: userContextQueryHandler
/// )
/// try await mediator.registerCommandHandler(handler)
/// ```
public actor LoginCommandHandler: CommandHandler {

    public typealias CommandType = LoginCommand

    // MARK: - Dependencies

    private let useCase: any LoginUseCaseProtocol

    /// Handler de GetUserContextQuery para invalidar cache
    private weak var userContextHandler: GetUserContextQueryHandler?

    // MARK: - Initialization

    /// Crea un nuevo handler para LoginCommand.
    ///
    /// - Parameters:
    ///   - useCase: Use case que ejecuta el login (inyectado via protocolo para DI)
    ///   - userContextHandler: Handler para invalidar cache de UserContext (opcional)
    public init(
        useCase: any LoginUseCaseProtocol,
        userContextHandler: GetUserContextQueryHandler? = nil
    ) {
        self.useCase = useCase
        self.userContextHandler = userContextHandler
    }

    // MARK: - CommandHandler Protocol

    /// Procesa el command y retorna el resultado.
    ///
    /// - Parameter command: Command con credenciales del usuario
    /// - Returns: CommandResult con LoginOutput y eventos emitidos
    /// - Throws: Error si falla la validación o la autenticación
    public func handle(_ command: LoginCommand) async throws -> CommandResult<LoginOutput> {
        // Nota: La validación ya se ejecutó en el Mediator antes de llamar a handle()

        // Crear input para el use case
        let input = LoginInput(
            email: command.email,
            password: command.password
        )

        // Ejecutar use case
        do {
            let output = try await useCase.execute(input: input)

            // Invalidar cache de UserContext después de login exitoso
            await invalidateUserContextCache()

            // Emitir eventos de dominio
            let events = [
                "LoginSuccessEvent",
                "UserContextInvalidatedEvent"
            ]

            // Crear metadata con información del login
            let metadata: [String: String] = [
                "userId": output.user.id.uuidString,
                "email": output.user.email,
                "loginAt": ISO8601DateFormatter().string(from: Date())
            ]

            // Retornar resultado exitoso
            return .success(
                output,
                events: events,
                metadata: metadata
            )

        } catch let error as UseCaseError {
            // Convertir UseCaseError a CommandResult de fallo
            return .failure(
                error,
                metadata: [
                    "email": command.email,
                    "errorType": String(describing: type(of: error))
                ]
            )
        } catch {
            // Error inesperado
            return .failure(
                error,
                metadata: [
                    "email": command.email,
                    "errorDescription": error.localizedDescription
                ]
            )
        }
    }

    // MARK: - Cache Management

    /// Configura el handler de UserContext para invalidación de cache.
    ///
    /// - Parameter handler: Handler de GetUserContextQuery
    public func setUserContextHandler(_ handler: GetUserContextQueryHandler) {
        self.userContextHandler = handler
    }

    /// Invalida el cache de UserContext.
    private func invalidateUserContextCache() async {
        await userContextHandler?.invalidateCache()
    }
}

// MARK: - Validation Errors

/// Errores de validación de commands.
public enum ValidationError: Error, LocalizedError, Sendable {
    /// Campo vacío o nulo
    case emptyField(fieldName: String)

    /// Formato inválido
    case invalidFormat(fieldName: String, reason: String)

    /// Longitud inválida
    case invalidLength(fieldName: String, expected: String, actual: Int)

    /// Valor fuera de rango
    case outOfRange(fieldName: String, min: Int?, max: Int?, actual: Int)

    /// Tipo MIME no soportado
    case unsupportedType(fieldName: String, type: String, supported: [String])

    /// Archivo no encontrado
    case fileNotFound(path: String)

    /// Datos incompletos
    case incompleteData(missing: [String])

    public var errorDescription: String? {
        switch self {
        case .emptyField(let fieldName):
            return "El campo '\(fieldName)' no puede estar vacío"
        case .invalidFormat(let fieldName, let reason):
            return "Formato inválido en '\(fieldName)': \(reason)"
        case .invalidLength(let fieldName, let expected, let actual):
            return "Longitud inválida en '\(fieldName)'. Esperado: \(expected), actual: \(actual)"
        case .outOfRange(let fieldName, let min, let max, let actual):
            var range = ""
            if let min = min, let max = max {
                range = "\(min)-\(max)"
            } else if let min = min {
                range = "mínimo \(min)"
            } else if let max = max {
                range = "máximo \(max)"
            }
            return "Valor fuera de rango en '\(fieldName)'. Rango permitido: \(range), actual: \(actual)"
        case .unsupportedType(let fieldName, let type, let supported):
            return "Tipo no soportado en '\(fieldName)': \(type). Tipos permitidos: \(supported.joined(separator: ", "))"
        case .fileNotFound(let path):
            return "Archivo no encontrado: \(path)"
        case .incompleteData(let missing):
            return "Datos incompletos. Faltan: \(missing.joined(separator: ", "))"
        }
    }
}
