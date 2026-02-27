# Integración con EventBus

Navegación event-driven usando el EventBus del sistema CQRS.

## Visión General

La arquitectura de navegación se integra con el **EventBus** del sistema CQRS para permitir navegación reactiva basada en eventos. Esto desacopla la lógica de negocio de la navegación, permitiendo que eventos de dominio disparen automáticamente cambios en la interfaz.

## ¿Por qué Event-Driven Navigation?

### Problema: Navegación Acoplada

En arquitecturas tradicionales, los comandos necesitan conocer la navegación:

```swift
// ❌ Comando acoplado a la navegación
struct UploadMaterialCommand: Command {
    func execute() async throws {
        // Lógica de negocio
        let material = try await uploadMaterial()
        
        // ¡Comando no debería conocer la UI!
        coordinator.navigate(to: .materialDetail(materialId: material.id))
    }
}
```

**Problemas:**
- Violación de Single Responsibility Principle
- Capa de dominio acoplada a UI
- Difícil de testear
- No reutilizable

### Solución: Event-Driven

Con EventBus, los comandos publican eventos y los coordinadores reaccionan:

```swift
// ✅ Comando puro, solo lógica de negocio
struct UploadMaterialCommand: Command {
    func execute() async throws -> UUID {
        let material = try await uploadMaterial()
        
        // Solo publica evento, no conoce UI
        await eventBus.publish(MaterialUploadedEvent(
            materialId: material.id
        ))
        
        return material.id
    }
}

// ✅ Coordinador reacciona al evento
await eventBus.subscribe(MaterialUploadedEvent.self) { event in
    coordinator.navigate(to: .materialDetail(materialId: event.materialId))
}
```

## Eventos de Navegación

### Eventos de Dominio

Eventos publicados por la capa de dominio:

```swift
// Evento de material subido
public struct MaterialUploadedEvent: Event {
    public let eventId: UUID
    public let timestamp: Date
    public let materialId: UUID
    
    public init(materialId: UUID) {
        self.eventId = UUID()
        self.timestamp = Date()
        self.materialId = materialId
    }
}

// Evento de evaluación completada
public struct AssessmentSubmittedEvent: Event {
    public let eventId: UUID
    public let timestamp: Date
    public let assessmentId: UUID
    public let userId: UUID
    
    public init(assessmentId: UUID, userId: UUID) {
        self.eventId = UUID()
        self.timestamp = Date()
        self.assessmentId = assessmentId
        self.userId = userId
    }
}

// Evento de logout
public struct UserLoggedOutEvent: Event {
    public let eventId: UUID
    public let timestamp: Date
    public let userId: UUID
    
    public init(userId: UUID) {
        self.eventId = UUID()
        self.timestamp = Date()
        self.userId = userId
    }
}
```

### Suscripción en AppCoordinator

El `AppCoordinator` se suscribe a eventos durante `setup()`:

```swift
@MainActor
@Observable
public final class AppCoordinator {
    private let mediator: Mediator
    private let eventBus: EventBus
    
    public init(mediator: Mediator, eventBus: EventBus) {
        self.mediator = mediator
        self.eventBus = eventBus
    }
    
    public func setup() async {
        await subscribeToNavigationEvents()
    }
    
    private func subscribeToNavigationEvents() async {
        // Navegación cuando se sube un material
        await eventBus.subscribe(MaterialUploadedEvent.self) { [weak self] event in
            guard let self = self else { return }
            self.navigate(to: .materialDetail(materialId: event.materialId))
        }
        
        // Navegación cuando se completa evaluación
        await eventBus.subscribe(AssessmentSubmittedEvent.self) { [weak self] event in
            guard let self = self else { return }
            self.navigate(to: .assessmentResults(
                assessmentId: event.assessmentId,
                userId: event.userId
            ))
        }
        
        // Logout y navegación a login
        await eventBus.subscribe(UserLoggedOutEvent.self) { [weak self] event in
            guard let self = self else { return }
            self.isAuthenticated = false
            self.currentUserId = nil
            self.popToRoot()
            self.navigate(to: .login)
        }
    }
    
    public func cleanup() async {
        await eventBus.unsubscribeAll()
    }
}
```

