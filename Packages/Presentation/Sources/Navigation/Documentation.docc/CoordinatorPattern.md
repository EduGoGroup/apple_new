# Patrón Coordinator

Implementación detallada del patrón Coordinator para navegación en SwiftUI.

## Qué es el Patrón Coordinator

El patrón **Coordinator** es un patrón de diseño arquitectural que encapsula la lógica de navegación en objetos dedicados llamados coordinadores. En lugar de que las vistas gestionen su propia navegación, delegan esta responsabilidad a los coordinadores.

### Problema que Resuelve

En aplicaciones SwiftUI tradicionales, la navegación suele estar acoplada a las vistas:

```swift
// ❌ Navegación acoplada a la vista
struct LoginView: View {
    @State private var showDashboard = false
    
    var body: some View {
        VStack {
            Button("Login") {
                // Lógica de autenticación
                showDashboard = true
            }
        }
        .navigationDestination(isPresented: $showDashboard) {
            DashboardView()
        }
    }
}
```

**Problemas:**
- La vista conoce demasiado sobre el flujo de navegación
- Difícil de testear
- Difícil de reutilizar
- Estado de navegación distribuido por toda la app

### Solución con Coordinator

```swift
// ✅ Navegación desacoplada con Coordinator
struct LoginView: View {
    @Environment(\.appCoordinator) private var coordinator
    
    var body: some View {
        VStack {
            Button("Login") {
                // Vista solo notifica, no conoce el destino
                coordinator?.navigate(to: .dashboard)
            }
        }
    }
}
```

## Jerarquía de Coordinadores

### AppCoordinator (Raíz)

El `AppCoordinator` es el coordinador raíz que gestiona el estado global:

```swift
@MainActor
@Observable
public final class AppCoordinator {
    // Estado global de navegación
    public var navigationPath: NavigationPath = NavigationPath()
    public var isAuthenticated: Bool = false
    public var currentUserId: UUID?
    public var activeSheet: Screen?
    public var activeFullScreenCover: Screen?
    
    // Dependencias
    private let mediator: Mediator
    private let eventBus: EventBus
    
    public init(mediator: Mediator, eventBus: EventBus) {
        self.mediator = mediator
        self.eventBus = eventBus
    }
    
    // Inicialización asíncrona
    public func setup() async {
        await subscribeToNavigationEvents()
    }
    
    // API pública de navegación
    public func navigate(to screen: Screen) {
        navigationPath.append(screen)
    }
    
    public func goBack() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
    }
    
    public func popToRoot() {
        navigationPath.removeLast(navigationPath.count)
    }
    
    public func presentSheet(_ screen: Screen) {
        activeSheet = screen
    }
    
    public func dismissSheet() {
        activeSheet = nil
    }
}
```

### FeatureCoordinator Protocol

Los coordinadores de features implementan este protocolo:

```swift
@MainActor
public protocol FeatureCoordinator: AnyObject {
    var appCoordinator: AppCoordinator { get }
    func start()
}
```

**Características:**
- `@MainActor`: garantiza ejecución en el main thread
- `AnyObject`: solo clases pueden implementarlo (necesario para weak references)
- `appCoordinator`: referencia al coordinador raíz
- `start()`: punto de entrada del flujo del feature

### AuthCoordinator

Gestiona flujos de autenticación:

```swift
@MainActor
public final class AuthCoordinator: FeatureCoordinator {
    public let appCoordinator: AppCoordinator
    private let mediator: Mediator
    
    public init(appCoordinator: AppCoordinator, mediator: Mediator) {
        self.appCoordinator = appCoordinator
        self.mediator = mediator
    }
    
    public func start() {
        showLogin()
    }
    
    public func showLogin() {
        appCoordinator.navigate(to: .login)
    }
    
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

### MaterialsCoordinator

Gestiona navegación de materiales educativos:

```swift
@MainActor
public final class MaterialsCoordinator: FeatureCoordinator {
    public let appCoordinator: AppCoordinator
    private let mediator: Mediator
    
