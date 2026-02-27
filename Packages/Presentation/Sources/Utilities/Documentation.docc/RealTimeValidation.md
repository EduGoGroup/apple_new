# Real-Time Validation

Implementa validación mientras el usuario escribe para una mejor experiencia.

## Overview

La validación en tiempo real proporciona feedback inmediato al usuario, reduciendo errores y mejorando la usabilidad. El módulo Binding hace esto trivial mediante `@BindableProperty`.

## Validación Básica

### Usando Validadores Predefinidos

```swift
@MainActor
@Observable
final class SignUpViewModel {
    @BindableProperty(validation: Validators.email())
    var email: String = ""
    
    @BindableProperty(validation: Validators.password(minLength: 8))
    var password: String = ""
    
    @BindableProperty(validation: Validators.nonEmpty(fieldName: "Nombre"))
    var name: String = ""
}
```

### Accediendo al Estado de Validación

```swift
// En el ViewModel
var isEmailValid: Bool {
    $email.validationState.isValid
}

var emailError: String? {
    $email.validationState.errorMessage
}

// En la Vista
Text(viewModel.$email.validationState.errorMessage ?? "")
    .foregroundColor(.red)
```

## Validadores Disponibles

### Validators

| Validador | Descripción | Ejemplo |
|-----------|-------------|---------|
| `email()` | Valida formato de email | `user@example.com` |
| `password(minLength:)` | Longitud mínima de contraseña | `minLength: 8` |
| `nonEmpty(fieldName:)` | Campo no vacío | `"Nombre"` |
| `minLength(_:fieldName:)` | Longitud mínima | `minLength: 3` |
| `maxLength(_:fieldName:)` | Longitud máxima | `maxLength: 100` |
| `pattern(_:message:)` | Regex personalizado | `^[A-Z].*` |
| `range(_:fieldName:)` | Rango numérico | `1...100` |
| `min(_:fieldName:)` | Valor mínimo | `min: 0` |
| `max(_:fieldName:)` | Valor máximo | `max: 999` |

### Ejemplos de Uso

```swift
// Email
@BindableProperty(validation: Validators.email())
var email: String = ""

// Password con mínimo 8 caracteres
@BindableProperty(validation: Validators.password(minLength: 8))
var password: String = ""

// Campo requerido
@BindableProperty(validation: Validators.nonEmpty(fieldName: "Nombre"))
var name: String = ""

// Longitud específica
@BindableProperty(validation: Validators.minLength(3, fieldName: "Username"))
var username: String = ""

// Rango numérico (requiere conversión)
@BindableProperty(validation: { value in
    guard let age = Int(value), (18...120).contains(age) else {
        return .invalid("Edad debe estar entre 18 y 120")
    }
    return .valid()
})
var ageString: String = ""
```

## Combinando Validadores

### Usando `all()`

```swift
@BindableProperty(
    validation: Validators.all(
        Validators.nonEmpty(fieldName: "Username"),
        Validators.minLength(3, fieldName: "Username"),
        Validators.maxLength(20, fieldName: "Username"),
        Validators.pattern("^[a-zA-Z0-9_]+$", message: "Solo letras, números y guiones bajos")
    )
)
var username: String = ""
```

### Validación Condicional con `when()`

```swift
@BindableProperty(
    validation: Validators.when(
        { !$0.isEmpty },  // Solo validar si no está vacío
        then: Validators.email()
    )
)
var optionalEmail: String = ""
```

## Validadores Personalizados

### Función Simple

```swift
func validatePhoneNumber(_ phone: String) -> ValidationResult {
    let pattern = "^\\+?[0-9]{10,15}$"
    let regex = try? NSRegularExpression(pattern: pattern)
    let range = NSRange(phone.startIndex..., in: phone)
    
    if regex?.firstMatch(in: phone, range: range) != nil {
        return .valid()
    }
    return .invalid("Número de teléfono inválido")
}

@BindableProperty(validation: validatePhoneNumber)
var phone: String = ""
```

### Closure Inline

```swift
@BindableProperty(
    validation: { value in
        guard value.count >= 4 else {
            return .invalid("Mínimo 4 dígitos")
        }
        guard value.allSatisfy({ $0.isNumber }) else {
            return .invalid("Solo números permitidos")
        }
        return .valid()
    }
)
var pin: String = ""
```

### Validador Reutilizable

```swift
enum CustomValidators {
    static func creditCard() -> @Sendable (String) -> ValidationResult {
        return { value in
            let digits = value.filter { $0.isNumber }
            guard digits.count >= 13 && digits.count <= 19 else {
                return .invalid("Número de tarjeta inválido")
            }
            // Algoritmo de Luhn
            guard isValidLuhn(digits) else {
                return .invalid("Número de tarjeta inválido")
            }
            return .valid()
        }
    }
    
    private static func isValidLuhn(_ digits: String) -> Bool {
        // Implementación del algoritmo de Luhn
        var sum = 0
        let reversedDigits = digits.reversed().map { Int(String($0))! }
        for (index, digit) in reversedDigits.enumerated() {
            if index % 2 == 1 {
                let doubled = digit * 2
                sum += doubled > 9 ? doubled - 9 : doubled
            } else {
                sum += digit
            }
        }
        return sum % 10 == 0
    }
}

// Uso
@BindableProperty(validation: CustomValidators.creditCard())
var cardNumber: String = ""
```

## Feedback Visual

### Con ViewModifiers

```swift
TextField("Email", text: $viewModel.email)
    .validated(viewModel.$email.validationState)
```

### Personalizado

```swift
TextField("Email", text: $viewModel.email)
    .validated(
        viewModel.$email.validationState,
        showValidation: hasInteracted,
        style: .minimal
    )
```

### Estados Visuales

```swift
struct CustomValidationView: View {
    let validationState: BindableProperty<String>.ValidationState
    
    var body: some View {
        HStack {
            if validationState.isValid {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else if let error = validationState.errorMessage {
                VStack(alignment: .leading) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }
}
```

## Validación Manual

### Disparar Validación

```swift
// Validar antes de submit
func submit() {
    $email.validate()
    $password.validate()
    
    if $email.validationState.isValid && $password.validationState.isValid {
        // Proceder con submit
    }
}
```

### Limpiar Validación

```swift
// Al comenzar a editar
func onEmailEditingBegan() {
    $email.resetValidation()
}
```

## Ver También

- <doc:CrossFieldValidation>
- <doc:CustomValidators>
- <doc:ViewModifiersGuide>
