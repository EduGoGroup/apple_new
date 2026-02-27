# Custom Validators

Crea validadores personalizados para reglas de negocio específicas.

## Overview

Aunque el módulo Binding incluye validadores comunes, frecuentemente necesitarás crear validadores personalizados para requisitos específicos de tu aplicación.

## Anatomía de un Validador

Un validador es una función que recibe un valor y retorna un `ValidationResult`:

```swift
// Firma básica
typealias Validator<T> = (T) -> ValidationResult

// Para uso con @BindableProperty (debe ser @Sendable)
typealias SendableValidator<T> = @Sendable (T) -> ValidationResult
```

### ValidationResult

```swift
public struct ValidationResult: Sendable, Equatable {
    public let isValid: Bool
    public let errorMessage: String?
    
    public static func valid() -> ValidationResult
    public static func invalid(_ message: String) -> ValidationResult
}
```

## Crear Validadores Simples

### Closure Inline

```swift
@BindableProperty(
    validation: { value in
        guard !value.isEmpty else {
            return .invalid("Campo requerido")
        }
        guard value.count <= 50 else {
            return .invalid("Máximo 50 caracteres")
        }
        return .valid()
    }
)
var title: String = ""
```

### Función Nombrada

```swift
func validateUsername(_ username: String) -> ValidationResult {
    // Longitud
    guard username.count >= 3 else {
        return .invalid("Mínimo 3 caracteres")
    }
    guard username.count <= 20 else {
        return .invalid("Máximo 20 caracteres")
    }
    
    // Caracteres permitidos
    let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
    guard username.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else {
        return .invalid("Solo letras, números y guión bajo")
    }
    
    // No puede empezar con número
    guard !username.first!.isNumber else {
        return .invalid("No puede empezar con número")
    }
    
    return .valid()
}

@BindableProperty(validation: validateUsername)
var username: String = ""
```

## Validadores Parametrizados

### Con Factory Function

```swift
enum AppValidators {
    static func exactLength(_ length: Int, fieldName: String) -> @Sendable (String) -> ValidationResult {
        return { value in
            guard value.count == length else {
                return .invalid("\(fieldName) debe tener exactamente \(length) caracteres")
            }
            return .valid()
        }
    }
    
    static func numeric(fieldName: String) -> @Sendable (String) -> ValidationResult {
        return { value in
            guard value.allSatisfy({ $0.isNumber }) else {
                return .invalid("\(fieldName) solo puede contener números")
            }
            return .valid()
        }
    }
}

// Uso
@BindableProperty(validation: AppValidators.exactLength(4, fieldName: "PIN"))
var pin: String = ""

@BindableProperty(validation: AppValidators.numeric(fieldName: "Código"))
var code: String = ""
```

### Con Configuración

```swift
struct PhoneValidator {
    let countryCode: String
    let minDigits: Int
    let maxDigits: Int
    
    func validate(_ phone: String) -> ValidationResult {
        let digits = phone.filter { $0.isNumber }
        
        guard digits.count >= minDigits else {
            return .invalid("Mínimo \(minDigits) dígitos")
        }
        guard digits.count <= maxDigits else {
            return .invalid("Máximo \(maxDigits) dígitos")
        }
        
        return .valid()
    }
}

// Configuración para México
let mexicanPhoneValidator = PhoneValidator(
    countryCode: "+52",
    minDigits: 10,
    maxDigits: 10
)

@BindableProperty(validation: mexicanPhoneValidator.validate)
var phone: String = ""
```

## Validadores con Regex

### Patrón Simple

