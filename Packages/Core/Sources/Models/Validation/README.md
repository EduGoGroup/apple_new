# Domain Validation

Módulo de validaciones centralizadas para el dominio EduGo.

## Filosofía

- **Centralización**: Toda la lógica de validación en un solo lugar
- **Reutilización**: Evitar duplicación de código de validación
- **Errores tipados**: Uso consistente de `DomainError`
- **Thread-safety**: Todos los validadores son `Sendable` y stateless

## Arquitectura

```
DomainValidation (Facade)
    ├── EmailValidator
    ├── PhoneValidator (futuro)
    └── PasswordValidator (futuro)
```

## Uso

### Validación con excepciones

```swift
import Models

// Usando la facade
try DomainValidation.validateEmail("user@edugo.com")

// Usando validador directo
let validator = EmailValidator()
try validator.validate("admin@example.com")

// Manejo de errores tipado
do {
    try DomainValidation.validateEmail(userInput)
} catch let error as DomainError {
    print(error.errorDescription)
}
```

### Verificación sin excepciones

```swift
// Usando la facade
if DomainValidation.isValidEmail("test@edugo.com") {
    print("Email válido")
}

// Usando validador directo
let isValid = EmailValidator.isValid("user@example.com")
submitButton.isEnabled = isValid

// Filtrado de listas
let validEmails = emails.filter { DomainValidation.isValidEmail($0) }
```

## Validadores Disponibles

### EmailValidator

Valida formato de direcciones de correo electrónico.

**Reglas:**
- Parte local: letras, números, caracteres `._%+-`
- Símbolo `@` separador
- Dominio: letras, números, guiones
- TLD de al menos 2 caracteres

**Ejemplos válidos:**
- `user@example.com`
- `john.doe+tag@company.co.uk`
- `admin_2024@edugo-system.mx`

**Ejemplos inválidos:**
- `invalid` (sin @)
- `@example.com` (sin parte local)
- `user@invalid` (sin TLD válido)
- `user @mail.com` (espacios)

## Agregar Nuevos Validadores

1. Crear archivo del validador (ej: `PhoneValidator.swift`)
2. Implementar con la misma estructura que `EmailValidator`
3. Agregar métodos wrapper en `DomainValidation`
4. Crear tests en `Tests/ModelsTests/Validation/`
5. Documentar en este README

### Template de Validador

```swift
import Foundation
import EduGoCommon

public struct MyValidator: Sendable {
    public init() {}
    
    public func validate(_ value: String) throws {
        try Self.validate(value)
    }
    
    public static func validate(_ value: String) throws {
        guard !value.isEmpty else {
            throw DomainError.validationFailed(
                field: "myField",
                reason: "El campo no puede estar vacío"
            )
        }
        
        guard isValidFormat(value) else {
            throw DomainError.validationFailed(
                field: "myField",
                reason: "Formato inválido"
            )
        }
    }
    
    public static func isValid(_ value: String) -> Bool {
        guard !value.isEmpty else { return false }
        return isValidFormat(value)
    }
    
    private static func isValidFormat(_ value: String) -> Bool {
        // Lógica de validación
        true
    }
}
```

### Actualizar DomainValidation Facade

```swift
extension DomainValidation {
    public static func validateMyField(_ value: String) throws {
        try MyValidator.validate(value)
    }
    
    public static func isValidMyField(_ value: String) -> Bool {
        MyValidator.isValid(value)
    }
}
```

## Testing

Todos los validadores deben incluir tests exhaustivos:

- ✅ Casos válidos (múltiples variantes)
- ✅ Casos inválidos (edge cases)
- ✅ Verificación de `DomainError` correcto
- ✅ Tests de concurrencia (`Sendable`)
- ✅ Consistencia entre facade y validador directo

## Migración

Para migrar código existente que usa validación inline:

**Antes:**
```swift
private static func isValidEmail(_ email: String) -> Bool {
    let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
    return email.range(of: emailRegex, options: .regularExpression) != nil
}
```

**Después:**
```swift
// Opción 1: Usar facade
try DomainValidation.validateEmail(email)

// Opción 2: Usar validador directo
try EmailValidator.validate(email)

// Opción 3: Verificación sin throw
guard DomainValidation.isValidEmail(email) else {
    throw CustomError.invalidEmail
}
```

## Beneficios

1. **Mantenibilidad**: Cambios en reglas de validación en un solo lugar
2. **Consistencia**: Mismas reglas en toda la aplicación
3. **Testabilidad**: Fácil de testear de forma aislada
4. **Descubribilidad**: API clara y consistente
5. **Type Safety**: Errores tipados con `DomainError`
6. **Concurrencia**: Todos los validadores son `Sendable`
