# Modernizacion Swift 6.2 y Liquid Glass

## 1. Actualizacion de Deployment Target

### Cambio Requerido

| Actual | Nuevo |
|--------|-------|
| iOS 18.0 | iOS 26.0 |
| macOS 15.0 | macOS 26.0 |

**Justificacion**: iOS 26 es requerido para las APIs nativas de Liquid Glass (`.glassEffect()`, materiales translucidos, lensing). Sin este target, los efectos serian simulados.

**Accion**: Actualizar todos los `Package.swift` (raiz + cada modulo) cambiando `.iOS(.v18)` por `.iOS(.v26)` y `.macOS(.v15)` por `.macOS(.v26)`.

## 2. Concurrencia Swift 6.2

### 2.1 MainActor by Default

Swift 6.2 introduce MainActor isolation por defecto. Esto simplifica enormemente la anotacion de ViewModels y codigo de UI.

**Antes (Swift 5.9-6.1):**

```swift
@MainActor
@Observable
final class DynamicScreenViewModel {
    var screenState: ScreenState = .loading
    var zones: [Zone] = []

    func loadScreen(_ id: ScreenID) async {
        // Ya estaba en MainActor por la anotacion explicita
    }
}
```

**Swift 6.2:**

```swift
@Observable
final class DynamicScreenViewModel {
    var screenState: ScreenState = .loading
    var zones: [Zone] = []

    // Codigo corre en MainActor por defecto
    // Solo anotar @Sendable los closures que deben cruzar boundaries

    func loadScreen(_ id: ScreenID) async {
        // MainActor implicitamente
    }
}
```

**Accion**: Revisar todos los ViewModels y eliminar anotaciones `@MainActor` redundantes. Sin embargo, mantener `@MainActor` explicito en codigo nuevo por claridad hasta que el equipo se familiarice con el cambio.

### 2.2 Strict Concurrency

Verificar que TODOS los tipos que cruzan boundaries de concurrencia sean `Sendable`:

- Los modelos de Dynamic UI (`ScreenDefinition`, `Zone`, `Slot`, etc.) son structs Codable, inherentemente Sendable
- Los actors (`ScreenLoader`, `DataLoader`) son Sendable por definicion
- Los enums (`ScreenPattern`, `ControlType`, etc.) son Sendable si todos los associated values lo son

**Verificacion requerida:**

```swift
// Estos structs deben ser Sendable (ya lo son si son value types puros)
struct ScreenDefinition: Codable, Sendable {
    let id: ScreenID
    let zones: [Zone]
    let pattern: ScreenPattern
}

// Los actors son Sendable por definicion
actor ScreenLoader {
    func load(_ id: ScreenID) async throws -> ScreenDefinition { ... }
}

// Verificar enums con associated values
enum ControlType: Sendable {
    case button(ButtonConfig)    // ButtonConfig debe ser Sendable
    case textField(TextConfig)   // TextConfig debe ser Sendable
    case list(ListConfig)        // ListConfig debe ser Sendable
}
```

**Accion**: Ejecutar la compilacion con strict concurrency checking habilitado y resolver todas las advertencias.

### 2.3 Observations (nuevo en Swift 6.2)

Nueva async sequence para streaming de cambios de estado. Reemplaza patrones manuales de `withObservationTracking`.

```swift
// Patron anterior con withObservationTracking
func trackChanges() {
    withObservationTracking {
        let currentState = viewModel.screenState
        // Procesar estado
    } onChange: {
        Task { @MainActor in
            trackChanges() // Re-registrar recursivamente
        }
    }
}

// Nuevo en Swift 6.2 - async sequence nativa
func trackChanges() async {
    for await changes in observations(of: viewModel) {
        // Reaccionar a cambios de estado automaticamente
        // No requiere re-registro manual
        updateUI(with: changes)
    }
}
```

**Accion**: Evaluar uso de `Observations` en el sistema de StateManagement existente (`StatePublisher`, `StateMachines`). Priorizar migracion en los puntos donde se use `withObservationTracking` directamente.

### 2.4 InlineArray

Para colecciones de tamano fijo con almacenamiento en stack:

