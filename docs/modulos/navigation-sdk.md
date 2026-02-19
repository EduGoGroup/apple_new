# Navigation SDK

**Estado de extraccion:** Parcial (80% framework generico, 20% implementaciones EduGo)
**Dependencias externas:** SwiftUI (framework Apple)
**Origen en proyecto:** `Packages/Presentation/Sources/Navigation/`

---

## a) Que hace este SDK

Framework de navegacion basado en el patron Coordinator para aplicaciones SwiftUI. Proporciona:

### Coordinadores
- **FeatureCoordinator**: Protocolo base para coordinadores de feature
- **AppCoordinator**: Coordinador principal con `NavigationPath` type-safe, modal presentation (sheets/fullScreenCover) y estado observable

### Deep Linking
- **DeeplinkParser**: Parser generico de URLs con soporte para URL schemes y universal links
- **DeeplinkHandler**: Gestion de deeplinks desde notificaciones push, URL schemes y universal links

### Uso tipico por el consumidor

```swift
// 1. Definir pantallas propias
enum MiPantalla: Hashable, Sendable {
    case inicio
    case detalle(id: UUID)
    case perfil(userId: UUID)
    case configuracion
}

// 2. Crear coordinador principal
let coordinator = AppCoordinator()

// 3. Navegar
coordinator.navigate(to: MiPantalla.detalle(id: itemId))
coordinator.presentSheet(MiPantalla.perfil(userId: userId))
coordinator.pop()
coordinator.popToRoot()

// 4. Deep links
let deeplink = DeeplinkParser.parse(url: incomingURL)
coordinator.handle(deeplink)
```

---

## b) Compila como proyecto independiente?

**La parte framework: Casi.** El framework base (FeatureCoordinator, AppCoordinator core) es generico pero tiene integracion con:

- **EventBus** (de EduDomain): El AppCoordinator se suscribe a eventos de dominio para navegar automaticamente
- **Screen enum**: Define las pantallas especificas de EduGo
- **Deeplink enum**: Define las rutas especificas

**Solucion**: Hacer el AppCoordinator generico sobre un tipo `Screen: Hashable` y el EventBus opcional.

---

## c) Dependencias si se extrae

### Framework generico:

| Dependencia | Tipo | Notas |
|---|---|---|
| SwiftUI | Framework Apple | NavigationPath, NavigationStack |

### Dependencias opcionales:

| Dependencia | Tipo | Notas |
|---|---|---|
| EventBus | Del CQRS SDK | Para navegacion reactiva por eventos. Abstraible |

---

## d) Que se fusionaria con este SDK

Dos opciones:

**Opcion A - SDK independiente**: Navigation SDK solo, con el framework de coordinadores + deeplinks. Ligero y enfocado.

**Opcion B - Fusionar con UI Components SDK**: Crear un mega-SDK de "Presentation" que incluya DesignSystem + Components + Forms + Navigation. Tiene sentido si el consumidor siempre va a usar todo junto.

---

## e) Interfaces publicas (contrato del SDK)

### Coordinadores

```swift
public protocol FeatureCoordinator: AnyObject, Observable {
    associatedtype Screen: Hashable
    var navigationPath: NavigationPath { get set }
    func navigate(to screen: Screen)
    func pop()
    func popToRoot()
}

@MainActor @Observable
public class AppCoordinator<Screen: Hashable & Sendable> {
    public var navigationPath: NavigationPath
    public var presentedSheet: Screen?
    public var presentedFullScreen: Screen?

    public func navigate(to screen: Screen)
    public func presentSheet(_ screen: Screen)
    public func presentFullScreen(_ screen: Screen)
    public func dismissSheet()
    public func pop()
    public func popToRoot()
}
```

### Deep Links

```swift
public struct DeeplinkParser<Screen: Hashable> {
    public init(routes: [String: (URL) -> Screen?])
    public func parse(url: URL) -> Screen?
}

public class DeeplinkHandler<Screen: Hashable> {
    public init(parser: DeeplinkParser<Screen>, coordinator: AppCoordinator<Screen>)
    public func handle(url: URL) -> Bool
    public func handle(notification: [AnyHashable: Any]) -> Bool
}
```

---

## f) Que necesita personalizar el consumidor

### Implementar obligatoriamente

1. **Su enum `Screen`**: Definir todas las pantallas de su app
2. **Su `DeeplinkParser` routes**: Mapear URLs a pantallas
3. **Sus FeatureCoordinators**: Si necesita sub-coordinadores por feature

### Que se lleva tal cual vs que adapta

| Componente | Se lleva tal cual? | Adaptacion necesaria |
|---|---|---|
| FeatureCoordinator protocol | Si | - |
| AppCoordinator (genericizado) | Si | Hacerlo generico sobre Screen |
| DeeplinkParser | Si | Configurar rutas propias |
| DeeplinkHandler | Si | - |
| Screen enum | **No** | Pantallas de EduGo (.login, .dashboard, etc.) |
| Deeplink enum | **No** | Rutas de EduGo (/materials, /assessments) |
| CoordinatorFactory | **No** | Crea coordinadores de features de EduGo |
| AuthCoordinator, MaterialsCoordinator, etc. | **No** | Coordinadores de features de EduGo |

### Cambios necesarios para portabilidad

1. **Genericizar AppCoordinator**: Hacerlo generico sobre `<Screen: Hashable & Sendable>` en lugar de usar el enum concreto
2. **Hacer EventBus opcional**: Inyectar como dependencia opcional, no hard-wired
3. **Eliminar Screen, Deeplink, CoordinatorFactory concretos**: Son de EduGo
4. **Eliminar feature coordinators concretos**: AuthCoordinator, MaterialsCoordinator, etc.