    public init(appCoordinator: AppCoordinator, mediator: Mediator) {
        self.appCoordinator = appCoordinator
        self.mediator = mediator
    }
    
    public func start() {
        // Punto de entrada del feature
    }
    
    public func showMaterialDetail(materialId: UUID) {
        appCoordinator.navigate(to: .materialDetail(materialId: materialId))
    }
    
    public func showMaterialInSheet(materialId: UUID) {
        appCoordinator.presentSheet(.materialDetail(materialId: materialId))
    }
}
```

### AssessmentCoordinator

Gestiona flujos de evaluaciones:

```swift
@MainActor
public final class AssessmentCoordinator: FeatureCoordinator {
    public let appCoordinator: AppCoordinator
    private let mediator: Mediator
    
    public init(appCoordinator: AppCoordinator, mediator: Mediator) {
        self.appCoordinator = appCoordinator
        self.mediator = mediator
    }
    
    public func start() {
        // Punto de entrada del feature
    }
    
    public func showAssessment(assessmentId: UUID, userId: UUID) {
        appCoordinator.navigate(to: .assessment(
            assessmentId: assessmentId,
            userId: userId
        ))
    }
    
    public func handleAssessmentComplete() {
        appCoordinator.goBack()
        // Podría navegar a resultados
    }
}
```

### DashboardCoordinator

Gestiona navegación del dashboard:

```swift
@MainActor
public final class DashboardCoordinator: FeatureCoordinator {
    public let appCoordinator: AppCoordinator
    private let mediator: Mediator
    
    public init(appCoordinator: AppCoordinator, mediator: Mediator) {
        self.appCoordinator = appCoordinator
        self.mediator = mediator
    }
    
    public func start() {
        appCoordinator.navigate(to: .dashboard)
    }
    
    public func showProfile(userId: UUID) {
        appCoordinator.navigate(to: .profile(userId: userId))
    }
    
    public func showSettings() {
        appCoordinator.presentSheet(.settings)
    }
}
```

## CoordinatorFactory

Factory pattern para crear coordinadores con dependencias:

```swift
@MainActor
public struct CoordinatorFactory {
    public init() {}
    
    public static func makeAuthCoordinator(
        appCoordinator: AppCoordinator,
        mediator: Mediator
    ) -> AuthCoordinator {
        return AuthCoordinator(
            appCoordinator: appCoordinator,
            mediator: mediator
        )
    }
    
    public static func makeMaterialsCoordinator(
        appCoordinator: AppCoordinator,
        mediator: Mediator
    ) -> MaterialsCoordinator {
        return MaterialsCoordinator(
            appCoordinator: appCoordinator,
            mediator: mediator
        )
    }
    
    public static func makeAssessmentCoordinator(
        appCoordinator: AppCoordinator,
        mediator: Mediator
    ) -> AssessmentCoordinator {
        return AssessmentCoordinator(
            appCoordinator: appCoordinator,
            mediator: mediator
        )
    }
    
    public static func makeDashboardCoordinator(
        appCoordinator: AppCoordinator,
        mediator: Mediator
    ) -> DashboardCoordinator {
        return DashboardCoordinator(
            appCoordinator: appCoordinator,
            mediator: mediator
        )
    }
}
```

**Ventajas del Factory:**
- Centraliza la creación de coordinadores
- Gestiona dependencias de forma consistente
- Facilita testing con mocks
- Permite cambiar implementaciones fácilmente

## Uso en la Aplicación

### Configuración Inicial

```swift
@main
struct EduGoApp: App {
    let appCoordinator: AppCoordinator
    let coordinatorFactory: CoordinatorFactory
    