## Flujo Completo Event-Driven

### 1. Usuario Interactúa con UI

```swift
struct UploadMaterialView: View {
    @State private var viewModel: UploadMaterialViewModel
    
    var body: some View {
        VStack {
            Button("Subir Material") {
                Task {
                    await viewModel.uploadMaterial()
                }
            }
        }
    }
}
```

### 2. ViewModel Ejecuta Comando

```swift
@MainActor
@Observable
final class UploadMaterialViewModel {
    private let mediator: Mediator
    var isLoading: Bool = false
    
    func uploadMaterial() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let command = UploadMaterialCommand(
                title: "Material",
                content: Data()
            )
            _ = try await mediator.send(command)
            // ViewModel no navega, solo ejecuta comando
        } catch {
            // Manejar error
        }
    }
}
```

### 3. Comando Publica Evento

```swift
struct UploadMaterialCommand: Command {
    let title: String
    let content: Data
    
    func execute() async throws -> UUID {
        // Lógica de negocio
        let material = Material(
            id: UUID(),
            title: title,
            content: content
        )
        
        try await repository.save(material)
        
        // Publicar evento
        await eventBus.publish(MaterialUploadedEvent(
            materialId: material.id
        ))
        
        return material.id
    }
}
```

### 4. AppCoordinator Reacciona

```swift
// El handler de suscripción se ejecuta automáticamente
await eventBus.subscribe(MaterialUploadedEvent.self) { event in
    // Navegación automática
    coordinator.navigate(to: .materialDetail(materialId: event.materialId))
}
```

### 5. SwiftUI Renderiza

```swift
NavigationStack(path: $appCoordinator.navigationPath) {
    RootView()
        .navigationDestination(for: Screen.self) { screen in
            if case .materialDetail(let materialId) = screen {
                MaterialDetailView(materialId: materialId)
            }
        }
}
```

## Diagrama de Flujo

```
┌─────────────────────────────────────────────────────────────┐
│                      Usuario                                 │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                   SwiftUI View                               │
│  Button("Upload") { viewModel.uploadMaterial() }            │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                   ViewModel                                  │
│  await mediator.send(UploadMaterialCommand())                │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│              Command Handler (Domain Layer)                  │
│  1. Execute business logic                                   │
│  2. await eventBus.publish(MaterialUploadedEvent())         │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                   EventBus                                   │
│  Notifies all subscribers                                    │
└───────────┬───────────────────────────┬─────────────────────┘
            │                           │
            ▼                           ▼
┌─────────────────────┐     ┌─────────────────────────────────┐
│  AppCoordinator     │     │  Other Subscribers              │
│  navigate(to:       │     │  (Analytics, Logging, etc)      │
│    .materialDetail) │     │                                 │
└─────────┬───────────┘     └─────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────┐
│            NavigationStack (SwiftUI)                         │
│  Renders MaterialDetailView                                  │
└─────────────────────────────────────────────────────────────┘
```

## Ventajas de Event-Driven Navigation

### 1. Desacoplamiento

La capa de dominio no conoce la UI:

```swift
// Domain layer: solo publica eventos
await eventBus.publish(MaterialUploadedEvent(materialId: id))

// UI layer: reacciona a eventos
await eventBus.subscribe(MaterialUploadedEvent.self) { event in
    coordinator.navigate(to: .materialDetail(materialId: event.materialId))
}
```

### 2. Múltiples Suscriptores

Un evento puede disparar múltiples acciones:

```swift
// Navegación
await eventBus.subscribe(MaterialUploadedEvent.self) { event in
    coordinator.navigate(to: .materialDetail(materialId: event.materialId))
}

// Analytics
await eventBus.subscribe(MaterialUploadedEvent.self) { event in
    analytics.track("material_uploaded", properties: ["id": event.materialId])
}

// Notificaciones
await eventBus.subscribe(MaterialUploadedEvent.self) { event in
    notificationService.showSuccess("Material subido correctamente")
}
```

