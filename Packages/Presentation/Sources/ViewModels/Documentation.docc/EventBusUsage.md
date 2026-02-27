# Uso del EventBus

Cómo suscribirse a eventos de dominio para mantener ViewModels sincronizados.

## Overview

El EventBus en EduGo permite comunicación desacoplada entre ViewModels. Cuando una
acción en un ViewModel genera un evento de dominio, otros ViewModels suscritos
pueden reaccionar automáticamente, manteniendo la UI sincronizada sin acoplamiento directo.

## Arquitectura de Eventos

```
┌─────────────────┐                    ┌─────────────────┐
│  LoginViewModel │                    │DashboardViewModel│
│                 │                    │                 │
│ login() ────────┼──▶ LoginCommand    │ subscribed to:  │
│                 │         │          │ LoginSuccessEvent│
└─────────────────┘         │          └────────┬────────┘
                            ▼                   │
                    ┌───────────────┐           │
                    │    Handler    │           │
                    │               │           │
                    │ publishes:    │           │
                    │ LoginSuccess  │───────────┘
                    │    Event      │     triggers refresh()
                    └───────────────┘
```

## Patrón de Suscripción

### Estructura Básica

```swift
@MainActor
@Observable
public final class DashboardViewModel {
    
    private let eventBus: EventBus
    private var subscriptionIds: [UUID] = []
    
    public init(mediator: Mediator, eventBus: EventBus, userId: UUID) {
        self.mediator = mediator
        self.eventBus = eventBus
        self.userId = userId
        
        // Suscribirse a eventos en init
        Task {
            await subscribeToEvents()
        }
    }
    
    private func subscribeToEvents() async {
        // Suscribirse a LoginSuccessEvent
        let loginId = await eventBus.subscribe(to: LoginSuccessEvent.self) { [weak self] event in
            guard let self = self else { return }
            
            await MainActor.run {
                Task {
                    await self.refresh()
                }
            }
        }
        subscriptionIds.append(loginId)
    }
}
```

### Filtrado por Usuario/Contexto

```swift
private func subscribeToEvents() async {
    let id = await eventBus.subscribe(to: AssessmentSubmittedEvent.self) { [weak self] event in
        guard let self = self else { return }
        
        // Solo reaccionar si el evento es para este usuario
        if event.userId == self.userId {
            await MainActor.run {
                Task {
                    await self.refresh()
                }
            }
        }
    }
    subscriptionIds.append(id)
}
```

## Eventos Disponibles en EduGo

### Eventos de Autenticación

| Evento | Campos | Publicado Por |
|--------|--------|---------------|
| `LoginSuccessEvent` | `userId`, `timestamp` | LoginCommandHandler |
| `LogoutEvent` | `userId` | LogoutCommandHandler |

### Eventos de Materiales

| Evento | Campos | Publicado Por |
|--------|--------|---------------|
| `MaterialUploadedEvent` | `materialId`, `uploaderId`, `title` | UploadMaterialHandler |
| `MaterialAssignedEvent` | `materialId`, `assignmentId`, `gradeId` | AssignMaterialHandler |
| `MaterialDeletedEvent` | `materialId` | DeleteMaterialHandler |

### Eventos de Evaluación

| Evento | Campos | Publicado Por |
|--------|--------|---------------|
| `AssessmentSubmittedEvent` | `attemptId`, `userId`, `passed`, `percentage` | SubmitAssessmentHandler |
| `AssessmentGradedEvent` | `attemptId`, `grade`, `feedback` | GradeAssessmentHandler |

### Eventos de Contexto

| Evento | Campos | Publicado Por |
|--------|--------|---------------|
| `ContextSwitchedEvent` | `userId`, `newRole`, `schoolId` | SwitchContextHandler |

## Matriz de Suscripciones

Qué ViewModels escuchan qué eventos:

| ViewModel | Eventos Suscritos | Acción |
|-----------|-------------------|--------|
| `DashboardViewModel` | `LoginSuccessEvent`, `MaterialUploadedEvent`, `AssessmentSubmittedEvent` | `refresh()` |
| `MaterialListViewModel` | `MaterialUploadedEvent`, `MaterialAssignedEvent`, `MaterialDeletedEvent` | `loadMaterials()` |
| `AssessmentViewModel` | `AssessmentGradedEvent` | `loadAssessment()` |
| `UserProfileViewModel` | `ContextSwitchedEvent` | `loadProfile()` |

