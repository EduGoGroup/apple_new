# Mejores Prácticas

Guía de mejores prácticas para usar la arquitectura de navegación.

## Visión General

Esta guía presenta las mejores prácticas para trabajar con la arquitectura de navegación basada en Coordinator, garantizando código mantenible, testeable y escalable.

## Type-Safe Navigation

### Usar Screen Enum

Siempre usar el enum `Screen` en lugar de strings:

```swift
// ✅ Correcto: Type-safe
coordinator.navigate(to: .materialDetail(materialId: uuid))

// ❌ Incorrecto: Strings mágicos
coordinator.navigate(to: "material_detail?id=\(uuid)")
```

**Ventajas:**
- Compilador valida rutas
- Autocompletado en el IDE
- Refactoring seguro
- Imposible tener typos

### Asociar Valores con Cases

Usar associated values para parámetros:

```swift
public enum Screen: Hashable, Sendable {
    case materialDetail(materialId: UUID)
    case assessment(assessmentId: UUID, userId: UUID)
    case profile(userId: UUID)
}
```

**Ventajas:**
- Type-safety en parámetros
- Imposible olvidar parámetros requeridos
- Documentación implícita

## Separación de Responsabilidades

### Vistas Solo Renderizan UI

Las vistas no deben conocer la lógica de navegación:

```swift
// ✅ Correcto: Vista delega navegación
struct MaterialListView: View {
    @Environment(\.appCoordinator) private var coordinator
    let materials: [Material]
    
    var body: some View {
        List(materials) { material in
            Button(material.title) {
                coordinator?.navigate(to: .materialDetail(materialId: material.id))
            }
        }
    }
}

// ❌ Incorrecto: Vista conoce el destino
struct MaterialListView: View {
    @State private var selectedMaterial: Material?
    
    var body: some View {
        List(materials) { material in
            Button(material.title) {
                selectedMaterial = material
            }
        }
        .navigationDestination(item: $selectedMaterial) { material in
            MaterialDetailView(material: material)
        }
    }
}
```

### ViewModels Ejecutan Lógica

ViewModels ejecutan comandos, no navegan directamente:

```swift
// ✅ Correcto: ViewModel ejecuta comando, evento dispara navegación
@MainActor
@Observable
final class UploadMaterialViewModel {
    private let mediator: Mediator
    
    func uploadMaterial() async {
        do {
            let command = UploadMaterialCommand(title: title, content: content)
            _ = try await mediator.send(command)
            // Comando publica evento, AppCoordinator navega
        } catch {
            // Manejar error
        }
    }
}

// ❌ Incorrecto: ViewModel navega directamente
@MainActor
@Observable
final class UploadMaterialViewModel {
    private let mediator: Mediator
    private let coordinator: AppCoordinator
    
    func uploadMaterial() async {
        do {
            let command = UploadMaterialCommand(title: title, content: content)
            let materialId = try await mediator.send(command)
            coordinator.navigate(to: .materialDetail(materialId: materialId))
        } catch {
            // Manejar error
        }
    }
}
```

### Coordinadores Gestionan Navegación

Coordinadores contienen toda la lógica de flujos de navegación:

```swift
// ✅ Correcto: AuthCoordinator gestiona flujo completo
@MainActor
public final class AuthCoordinator: FeatureCoordinator {
    public func handleSuccessfulLogin(userId: UUID) {
        appCoordinator.isAuthenticated = true
        appCoordinator.currentUserId = userId
        appCoordinator.popToRoot()
        appCoordinator.navigate(to: .dashboard)
    }
    
    public func handleLogout() {
        appCoordinator.isAuthenticated = false
        appCoordinator.currentUserId = nil
        appCoordinator.popToRoot()
        appCoordinator.navigate(to: .login)
    }
}
```

## Concurrency & Threading

### @MainActor en Coordinadores

Todos los coordinadores deben usar `@MainActor`:

```swift
// ✅ Correcto
@MainActor
@Observable
public final class AppCoordinator {
    public var navigationPath: NavigationPath = NavigationPath()
    
    public func navigate(to screen: Screen) {
        navigationPath.append(screen)
    }
}

// ❌ Incorrecto: Sin @MainActor puede causar crashes
@Observable
public final class AppCoordinator {
    public var navigationPath: NavigationPath = NavigationPath()
    
    public func navigate(to screen: Screen) {
        navigationPath.append(screen) // Crash si no está en main thread
    }
}
```