```swift
// Nuevo en Swift 6.2 - almacenamiento en stack, sin heap allocation
let fixedSlots: InlineArray<5, Slot> = ...

// Caso de uso: buffers internos de tamano conocido
struct RenderCache {
    var recentScreens: InlineArray<3, ScreenDefinition>
    var activeZones: InlineArray<8, ZoneID>
}
```

**Accion**: No aplicable inmediatamente al sistema Dynamic UI. Considerar para:
- Caches de tamano fijo en el rendering pipeline
- Buffers internos en el sistema de eventos
- Colecciones pequenas de configuracion conocida en tiempo de compilacion

## 3. Patron de Observacion

### Eliminar @Published / @ObservableObject

El proyecto debe usar EXCLUSIVAMENTE la macro `@Observable` (disponible desde Swift 5.9, adoptada plenamente en el proyecto):

**NO usar (patron obsoleto):**

```swift
// PROHIBIDO - Patron Combine legacy
class ViewModel: ObservableObject {
    @Published var state: ScreenState = .loading
    @Published var zones: [Zone] = []
    @Published var error: AppError?
}

// En View - PROHIBIDO:
struct ScreenView: View {
    @StateObject var vm = ViewModel()          // NO
    @ObservedObject var vm: ViewModel          // NO
    @EnvironmentObject var vm: ViewModel       // NO
}
```

**SI usar (patron correcto):**

```swift
// CORRECTO - Macro @Observable
@Observable
final class ViewModel {
    var state: ScreenState = .loading
    var zones: [Zone] = []
    var error: AppError?

    // Propiedades que NO deben triggear re-renders
    @ObservationIgnored
    var internalCache: [String: Any] = [:]
}

// En View - CORRECTO:
struct ScreenView: View {
    @State var vm = ViewModel()                     // Ownership local
    @Environment(ViewModel.self) var vm             // Inyectado via environment
    let vm: ViewModel                               // Pasado como parametro
}
```

**Ventajas del patron @Observable:**
- Tracking granular automatico (solo las propiedades leidas en `body` causan re-render)
- Sin overhead de publishers Combine
- Interoperabilidad directa con el sistema de `@Environment` de SwiftUI
- Simplifica significativamente el boilerplate

**Accion**: Auditar todos los ViewModels existentes y migrar cualquier `@Published`/`ObservableObject` residual. Buscar especificamente:
- Archivos que importen `Combine` solo para `ObservableObject`
- Usos de `@StateObject`, `@ObservedObject`, `@EnvironmentObject`
- Clases que conformen `ObservableObject`

## 4. Dependency Injection

### Eliminar Swinject o DI manual complejo

Usar `@Environment` nativo de SwiftUI como mecanismo principal de DI:

```swift
// Punto de entrada - registrar todas las dependencias
@main
struct EduGoApp: App {
    @State private var serviceContainer = ServiceContainer(
        environment: .production
    )
    @State private var screenLoader = ScreenLoader()
    @State private var authService = AuthService()
    @State private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(serviceContainer)
                .environment(screenLoader)
                .environment(authService)
                .environment(themeManager)
        }
    }
}

// Consumir en cualquier View del arbol
struct DynamicScreenView: View {
    @Environment(ScreenLoader.self) var screenLoader
    @Environment(ThemeManager.self) var themeManager

    var body: some View {
        // screenLoader y themeManager disponibles automaticamente
    }
}
```

### ServiceContainer para servicios no-UI

Para actors y servicios de red que no necesitan inyeccion directa en Views:

```swift
@Observable
final class ServiceContainer {
    let screenLoader: ScreenLoader
    let dataLoader: DataLoader
    let authService: AuthService
    let actionRegistry: ActionRegistry
    let eventBus: EventBus

    init(environment: AppEnvironment) {
        self.screenLoader = ScreenLoader(baseURL: environment.apiBaseURL)
        self.dataLoader = DataLoader(cache: environment.cachePolicy)
        self.authService = AuthService(config: environment.authConfig)
        self.actionRegistry = ActionRegistry()
        self.eventBus = EventBus()
    }
}

// Acceder desde Views cuando se necesite un servicio especifico
struct SomeView: View {
    @Environment(ServiceContainer.self) var services

    func performAction() async {
        await services.actionRegistry.execute(.navigate(to: screenID))
    }
}
```