## Cleanup de Suscripciones

### Importante: Evitar Memory Leaks

Las suscripciones deben limpiarse cuando el ViewModel se destruye:

```swift
@MainActor
@Observable
public final class MyViewModel {
    private var subscriptionIds: [UUID] = []
    private let eventBus: EventBus
    
    deinit {
        // Limpiar suscripciones
        let ids = subscriptionIds
        let bus = eventBus
        
        Task {
            for id in ids {
                await bus.unsubscribe(id)
            }
        }
    }
}
```

### Patrón con Cancellation Token

Para escenarios más complejos:

```swift
@MainActor
@Observable
public final class ComplexViewModel {
    private var subscriptionTask: Task<Void, Never>?
    
    public init(eventBus: EventBus) {
        self.eventBus = eventBus
        
        subscriptionTask = Task {
            await subscribeToEvents()
        }
    }
    
    public func cleanup() {
        subscriptionTask?.cancel()
        
        Task {
            for id in subscriptionIds {
                await eventBus.unsubscribe(id)
            }
        }
    }
}
```

## Patrones Avanzados

### Debouncing de Eventos

Cuando eventos pueden llegar muy rápido:

```swift
private var refreshTask: Task<Void, Never>?

private func handleRefreshEvent() {
    // Cancelar refresh anterior si existe
    refreshTask?.cancel()
    
    // Debounce: esperar 100ms antes de refrescar
    refreshTask = Task {
        try? await Task.sleep(for: .milliseconds(100))
        
        guard !Task.isCancelled else { return }
        
        await refresh()
    }
}
```

### Múltiples Eventos → Una Acción

```swift
private func subscribeToEvents() async {
    // Varios eventos disparan la misma acción
    let refreshTriggers: [any DomainEvent.Type] = [
        LoginSuccessEvent.self,
        MaterialUploadedEvent.self,
        AssessmentSubmittedEvent.self
    ]
    
    for eventType in refreshTriggers {
        let id = await eventBus.subscribe(to: eventType) { [weak self] _ in
            guard let self = self else { return }
            await MainActor.run {
                Task { await self.refresh() }
            }
        }
        subscriptionIds.append(id)
    }
}
```

### Evento con Datos Específicos

```swift
private func subscribeToMaterialEvents() async {
    let id = await eventBus.subscribe(to: MaterialUploadedEvent.self) { [weak self] event in
        guard let self = self else { return }
        
        await MainActor.run {
            // Usar datos del evento directamente
            self.showNotification(
                title: "Material subido",
                message: "Se subió: \(event.title)"
            )
            
            // Y también refrescar lista
            Task {
                await self.loadMaterials()
            }
        }
    }
    subscriptionIds.append(id)
}
```

## Testing de Suscripciones

```swift
@Suite("Event Subscription Tests")
@MainActor
struct EventSubscriptionTests {
    
    @Test
    func dashboardRefreshesOnLoginSuccess() async throws {
        // Arrange
        let eventBus = EventBus()
        let mockMediator = MockMediator()
        
        let dashboardVM = DashboardViewModel(
            mediator: mockMediator,
            eventBus: eventBus,
            userId: UUID()
        )
        
        // Cargar datos iniciales
        await dashboardVM.loadDashboard()
        let initialCallCount = mockMediator.sendCallCount
        
        // Act: Publicar evento
        let event = LoginSuccessEvent(userId: dashboardVM.userId, timestamp: Date())
        await eventBus.publish(event)
        
        // Esperar propagación
        try await Task.sleep(for: .milliseconds(150))
        
        // Assert: Debe haber refrescado
        #expect(mockMediator.sendCallCount > initialCallCount)
    }
}
```

## Checklist de EventBus

- [ ] Suscribirse en `init` dentro de `Task { }`
- [ ] Guardar IDs de suscripción en array
- [ ] Usar `[weak self]` en closures
- [ ] Envolver callbacks en `MainActor.run`
- [ ] Filtrar eventos por usuario/contexto si aplica
- [ ] Limpiar suscripciones en `deinit`
- [ ] Testear propagación de eventos

## See Also

- <doc:MediatorIntegration>
- <doc:ViewModelTesting>
