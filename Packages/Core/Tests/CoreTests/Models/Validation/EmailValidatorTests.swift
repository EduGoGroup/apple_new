import Testing
import Foundation
@testable import EduModels
import EduFoundation

/// Suite de tests para `EmailValidator`.
///
/// Verifica que la validación de emails funcione correctamente según las reglas
/// de negocio del dominio EduGo, usando `DomainError` para errores tipados.
@Suite("EmailValidator Tests")
struct EmailValidatorTests {

    // MARK: - Valid Email Tests

    @Test("Valida email con formato estándar correcto")
    func validateStandardEmail() throws {
        let validator = EmailValidator()

        #expect(throws: Never.self) {
            try validator.validate("user@example.com")
        }
    }

    @Test("Valida email con números en parte local")
    func validateEmailWithNumbers() throws {
        let validator = EmailValidator()

        #expect(throws: Never.self) {
            try validator.validate("user123@edugo.com")
        }
    }

    @Test("Valida email con caracteres especiales permitidos")
    func validateEmailWithSpecialCharacters() throws {
        let validator = EmailValidator()

        #expect(throws: Never.self) {
            try validator.validate("john.doe+tag@company.co.uk")
        }
        #expect(throws: Never.self) {
            try validator.validate("admin_2024@edugo-system.mx")
        }
        #expect(throws: Never.self) {
            try validator.validate("contact%info@test.org")
        }
    }

    @Test("Valida email con TLD largo")
    func validateEmailWithLongTLD() throws {
        let validator = EmailValidator()

        #expect(throws: Never.self) {
            try validator.validate("user@example.technology")
        }
    }

    @Test("Valida email con subdominio")
    func validateEmailWithSubdomain() throws {
        let validator = EmailValidator()

        #expect(throws: Never.self) {
            try validator.validate("admin@mail.edugo.com")
        }
    }

    @Test("Método estático valida correctamente")
    func staticValidateMethod() throws {
        #expect(throws: Never.self) {
            try EmailValidator.validate("static@test.com")
        }
    }

    @Test("Método isValid retorna true para emails correctos")
    func isValidMethodReturnsTrue() {
        #expect(EmailValidator.isValid("valid@example.com"))
        #expect(EmailValidator.isValid("another.valid@edugo.mx"))
    }

    // MARK: - Invalid Email Tests

    @Test("Rechaza email vacío con DomainError")
    func rejectEmptyEmail() throws {
        let validator = EmailValidator()

        #expect(throws: DomainError.validationFailed(field: "email", reason: "El correo electrónico no puede estar vacío")) {
            try validator.validate("")
        }
    }

    @Test("Rechaza email con solo espacios")
    func rejectWhitespaceOnlyEmail() throws {
        let validator = EmailValidator()

        #expect(throws: DomainError.validationFailed(field: "email", reason: "El correo electrónico no puede estar vacío")) {
            try validator.validate("   ")
        }
    }

    @Test("Rechaza email sin símbolo @")
    func rejectEmailWithoutAtSymbol() throws {
        let validator = EmailValidator()

        #expect {
            try validator.validate("invalidemailexample.com")
        } throws: { error in
            guard let domainError = error as? DomainError,
                  case .validationFailed(let field, _) = domainError else {
                return false
            }
            return field == "email"
        }
    }

    @Test("Rechaza email sin parte local")
    func rejectEmailWithoutLocalPart() throws {
        let validator = EmailValidator()

        #expect {
            try validator.validate("@example.com")
        } throws: { error in
            guard let domainError = error as? DomainError,
                  case .validationFailed(let field, _) = domainError else {
                return false
            }
            return field == "email"
        }
    }

    @Test("Rechaza email sin dominio")
    func rejectEmailWithoutDomain() throws {
        let validator = EmailValidator()

        #expect {
            try validator.validate("user@")
        } throws: { error in
            guard let domainError = error as? DomainError,
                  case .validationFailed(let field, _) = domainError else {
                return false
            }
            return field == "email"
        }
    }

    @Test("Rechaza email sin TLD")
    func rejectEmailWithoutTLD() throws {
        let validator = EmailValidator()

        #expect {
            try validator.validate("user@invalid")
        } throws: { error in
            guard let domainError = error as? DomainError,
                  case .validationFailed(let field, _) = domainError else {
                return false
            }
            return field == "email"
        }
    }

    @Test("Rechaza email con TLD de un solo carácter")
    func rejectEmailWithSingleCharTLD() throws {
        let validator = EmailValidator()

        #expect {
            try validator.validate("user@example.c")
        } throws: { error in
            guard let domainError = error as? DomainError,
                  case .validationFailed(let field, _) = domainError else {
                return false
            }
            return field == "email"
        }
    }

    @Test("Rechaza email con espacios")
    func rejectEmailWithSpaces() throws {
        let validator = EmailValidator()

        #expect {
            try validator.validate("user name@example.com")
        } throws: { error in
            guard let domainError = error as? DomainError,
                  case .validationFailed(let field, _) = domainError else {
                return false
            }
            return field == "email"
        }
    }

    @Test("Rechaza email con caracteres inválidos")
    func rejectEmailWithInvalidCharacters() throws {
        let validator = EmailValidator()

        #expect {
            try validator.validate("user#invalid@example.com")
        } throws: { error in
            guard let domainError = error as? DomainError,
                  case .validationFailed(let field, _) = domainError else {
                return false
            }
            return field == "email"
        }
    }

    @Test("Método isValid retorna false para emails incorrectos")
    func isValidMethodReturnsFalse() {
        #expect(!EmailValidator.isValid(""))
        #expect(!EmailValidator.isValid("invalid"))
        #expect(!EmailValidator.isValid("@example.com"))
        #expect(!EmailValidator.isValid("user@invalid"))
        #expect(!EmailValidator.isValid("user @example.com"))
    }

    // MARK: - Edge Cases

    @Test("Trim de espacios antes y después del email")
    func trimWhitespace() throws {
        let validator = EmailValidator()

        #expect(throws: Never.self) {
            try validator.validate("  user@example.com  ")
        }
    }

    @Test("Email con múltiples puntos en parte local")
    func multipleDotsInLocalPart() throws {
        let validator = EmailValidator()

        #expect(throws: Never.self) {
            try validator.validate("first.middle.last@example.com")
        }
    }

    @Test("Email con guiones en dominio")
    func hyphensInDomain() throws {
        let validator = EmailValidator()

        #expect(throws: Never.self) {
            try validator.validate("user@my-company.com")
        }
    }

    // MARK: - DomainError Structure Tests

    @Test("DomainError contiene información correcta del campo")
    func domainErrorFieldInfo() throws {
        let validator = EmailValidator()

        do {
            try validator.validate("invalid-email")
            Issue.record("Se esperaba que lanzara DomainError")
        } catch let error as DomainError {
            guard case .validationFailed(let field, let reason) = error else {
                Issue.record("Se esperaba DomainError.validationFailed")
                return
            }
            #expect(field == "email")
            #expect(!reason.isEmpty)
        } catch {
            Issue.record("Se esperaba DomainError pero se obtuvo: \(error)")
        }
    }

    @Test("DomainError es Equatable")
    func domainErrorEquatable() {
        let error1 = DomainError.validationFailed(field: "email", reason: "Formato inválido")
        let error2 = DomainError.validationFailed(field: "email", reason: "Formato inválido")
        let error3 = DomainError.validationFailed(field: "email", reason: "Diferente razón")

        #expect(error1 == error2)
        #expect(error1 != error3)
    }

    // MARK: - Concurrency Tests

    @Test("EmailValidator es Sendable y thread-safe")
    func sendableConformance() async throws {
        let validator = EmailValidator()

        // Ejecutar validaciones concurrentes
        await withTaskGroup(of: Void.self) { group in
            for i in 1...100 {
                group.addTask {
                    do {
                        try validator.validate("user\(i)@example.com")
                    } catch {
                        Issue.record("No debería lanzar error para email válido: \(error)")
                    }
                }
            }
        }
    }

    @Test("Validación concurrente con emails inválidos")
    func concurrentInvalidValidation() async throws {
        let validator = EmailValidator()

        await withTaskGroup(of: Bool.self) { group in
            for i in 1...50 {
                group.addTask {
                    do {
                        try validator.validate("invalid-email-\(i)")
                        return false // No debería llegar aquí
                    } catch is DomainError {
                        return true // Error esperado
                    } catch {
                        return false // Error inesperado
                    }
                }
            }

            var allThrew = true
            for await result in group {
                if !result {
                    allThrew = false
                }
            }
            #expect(allThrew)
        }
    }
}
