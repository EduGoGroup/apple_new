# Getting Started

Aprende a usar el sistema de binding bidireccional en tus ViewModels.

## Overview

El módulo Binding simplifica la gestión de estado en ViewModels mediante property wrappers que encapsulan validación, debouncing y notificación de cambios.

### Requisitos

- Swift 6.0+
- iOS 26+ / macOS 26+
- SwiftUI

### Instalación

El módulo Binding está disponible como un Swift Package local:

```swift
dependencies: [
    .package(path: "../TIER-3-Presentation/Binding")
]
```

## Tu Primer ViewModel con Binding

### Paso 1: Crear el ViewModel

```swift
import Binding
import Observation

@MainActor
@Observable
final class ProfileViewModel {
    // Propiedad con validación automática
    @BindableProperty(
        validation: Validators.nonEmpty(fieldName: "Nombre")
    )
    var name: String = ""
    
    // Propiedad con validación de email
    @BindableProperty(
        validation: Validators.email()
    )
    var email: String = ""
    
    // Verifica si el formulario es válido
    var isFormValid: Bool {
        $name.validationState.isValid && $email.validationState.isValid
    }
}
```

### Paso 2: Crear la Vista

```swift
import SwiftUI
import Binding

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()
    @State private var showValidation = false
    
    var body: some View {
        Form {
            Section("Información Personal") {
                TextField("Nombre", text: $viewModel.name)
                    .validated(
                        viewModel.$name.validationState,
                        showValidation: showValidation
                    )
                
                TextField("Email", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .validated(
                        viewModel.$email.validationState,
                        showValidation: showValidation
                    )
            }
            
            Section {
                Button("Guardar") {
                    showValidation = true
                    if viewModel.isFormValid {
                        // Guardar cambios
                    }
                }
                .disabled(!viewModel.isFormValid)
            }
        }
    }
}
```

## Conceptos Clave

### @MainActor

Todos los ViewModels deben marcarse con `@MainActor` para garantizar thread-safety:

```swift
@MainActor  // Obligatorio
@Observable
final class ViewModel {
    // Propiedades actualizadas en main thread
}
```

### ValidationState

Cada `@BindableProperty` expone un `validationState` observable:

```swift
@BindableProperty(validation: Validators.email())
var email: String = ""

// Acceso al estado de validación
let isValid = $email.validationState.isValid
let error = $email.validationState.errorMessage
```

### Validación Manual

Puedes disparar validación manualmente:

```swift
// Validar el valor actual
$email.validate()

// Limpiar estado de validación
$email.resetValidation()
```

## Siguiente Paso

- <doc:RealTimeValidation> - Aprende sobre validación en tiempo real
- <doc:ViewModifiersGuide> - Usa ViewModifiers para feedback visual
- <doc:BestPractices> - Mejores prácticas y patrones recomendados
