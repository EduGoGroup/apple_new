# Arquitectura de Navegación

Descripción completa de la arquitectura de navegación basada en el patrón Coordinator.

## Visión General

La arquitectura de navegación de EduGo implementa el patrón **Coordinator** para gestionar todo el flujo de navegación de la aplicación. Esta arquitectura separa la lógica de navegación de las vistas, creando un sistema mantenible, testeable y escalable.

## Componentes Principales

### 1. Screen Enum

El tipo `Screen` es un enum type-safe que representa todas las posibles pantallas de la aplicación:

```swift
public enum Screen: Hashable, Sendable {
    case login
    case dashboard
    case materialDetail(materialId: UUID)
    case assessment(assessmentId: UUID, userId: UUID)
    case profile(userId: UUID)
    case settings
}
```

**Ventajas:**
- Type-safety: el compilador valida todas las rutas
- Sin strings mágicos
- Autocompletado en el IDE
- Refactoring seguro

### 2. AppCoordinator

El `AppCoordinator` es el coordinador principal que gestiona el estado global de navegación:

```swift
@MainActor
@Observable
public final class AppCoordinator {
    public var navigationPath: NavigationPath
    public var isAuthenticated: Bool
    public var currentUserId: UUID?
    public var activeSheet: Screen?
    public var activeFullScreenCover: Screen?
    
    public func navigate(to screen: Screen)
    public func goBack()
    public func popToRoot()
    public func presentSheet(_ screen: Screen)
    public func dismissSheet()
}
```

**Responsabilidades:**
- Gestionar el NavigationPath global
- Controlar el estado de autenticación
- Presentar sheets y full screen covers
- Suscribirse a eventos del EventBus

### 3. FeatureCoordinators

Los coordinadores especializados gestionan la navegación de features específicas:

```swift
@MainActor
public protocol FeatureCoordinator: AnyObject {
    var appCoordinator: AppCoordinator { get }
    func start()
}
```

**Implementaciones:**
- `AuthCoordinator`: flujos de autenticación
- `MaterialsCoordinator`: navegación de materiales educativos
- `AssessmentCoordinator`: flujos de evaluaciones
- `DashboardCoordinator`: navegación del dashboard

### 4. CoordinatorFactory

Factory pattern para crear coordinadores con sus dependencias:

```swift
@MainActor
public struct CoordinatorFactory {
    public static func makeAuthCoordinator(
        appCoordinator: AppCoordinator,
        mediator: Mediator
    ) -> AuthCoordinator
    
    public static func makeMaterialsCoordinator(
        appCoordinator: AppCoordinator,
        mediator: Mediator
    ) -> MaterialsCoordinator
}
```

## Flujo de Navegación

### Navegación Básica

```swift
// 1. Usuario interactúa con la UI
Button("Ver Dashboard") {
    coordinator.navigate(to: .dashboard)
}

// 2. AppCoordinator actualiza el NavigationPath
public func navigate(to screen: Screen) {
    navigationPath.append(screen)
}

// 3. SwiftUI renderiza la nueva vista
NavigationStack(path: $appCoordinator.navigationPath) {
    RootView()
        .navigationDestination(for: Screen.self) { screen in
            viewForScreen(screen)
        }
}
```

### Navegación Event-Driven

```swift
// 1. Un comando publica un evento
await eventBus.publish(MaterialUploadedEvent(materialId: materialId))

// 2. AppCoordinator recibe el evento
private func subscribeToNavigationEvents() async {
    await eventBus.subscribe(MaterialUploadedEvent.self) { [weak self] event in
        guard let self = self else { return }
        self.navigate(to: .materialDetail(materialId: event.materialId))
    }
}

// 3. Se ejecuta la navegación automáticamente
```

## Integración con SwiftUI

### Environment Injection

```swift
// Definir el EnvironmentKey
private struct AppCoordinatorKey: EnvironmentKey {
    static let defaultValue: AppCoordinator? = nil
}

extension EnvironmentValues {
    public var appCoordinator: AppCoordinator? {
        get { self[AppCoordinatorKey.self] }
        set { self[AppCoordinatorKey.self] = newValue }
    }
}

// Uso en vistas
struct MyView: View {
    @Environment(\.appCoordinator) private var coordinator
    
    var body: some View {
        Button("Navegar") {
            coordinator?.navigate(to: .dashboard)
        }
    }
}
```

### ViewModifiers

```swift
// NavigationDestinationModifier
.navigationDestination(for: Screen.self) { screen in
    viewForScreen(screen)
}

// NavigationBarModifier
.navigationBar(
    title: "Título",
    showBackButton: true,
    backAction: { coordinator?.goBack() }
)
```

## Diagrama de Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                         SwiftUI App                          │
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              NavigationStack                           │  │
│  │  path: $appCoordinator.navigationPath                 │  │
│  └───────────────────────────────────────────────────────┘  │
│                            │                                  │
│                            ▼                                  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │           AppCoordinator (@MainActor)                  │  │
│  │  - navigationPath: NavigationPath                     │  │
│  │  - isAuthenticated: Bool                              │  │
│  │  - activeSheet: Screen?                               │  │
│  │  + navigate(to: Screen)                               │  │
│  │  + presentSheet(_ screen: Screen)                     │  │
│  │  + goBack()                                            │  │
│  └───────────────────────────────────────────────────────┘  │
│           │              │              │                     │
│           ▼              ▼              ▼                     │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │    Auth     │ │  Materials  │ │ Assessment  │           │
│  │ Coordinator │ │ Coordinator │ │ Coordinator │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
│           │              │              │                     │
│           └──────────────┴──────────────┘                     │
│                          │                                     │
│                          ▼                                     │
│  ┌───────────────────────────────────────────────────────┐  │
│  │               EventBus (CQRS)                          │  │
│  │  - MaterialUploadedEvent                              │  │
│  │  - AssessmentSubmittedEvent                           │  │
│  │  - UserLoggedOutEvent                                 │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Ventajas de esta Arquitectura

### 1. Separación de Responsabilidades
Las vistas solo renderizan UI, los coordinadores gestionan la navegación.

### 2. Testabilidad
Los coordinadores son clases aisladas fáciles de testear:

```swift
func testNavigateToDashboard() async throws {
    let coordinator = AppCoordinator(mediator: mockMediator, eventBus: mockEventBus)
    await coordinator.setup()
    
    coordinator.navigate(to: .dashboard)
    
    XCTAssertEqual(coordinator.navigationPath.count, 1)
}
```

### 3. Reutilización
Los coordinadores pueden reutilizarse en diferentes partes de la app.

### 4. Type Safety
El compilador valida todas las rutas y parámetros.

### 5. Escalabilidad
Fácil agregar nuevas pantallas y flujos de navegación.

### 6. Deep Linking
Integración natural con URLs y notificaciones push.

## Temas Relacionados

- <doc:CoordinatorPattern>
- <doc:EventBusIntegration>
- <doc:DeeplinkHandling>
- <doc:BestPractices>
