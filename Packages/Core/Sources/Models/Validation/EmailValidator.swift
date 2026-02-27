import Foundation
import EduFoundation

/// Validador centralizado para direcciones de correo electrónico en el dominio EduGo.
///
/// Este validador proporciona una implementación thread-safe y reutilizable para
/// validar formatos de email según las reglas de negocio del sistema.
///
/// ## Conformidades
/// - `Sendable`: Thread-safe para uso concurrente en Swift 6.2
///
/// ## Reglas de validación
/// El email debe cumplir con el siguiente formato:
/// - Parte local: letras (a-z, A-Z), números (0-9), y caracteres especiales `._%+-`
/// - Símbolo `@` separador
/// - Dominio: letras, números y guiones
/// - Punto seguido de TLD de al menos 2 caracteres
///
/// ## Ejemplo de uso
/// ```swift
/// let validator = EmailValidator()
///
/// // Email válido
/// try validator.validate("usuario@edugo.com")
///
/// // Email inválido - lanzará DomainError
/// do {
///     try validator.validate("usuario@invalid")
/// } catch let error as DomainError {
///     print(error.errorDescription) // "Error de validación en 'email': Formato de correo electrónico inválido"
/// }
/// ```
///
/// ## Implementación funcional
/// ```swift
/// // También disponible como función estática
/// try EmailValidator.validate("test@example.com")
/// ```
public struct EmailValidator: Sendable {

    // MARK: - Properties

    /// Expresión regular para validar formato de email.
    ///
    /// Patrón: `^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$`
    ///
    /// - Parte local: `[A-Za-z0-9._%+-]+`
    /// - Separador: `@`
    /// - Dominio: `[A-Za-z0-9.-]+`
    /// - TLD: `\.[A-Za-z]{2,}`
    private static let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#

    // MARK: - Initialization

    /// Inicializa una nueva instancia del validador de email.
    ///
    /// Como el validador es stateless, esta inicialización es trivial
    /// y principalmente sirve para uso en inyección de dependencias.
    public init() {}

    // MARK: - Instance Methods

    /// Valida que un email cumpla con el formato requerido.
    ///
    /// - Parameter email: La dirección de correo electrónico a validar.
    /// - Throws: `DomainError.validationFailed` si el formato es inválido.
    ///
    /// ## Ejemplo
    /// ```swift
    /// let validator = EmailValidator()
    ///
    /// // Casos válidos
    /// try validator.validate("user@example.com")
    /// try validator.validate("john.doe+tag@company.co.uk")
    /// try validator.validate("admin123@edugo.mx")
    ///
    /// // Casos inválidos (lanzan error)
    /// try validator.validate("invalid")           // Sin @
    /// try validator.validate("@example.com")      // Sin parte local
    /// try validator.validate("user@invalid")      // Sin TLD válido
    /// try validator.validate("user @mail.com")    // Espacios
    /// ```
    public func validate(_ email: String) throws {
        try Self.validate(email)
    }

    // MARK: - Static Methods

    /// Valida que un email cumpla con el formato requerido (versión estática).
    ///
    /// - Parameter email: La dirección de correo electrónico a validar.
    /// - Throws: `DomainError.validationFailed` si el formato es inválido.
    ///
    /// ## Ejemplo
    /// ```swift
    /// // Uso directo sin instanciar el validador
    /// try EmailValidator.validate("user@edugo.com")
    /// ```
    public static func validate(_ email: String) throws {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)

        guard !trimmedEmail.isEmpty else {
            throw DomainError.validationFailed(
                field: "email",
                reason: "El correo electrónico no puede estar vacío"
            )
        }

        guard isValidFormat(trimmedEmail) else {
            throw DomainError.validationFailed(
                field: "email",
                reason: "Formato de correo electrónico inválido"
            )
        }
    }

    /// Verifica si un email cumple con el formato esperado sin lanzar excepciones.
    ///
    /// - Parameter email: La dirección de correo electrónico a verificar.
    /// - Returns: `true` si el formato es válido, `false` en caso contrario.
    ///
    /// ## Ejemplo
    /// ```swift
    /// if EmailValidator.isValid("user@edugo.com") {
    ///     print("Email válido")
    /// }
    /// ```
    public static func isValid(_ email: String) -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        guard !trimmedEmail.isEmpty else { return false }
        return isValidFormat(trimmedEmail)
    }

    // MARK: - Private Helpers

    /// Verifica el formato del email contra la expresión regular.
    ///
    /// - Parameter email: Email ya procesado (trimmed, no vacío).
    /// - Returns: `true` si coincide con el patrón regex.
    private static func isValidFormat(_ email: String) -> Bool {
        email.range(of: emailRegex, options: .regularExpression) != nil
    }
}