**Accion**: Eliminar cualquier framework de DI de terceros. El sistema de `@Environment` de SwiftUI es suficiente para las necesidades del proyecto.

## 5. Eventos Reactivos

### Migrar de Combine/NotificationCenter a AsyncSequence

**NO usar (patrones legacy):**

```swift
// PROHIBIDO - NotificationCenter
NotificationCenter.default.post(name: .sessionExpired, object: nil)
NotificationCenter.default.addObserver(forName: .sessionExpired, ...) { _ in
    // Manejar evento
}

// PROHIBIDO - Combine subjects
let publisher = PassthroughSubject<AuthEvent, Never>()
publisher.sink { event in
    // Manejar evento
}
```

**SI usar (AsyncSequence nativo):**

```swift
// Actor que gestiona el stream de eventos
actor AuthEventStream {
    private var continuations: [UUID: AsyncStream<AuthEvent>.Continuation] = [:]

    var events: AsyncStream<AuthEvent> {
        AsyncStream { continuation in
            let id = UUID()
            continuations[id] = continuation
            continuation.onTermination = { @Sendable _ in
                Task { await self.removeContinuation(id) }
            }
        }
    }

    func emit(_ event: AuthEvent) {
        for continuation in continuations.values {
            continuation.yield(event)
        }
    }

    private func removeContinuation(_ id: UUID) {
        continuations.removeValue(forKey: id)
    }
}

// Consumir en una View
struct AuthAwareView: View {
    @Environment(AuthEventStream.self) var authEvents

    var body: some View {
        ContentView()
            .task {
                for await event in await authEvents.events {
                    switch event {
                    case .sessionExpired:
                        // Navegar a login
                    case .tokenRefreshed:
                        // Actualizar estado
                    }
                }
            }
    }
}
```

### EventBus generico con AsyncSequence

```swift
actor EventBus {
    private var streams: [String: Any] = [:]

    func stream<E: Sendable>(for type: E.Type) -> AsyncStream<E> {
        let key = String(describing: type)
        if let existing = streams[key] as? AsyncStream<E> {
            return existing
        }
        // Crear nuevo stream...
    }

    func emit<E: Sendable>(_ event: E) {
        // Emitir al stream correspondiente
    }
}
```

**Accion**: Revisar el EventBus del sistema CQRS y verificar que use AsyncSequence. Migrar cualquier uso residual de Combine o NotificationCenter. Buscar:
- `import Combine` en archivos que no sean estrictamente necesarios
- `NotificationCenter.default` en cualquier parte del codigo
- `PassthroughSubject`, `CurrentValueSubject`
- `.sink`, `.assign`, `.store(in: &cancellables)`

## 6. Liquid Glass - Migracion a APIs Nativas

### Estado Actual del Design System

El design system del proyecto tiene componentes custom que simulan Liquid Glass:

| Componente | Descripcion |
|-----------|-------------|
| `EduLiquidGlass` | Efectos liquid glass propios con materiales y gradientes |
| `EduVisualEffects` | Efectos visuales generales (blur, vibrancy) |
| `EduShadow` | Sombras personalizadas para elevation |
| `EduShapes` | Formas customizadas (rounded rectangles, capsulas) |
| `EduGlassModifiers` | Modifiers de conveniencia para aplicar glass |

### APIs Nativas de iOS 26

Apple introdujo en iOS 26 / WWDC 2025:

- **`.glassEffect()`** - Modifier principal para aplicar el efecto Liquid Glass nativo
- **Materials actualizados** - Soporte glass integrado en el sistema de materiales
- **Tab bars con glass** - Se contraen automaticamente al hacer scroll
- **Sheets con glass** - Partial height sheets son inset con glass background por defecto
- **Lensing** - Efecto de distorsion optica que magnifica contenido debajo del glass

### Plan de Migracion

#### Paso 1: Mantener la capa de abstraccion

Conservar los nombres y la API publica de los componentes Edu* existentes. Esto permite:
- No romper ningun codigo existente que use el design system
- Mantener la consistencia del lenguaje de diseno
- Centralizar la logica de glass en un solo lugar