### 3. Testabilidad

Fácil de testear con mocks:

```swift
func testMaterialUploadedTriggersNavigation() async throws {
    let mockEventBus = MockEventBus()
    let appCoordinator = AppCoordinator(
        mediator: mockMediator,
        eventBus: mockEventBus
    )
    await appCoordinator.setup()
    
    // Simular publicación de evento
    await mockEventBus.publish(MaterialUploadedEvent(
        materialId: UUID()
    ))
    
    // Verificar navegación
    XCTAssertEqual(appCoordinator.navigationPath.count, 1)
}
```

### 4. Extensibilidad

Agregar nuevos suscriptores sin modificar código existente:

```swift
// Nuevo suscriptor sin tocar código existente
await eventBus.subscribe(MaterialUploadedEvent.self) { event in
    cacheService.invalidateCache(for: event.materialId)
}
```

## Gestión de Memoria

### Weak Self en Closures

Importante usar `[weak self]` para evitar retain cycles:

```swift
await eventBus.subscribe(MaterialUploadedEvent.self) { [weak self] event in
    guard let self = self else { return }
    self.navigate(to: .materialDetail(materialId: event.materialId))
}
```

### Cleanup

Limpiar suscripciones cuando se destruye el coordinador:

```swift
deinit {
    Task { @MainActor in
        await cleanup()
    }
}

public func cleanup() async {
    await eventBus.unsubscribeAll()
}
```

## Patrones Avanzados

### Navegación Condicional

```swift
await eventBus.subscribe(AssessmentSubmittedEvent.self) { [weak self] event in
    guard let self = self else { return }
    
    // Navegación condicional basada en estado
    if self.isAuthenticated {
        self.navigate(to: .assessmentResults(
            assessmentId: event.assessmentId,
            userId: event.userId
        ))
    } else {
        self.navigate(to: .login)
    }
}
```

### Eventos Compuestos

```swift
await eventBus.subscribe(UserProfileUpdatedEvent.self) { [weak self] event in
    guard let self = self else { return }
    
    // Actualizar estado y navegar
    self.currentUserId = event.userId
    self.navigate(to: .profile(userId: event.userId))
}
```

### Debouncing

```swift
private var navigationTask: Task<Void, Never>?

await eventBus.subscribe(SearchQueryChangedEvent.self) { [weak self] event in
    guard let self = self else { return }
    
    // Cancelar navegación previa
    navigationTask?.cancel()
    
    // Debounce navigation
    navigationTask = Task { @MainActor in
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }
        self.navigate(to: .searchResults(query: event.query))
    }
}
```

## Mejores Prácticas

### 1. Un Evento, Una Responsabilidad

Cada evento debe representar un solo hecho del dominio:

```swift
// ✅ Bueno
MaterialUploadedEvent(materialId: UUID)

// ❌ Malo
MaterialUploadedAndShouldNavigateEvent(materialId: UUID, destination: Screen)
```

### 2. Eventos Inmutables

Los eventos deben ser structs inmutables:

```swift
public struct MaterialUploadedEvent: Event {
    public let eventId: UUID
    public let timestamp: Date
    public let materialId: UUID
    
    // Sin setters, solo getters
}
```

### 3. Setup Asíncrono

Suscripciones deben hacerse en `setup()`, no en `init`:

```swift
// ✅ Correcto
public func setup() async {
    await subscribeToNavigationEvents()
}

// ❌ Incorrecto
public init(...) {
    Task {
        await subscribeToNavigationEvents() // Race condition
    }
}
```

### 4. Weak References

Siempre usar `[weak self]` en suscripciones:

```swift
await eventBus.subscribe(Event.self) { [weak self] event in
    guard let self = self else { return }
    // ...
}
```

## Temas Relacionados

- <doc:NavigationArchitecture>
- <doc:CoordinatorPattern>
- <doc:BestPractices>