```swift
enum RegexValidators {
    static func pattern(
        _ pattern: String,
        message: String
    ) -> @Sendable (String) -> ValidationResult {
        return { value in
            guard let regex = try? NSRegularExpression(pattern: pattern) else {
                return .invalid("Error en validación")
            }
            
            let range = NSRange(value.startIndex..., in: value)
            if regex.firstMatch(in: value, range: range) != nil {
                return .valid()
            }
            return .invalid(message)
        }
    }
    
    static func mexicanRFC() -> @Sendable (String) -> ValidationResult {
        pattern(
            "^[A-Z&Ñ]{3,4}[0-9]{6}[A-Z0-9]{3}$",
            message: "RFC inválido"
        )
    }
    
    static func mexicanCURP() -> @Sendable (String) -> ValidationResult {
        pattern(
            "^[A-Z]{4}[0-9]{6}[HM][A-Z]{5}[0-9A-Z]{2}$",
            message: "CURP inválido"
        )
    }
    
    static func postalCode() -> @Sendable (String) -> ValidationResult {
        pattern(
            "^[0-9]{5}$",
            message: "Código postal inválido"
        )
    }
}
```

### Uso

```swift
@BindableProperty(validation: RegexValidators.mexicanRFC())
var rfc: String = ""

@BindableProperty(validation: RegexValidators.postalCode())
var postalCode: String = ""
```

## Validadores Asíncronos

Para validaciones que requieren llamadas de red, usa `@DebouncedProperty`:

```swift
@MainActor
@Observable
final class SignUpViewModel {
    @DebouncedProperty(
        debounceInterval: 0.5,
        onDebouncedChange: { [weak self] username in
            await self?.checkUsernameAvailability(username)
        }
    )
    var username: String = ""
    
    var usernameAvailability: UsernameAvailability = .unknown
    
    private func checkUsernameAvailability(_ username: String) async {
        guard !username.isEmpty else {
            usernameAvailability = .unknown
            return
        }
        
        usernameAvailability = .checking
        
        do {
            let isAvailable = try await userService.checkUsername(username)
            usernameAvailability = isAvailable ? .available : .taken
        } catch {
            usernameAvailability = .error
        }
    }
}

enum UsernameAvailability {
    case unknown
    case checking
    case available
    case taken
    case error
}
```

## Composición de Validadores

### Combinar con `all()`

```swift
@BindableProperty(
    validation: Validators.all(
        Validators.nonEmpty(fieldName: "Email"),
        Validators.email(),
        AppValidators.allowedDomain(["edugo.com", "school.edu"])
    )
)
var schoolEmail: String = ""
```

### Validador Compuesto Personalizado

```swift
enum PasswordValidators {
    static func strong() -> @Sendable (String) -> ValidationResult {
        return { password in
            var errors: [String] = []
            
            if password.count < 8 {
                errors.append("mínimo 8 caracteres")
            }
            if !password.contains(where: { $0.isUppercase }) {
                errors.append("una mayúscula")
            }
            if !password.contains(where: { $0.isLowercase }) {
                errors.append("una minúscula")
            }
            if !password.contains(where: { $0.isNumber }) {
                errors.append("un número")
            }
            if !password.contains(where: { "!@#$%^&*".contains($0) }) {
                errors.append("un símbolo especial")
            }
            
            if errors.isEmpty {
                return .valid()
            }
            
            return .invalid("Requiere: \(errors.joined(separator: ", "))")
        }
    }
}
```

## Testing de Validadores

```swift
import Testing
@testable import Binding

@Suite("Custom Validators Tests")
struct CustomValidatorsTests {
    
    @Test("RFC validator accepts valid RFC")
    func validRFC() {
        let validator = RegexValidators.mexicanRFC()
        
        #expect(validator("XAXX010101000").isValid)
        #expect(validator("GODE561231GR8").isValid)
    }
    
    @Test("RFC validator rejects invalid RFC")
    func invalidRFC() {
        let validator = RegexValidators.mexicanRFC()
        
        #expect(!validator("INVALID").isValid)
        #expect(!validator("123").isValid)
        #expect(validator("").errorMessage != nil)
    }
    
    @Test("Strong password validator checks all requirements")
    func strongPassword() {
        let validator = PasswordValidators.strong()
        
        #expect(validator("Abc123!@").isValid)
        #expect(!validator("abc123").isValid)  // Sin mayúscula ni símbolo
        #expect(!validator("short").isValid)    // Muy corta
    }
}
```

## Ver También

- <doc:RealTimeValidation>
- <doc:CrossFieldValidation>
- ``Validators``
