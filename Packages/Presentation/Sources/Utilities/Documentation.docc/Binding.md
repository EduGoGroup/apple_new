# ``Binding``

Sistema de binding bidireccional thread-safe para ViewModels en EduGo.

## Overview

El módulo Binding proporciona una arquitectura robusta para gestionar el enlace bidireccional entre la capa de presentación (SwiftUI) y los ViewModels, con soporte completo para:

- **Validación en tiempo real** mediante property wrappers
- **Thread-safety** garantizado con `@MainActor`
- **Debouncing** para optimizar llamadas al backend
- **Gestión de formularios** con validación cruzada
- **ViewModifiers** para feedback visual automático

### Componentes Principales

El sistema se basa en tres pilares fundamentales:

1. **Property Wrappers**: `@BindableProperty` y `@DebouncedProperty` para encapsular lógica de validación y optimización
2. **FormState**: Gestor de estado para formularios complejos con múltiples campos
3. **ViewModifiers**: Componentes SwiftUI reutilizables para feedback visual

### Ejemplo Rápido

```swift
@MainActor
@Observable
final class LoginViewModel {
    @BindableProperty(validation: Validators.email())
    var email: String = ""
    
    @BindableProperty(validation: Validators.password(minLength: 8))
    var password: String = ""
    
    let formState = FormState()
    
    var canSubmit: Bool {
        $email.validationState.isValid && $password.validationState.isValid
    }
}
```

```swift
struct LoginView: View {
    @State private var viewModel = LoginViewModel()
    
    var body: some View {
        Form {
            TextField("Email", text: $viewModel.email)
                .validated(viewModel.$email.validationState)
            
            SecureField("Password", text: $viewModel.password)
                .validated(viewModel.$password.validationState)
            
            Button("Login") { }
                .disabled(!viewModel.canSubmit)
        }
        .formErrorBanner(viewModel.formState)
    }
}
```

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:Architecture>
- <doc:ThreadSafety>

### Property Wrappers

- ``BindableProperty``
- ``DebouncedProperty``
- ``ValidationResult``

### Form Management

- ``FormState``
- ``Validators``
- ``CrossValidators``

### Validation

- <doc:RealTimeValidation>
- <doc:CrossFieldValidation>
- <doc:CustomValidators>

### SwiftUI Integration

- <doc:ViewModifiersGuide>
- ``ValidationFieldModifier``
- ``LoadingOverlayModifier``
- ``FormErrorBannerModifier``
- ``DisabledDuringSubmitModifier``
- ``ProgressBarModifier``
- ``ShakeEffectModifier``

### Best Practices

- <doc:BestPractices>
- <doc:PerformanceOptimization>

### Examples

- <doc:LoginExample>
- <doc:RegistrationExample>
- <doc:SearchExample>