### Async Setup

Suscripciones al EventBus deben hacerse en `setup()`, no en `init`:

```swift
// ✅ Correcto: Setup asíncrono
@MainActor
@Observable
public final class AppCoordinator {
    public init(mediator: Mediator, eventBus: EventBus) {
        self.mediator = mediator
        self.eventBus = eventBus
    }
    
    public func setup() async {
        await subscribeToNavigationEvents()
    }
}

// Uso
let coordinator = AppCoordinator(mediator: mediator, eventBus: eventBus)
Task { @MainActor in
    await coordinator.setup()
}

// ❌ Incorrecto: Suscripciones en init causan race conditions
@MainActor
@Observable
public final class AppCoordinator {
    public init(mediator: Mediator, eventBus: EventBus) {
        self.mediator = mediator
        self.eventBus = eventBus
        
        Task {
            await subscribeToNavigationEvents() // Race condition
        }
    }
}
```

### Weak Self en Closures

Siempre usar `[weak self]` en suscripciones a eventos:

```swift
// ✅ Correcto: Evita retain cycles
await eventBus.subscribe(MaterialUploadedEvent.self) { [weak self] event in
    guard let self = self else { return }
    self.navigate(to: .materialDetail(materialId: event.materialId))
}

// ❌ Incorrecto: Retain cycle
await eventBus.subscribe(MaterialUploadedEvent.self) { event in
    self.navigate(to: .materialDetail(materialId: event.materialId))
}
```

## Testing

### Testear Coordinadores Aisladamente

```swift
func testNavigateToDashboard() async throws {
    // Arrange
    let mockMediator = MockMediator()
    let mockEventBus = MockEventBus()
    let coordinator = AppCoordinator(
        mediator: mockMediator,
        eventBus: mockEventBus
    )
    await coordinator.setup()
    
    // Act
    coordinator.navigate(to: .dashboard)
    
    // Assert
    XCTAssertEqual(coordinator.navigationPath.count, 1)
}
```

### Testear Event-Driven Navigation

```swift
func testMaterialUploadedEventTriggersNavigation() async throws {
    // Arrange
    let mockMediator = MockMediator()
    let eventBus = EventBus()
    let coordinator = AppCoordinator(
        mediator: mockMediator,
        eventBus: eventBus
    )
    await coordinator.setup()
    
    // Act
    let materialId = UUID()
    await eventBus.publish(MaterialUploadedEvent(materialId: materialId))
    
    // Dar tiempo para que el evento se procese
    try await Task.sleep(for: .milliseconds(100))
    
    // Assert
    XCTAssertEqual(coordinator.navigationPath.count, 1)
}
```

### Testear Deep Linking

```swift
func testDeeplinkParsing() throws {
    // Arrange
    let url = URL(string: "edugo://materials/123e4567-e89b-12d3-a456-426614174000")!
    
    // Act
    let deeplink = DeeplinkParser.parse(url)
    
    // Assert
    XCTAssertEqual(
        deeplink,
        .materialDetail(materialId: UUID(uuidString: "123e4567-e89b-12d3-a456-426614174000")!)
    )
}

func testDeeplinkHandlingWhenAuthenticated() async throws {
    // Arrange
    let mockMediator = MockMediator()
    let mockEventBus = MockEventBus()
    let coordinator = AppCoordinator(
        mediator: mockMediator,
        eventBus: mockEventBus
    )
    coordinator.isAuthenticated = true
    
    let handler = DeeplinkHandler(appCoordinator: coordinator)
    let url = URL(string: "edugo://dashboard")!
    
    // Act
    let handled = handler.handle(url)
    
    // Assert
    XCTAssertTrue(handled)
    XCTAssertEqual(coordinator.navigationPath.count, 1)
}
```

### Usar ViewModels Mockeados

```swift
func testLoginViewModelCallsAuthCoordinator() async throws {
    // Arrange
    let mockMediator = MockMediator()
    let mockAppCoordinator = MockAppCoordinator()
    let authCoordinator = AuthCoordinator(
        appCoordinator: mockAppCoordinator,
        mediator: mockMediator
    )
    
    // Act
    authCoordinator.handleSuccessfulLogin(userId: UUID())
    
    // Assert
    XCTAssertTrue(mockAppCoordinator.isAuthenticated)
}
```

