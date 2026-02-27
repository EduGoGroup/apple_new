# MainActor Isolation

Garantiza thread-safety en ViewModels usando @MainActor isolation.

## Overview

En Swift 6 con strict concurrency, el aislamiento de actores es fundamental para
evitar data races. Los ViewModels en EduGo usan `@MainActor` para garantizar que
todas las actualizaciones de UI ocurran en el main thread de manera segura.

## Fundamentos de @MainActor

### Declaración a Nivel de Clase

```swift
@MainActor
public final class DashboardViewModel {
    // Todas las propiedades y métodos están aislados al main thread
    public var dashboard: Dashboard?
    public var isLoading: Bool = false
    
    public func loadDashboard() async {
        // Garantizado ejecutarse en main thread
        isLoading = true
        // ...
    }
}
```

### Por Qué es Obligatorio

Sin `@MainActor`, actualizaciones de UI desde async contexts causan warnings o crashes:

```swift
// INCORRECTO - Data race potencial
class UnsafeViewModel {
    var name: String = "" // Acceso no protegido
    
    func fetchName() async {
        let result = await api.getName()
        name = result // Warning: actualización desde background thread
    }
}

// CORRECTO - Aislado al main thread
@MainActor
class SafeViewModel {
    var name: String = ""
    
    func fetchName() async {
        let result = await api.getName()
        name = result // Garantizado en main thread
    }
}
```

## Integración con Async/Await

### Métodos Async en @MainActor

Los métodos `async` en un ViewModel `@MainActor` se ejecutan en el main thread:

```swift
@MainActor
public final class MyViewModel {
    public var data: String = ""
    public var isLoading: Bool = false
    
    public func loadData() async {
        isLoading = true // Main thread
        
        // El await puede suspender, pero el código
        // antes y después sigue en main thread
        let result = try? await mediator.send(query)
        
        data = result ?? "" // Main thread
        isLoading = false   // Main thread
    }
}
```

### Llamadas a APIs No-MainActor

Cuando llamas APIs que no son `@MainActor`, Swift maneja el switching automáticamente:

```swift
@MainActor
public final class UserViewModel {
    private let mediator: Mediator // No es @MainActor
    
    public func fetchUser() async {
        // Main thread: actualizar UI
        isLoading = true
        
        // Swift cambia automáticamente al executor del mediator
        let user = try? await mediator.send(GetUserQuery())
        
        // De vuelta al main thread automáticamente
        self.user = user
        isLoading = false
    }
}
```

## Patrones Comunes

### Suscripción a Eventos

Al suscribirse a eventos async, asegura que el callback se ejecute en main thread:

```swift
@MainActor
public final class DashboardViewModel {
    private func subscribeToEvents() async {
        let id = await eventBus.subscribe(to: LoginSuccessEvent.self) { [weak self] event in
            guard let self = self else { return }
            
            // Forzar ejecución en MainActor
            await MainActor.run {
                Task {
                    await self.refresh()
                }
            }
        }
        subscriptionIds.append(id)
    }
}
```

### Task Groups con UI Updates

Cuando usas TaskGroup, las actualizaciones de UI deben volver al main actor:

```swift
@MainActor
public final class BatchViewModel {
    public var results: [Result] = []
    public var progress: Double = 0
    
    public func processBatch(items: [Item]) async {
        let total = Double(items.count)
        var processed = 0
        
        await withTaskGroup(of: Result.self) { group in
            for item in items {
                group.addTask {
                    // Procesamiento en background
                    await self.process(item)
                }
            }
            
            for await result in group {
                // De vuelta en MainActor automáticamente
                results.append(result)
                processed += 1
                progress = Double(processed) / total
            }
        }
    }
    
    // Método sin @MainActor para procesamiento en background
    nonisolated func process(_ item: Item) async -> Result {
        // Heavy computation en background
        return Result(item: item)
    }
}
```

### Nonisolated para Operaciones Sin UI

Usa `nonisolated` para métodos que no necesitan main thread:

```swift
@MainActor
public final class DataViewModel {
    public var processedData: [ProcessedItem] = []
    
    public func loadAndProcess() async {
        isLoading = true
        
        let rawData = try? await mediator.send(GetDataQuery())
        
        // Procesar en background (no bloquea UI)
        let processed = await processInBackground(rawData ?? [])
        
        // Actualizar UI en main thread
        self.processedData = processed
        isLoading = false
    }
    
    // No necesita main thread
    nonisolated func processInBackground(_ items: [RawItem]) async -> [ProcessedItem] {
        items.map { ProcessedItem(from: $0) }
    }
}
```

## Swift 6 Strict Concurrency

### Complete Checking

EduGo usa strict concurrency completa:

```swift
// Package.swift
.target(
    name: "ViewModels",
    swiftSettings: [
        .swiftLanguageMode(.v6),
        .enableExperimentalFeature("StrictConcurrency=complete")
    ]
)
```

### Errores Comunes y Soluciones

**Error: "Capture of 'self' with non-sendable type"**

```swift
// INCORRECTO
eventBus.subscribe { event in
    self.handleEvent(event) // Error: self no es Sendable
}

// CORRECTO
eventBus.subscribe { [weak self] event in
    guard let self = self else { return }
    await MainActor.run {
        Task { await self.handleEvent(event) }
    }
}
```

**Error: "Reference to property in @MainActor isolated class"**

```swift
// INCORRECTO
Task.detached {
    self.isLoading = true // Error: acceso fuera de MainActor
}

// CORRECTO
Task { @MainActor in
    self.isLoading = true
}
```

## Testing con @MainActor

Los tests de ViewModels también deben usar `@MainActor`:

```swift
@Suite("DashboardViewModel Tests")
@MainActor
struct DashboardViewModelTests {
    @Test
    func loadDashboard_setsLoadingState() async {
        let sut = DashboardViewModel(
            mediator: MockMediator(),
            eventBus: MockEventBus(),
            userId: UUID()
        )
        
        // No necesitas MainActor.run porque el test ya está aislado
        await sut.loadDashboard()
        
        #expect(sut.isLoading == false)
    }
}
```

## Checklist de MainActor

- [ ] Todos los ViewModels usan `@MainActor` a nivel de clase
- [ ] Callbacks de eventos usan `MainActor.run`
- [ ] Operaciones pesadas usan `nonisolated`
- [ ] Tests usan `@MainActor` en el Suite
- [ ] No hay accesos a propiedades desde `Task.detached`

## See Also

- <doc:CreatingAViewModel>
- <doc:ObservablePatterns>
- <doc:ViewModelTesting>
