# ``Navigation``

Arquitectura de navegación basada en el patrón Coordinator para aplicaciones SwiftUI.

## Visión General

El módulo **Navigation** proporciona una arquitectura completa y type-safe para gestionar la navegación en aplicaciones SwiftUI. Implementa el patrón Coordinator para separar la lógica de navegación de las vistas, integrándose con el EventBus del sistema CQRS para navegación event-driven.

### Características Principales

- **Type-Safe Navigation**: Navegación basada en enums sin strings mágicos
- **Coordinator Pattern**: Separación clara de responsabilidades de navegación
- **EventBus Integration**: Navegación reactiva basada en eventos del sistema
- **Deep Linking**: Soporte completo para URL schemes y Universal Links
- **SwiftUI Native**: Aprovecha NavigationStack y NavigationPath de iOS 26+
- **Concurrency Safe**: @MainActor y Swift 6.2 StrictConcurrency
- **Multi-Platform**: Compatible con iOS 26+ y macOS 26+

## Temas

### Artículos

- <doc:NavigationArchitecture>
- <doc:CoordinatorPattern>
- <doc:EventBusIntegration>
- <doc:DeeplinkHandling>
- <doc:BestPractices>

### Coordinadores

- ``AppCoordinator``
- ``FeatureCoordinator``
- ``AuthCoordinator``
- ``MaterialsCoordinator``
- ``AssessmentCoordinator``
- ``DashboardCoordinator``
- ``CoordinatorFactory``

### Deep Linking

- ``Deeplink``
- ``DeeplinkParser``
- ``DeeplinkHandler``

### Navegación Type-Safe

- ``Screen``

### Helpers de SwiftUI

- ``NavigationDestinationModifier``
- ``NavigationBarModifier``
- ``NavigationButton``
- ``SheetButton``
- ``FullScreenCoverButton``

## Inicio Rápido

### Configuración Básica

```swift
import Navigation
import EventBus
import CQRS

@main
struct MyApp: App {
    let appCoordinator: AppCoordinator
    
    init() {
        let mediator = Mediator()
        let eventBus = EventBus()
        self.appCoordinator = AppCoordinator(mediator: mediator, eventBus: eventBus)
        
        Task { @MainActor in
            await appCoordinator.setup()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $appCoordinator.navigationPath) {
                RootView()
                    .navigationDestination(for: Screen.self) { screen in
                        // Vista para cada screen
                    }
            }
            .environment(\.appCoordinator, appCoordinator)
        }
    }
}
```

### Navegación en Vistas

```swift
struct MyView: View {
    @Environment(\.appCoordinator) private var coordinator
    
    var body: some View {
        VStack {
            NavigationButton(destination: .dashboard) {
                Text("Ir a Dashboard")
            }
            
            Button("Ver Material") {
                coordinator?.navigate(to: .materialDetail(materialId: UUID()))
            }
        }
    }
}
```

### Deep Linking

```swift
// En tu App
.onOpenURL { url in
    let handler = DeeplinkHandler(appCoordinator: appCoordinator)
    _ = handler.handle(url)
}

// Soporta URLs como:
// edugo://dashboard
// https://edugo.app/materials/123e4567-e89b-12d3-a456-426614174000
```

## Requisitos

- iOS 26.0+ / macOS 26.0+
- Swift 6.2+
- Xcode 16.0+

## Dependencias

- **EventBus**: Sistema de eventos CQRS
- **CQRS**: Mediator para comandos y queries