## Environment Injection

### Inyectar Coordinator en Root

```swift
@main
struct EduGoApp: App {
    let appCoordinator: AppCoordinator
    
    init() {
        let mediator = Mediator()
        let eventBus = EventBus()
        self.appCoordinator = AppCoordinator(
            mediator: mediator,
            eventBus: eventBus
        )
        
        Task { @MainActor in
            await appCoordinator.setup()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $appCoordinator.navigationPath) {
                ContentView()
            }
            .environment(\.appCoordinator, appCoordinator)
        }
    }
}
```

### Acceder en Vistas

```swift
struct MyView: View {
    @Environment(\.appCoordinator) private var coordinator
    
    var body: some View {
        Button("Navigate") {
            coordinator?.navigate(to: .dashboard)
        }
    }
}
```

### Propagar a Child Views

El environment se propaga automáticamente a vistas hijas:

```swift
struct ParentView: View {
    var body: some View {
        ChildView() // Hereda automáticamente appCoordinator
    }
}

struct ChildView: View {
    @Environment(\.appCoordinator) private var coordinator
    
    var body: some View {
        Button("Navigate") {
            coordinator?.navigate(to: .dashboard)
        }
    }
}
```

## Gestión de Estado

### Estado Global en AppCoordinator

```swift
@MainActor
@Observable
public final class AppCoordinator {
    // Estado global
    public var navigationPath: NavigationPath = NavigationPath()
    public var isAuthenticated: Bool = false
    public var currentUserId: UUID?
    public var activeSheet: Screen?
    public var activeFullScreenCover: Screen?
}
```

### Estado Local en ViewModels

```swift
@MainActor
@Observable
final class MaterialDetailViewModel {
    // Estado local
    var material: Material?
    var isLoading: Bool = false
    var errorMessage: String?
}
```

### No Duplicar Estado

```swift
// ✅ Correcto: Single source of truth
struct DashboardView: View {
    @Environment(\.appCoordinator) private var coordinator
    
    var body: some View {
        if coordinator?.isAuthenticated == true {
            // Renderizar dashboard
        } else {
            // Renderizar login
        }
    }
}

// ❌ Incorrecto: Estado duplicado
struct DashboardView: View {
    @Environment(\.appCoordinator) private var coordinator
    @State private var isAuthenticated: Bool = false
    
    var body: some View {
        if isAuthenticated {
            // Estado duplicado, puede desincronizarse
        }
    }
}
```

## NavigationPath Management

### Usar NavigationPath en Lugar de Arrays

```swift
// ✅ Correcto: Type-erased NavigationPath
@MainActor
@Observable
public final class AppCoordinator {
    public var navigationPath: NavigationPath = NavigationPath()
    
    public func navigate(to screen: Screen) {
        navigationPath.append(screen)
    }
}

// ❌ Incorrecto: Array requiere conocer todos los tipos
@MainActor
@Observable
public final class AppCoordinator {
    public var navigationPath: [Screen] = []
    
    public func navigate(to screen: Screen) {
        navigationPath.append(screen)
    }
}
```

### Limpiar NavigationPath

```swift
// Volver atrás
public func goBack() {
    guard !navigationPath.isEmpty else { return }
    navigationPath.removeLast()
}

// Volver a la raíz
public func popToRoot() {
    navigationPath.removeLast(navigationPath.count)
}

// Navegar y reemplazar stack
public func replaceStack(with screen: Screen) {
    popToRoot()
    navigate(to: screen)
}
```

## Presentación Modal

### Sheets

```swift
// Presentar
public func presentSheet(_ screen: Screen) {
    activeSheet = screen
}

// Dismissar
public func dismissSheet() {
    activeSheet = nil
}

// En SwiftUI
.sheet(item: $appCoordinator.activeSheet) { screen in
    viewForScreen(screen)
}
```

### Full Screen Covers

```swift
// Presentar
public func presentFullScreenCover(_ screen: Screen) {
    activeFullScreenCover = screen
}

// Dismissar
public func dismissFullScreenCover() {
    activeFullScreenCover = nil
}

// En SwiftUI
.fullScreenCover(item: $appCoordinator.activeFullScreenCover) { screen in
    viewForScreen(screen)
}
```

