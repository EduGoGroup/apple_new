# Thread Safety

Garantiza la seguridad de hilos en tus ViewModels con @MainActor.

## Overview

Swift 6 introduce strict concurrency checking, lo que significa que el compilador verifica en tiempo de compilación que tu código sea thread-safe. El módulo Binding está diseñado desde cero para cumplir con estos requisitos.

## El Problema

Sin protección adecuada, múltiples hilos pueden acceder a las propiedades del ViewModel simultáneamente:

```swift
// PELIGROSO: Sin protección de hilos
@Observable
final class UnsafeViewModel {
    var counter: Int = 0
    
    func increment() {
        counter += 1  // Race condition potencial
    }
}
```

## La Solución: @MainActor

`@MainActor` garantiza que todas las operaciones se ejecuten en el main thread:

```swift
// SEGURO: Protegido con @MainActor
@MainActor
@Observable
final class SafeViewModel {
    var counter: Int = 0
    
    func increment() {
        counter += 1  // Siempre en main thread
    }
}
```

## Reglas de Oro

### 1. Siempre Usar @MainActor en ViewModels

```swift
@MainActor  // OBLIGATORIO
@Observable
final class ViewModel {
    // Todas las propiedades son thread-safe automáticamente
    @BindableProperty(validation: Validators.email())
    var email: String = ""
}
```

### 2. Validadores Deben Ser @Sendable

Los validadores pueden ejecutarse en cualquier contexto:

```swift
// Los validadores built-in son @Sendable
Validators.email()  // @Sendable (String) -> ValidationResult

// Custom validators también deben serlo
let customValidator: @Sendable (String) -> ValidationResult = { value in
    value.isEmpty ? .invalid("Required") : .valid()
}
```

### 3. Callbacks Deben Ser @Sendable

```swift
@BindableProperty(
    validation: Validators.email(),
    onChange: { @Sendable newValue in  // @Sendable closure
        print("Changed to: \(newValue)")
    }
)
var email: String = ""
```

## Llamadas Asíncronas

### Desde el ViewModel

```swift
@MainActor
@Observable
final class SearchViewModel {
    var results: [Result] = []
    var isLoading = false
    
    func search(query: String) async {
        isLoading = true
        defer { isLoading = false }
        
        // Llamada de red en background
        let data = await networkService.search(query)
        
        // Actualización automáticamente en main thread
        results = data
    }
}
```

### Desde la Vista

```swift
struct SearchView: View {
    @State private var viewModel = SearchViewModel()
    
    var body: some View {
        List(viewModel.results) { result in
            Text(result.title)
        }
        .task {
            await viewModel.search(query: "swift")
        }
    }
}
```

## DebouncedProperty y Concurrencia

`@DebouncedProperty` maneja internamente la concurrencia:

```swift
@DebouncedProperty(
    debounceInterval: 0.5,
    onDebouncedChange: { @Sendable [weak self] query in
        // Este closure se ejecuta en contexto async
        await self?.performSearch(query)
    }
)
var searchQuery: String = ""
```

### Cancelación Automática

```swift
// Cambios rápidos cancelan operaciones pendientes
viewModel.searchQuery = "a"    // Inicia timer
viewModel.searchQuery = "ab"   // Cancela anterior, inicia nuevo
viewModel.searchQuery = "abc"  // Cancela anterior, inicia nuevo
// Solo "abc" dispara la búsqueda después de 0.5s
```

## FormState y Thread-Safety

`FormState` es `@MainActor` isolated:

```swift
@MainActor
@Observable
public final class FormState: Sendable {
    public var isValid: Bool = false
    public var isSubmitting: Bool = false
    public var errors: [String: String] = [:]
    
    public func submit(
        action: @escaping @Sendable () async throws -> Void
    ) async -> Bool {
        // Ejecución segura en main thread
    }
}
```

## Patrones Comunes

### Captura Débil en Closures

```swift
@BindableProperty(
    validation: Validators.email(),
    onChange: { [weak self] newValue in
        self?.onEmailChanged(newValue)
    }
)
var email: String = ""
```

### Isolation Heredada

```swift
@MainActor
final class ParentViewModel {
    // Child también está en @MainActor
    let childViewModel = ChildViewModel()
}

@MainActor
final class ChildViewModel {
    // Hereda isolation del parent
}
```

## Errores Comunes

### Error: Actor Isolation

```swift
// ERROR: Main actor-isolated property cannot be mutated from nonisolated context
func badUpdate() {
    viewModel.email = "test"  // Sin await o Task
}

// CORRECTO
func goodUpdate() async {
    await MainActor.run {
        viewModel.email = "test"
    }
}
```

### Error: Sendable Conformance

```swift
// ERROR: Capture of non-sendable type
class NonSendableService {
    func fetch() async { }
}

// CORRECTO
final class SendableService: Sendable {
    func fetch() async { }
}
```

## Ver También

- <doc:Architecture>
- <doc:BestPractices>
- <doc:PerformanceOptimization>