#### Paso 2: Re-implementar internamente con APIs nativas

```swift
// ANTES (simulado con materiales y gradientes):
struct EduLiquidGlass: ViewModifier {
    let intensity: GlassIntensity

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .overlay(
                LinearGradient(
                    colors: [.white.opacity(0.3), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.1), radius: 10)
    }
}

// DESPUES (iOS 26 nativo):
struct EduLiquidGlass: ViewModifier {
    let intensity: GlassIntensity

    func body(content: Content) -> some View {
        content
            .glassEffect()  // API nativa de iOS 26
            // Parametros adicionales segun intensity
    }
}
```

#### Paso 3: Mapear intensidades a parametros nativos

```swift
enum GlassIntensity {
    case subtle      // Glass ligero, alta transparencia
    case regular     // Glass estandar, balance visual
    case prominent   // Glass pronunciado, mas opacidad
    case solid       // Glass con fondo casi solido
}

extension GlassIntensity {
    /// Mapear a configuracion nativa de iOS 26
    var nativeConfiguration: GlassEffectConfiguration {
        switch self {
        case .subtle:     return .init(/* parametros iOS 26 */)
        case .regular:    return .init(/* parametros iOS 26 */)
        case .prominent:  return .init(/* parametros iOS 26 */)
        case .solid:      return .init(/* parametros iOS 26 */)
        }
    }
}
```

### Design Tokens a Actualizar

Revisar y actualizar segun la guia de diseno del proyecto (`iOS26/Tokens/`):

| Token Actual | Accion |
|-------------|--------|
| Colors: `.glassTinted`, `.glassContainer` | Mapear a colores nativos de glass en iOS 26 |
| Typography: `.glassOptimized` | Mantener como convenience modifier para legibilidad sobre glass |
| Spacing: `glassEdge(20)`, `glassInset(24)` | Mantener como constantes del design system |
| Elevation: `.liquidElevation()` | Combinar con `.glassEffect()` nativo para sombras correctas |
| Shapes: `LiquidRoundedRectangle` | Evaluar si iOS 26 ofrece forma equivalente nativa con lensing |

## 7. Componentes SwiftUI - Actualizaciones

### Navigation

**TabView:**
- iOS 26 tiene tab bars que se contraen automaticamente con scroll
- Verificar que `EduTabBar` aproveche este comportamiento nativo
- Si `EduTabBar` tiene animaciones custom de collapse, evaluar si la animacion nativa es suficiente
- El glass se aplica automaticamente a tab bars en iOS 26

```swift
// iOS 26 - TabView con glass automatico
TabView {
    Tab("Inicio", systemImage: "house") {
        HomeView()
    }
    Tab("Cursos", systemImage: "book") {
        CoursesView()
    }
}
// El tab bar adopta glass y collapse automaticamente
```

**NavigationSplitView:**
- Sin cambios significativos en la API
- Verificar que adopte glass automaticamente en la sidebar
- Las toolbars adoptan glass por defecto en iOS 26

### Sheets

iOS 26 cambia el comportamiento por defecto de sheets:

```swift
// iOS 26 - Sheets son inset con glass background por defecto
.sheet(isPresented: $showDetail) {
    DetailView()
    // Automaticamente: inset, glass background, bordes redondeados
}
```

**Accion**: Verificar compatibilidad con overlays existentes del design system. Si `EduSheet` aplica estilos custom, verificar que no conflicten con los estilos nativos de iOS 26.

### Lists

- Verificar que `EduListView` aproveche las mejoras automaticas de iOS 26 en listas
- Los separadores y backgrounds de listas se integran con glass automaticamente
- Evaluar si estilos custom de celdas necesitan ajustes para el nuevo contexto visual

### ScrollView

- Verificar comportamiento de `contentMargins` con glass toolbars
- El `safeAreaInset` interactua diferente con toolbars glass que se contraen

## 8. Terminologia

### Corregir referencias en codigo y documentacion

El proyecto es exclusivamente Apple. Cualquier terminologia de otras plataformas debe ser corregida:

| Incorrecto | Correcto | Notas |
|------------|----------|-------|
| dp (density-independent pixels) | points (pt) | Unidad nativa de Apple |
| Material Design | Human Interface Guidelines | Guia de diseno de Apple |
| FAB (Floating Action Button) | Toolbar button o custom floating | Apple no tiene FAB nativo |
| Column/Row (Compose) | VStack/HStack | Layout containers de SwiftUI |
| LazyColumn/LazyRow | List / ScrollView + LazyVStack | Listas en SwiftUI |
| ConstraintLayout | GeometryReader / Layout protocol | Sistema de layout de SwiftUI |
| RecyclerView | List | Lista con recycling automatico |
| Fragment | View | Componente de UI |
| Activity | Scene / WindowGroup | Contenedor de ventana |
| ViewModel (AAC) | @Observable class | Patron de observacion SwiftUI |
| LiveData | @Observable property | Binding reactivo |
| StateFlow | AsyncSequence | Stream de estado |

**Accion**: Buscar en todo el codebase y documentacion por estos terminos y corregirlos.

## 9. Checklist de Modernizacion

### Deployment Target
- [ ] Actualizar deployment target a iOS 26 en `Package.swift` raiz
- [ ] Actualizar deployment target a macOS 26 en `Package.swift` raiz
- [ ] Actualizar deployment target en cada modulo SPM individual
- [ ] Verificar que Xcode 26+ esta instalado en todos los equipos de desarrollo

### Concurrencia
- [ ] Habilitar strict concurrency checking en todos los targets
- [ ] Auditar y eliminar anotaciones `@MainActor` redundantes (por MainActor by default)
- [ ] Verificar `Sendable` conformance en todos los modelos que cruzan boundaries
- [ ] Resolver todas las advertencias de concurrencia del compilador

### Patron de Observacion
- [ ] Auditar y migrar `@Published` / `@ObservableObject` a `@Observable`
- [ ] Auditar y migrar `@StateObject` a `@State`
- [ ] Auditar y migrar `@ObservedObject` a parametro directo o `@Bindable`
- [ ] Auditar y migrar `@EnvironmentObject` a `@Environment`
- [ ] Eliminar `import Combine` donde ya no sea necesario

### Eventos Reactivos
- [ ] Auditar y migrar `Combine` publishers a `AsyncSequence`
- [ ] Auditar y migrar `NotificationCenter` a `AsyncStream`
- [ ] Migrar `PassthroughSubject` / `CurrentValueSubject` a actors con `AsyncStream`
- [ ] Verificar que el EventBus del sistema CQRS use `AsyncSequence`
- [ ] Eliminar `AnyCancellable` y `cancellables` sets

### Liquid Glass
- [ ] Re-implementar `EduLiquidGlass` con `.glassEffect()` nativo
- [ ] Re-implementar `EduVisualEffects` con APIs nativas de iOS 26
- [ ] Actualizar `EduShadow` para compatibilidad con glass
- [ ] Verificar `EduShapes` con formas nativas de iOS 26
- [ ] Actualizar design tokens de colores para glass nativo
- [ ] Actualizar design tokens de elevation para glass nativo

### Componentes SwiftUI
- [ ] Verificar que `EduTabBar` funcione con glass y collapse nativo
- [ ] Verificar que `NavigationSplitView` adopte glass automaticamente
- [ ] Verificar que sheets funcionen con inset glass por defecto
- [ ] Verificar que listas se integren con glass correctamente
- [ ] Eliminar `UIDevice.current.userInterfaceIdiom` y usar `@Environment(\.horizontalSizeClass)`
- [ ] Eliminar `AppDelegate` si no se necesita y usar `@main App` puro

### Testing y DemoApp
- [ ] Verificar que todos los tests unitarios compilen con iOS 26 target
- [ ] Verificar que todos los tests de UI compilen con iOS 26 target
- [ ] Actualizar DemoApp para demostrar Dynamic UI con glass nativo
- [ ] Agregar previews con glass para los componentes principales del design system

### Terminologia
- [ ] Buscar y corregir terminologia incorrecta en codigo fuente
- [ ] Buscar y corregir terminologia incorrecta en documentacion
- [ ] Buscar y corregir terminologia incorrecta en comentarios de codigo
