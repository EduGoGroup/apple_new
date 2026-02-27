import Testing
import Foundation
@testable import EduModels
import EduFoundation

/// Suite de tests para `DomainValidation` facade.
///
/// Verifica que la facade de validaciones de dominio funcione correctamente
/// como punto de entrada unificado para todas las validaciones.
@Suite("DomainValidation Facade Tests")
struct DomainValidationTests {

    // MARK: - Email Validation via Facade

    @Test("Facade valida email correcto")
    func facadeValidatesCorrectEmail() throws {
        #expect(throws: Never.self) {
            try DomainValidation.validateEmail("user@example.com")
        }
    }

    @Test("Facade rechaza email inválido")
    func facadeRejectsInvalidEmail() throws {
        #expect {
            try DomainValidation.validateEmail("invalid")
        } throws: { error in
            guard let domainError = error as? DomainError,
                  case .validationFailed(let field, _) = domainError else {
                return false
            }
            return field == "email"
        }
    }

    @Test("Facade isValidEmail retorna true para email correcto")
    func facadeIsValidEmailReturnsTrue() {
        #expect(DomainValidation.isValidEmail("valid@example.com"))
    }

    @Test("Facade isValidEmail retorna false para email incorrecto")
    func facadeIsValidEmailReturnsFalse() {
        #expect(!DomainValidation.isValidEmail("invalid"))
        #expect(!DomainValidation.isValidEmail(""))
        #expect(!DomainValidation.isValidEmail("@example.com"))
    }

    // MARK: - Consistency Tests

    @Test("Facade produce mismo resultado que EmailValidator directo")
    func facadeConsistentWithDirectValidator() throws {
        let testEmails = [
            "valid@example.com",
            "user123@edugo.mx",
            "invalid",
            "@test.com",
            "user@",
            ""
        ]

        for email in testEmails {
            // Validar que ambos métodos producen el mismo resultado
            let facadeResult = DomainValidation.isValidEmail(email)
            let directResult = EmailValidator.isValid(email)

            #expect(facadeResult == directResult,
                   "Facade y EmailValidator deben producir el mismo resultado para: \(email)")
        }
    }

    @Test("Facade lanza mismo error que EmailValidator")
    func facadeSameErrorAsValidator() throws {
        let invalidEmail = "invalid-email"

        var facadeError: DomainError?
        var validatorError: DomainError?

        do {
            try DomainValidation.validateEmail(invalidEmail)
        } catch let error as DomainError {
            facadeError = error
        }

        do {
            try EmailValidator.validate(invalidEmail)
        } catch let error as DomainError {
            validatorError = error
        }

        #expect(facadeError != nil)
        #expect(validatorError != nil)
        #expect(facadeError == validatorError,
               "Facade y EmailValidator deben lanzar el mismo error")
    }

    // MARK: - Usage Pattern Tests

    @Test("Facade soporta patrón de validación en pipeline")
    func facadeSupportsValidationPipeline() throws {
        let emails = [
            "admin@edugo.com",
            "invalid",
            "user@example.com",
            "@wrong.com",
            "test@valid.org"
        ]

        // Filtrar emails válidos usando facade
        let validEmails = emails.filter { DomainValidation.isValidEmail($0) }

        #expect(validEmails.count == 3)
        #expect(validEmails.contains("admin@edugo.com"))
        #expect(validEmails.contains("user@example.com"))
        #expect(validEmails.contains("test@valid.org"))
    }

    @Test("Facade soporta validación con manejo de errores tipado")
    func facadeSupportsTypedErrorHandling() throws {
        let invalidEmail = "not-an-email"

        do {
            try DomainValidation.validateEmail(invalidEmail)
            Issue.record("Debería lanzar error")
        } catch let error as DomainError {
            // Verificar estructura del error
            guard case .validationFailed(let field, let reason) = error else {
                Issue.record("Tipo de error incorrecto")
                return
            }

            #expect(field == "email")
            #expect(reason.contains("inválido") || reason.contains("vacío"))

            // Verificar LocalizedError
            #expect(error.errorDescription != nil)
            #expect(error.failureReason != nil)
            #expect(error.recoverySuggestion != nil)
        }
    }

    // MARK: - Concurrency Tests

    @Test("Facade es thread-safe para validaciones concurrentes")
    func facadeThreadSafeConcurrentValidation() async throws {
        let validEmails = (1...50).map { "user\($0)@example.com" }
        let invalidEmails = (1...50).map { "invalid-\($0)" }
        let allEmails = validEmails + invalidEmails

        await withTaskGroup(of: (String, Bool).self) { group in
            for email in allEmails {
                group.addTask {
                    let isValid = DomainValidation.isValidEmail(email)
                    return (email, isValid)
                }
            }

            var results: [String: Bool] = [:]
            for await (email, isValid) in group {
                results[email] = isValid
            }

            // Verificar resultados
            for validEmail in validEmails {
                #expect(results[validEmail] == true,
                       "Email válido debe ser reconocido: \(validEmail)")
            }

            for invalidEmail in invalidEmails {
                #expect(results[invalidEmail] == false,
                       "Email inválido debe ser rechazado: \(invalidEmail)")
            }
        }
    }

    // MARK: - API Discoverability Tests

    @Test("Facade proporciona API consistente y descubrible")
    func facadeConsistentAPI() {
        // Verificar que los métodos siguen el patrón esperado:
        // - validate*(_ value: String) throws
        // - isValid*(_ value: String) -> Bool

        // Este test documenta la API esperada
        let email = "test@example.com"

        // Patrón 1: Validación con excepciones
        #expect(throws: Never.self) {
            try DomainValidation.validateEmail(email)
        }

        // Patrón 2: Verificación sin excepciones
        let result = DomainValidation.isValidEmail(email)
        #expect(result == true)
    }
}
