# Patrones con @Observable

Patrones y mejores prácticas para usar el macro @Observable en Swift 6.

## Overview

El macro `@Observable` introducido en Swift 5.9 y mejorado en Swift 6 proporciona
observación reactiva de propiedades de manera automática y eficiente. En EduGo,
todos los ViewModels usan este patrón para notificar cambios a las vistas.

## Fundamentos de @Observable

### Declaración Básica

```swift
import Observation

@Observable
public final class CounterViewModel {
    public var count: Int = 0
    
    public func increment() {
        count += 1 // Notifica automáticamente a observadores
    }
}
```

### Comparación con ObservableObject (Legacy)

| Característica | @Observable | ObservableObject |
|----------------|-------------|------------------|
| Declaración | `@Observable` | `ObservableObject` + `@Published` |
| Granularidad | Por propiedad | Todo el objeto |
| Performance | Alta (solo cambios) | Media (recalcula todo) |
| Sintaxis | Limpia | Verbose |
| Swift 6 Ready | Si | Legado |

```swift
// Legacy (NO usar en código nuevo)
class LegacyViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var age: Int = 0
}

// Moderno (USAR siempre)
@Observable
class ModernViewModel {
    var name: String = ""
    var age: Int = 0
}
```

## Propiedades Observables

### Propiedades Automáticamente Observables

Todas las propiedades `var` son observables automáticamente:

```swift
@Observable
public final class UserViewModel {
    // Todas estas son observables automáticamente
    public var name: String = ""
    public var email: String = ""
    public var age: Int = 0
    public var isActive: Bool = true
}
```

### Propiedades No Observables

Usa `@ObservationIgnored` para propiedades que no deben notificar cambios:

```swift
@Observable
public final class MyViewModel {
    public var displayName: String = ""
    
    // No notifica cambios (dependencia interna)
    @ObservationIgnored
    private let mediator: Mediator
    
    // No notifica cambios (estado interno de tracking)
    @ObservationIgnored
    private var subscriptionIds: [UUID] = []
}
```

**Usar `@ObservationIgnored` para:**
- Dependencias inyectadas (mediator, eventBus)
- IDs de suscripciones
- Cache interno
- Referencias a otros objetos no-UI

## Observación en SwiftUI

### Observación Implícita

SwiftUI observa automáticamente propiedades usadas en el body:

```swift
struct UserView: View {
    @State private var viewModel = UserViewModel()
    
    var body: some View {
        VStack {
            // Solo re-renderiza si 'name' cambia
            Text(viewModel.name)
            
            // Solo re-renderiza si 'isLoading' cambia
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }
}
```

### Inyección de ViewModel

Para ViewModels con dependencias, usa inyección desde el ambiente:

```swift
struct DashboardView: View {
    let viewModel: DashboardViewModel
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let dashboard = viewModel.dashboard {
                DashboardContent(dashboard: dashboard)
            }
        }
        .task {
            await viewModel.loadDashboard()
        }
    }
}

// Uso
DashboardView(
    viewModel: DashboardViewModel(
        mediator: mediator,
        eventBus: eventBus,
        userId: userId
    )
)
```

## Patrones Avanzados

### Computed Properties Observables

Las computed properties que dependen de propiedades observables también notifican:

```swift
@Observable
public final class FormViewModel {
    public var email: String = ""
    public var password: String = ""
    
    // Se actualiza cuando email o password cambian
    public var isFormValid: Bool {
        !email.isEmpty && password.count >= 8
    }
    
    // Se actualiza cuando isFormValid o isLoading cambian
    public var canSubmit: Bool {
        isFormValid && !isLoading
    }
    
    public var isLoading: Bool = false
}
```

### Observación Condicional

Optimiza re-renders usando observación selectiva:

```swift
struct OptimizedView: View {
    let viewModel: ComplexViewModel
    
    var body: some View {
        VStack {
            // Este componente solo observa 'title'
            HeaderView(title: viewModel.title)
            
            // Este componente solo observa 'items'
            ItemsListView(items: viewModel.items)
            
            // Este componente solo observa 'isLoading'
            LoadingOverlay(isVisible: viewModel.isLoading)
        }
    }
}
```

### Encapsulación de Estado

Usa métodos públicos para modificar estado, manteniendo setters privados:

```swift
@Observable
public final class CartViewModel {
    // Solo lectura desde fuera
    public private(set) var items: [CartItem] = []
    public private(set) var total: Decimal = 0
    
    // Modificación controlada via métodos
    public func addItem(_ item: CartItem) {
        items.append(item)
        recalculateTotal()
    }
    
    public func removeItem(at index: Int) {
        items.remove(at: index)
        recalculateTotal()
    }
    
    private func recalculateTotal() {
        total = items.reduce(0) { $0 + $1.price }
    }
}
```

## Migración desde ObservableObject

### Antes (Legacy)

```swift
class ProfileViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var bio: String = ""
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    private let service: ProfileService
    
    init(service: ProfileService) {
        self.service = service
    }
}

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    
    init(service: ProfileService) {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(service: service))
    }
}
```

### Después (@Observable)

```swift
@Observable
final class ProfileViewModel {
    var name: String = ""
    var bio: String = ""
    var isLoading: Bool = false
    var error: Error?
    
    @ObservationIgnored
    private let service: ProfileService
    
    init(service: ProfileService) {
        self.service = service
    }
}

struct ProfileView: View {
    let viewModel: ProfileViewModel
    
    var body: some View {
        // viewModel se observa automáticamente
    }
}
```

## Checklist de @Observable

- [ ] Usar `@Observable` en lugar de `ObservableObject`
- [ ] Marcar dependencias con `@ObservationIgnored`
- [ ] No usar `@Published` (innecesario)
- [ ] Computed properties para estados derivados
- [ ] `private(set)` para propiedades de solo lectura

## See Also

- <doc:CreatingAViewModel>
- <doc:MainActorIsolation>
