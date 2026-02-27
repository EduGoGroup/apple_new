import Foundation
import EduFoundation

/// Namespace para validaciones de dominio centralizadas en EduGo.
///
/// Este enum sin casos sirve como punto de entrada común para todas las
/// validaciones del dominio, proporcionando una API consistente y descubrible.
///
/// ## Filosofía
/// - **Centralización**: Todas las validaciones de dominio en un lugar
/// - **Reutilización**: Evitar duplicación de lógica de validación
/// - **Errores tipados**: Usar `DomainError` para error handling consistente
/// - **Thread-safety**: Todas las validaciones son `Sendable` y stateless
///
/// ## Ejemplo de uso
/// ```swift
/// // Validar email
/// try DomainValidation.validateEmail("user@edugo.com")
///
/// // Verificar sin lanzar excepciones
/// if DomainValidation.isValidEmail("test@example.com") {
///     print("Email válido")
/// }
/// ```
///
/// ## Extensibilidad
/// Al agregar nuevas validaciones, se recomienda:
/// 1. Crear un validador dedicado (ej: `PhoneValidator.swift`)
/// 2. Agregar método wrapper en `DomainValidation`
/// 3. Mantener consistencia en naming: `validate*` y `isValid*`
///
/// ## Arquitectura
/// ```
/// DomainValidation (Facade)
///     ├── EmailValidator
///     ├── PhoneValidator (futuro)
///     └── PasswordValidator (futuro)
/// ```
public enum DomainValidation {

    // MARK: - Email Validation

    /// Valida que un email cumpla con el formato requerido del dominio.
    ///
    /// Delega la validación a `EmailValidator` para mantener separación de responsabilidades.
    ///
    /// - Parameter email: La dirección de correo electrónico a validar.
    /// - Throws: `DomainError.validationFailed` si el formato es inválido.
    ///
    /// ## Ejemplo
    /// ```swift
    /// // Uso directo de la facade
    /// try DomainValidation.validateEmail("admin@edugo.com")
    ///
    /// // Captura de error tipado
    /// do {
    ///     try DomainValidation.validateEmail("invalid")
    /// } catch let error as DomainError {
    ///     print(error.errorDescription)
    /// }
    /// ```
    public static func validateEmail(_ email: String) throws {
        try EmailValidator.validate(email)
    }

    /// Verifica si un email es válido sin lanzar excepciones.
    ///
    /// Útil para validaciones en UI o casos donde no se requiere error handling.
    ///
    /// - Parameter email: La dirección de correo electrónico a verificar.
    /// - Returns: `true` si el formato es válido, `false` en caso contrario.
    ///
    /// ## Ejemplo
    /// ```swift
    /// // Validación en UI
    /// let isValid = DomainValidation.isValidEmail(userInput)
    /// submitButton.isEnabled = isValid
    ///
    /// // Filtrado de lista
    /// let validEmails = emails.filter { DomainValidation.isValidEmail($0) }
    /// ```
    public static func isValidEmail(_ email: String) -> Bool {
        EmailValidator.isValid(email)
    }

    // MARK: - Future Validations

    // TODO: Agregar validatePhone cuando se implemente PhoneValidator
    // TODO: Agregar validatePassword cuando se implemente PasswordValidator
    // TODO: Agregar validateUsername cuando se implemente UsernameValidator
}
