# Performance Optimization

Optimiza el rendimiento de binding y validación.

## Overview

El módulo Binding está optimizado para rendimiento, pero hay prácticas adicionales que pueden mejorar la experiencia del usuario.

## Debouncing

### Por Qué Usar Debouncing

Sin debouncing, cada tecla dispara una acción:

```
Usuario escribe: "hello"
Sin debouncing: 5 llamadas al servidor
Con debouncing (0.5s): 1 llamada al servidor
```

### Implementación

```swift
@DebouncedProperty(
    debounceInterval: 0.5,  // 500ms
    onDebouncedChange: { [weak self] query in
        await self?.performSearch(query)
    }
)
var searchQuery: String = ""
```

### Elegir el Intervalo Correcto

| Caso de Uso | Intervalo Recomendado |
|-------------|----------------------|
| Búsqueda con autocompletado | 300-500ms |
| Validación de disponibilidad | 500-1000ms |
| Guardado automático | 1000-2000ms |
| Filtros en tiempo real | 200-300ms |

## Validación Eficiente

### Evitar Validaciones Costosas

```swift
// INEFICIENTE: Regex compilado en cada validación
@BindableProperty(
    validation: { value in
        let regex = try! NSRegularExpression(pattern: "...")  // Compilación repetida
        // ...
    }
)
var field: String = ""

// EFICIENTE: Regex precompilado
private static let emailRegex = try! NSRegularExpression(
    pattern: "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
)

@BindableProperty(
    validation: { value in
        let range = NSRange(value.startIndex..., in: value)
        return Self.emailRegex.firstMatch(in: value, range: range) != nil
            ? .valid()
            : .invalid("Email inválido")
    }
)
var email: String = ""
```

### Validación Lazy

```swift
// Solo validar si el campo no está vacío
@BindableProperty(
    validation: Validators.when(
        { !$0.isEmpty },
        then: Validators.email()
    )
)
var optionalEmail: String = ""
```

### Evitar Validaciones Síncronas Pesadas

```swift
// INCORRECTO: Operación costosa en validación síncrona
@BindableProperty(
    validation: { value in
        let hash = computeExpensiveHash(value)  // Bloquea UI
        return isValidHash(hash) ? .valid() : .invalid("...")
    }
)
var field: String = ""

// CORRECTO: Usar DebouncedProperty para operaciones costosas
@DebouncedProperty(
    debounceInterval: 0.3,
    onDebouncedChange: { [weak self] value in
        await self?.validateExpensive(value)
    }
)
var field: String = ""
```

## Optimización de Renders

### Observación Granular

```swift
// INEFICIENTE: Todo el ViewModel en @State
@State private var viewModel = LargeViewModel()

// EFICIENTE: Solo las propiedades necesarias
@State private var email: String = ""
@State private var validationState: ValidationState
```

### Propiedades Computadas vs Almacenadas

```swift
// EFICIENTE: Propiedad computada
var isFormValid: Bool {
    $email.validationState.isValid && $password.validationState.isValid
}

// INEFICIENTE: Propiedad almacenada que requiere sincronización
var isFormValid: Bool = false  // Debe actualizarse manualmente
```

## Memoria

### Weak References

```swift
// Evitar retain cycles
@BindableProperty(
    validation: Validators.email(),
    onChange: { [weak self] value in
        self?.onEmailChanged(value)
    }
)
var email: String = ""
```

### Limpieza de Cross-Validators

```swift
deinit {
    formState.clearCrossValidators()
}
```

### Cancelar Tareas Pendientes

```swift
@MainActor
@Observable
final class SearchViewModel {
    private var searchTask: Task<Void, Never>?
    
    func search(_ query: String) {
        searchTask?.cancel()  // Cancelar búsqueda anterior
        searchTask = Task {
            await performSearch(query)
        }
    }
    
    deinit {
        searchTask?.cancel()
    }
}
```

## Networking

### Cancelación Automática con Debouncing

```swift
@DebouncedProperty(
    debounceInterval: 0.5,
    onDebouncedChange: { [weak self] query in
        await self?.search(query)
    }
)
var searchQuery: String = ""

// El DebouncedProperty cancela automáticamente cambios rápidos
```

### Cache de Resultados

```swift
@MainActor
@Observable
final class SearchViewModel {
    private var cache: [String: [Result]] = [:]
    
    func search(_ query: String) async {
        if let cached = cache[query] {
            results = cached
            return
        }
        
        let newResults = await api.search(query)
        cache[query] = newResults
        results = newResults
    }
}
```

## Métricas y Profiling

### Medir Tiempo de Validación

```swift
func timeValidation<T>(_ validator: (T) -> ValidationResult, value: T) -> (ValidationResult, TimeInterval) {
    let start = CFAbsoluteTimeGetCurrent()
    let result = validator(value)
    let duration = CFAbsoluteTimeGetCurrent() - start
    return (result, duration)
}

// Uso en desarrollo
#if DEBUG
let (result, time) = timeValidation(Validators.email(), value: email)
print("Validation took: \(time * 1000)ms")
#endif
```

### Detectar Re-renders Excesivos

```swift
struct DebugView: View {
    let label: String
    
    var body: some View {
        #if DEBUG
        let _ = print("Rendering: \(label)")
        #endif
        
        // Vista real
    }
}
```

## Checklist de Performance

- [ ] Debouncing en búsquedas y validaciones async
- [ ] Regex precompilados
- [ ] Weak references en closures
- [ ] Cancelación de tareas pendientes
- [ ] Cache cuando sea apropiado
- [ ] Validación lazy para campos opcionales
- [ ] Profiling de validadores costosos

## Ver También

- <doc:BestPractices>
- <doc:Architecture>
- ``DebouncedProperty``
