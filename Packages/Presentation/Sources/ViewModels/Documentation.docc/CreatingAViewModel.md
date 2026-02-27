# Creando un ViewModel

Aprende a crear un ViewModel desde cero siguiendo las convenciones del proyecto EduGo.

## Overview

Todo ViewModel en EduGo debe seguir una estructura consistente que garantiza:
- Thread-safety automático
- Observación reactiva eficiente
- Testabilidad mediante inyección de dependencias
- Comunicación desacoplada con el dominio

## Estructura Base

Todo ViewModel debe seguir esta estructura canónica:

```swift
@MainActor
@Observable
public final class MyViewModel {
    
    // MARK: - Published State
    
    /// Datos principales del ViewModel
    public var data: MyData?
    
    /// Estado de carga
    public var isLoading: Bool = false
    
    /// Error actual si lo hay
    public var error: Error?
    
    // MARK: - Dependencies
    
    private let mediator: Mediator
    private let eventBus: EventBus
    
    // MARK: - Subscriptions
    
    private var subscriptionIds: [UUID] = []
    
    // MARK: - Initialization
    
    public init(mediator: Mediator, eventBus: EventBus) {
        self.mediator = mediator
        self.eventBus = eventBus
        
        Task {
            await subscribeToEvents()
        }
    }
    
    // MARK: - Public Methods
    
    public func loadData() async {
        isLoading = true
        error = nil
        
        do {
            let query = GetMyDataQuery(...)
            self.data = try await mediator.send(query)
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    private func subscribeToEvents() async {
        // Suscripciones a eventos...
    }
}
```

## Decoradores Obligatorios

### @MainActor

El decorador `@MainActor` garantiza que todas las propiedades y métodos del ViewModel
se ejecuten en el main thread. Esto es **obligatorio** para ViewModels que actualizan UI.

```swift
@MainActor
public final class MyViewModel {
    // Todas las propiedades se actualizan en main thread
    public var data: String = ""
}
```

**Beneficios:**
- Elimina data races automáticamente
- Simplifica el código (no necesitas `DispatchQueue.main.async`)
- Compilador detecta errores de concurrencia en tiempo de compilación

### @Observable

El macro `@Observable` (Swift 6) habilita observación reactiva de propiedades.
Reemplaza el patrón anterior de `ObservableObject` + `@Published`.

```swift
@Observable
public final class MyViewModel {
    // Cambios en 'name' notifican automáticamente a las vistas
    public var name: String = ""
}
```

**Ventajas sobre ObservableObject:**
- Sintaxis más limpia (no requiere `@Published`)
- Mejor rendimiento (observación granular por propiedad)
- Type-safe y compatible con Swift 6

## Inyección de Dependencias

**Regla de oro**: NUNCA crear dependencias dentro del ViewModel.

```swift
// INCORRECTO - No testeable
class MyViewModel {
    private let mediator = Mediator() // Crea dependencia interna
}

// CORRECTO - Inyección por constructor
class MyViewModel {
    private let mediator: Mediator
    
    init(mediator: Mediator) {
        self.mediator = mediator
    }
}
```

La inyección de dependencias permite:
- **Testing**: Inyectar stubs y mocks
- **Flexibilidad**: Cambiar implementaciones sin modificar el ViewModel
- **Claridad**: Dependencias explícitas en el constructor

## Manejo de Estado

### Estados Principales

Todo ViewModel debe exponer al menos estos estados:

| Propiedad | Tipo | Propósito |
|-----------|------|-----------|
| `isLoading` | `Bool` | Indica operación en progreso |
| `error` | `Error?` | Error actual para mostrar al usuario |
| `data` | Modelo específico | Datos principales del ViewModel |

### Computed Properties Útiles

```swift
extension MyViewModel {
    /// Indica si hay datos cargados
    public var hasData: Bool {
        data != nil
    }
    
    /// Indica si hay un error
    public var hasError: Bool {
        error != nil
    }
    
    /// Mensaje de error legible para UI
    public var errorMessage: String? {
        error?.localizedDescription
    }
}
```

## Ejemplo Completo: LoginViewModel

```swift
@MainActor
@Observable
public final class LoginViewModel {
    
    // MARK: - Published State
    
    public var email: String = ""
    public var password: String = ""
    public var isLoading: Bool = false
    public var error: Error?
    public var authenticatedUser: User?
    public var isAuthenticated: Bool = false
    
    // MARK: - Dependencies
    
    private let mediator: Mediator
    
    // MARK: - Initialization
    
    public init(mediator: Mediator) {
        self.mediator = mediator
    }
    
    // MARK: - Public Methods
    
    public func login() async {
        isLoading = true
        error = nil
        
        do {
            let command = LoginCommand(
                email: email,
                password: password
            )
            
            let result = try await mediator.execute(command)
            
            if result.isSuccess, let output = result.getValue() {
                self.authenticatedUser = output.user
                self.isAuthenticated = true
                self.password = "" // Limpiar por seguridad
            }
        } catch {
            self.error = error
            self.password = ""
        }
        
        isLoading = false
    }
}

// MARK: - Computed Properties

extension LoginViewModel {
    public var isFormValid: Bool {
        !email.isEmpty && password.count >= 8
    }
    
    public var isLoginButtonDisabled: Bool {
        isLoading || !isFormValid
    }
}
```

## Checklist de Creación

Antes de considerar un ViewModel completo, verifica:

- [ ] Usa `@MainActor` y `@Observable`
- [ ] Dependencias inyectadas por constructor
- [ ] Estados `isLoading` y `error` expuestos
- [ ] Métodos públicos son `async`
- [ ] Errores manejados con `do-catch`
- [ ] Computed properties para estados derivados
- [ ] Documentación con `///` en elementos públicos

## See Also

- <doc:ObservablePatterns>
- <doc:MainActorIsolation>
- <doc:MediatorIntegration>
