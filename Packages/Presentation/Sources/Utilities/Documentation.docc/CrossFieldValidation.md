# Cross-Field Validation

Valida relaciones entre múltiples campos del formulario.

## Overview

La validación cruzada permite verificar reglas que dependen de múltiples campos, como confirmar contraseñas, rangos de fechas, o campos condicionales.

## FormState para Validación Cruzada

### Configuración Básica

```swift
@MainActor
@Observable
final class RegistrationViewModel {
    @BindableProperty(validation: Validators.password(minLength: 8))
    var password: String = ""
    
    @BindableProperty(validation: Validators.nonEmpty(fieldName: "Confirmación"))
    var passwordConfirmation: String = ""
    
    let formState = FormState()
    
    init() {
        setupCrossValidation()
    }
    
    private func setupCrossValidation() {
        formState.registerCrossValidator { [weak self] in
            guard let self else { return .valid() }
            return CrossValidators.passwordMatch(password, passwordConfirmation)
        }
    }
}
```

### Uso en la Vista

```swift
struct RegistrationView: View {
    @State private var viewModel = RegistrationViewModel()
    
    var body: some View {
        Form {
            SecureField("Contraseña", text: $viewModel.password)
                .validated(viewModel.$password.validationState)
            
            SecureField("Confirmar", text: $viewModel.passwordConfirmation)
                .validated(viewModel.$passwordConfirmation.validationState)
            
            Button("Registrar") {
                Task {
                    await viewModel.formState.submit {
                        // Registro exitoso
                    }
                }
            }
        }
        .formErrorBanner(viewModel.formState)
    }
}
```

## CrossValidators Disponibles

### Comparación de Valores

```swift
// Passwords coinciden
CrossValidators.passwordMatch(password, confirmation)

// Valores iguales
CrossValidators.equal(value1, value2, fieldName: "Campos")

// Valores diferentes
CrossValidators.notEqual(newPassword, oldPassword, fieldName: "Nueva contraseña")

// Menor que
CrossValidators.lessThan(startDate, endDate, fieldName: "Fecha inicio")

// Mayor que
CrossValidators.greaterThan(endDate, startDate, fieldName: "Fecha fin")
```

### Validación de Fechas

```swift
// Rango de fechas válido
CrossValidators.dateRange(startDate, endDate)

// Rango opcional (permite nil)
CrossValidators.optionalDateRange(startDate, endDate)

// Fecha no en el pasado
CrossValidators.notInPast(selectedDate)
```

### Validación de Colecciones

```swift
// Al menos uno seleccionado (Set)
CrossValidators.atLeastOneSelected(selectedItems)

// Al menos uno seleccionado (Array)
CrossValidators.atLeastOneSelected(selectedIds)

// Cantidad exacta
CrossValidators.exactCount(selectedItems, expected: 3, fieldName: "Opciones")

// Cantidad en rango
CrossValidators.countInRange(selectedItems, range: 1...5, fieldName: "Selección")
```

### Validación Condicional

```swift
// Campo requerido si condición es true
CrossValidators.conditionalRequired(
    value: phoneNumber,
    condition: wantsNotifications,
    fieldName: "Teléfono"
)

// Requerido cuando otro campo tiene valor
CrossValidators.requiredWhenPresent(
    value: city,
    dependsOn: country,
    fieldName: "Ciudad"
)
```

## Múltiples Validadores Cruzados

### Registro Individual

```swift
private func setupCrossValidation() {
    // Validador 1: Passwords coinciden
    formState.registerCrossValidator { [weak self] in
        guard let self else { return .valid() }
        return CrossValidators.passwordMatch(password, passwordConfirmation)
    }
    
    // Validador 2: Fecha fin posterior a inicio
    formState.registerCrossValidator { [weak self] in
        guard let self else { return .valid() }
        return CrossValidators.dateRange(startDate, endDate)
    }
    
    // Validador 3: Al menos un rol seleccionado
    formState.registerCrossValidator { [weak self] in
        guard let self else { return .valid() }
        return CrossValidators.atLeastOneSelected(selectedRoles)
    }
}
```

### Usando `all()`

```swift
formState.registerCrossValidator { [weak self] in
    guard let self else { return .valid() }
    
    return CrossValidators.all(
        CrossValidators.passwordMatch(password, passwordConfirmation),
        CrossValidators.dateRange(startDate, endDate),
        CrossValidators.atLeastOneSelected(selectedRoles)
    )
}
```

### Colectando Todos los Errores

```swift
formState.registerCrossValidator { [weak self] in
    guard let self else { return .valid() }
    
    // Retorna todos los errores concatenados
    return CrossValidators.allCollectingErrors(
        CrossValidators.passwordMatch(password, passwordConfirmation),
        CrossValidators.dateRange(startDate, endDate),
        CrossValidators.atLeastOneSelected(selectedRoles)
    )
}
```

## Validadores Cruzados Personalizados

### Función Simple

```swift
func validateAgeAndLicense() -> ValidationResult {
    guard age >= 18 else {
        return .invalid("Debe ser mayor de 18 años")
    }
    guard hasDriverLicense || age >= 21 else {
        return .invalid("Sin licencia, debe ser mayor de 21")
    }
    return .valid()
}

formState.registerCrossValidator(validateAgeAndLicense)
```

### Validador Reutilizable

```swift
enum CustomCrossValidators {
    static func passwordStrength(
        password: String,
        username: String,
        email: String
    ) -> ValidationResult {
        // No puede contener username
        if password.lowercased().contains(username.lowercased()) {
            return .invalid("La contraseña no puede contener el nombre de usuario")
        }
        
        // No puede contener parte del email
        let emailPrefix = email.components(separatedBy: "@").first ?? ""
        if password.lowercased().contains(emailPrefix.lowercased()) {
            return .invalid("La contraseña no puede contener parte del email")
        }
        
        return .valid()
    }
}

// Uso
formState.registerCrossValidator { [weak self] in
    guard let self else { return .valid() }
    return CustomCrossValidators.passwordStrength(
        password: password,
        username: username,
        email: email
    )
}
```

## Manejo de Errores de Formulario

### Errores en FormState

Los errores de validación cruzada se almacenan bajo la clave `"form"`:

```swift
// Acceso directo
if let formError = formState.errors["form"] {
    print("Error de formulario: \(formError)")
}

// En la vista con ViewModifier
Form { }
    .formErrorBanner(formState)  // Muestra errores automáticamente
```

### Limpiar Errores

```swift
// Limpiar error específico
formState.clearError(for: "form")

// Limpiar todos los errores
formState.reset()

// Limpiar validadores cruzados
formState.clearCrossValidators()
```

## Validación y Submit

### Submit con Validación

```swift
func register() async {
    let success = await formState.submit { [weak self] in
        guard let self else { return }
        try await authService.register(
            email: email,
            password: password
        )
    }
    
    if success {
        // Navegación o feedback
    }
}
```

### Estado de Submit

```swift
Button("Registrar") {
    Task { await viewModel.register() }
}
.disabled(formState.isSubmitting || !formState.isValid)

ProgressView()
    .opacity(formState.isSubmitting ? 1 : 0)
```

## Ver También

- <doc:RealTimeValidation>
- <doc:CustomValidators>
- ``FormState``
- ``CrossValidators``
