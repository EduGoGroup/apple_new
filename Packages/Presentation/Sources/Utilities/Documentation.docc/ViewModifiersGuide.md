# ViewModifiers Guide

Usa ViewModifiers para agregar feedback visual automático a tus formularios.

## Overview

El módulo Binding incluye ViewModifiers de SwiftUI listos para usar que proporcionan feedback visual para validación, carga, errores y progreso.

## ViewModifiers Disponibles

| Modifier | Propósito | Ejemplo de Uso |
|----------|-----------|----------------|
| `.validated()` | Muestra estado de validación | Campos de formulario |
| `.loadingOverlay()` | Overlay durante operaciones | Forms, Screens |
| `.formErrorBanner()` | Banner de errores | Formularios |
| `.disabledDuringSubmit()` | Deshabilita durante envío | Botones |
| `.progressBar()` | Barra de progreso | Uploads, Downloads |
| `.shakeOnError()` | Animación de error | Campos inválidos |

## Validated Modifier

### Uso Básico

```swift
TextField("Email", text: $viewModel.email)
    .validated(viewModel.$email.validationState)
```

### Con Control de Visibilidad

```swift
@State private var showValidation = false

TextField("Email", text: $viewModel.email)
    .validated(
        viewModel.$email.validationState,
        showValidation: showValidation
    )

Button("Validar") {
    showValidation = true
}
```

### Estilos Disponibles

```swift
// Estilo por defecto (iconos + borde + mensaje)
.validated(state, style: .default)

// Estilo minimal (solo borde + mensaje)
.validated(state, style: .minimal)

// Estilo personalizado
.validated(state, style: ValidationFieldStyle(
    showIcon: true,
    validIconName: "checkmark.seal.fill",
    invalidIconName: "exclamationmark.triangle.fill",
    validColor: .green,
    errorColor: .red,
    borderWidth: 2,
    borderRadius: 12,
    iconPadding: 10,
    iconFont: .title3,
    errorFont: .footnote,
    errorSpacing: 6,
    animationDuration: 0.3
))
```

## Loading Overlay Modifier

### Uso Básico

```swift
Form {
    // Contenido del formulario
}
.loadingOverlay(isLoading: viewModel.isSubmitting)
```

### Con Mensaje

```swift
.loadingOverlay(
    isLoading: viewModel.isSubmitting,
    message: "Guardando cambios..."
)
```

### Estilos

```swift
// Estilo por defecto (con contenedor)
.loadingOverlay(isLoading: true, style: .default)

// Estilo fullscreen (sin contenedor)
.loadingOverlay(isLoading: true, style: .fullscreen)

// Personalizado
.loadingOverlay(
    isLoading: true,
    style: LoadingOverlayStyle(
        blurRadius: 3,
        spinnerScale: 2.0,
        spinnerColor: .blue,
        contentSpacing: 20,
        messageFont: .headline,
        messageColor: .primary,
        containerPadding: 30,
        containerCornerRadius: 16,
        containerBackground: .init(.regularMaterial),
        shadowColor: .black.opacity(0.15),
        shadowRadius: 12,
        shadowY: 6,
        animationDuration: 0.25
    )
)
```

## Form Error Banner Modifier

### Uso Básico

```swift
Form {
    // Campos del formulario
}
.formErrorBanner(viewModel.formState)
```

### Estilos

```swift
// Error (rojo)
.formErrorBanner(formState, style: .default)

// Warning (amarillo)
.formErrorBanner(formState, style: .warning)

// Personalizado
.formErrorBanner(
    formState,
    style: FormErrorBannerStyle(
        iconName: "info.circle.fill",
        iconFont: .title2,
        iconSpacing: 14,
        messageFont: .callout,
        textColor: .white,
        backgroundColor: .orange,
        padding: EdgeInsets(top: 14, leading: 18, bottom: 14, trailing: 18),
        showDismissButton: true,
        dismissButtonFont: .body.weight(.medium),
        animationDuration: 0.35
    )
)
```

## Disabled During Submit Modifier

### Uso Básico

```swift
Button("Guardar") {
    Task { await viewModel.save() }
}
.disabledDuringSubmit(viewModel.formState)
```

### Estilos

```swift
// Por defecto (opacity 0.6)
.disabledDuringSubmit(formState, style: .default)

// Sutil (opacity 0.8)
.disabledDuringSubmit(formState, style: .subtle)

// Personalizado
.disabledDuringSubmit(
    formState,
    style: DisabledDuringSubmitStyle(
        disabledOpacity: 0.5,
        animationDuration: 0.15
    )
)
```

## Progress Bar Modifier

### Uso Básico

```swift
Button("Subir Archivo") {
    Task { await viewModel.upload() }
}
.progressBar(progress: viewModel.uploadProgress)
```

### Sin Etiqueta

```swift
.progressBar(
    progress: viewModel.uploadProgress,
    showLabel: false
)
```

### Estilos

```swift
// Por defecto
.progressBar(progress: 0.5, style: .default)

// Compacto
.progressBar(progress: 0.5, style: .compact)

// Personalizado
.progressBar(
    progress: 0.5,
    style: ProgressBarStyle(
        spacing: 10,
        labelSpacing: 14,
        labelWidth: 45,
        labelFont: .callout.monospacedDigit(),
        labelColor: .primary,
        progressColor: .blue,
        animationDuration: 0.3
    )
)
```

## Shake On Error Modifier

### Uso Básico

```swift
@State private var showShake = false

TextField("PIN", text: $viewModel.pin)
    .shakeOnError(trigger: showShake)

Button("Verificar") {
    if !viewModel.isValid {
        showShake = true
        // Resetear después de la animación
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showShake = false
        }
    }
}
```

### Estilos

```swift
// Por defecto
.shakeOnError(trigger: true, style: .default)

// Sutil
.shakeOnError(trigger: true, style: .subtle)

// Intenso
.shakeOnError(trigger: true, style: .intense)

// Personalizado
.shakeOnError(
    trigger: true,
    style: ShakeEffectStyle(
        shakeCount: 4,
        shakeAmplitude: 12,
        shakeDuration: 0.45
    )
)
```

## Ejemplo Completo: Formulario de Login

```swift
struct LoginView: View {
    @State private var viewModel = LoginViewModel()
    @State private var showValidation = false
    @State private var shakePassword = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Credenciales") {
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .validated(
                            viewModel.$email.validationState,
                            showValidation: showValidation
                        )
                    
                    SecureField("Contraseña", text: $viewModel.password)
                        .textContentType(.password)
                        .validated(
                            viewModel.$password.validationState,
                            showValidation: showValidation
                        )
                        .shakeOnError(trigger: shakePassword)
                }
                
                Section {
                    Button {
                        showValidation = true
                        
                        if viewModel.isFormValid {
                            Task {
                                await viewModel.login()
                            }
                        } else {
                            shakePassword = true
                            Task {
                                try? await Task.sleep(for: .milliseconds(500))
                                shakePassword = false
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Iniciar Sesión")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(showValidation && !viewModel.isFormValid)
                    .disabledDuringSubmit(viewModel.formState)
                }
            }
            .formErrorBanner(viewModel.formState)
            .loadingOverlay(
                isLoading: viewModel.formState.isSubmitting,
                message: "Iniciando sesión..."
            )
            .navigationTitle("Login")
        }
    }
}
```

## Ver También

- <doc:RealTimeValidation>
- ``ValidationFieldModifier``
- ``LoadingOverlayModifier``
- ``FormErrorBannerModifier``