    init() {
        // Crear dependencias
        let mediator = Mediator()
        let eventBus = EventBus()
        
        // Crear coordinador raíz
        self.appCoordinator = AppCoordinator(
            mediator: mediator,
            eventBus: eventBus
        )
        
        self.coordinatorFactory = CoordinatorFactory()
        
        // Inicializar coordinador
        Task { @MainActor in
            await appCoordinator.setup()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $appCoordinator.navigationPath) {
                if appCoordinator.isAuthenticated {
                    DashboardView()
                } else {
                    LoginView()
                }
            }
            .navigationDestination(for: Screen.self) { screen in
                viewForScreen(screen)
            }
            .sheet(item: $appCoordinator.activeSheet) { screen in
                viewForScreen(screen)
            }
            .environment(\.appCoordinator, appCoordinator)
        }
    }
    
    @ViewBuilder
    private func viewForScreen(_ screen: Screen) -> some View {
        switch screen {
        case .login:
            LoginView()
        case .dashboard:
            DashboardView()
        case .materialDetail(let materialId):
            MaterialDetailView(materialId: materialId)
        case .assessment(let assessmentId, let userId):
            AssessmentView(assessmentId: assessmentId, userId: userId)
        case .profile(let userId):
            ProfileView(userId: userId)
        case .settings:
            SettingsView()
        }
    }
}
```

### Uso en ViewModels

```swift
@MainActor
@Observable
final class LoginViewModel {
    private let authCoordinator: AuthCoordinator
    private let mediator: Mediator
    
    var email: String = ""
    var password: String = ""
    var isLoading: Bool = false
    
    init(authCoordinator: AuthCoordinator, mediator: Mediator) {
        self.authCoordinator = authCoordinator
        self.mediator = mediator
    }
    
    func login() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let command = LoginCommand(email: email, password: password)
            let userId = try await mediator.send(command)
            authCoordinator.handleSuccessfulLogin(userId: userId)
        } catch {
            // Manejar error
        }
    }
}
```

## Diagrama de Jerarquía

```
                    ┌──────────────────┐
                    │  AppCoordinator  │
                    │   (@MainActor)   │
                    └────────┬─────────┘
                             │
                             │ delegates to
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
┌───────────────┐    ┌───────────────┐    ┌──────────────┐
│     Auth      │    │   Materials   │    │  Assessment  │
│  Coordinator  │    │  Coordinator  │    │  Coordinator │
└───────────────┘    └───────────────┘    └──────────────┘
        │                    │                    │
        │                    │                    │
        └────────────────────┴────────────────────┘
                             │
                             │ uses
                             │
                     ┌───────▼────────┐
                     │   Mediator     │
                     │   (CQRS)       │
                     └────────────────┘
```

## Ventajas del Patrón

### 1. Separación de Responsabilidades
```swift
// Vista: solo renderiza UI
struct LoginView: View {
    var body: some View {
        LoginButton()
    }
}

// Coordinator: gestiona navegación
coordinator.handleSuccessfulLogin(userId: userId)
```

### 2. Testabilidad
```swift
func testSuccessfulLogin() async throws {
    let mockMediator = MockMediator()
    let mockEventBus = MockEventBus()
    let appCoordinator = AppCoordinator(
        mediator: mockMediator,
        eventBus: mockEventBus
    )
    let authCoordinator = AuthCoordinator(
        appCoordinator: appCoordinator,
        mediator: mockMediator
    )
    
    authCoordinator.handleSuccessfulLogin(userId: UUID())
    
    XCTAssertTrue(appCoordinator.isAuthenticated)
    XCTAssertNotNil(appCoordinator.currentUserId)
}
```

### 3. Reutilización
Los coordinadores pueden reutilizarse en diferentes contextos sin modificar código.

### 4. Flujos Complejos
Facilita la implementación de flujos multi-paso:

```swift
func startOnboardingFlow() {
    navigate(to: .welcome)
}

func completeWelcome() {
    navigate(to: .permissions)
}

func completePermissions() {
    navigate(to: .tutorial)
}

func completeTutorial() {
    popToRoot()
    navigate(to: .dashboard)
}
```

## Temas Relacionados

- <doc:NavigationArchitecture>
- <doc:EventBusIntegration>
- <doc:BestPractices>