## Delegation Pattern

### Feature Coordinators Delegan a AppCoordinator

```swift
@MainActor
public final class MaterialsCoordinator: FeatureCoordinator {
    public let appCoordinator: AppCoordinator
    
    public func showMaterialDetail(materialId: UUID) {
        // Delegar navegación al AppCoordinator
        appCoordinator.navigate(to: .materialDetail(materialId: materialId))
    }
}
```

**Ventajas:**
- Single source of truth para navigationPath
- Evita inconsistencias
- Fácil de debuggear

## Limpieza de Recursos

### Cleanup en Coordinadores

```swift
@MainActor
@Observable
public final class AppCoordinator {
    deinit {
        Task { @MainActor in
            await cleanup()
        }
    }
    
    public func cleanup() async {
        await eventBus.unsubscribeAll()
    }
}
```

### Cancelar Tasks

```swift
@MainActor
@Observable
public final class AppCoordinator {
    private var subscriptionTasks: [Task<Void, Never>] = []
    
    public func setup() async {
        let task1 = Task {
            await eventBus.subscribe(Event1.self) { [weak self] event in
                // Handle
            }
        }
        subscriptionTasks.append(task1)
    }
    
    public func cleanup() async {
        subscriptionTasks.forEach { $0.cancel() }
        subscriptionTasks.removeAll()
        await eventBus.unsubscribeAll()
    }
}
```

## Errores Comunes a Evitar

### 1. Modificar UI desde Background Thread

```swift
// ❌ Crash: Modificar UI desde background thread
Task {
    let result = await fetchData()
    coordinator.navigate(to: .dashboard) // Crash
}

// ✅ Correcto: Asegurar main thread
Task { @MainActor in
    let result = await fetchData()
    coordinator.navigate(to: .dashboard)
}
```

### 2. Retain Cycles en Suscripciones

```swift
// ❌ Retain cycle
await eventBus.subscribe(Event.self) { event in
    self.navigate(to: .dashboard)
}

// ✅ Correcto
await eventBus.subscribe(Event.self) { [weak self] event in
    guard let self = self else { return }
    self.navigate(to: .dashboard)
}
```

### 3. Suscripciones en Init

```swift
// ❌ Race condition
public init(mediator: Mediator, eventBus: EventBus) {
    self.mediator = mediator
    self.eventBus = eventBus
    
    Task {
        await subscribeToNavigationEvents()
    }
}

// ✅ Correcto
public func setup() async {
    await subscribeToNavigationEvents()
}
```

### 4. Estado Duplicado

```swift
// ❌ Estado duplicado
@State private var isAuthenticated: Bool = false
@Environment(\.appCoordinator) private var coordinator

// ✅ Single source of truth
@Environment(\.appCoordinator) private var coordinator
var isAuthenticated: Bool {
    coordinator?.isAuthenticated ?? false
}
```

### 5. Navegación Directa desde ViewModels

```swift
// ❌ ViewModel conoce navegación
func uploadMaterial() async {
    let id = try await mediator.send(command)
    coordinator.navigate(to: .materialDetail(materialId: id))
}

// ✅ Navegación via eventos
func uploadMaterial() async {
    _ = try await mediator.send(command)
    // Comando publica evento, coordinador navega
}
```

## Checklist

### Antes de Implementar

- [ ] Definir todos los screens en el enum `Screen`
- [ ] Crear coordinadores necesarios
- [ ] Configurar EventBus
- [ ] Implementar deep links si es necesario

### Durante Implementación

- [ ] Usar `@MainActor` en coordinadores
- [ ] Usar `[weak self]` en closures
- [ ] Setup asíncrono en `setup()`, no en `init`
- [ ] Type-safe navigation con `Screen` enum
- [ ] Vistas solo renderizan, no navegan

### Antes de Commit

- [ ] Tests de coordinadores
- [ ] Tests de deep links
- [ ] Tests de event-driven navigation
- [ ] No hay warnings del compilador
- [ ] Documentación actualizada

## Temas Relacionados

- <doc:NavigationArchitecture>
- <doc:CoordinatorPattern>
- <doc:EventBusIntegration>
- <doc:DeeplinkHandling>
