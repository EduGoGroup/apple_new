# Architecture

Comprende la arquitectura del sistema de binding bidireccional thread-safe.

## Overview

El sistema de binding en EduGo está diseñado para proporcionar una capa de abstracción robusta entre SwiftUI y la lógica de negocio, garantizando:

- **Reactividad automática** mediante `@Observable`
- **Thread-safety** con `@MainActor`
- **Validación declarativa** usando property wrappers
- **Separación de concerns** entre UI y lógica

## Diagrama de Flujo

```
┌─────────────────────────────────────────────────────────────┐
│                        SwiftUI View                         │
│                                                             │
│  TextField("Email", text: $viewModel.email)                │
│      .validated(viewModel.$email.validationState)          │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼ Binding ($)
┌─────────────────────────────────────────────────────────────┐
│                    @BindableProperty                        │
│                                                             │
│  ┌─────────────┐    ┌──────────────┐    ┌───────────────┐  │
│  │   wrappedValue   │    validation   │    │ ValidationState │  │
│  │   (email)    │ ──▶│   closure    │ ──▶│   .isValid      │  │
│  └─────────────┘    └──────────────┘    │   .errorMessage │  │
│                                         └───────────────┘  │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼ @Observable triggers
┌─────────────────────────────────────────────────────────────┐
│                    SwiftUI Re-render                        │
│                                                             │
│  - Actualiza icono de validación                           │
│  - Muestra/oculta mensaje de error                         │
│  - Actualiza borde del campo                               │
└─────────────────────────────────────────────────────────────┘
```

## Capas de la Arquitectura

### 1. Capa de Presentación (SwiftUI)

La vista utiliza ViewModifiers para aplicar feedback visual:

```swift
struct LoginView: View {
    @State private var viewModel = LoginViewModel()
    
    var body: some View {
        TextField("Email", text: $viewModel.email)
            .validated(viewModel.$email.validationState)  // ViewModifier
            .loadingOverlay(isLoading: viewModel.isLoading)
    }
}
```

### 2. Capa de ViewModel

ViewModels usan property wrappers para encapsular lógica:

```swift
@MainActor
@Observable
final class LoginViewModel {
    @BindableProperty(validation: Validators.email())
    var email: String = ""
    
    @DebouncedProperty(
        debounceInterval: 0.5,
        onDebouncedChange: { [weak self] value in
            await self?.checkEmailAvailability(value)
        }
    )
    var emailForSearch: String = ""
    
    let formState = FormState()
}
```

### 3. Capa de Validación

Validadores son funciones puras y reutilizables:

```swift
// Validador simple
Validators.email()

// Validador compuesto
Validators.all(
    Validators.nonEmpty(fieldName: "Password"),
    Validators.minLength(8, fieldName: "Password")
)

// Validador cruzado
CrossValidators.passwordMatch(password, confirmation)
```

## Componentes Principales

### BindableProperty

Property wrapper que combina:
- Almacenamiento del valor
- Validación automática en cada cambio
- Estado observable para UI

```swift
@BindableProperty(
    validation: { value in
        value.count >= 3 ? .valid() : .invalid("Mínimo 3 caracteres")
    },
    onChange: { newValue in
        print("Nuevo valor: \(newValue)")
    }
)
var username: String = ""
```

### FormState

Gestor centralizado para formularios:
- Registro de validadores por campo
- Validación cruzada entre campos
- Estado de envío
- Mensajes de error consolidados

```swift
let formState = FormState()

formState.registerField("email") { [weak self] in
    guard let email = self?.email else { return .valid() }
    return Validators.email()(email)
}

formState.registerCrossValidator { [weak self] in
    guard let self else { return .valid() }
    return CrossValidators.passwordMatch(password, confirmation)
}
```

### ViewModifiers

Modificadores SwiftUI reutilizables:

| Modifier | Propósito |
|----------|-----------|
| `.validated()` | Muestra estado de validación |
| `.loadingOverlay()` | Overlay durante carga |
| `.formErrorBanner()` | Banner de errores de formulario |
| `.disabledDuringSubmit()` | Deshabilita durante envío |
| `.progressBar()` | Barra de progreso |
| `.shakeOnError()` | Efecto shake en error |

## Thread-Safety

El sistema garantiza thread-safety mediante:

### @MainActor Isolation

```swift
@MainActor  // Todas las operaciones en main thread
@Observable
final class ViewModel {
    // Propiedades automáticamente protegidas
}
```

### Sendable Conformance

```swift
// ValidationResult es Sendable
public struct ValidationResult: Sendable, Equatable {
    public let isValid: Bool
    public let errorMessage: String?
}

// Validators son @Sendable
public static func email() -> @Sendable (String) -> ValidationResult
```

## Integración con StateManagement

Para estados complejos, el sistema se integra con StateManagement:

```swift
@MainActor
@Observable
final class UploadViewModel: UploadStateObserver {
    var uploadState: UploadState = .idle
    var uploadProgress: Double = 0.0
    var uploadError: UploadError?
    
    private let stateMachine = UploadStateMachine()
    
    func startUpload() async {
        await observe(stateMachine.stateStream) { [weak self] state in
            self?.handleState(state)
        }
    }
    
    func onUploadCompleted() {
        // Notificar éxito
    }
}
```

## Ver También

- <doc:ThreadSafety>
- <doc:RealTimeValidation>
- <doc:BestPractices>
