# Best Practices

Patrones recomendados y errores comunes a evitar.

## Overview

Sigue estas mejores prácticas para aprovechar al máximo el sistema de binding y evitar problemas comunes.

## Reglas Fundamentales

### 1. Siempre Usar @MainActor en ViewModels

```swift
// INCORRECTO
@Observable
final class ViewModel {  // Sin @MainActor
    var name: String = ""  // Potencial race condition
}

// CORRECTO
@MainActor
@Observable
final class ViewModel {
    var name: String = ""  // Thread-safe
}
```

### 2. Validar en Tiempo Real

```swift
// INCORRECTO: Validación tardía
@MainActor
@Observable
final class BadViewModel {
    var email: String = ""
    
    func submit() {
        // Validación solo al enviar - mala UX
        guard isValidEmail(email) else {
            showError = true
            return
        }
    }
}

// CORRECTO: Validación instantánea
@MainActor
@Observable
final class GoodViewModel {
    @BindableProperty(validation: Validators.email())
    var email: String = ""
    
    // El usuario ve el error mientras escribe
}
```

### 3. Usar FormState para Formularios Complejos

```swift
// INCORRECTO: Múltiples variables booleanas
@MainActor
@Observable
final class BadFormViewModel {
    var isEmailValid = false
    var isPasswordValid = false
    var isNameValid = false
    var isSubmitting = false
    var formError: String?
    
    var canSubmit: Bool {
        isEmailValid && isPasswordValid && isNameValid && !isSubmitting
    }
}

// CORRECTO: FormState centralizado
@MainActor
@Observable
final class GoodFormViewModel {
    @BindableProperty(validation: Validators.email())
    var email: String = ""
    
    @BindableProperty(validation: Validators.password(minLength: 8))
    var password: String = ""
    
    let formState = FormState()
    
    var canSubmit: Bool {
        $email.validationState.isValid && 
        $password.validationState.isValid && 
        !formState.isSubmitting
    }
}
```

### 4. Debounce para Búsquedas

```swift
// INCORRECTO: Búsqueda en cada tecla
@MainActor
@Observable
final class BadSearchViewModel {
    var query: String = "" {
        didSet {
            Task { await search() }  // Demasiadas llamadas
        }
    }
}

// CORRECTO: Búsqueda debounced
@MainActor
@Observable
final class GoodSearchViewModel {
    @DebouncedProperty(
        debounceInterval: 0.5,
        onDebouncedChange: { [weak self] query in
            await self?.search(query)
        }
    )
    var query: String = ""
}
```

### 5. Weak References en Closures

```swift
// INCORRECTO: Retain cycle potencial
@BindableProperty(
    validation: Validators.email(),
    onChange: { [self] value in  // Strong reference
        self.onEmailChanged(value)
    }
)
var email: String = ""

// CORRECTO: Weak reference
@BindableProperty(
    validation: Validators.email(),
    onChange: { [weak self] value in
        self?.onEmailChanged(value)
    }
)
var email: String = ""
```

## Patrones Recomendados

### Mostrar Validación Solo Después de Interacción

```swift
struct FormView: View {
    @State private var viewModel = FormViewModel()
    @State private var hasInteracted = false
    
    var body: some View {
        TextField("Email", text: $viewModel.email)
            .validated(
                viewModel.$email.validationState,
                showValidation: hasInteracted
            )
            .onChange(of: viewModel.email) { _, _ in
                hasInteracted = true
            }
    }
}
```

### Validar Todos los Campos al Submit

```swift
@MainActor
@Observable
final class RegistrationViewModel {
    @BindableProperty(validation: Validators.email())
    var email: String = ""
    
    @BindableProperty(validation: Validators.password(minLength: 8))
    var password: String = ""
    
    func validateAll() {
        $email.validate()
        $password.validate()
    }
    
    func submit() async {
        validateAll()
        
        guard $email.validationState.isValid,
              $password.validationState.isValid else {
            return
        }
        
        await performSubmit()
    }
}
```

### Limpiar Errores al Editar

```swift
struct FieldView: View {
    @Bindable var viewModel: FormViewModel
    
    var body: some View {
        TextField("Email", text: $viewModel.email)
            .onChange(of: viewModel.email) { _, _ in
                viewModel.formState.clearError(for: "email")
            }
    }
}
```

### Componer Validadores Reutilizables

```swift
enum AppValidators {
    static func schoolEmail() -> @Sendable (String) -> ValidationResult {
        Validators.all(
            Validators.email(),
            allowedDomains(["school.edu", "edugo.com"])
        )
    }
    
    static func allowedDomains(_ domains: [String]) -> @Sendable (String) -> ValidationResult {
        return { email in
            let domain = email.components(separatedBy: "@").last ?? ""
            if domains.contains(where: { domain.hasSuffix($0) }) {
                return .valid()
            }
            return .invalid("Debe usar un email institucional")
        }
    }
}
```

## Errores Comunes a Evitar

### Error 1: Olvidar @MainActor

```swift
// Error de compilación en Swift 6
@Observable
final class ViewModel {
    @BindableProperty(validation: Validators.email())
    var email: String = ""  // Error: @MainActor required
}
```

### Error 2: Validación Sincrónica en Closure Async

```swift
// INCORRECTO
@DebouncedProperty(
    debounceInterval: 0.5,
    onDebouncedChange: { value in
        // Error: No se puede llamar sync desde async
        self.syncValidate(value)
    }
)
var query: String = ""

// CORRECTO
@DebouncedProperty(
    debounceInterval: 0.5,
    onDebouncedChange: { [weak self] value in
        await self?.asyncValidate(value)
    }
)
var query: String = ""
```

### Error 3: No Manejar Estados de Carga

```swift
// INCORRECTO: UI no responde durante submit
Button("Enviar") {
    Task { await viewModel.submit() }  // Sin indicador de carga
}

// CORRECTO
Button("Enviar") {
    Task { await viewModel.submit() }
}
.disabledDuringSubmit(viewModel.formState)

ProgressView()
    .opacity(viewModel.formState.isSubmitting ? 1 : 0)
```

### Error 4: Validadores No Sendable

```swift
// INCORRECTO: Captura estado mutable
var minLength = 8

@BindableProperty(
    validation: { value in
        value.count >= minLength ? .valid() : .invalid("...")
    }  // Error: minLength no es Sendable
)
var password: String = ""

// CORRECTO: Usar valor fijo
@BindableProperty(
    validation: Validators.minLength(8, fieldName: "Password")
)
var password: String = ""
```

## Checklist de Código

Antes de hacer PR, verifica:

- [ ] ViewModels tienen `@MainActor`
- [ ] Property wrappers usan validadores `@Sendable`
- [ ] Closures usan `[weak self]`
- [ ] FormState para formularios multi-campo
- [ ] Debouncing para búsquedas y llamadas frecuentes
- [ ] ViewModifiers para feedback visual
- [ ] Tests para validadores personalizados
- [ ] Documentación de reglas de negocio

## Ver También

- <doc:PerformanceOptimization>
- <doc:Architecture>
- <doc:ThreadSafety>
