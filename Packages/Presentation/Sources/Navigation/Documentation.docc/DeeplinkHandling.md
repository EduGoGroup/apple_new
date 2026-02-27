# Deep Link Handling

Manejo completo de deep links, URL schemes, Universal Links y notificaciones push.

## Visión General

El módulo **Navigation** proporciona un sistema completo de deep linking que permite navegar a pantallas específicas desde:
- **URL Schemes**: `edugo://dashboard`
- **Universal Links**: `https://edugo.app/dashboard`
- **Push Notifications**: Payloads con información de navegación

## Componentes de Deep Linking

### 1. Deeplink Enum

El enum `Deeplink` representa todas las rutas soportadas:

```swift
public enum Deeplink: Equatable, Sendable {
    case dashboard
    case materialDetail(materialId: UUID)
    case assessment(assessmentId: UUID, userId: UUID)
    case profile(userId: UUID)
    case settings
    
    /// Convierte el deeplink a un Screen para navegación
    public func toScreen() -> Screen {
        switch self {
        case .dashboard:
            return .dashboard
        case .materialDetail(let materialId):
            return .materialDetail(materialId: materialId)
        case .assessment(let assessmentId, let userId):
            return .assessment(assessmentId: assessmentId, userId: userId)
        case .profile(let userId):
            return .profile(userId: userId)
        case .settings:
            return .settings
        }
    }
    
    /// Genera el path de URL para el deeplink
    public var path: String {
        switch self {
        case .dashboard:
            return "/dashboard"
        case .materialDetail(let materialId):
            return "/materials/\(materialId.uuidString)"
        case .assessment(let assessmentId, let userId):
            return "/assessments/\(assessmentId.uuidString)?userId=\(userId.uuidString)"
        case .profile(let userId):
            return "/profile/\(userId.uuidString)"
        case .settings:
            return "/settings"
        }
    }
}
```

### 2. DeeplinkParser

El `DeeplinkParser` parsea URLs y las convierte en `Deeplink`:

```swift
public struct DeeplinkParser {
    public init() {}
    
    /// Parsea una URL y retorna el Deeplink correspondiente
    public static func parse(_ url: URL) -> Deeplink? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }
        
        // Extraer path components
        let pathComponents: [String]
        if components.scheme == "edugo" || components.scheme == "edugo-dev" {
            // URL Scheme: edugo://dashboard
            // El host contiene la ruta
            var parts: [String] = []
            if let host = components.host {
                parts.append(host)
            }
            let pathParts = components.path.split(separator: "/").map(String.init)
            parts.append(contentsOf: pathParts)
            pathComponents = parts
        } else {
            // Universal Link: https://edugo.app/dashboard
            // El path contiene la ruta
            pathComponents = components.path.split(separator: "/").map(String.init)
        }
        
        guard !pathComponents.isEmpty else {
            return nil
        }
        
        // Parsear basado en el primer componente
        switch pathComponents[0] {
        case "dashboard":
            return .dashboard
            
        case "materials":
            guard pathComponents.count > 1,
                  let materialId = UUID(uuidString: pathComponents[1]) else {
                return nil
            }
            return .materialDetail(materialId: materialId)
            
        case "assessments":
            guard pathComponents.count > 1,
                  let assessmentId = UUID(uuidString: pathComponents[1]),
                  let queryItems = components.queryItems,
                  let userIdString = queryItems.first(where: { $0.name == "userId" })?.value,
                  let userId = UUID(uuidString: userIdString) else {
                return nil
            }
            return .assessment(assessmentId: assessmentId, userId: userId)
            
        case "profile":
            guard pathComponents.count > 1,
                  let userId = UUID(uuidString: pathComponents[1]) else {
                return nil
            }
            return .profile(userId: userId)
            
        case "settings":
            return .settings
            
        default:
            return nil
        }
    }
}
```

**Diferencia entre URL Schemes y Universal Links:**

```
URL Scheme:
  edugo://dashboard
  ├── scheme: "edugo"
  ├── host: "dashboard"      ← Ruta aquí
  └── path: ""

Universal Link:
  https://edugo.app/dashboard
  ├── scheme: "https"
  ├── host: "edugo.app"
  └── path: "/dashboard"     ← Ruta aquí
```

### 3. DeeplinkHandler

El `DeeplinkHandler` gestiona la navegación desde deep links:

```swift
@MainActor
@Observable
public final class DeeplinkHandler {
    private let appCoordinator: AppCoordinator
    private var pendingDeeplink: Deeplink?
    
    public init(appCoordinator: AppCoordinator) {
        self.appCoordinator = appCoordinator
    }
    
    /// Maneja una URL y navega al destino correspondiente
    public func handle(_ url: URL) -> Bool {
        guard let deeplink = DeeplinkParser.parse(url) else {
            return false
        }
        
        // Si el usuario no está autenticado, guardar el deeplink
        guard appCoordinator.isAuthenticated else {
            pendingDeeplink = deeplink
            return true
        }
        
        // Navegar al screen
        let screen = deeplink.toScreen()
        appCoordinator.navigate(to: screen)
        return true
    }
    
    /// Maneja navegación desde push notification
    public func handlePushNotification(userInfo: [AnyHashable: Any]) -> Bool {
        guard let deeplinkString = userInfo["deeplink"] as? String,
              let url = URL(string: deeplinkString) else {
            return false
        }
        
        return handle(url)
    }
    
    /// Navega al deeplink pendiente después del login
    public func handlePostLoginNavigation() {
        guard let deeplink = pendingDeeplink else {
            return
        }
        
        pendingDeeplink = nil
        let screen = deeplink.toScreen()
        appCoordinator.navigate(to: screen)
    }
}
```

## Configuración en la Aplicación

### URL Schemes

#### 1. Configurar Info.plist

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>edugo</string>
            <string>edugo-dev</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.edugo.app</string>
    </dict>
</array>
```

#### 2. Manejar URL en App

```swift
@main
struct EduGoApp: App {
    let appCoordinator: AppCoordinator
    let deeplinkHandler: DeeplinkHandler
    
    init() {
        let mediator = Mediator()
        let eventBus = EventBus()
        
        self.appCoordinator = AppCoordinator(
            mediator: mediator,
            eventBus: eventBus
        )
        
        self.deeplinkHandler = DeeplinkHandler(
            appCoordinator: appCoordinator
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
            .onOpenURL { url in
                _ = deeplinkHandler.handle(url)
            }
        }
    }
}
```

### Universal Links

#### 1. Configurar Associated Domains

En Xcode: Target > Signing & Capabilities > Associated Domains

```
applinks:edugo.app
applinks:dev.edugo.app
```

#### 2. Configurar Apple App Site Association (AASA)

En el servidor web, servir el archivo `.well-known/apple-app-site-association`:

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.com.edugo.app",
        "paths": [
          "/dashboard",
          "/materials/*",
          "/assessments/*",
          "/profile/*",
          "/settings"
        ]
      }
    ]
  }
}
```

#### 3. Manejar Universal Link en App

```swift
.onOpenURL { url in
    // Universal Links y URL Schemes usan el mismo handler
    _ = deeplinkHandler.handle(url)
}
```

### Push Notifications

#### 1. Configurar Payload

El backend debe enviar notificaciones con deeplink:

```json
{
  "aps": {
    "alert": {
      "title": "Nuevo Material",
      "body": "Se ha subido un nuevo material"
    },
    "sound": "default"
  },
  "deeplink": "edugo://materials/123e4567-e89b-12d3-a456-426614174000"
}
```

#### 2. Manejar Notificación

```swift
import UserNotifications

@main
struct EduGoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // ...
}

class AppDelegate: NSObject, UIApplicationDelegate {
    var deeplinkHandler: DeeplinkHandler?
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        _ = deeplinkHandler?.handlePushNotification(userInfo: userInfo)
        completionHandler()
    }
}
```

## Flujo de Deep Linking

### Caso 1: Usuario Autenticado

```
1. Usuario hace clic en: edugo://materials/123
2. iOS abre la app
3. .onOpenURL se dispara
4. DeeplinkHandler.handle(url) parsea la URL
5. DeeplinkParser retorna .materialDetail(materialId: 123)
6. appCoordinator.isAuthenticated = true
7. AppCoordinator navega a .materialDetail(materialId: 123)
8. SwiftUI renderiza MaterialDetailView
```

### Caso 2: Usuario No Autenticado

```
1. Usuario hace clic en: edugo://materials/123
2. iOS abre la app
3. .onOpenURL se dispara
4. DeeplinkHandler.handle(url) parsea la URL
5. DeeplinkParser retorna .materialDetail(materialId: 123)
6. appCoordinator.isAuthenticated = false
7. DeeplinkHandler guarda el deeplink en pendingDeeplink
8. Usuario ve LoginView
9. Usuario se autentica exitosamente
10. AuthCoordinator llama deeplinkHandler.handlePostLoginNavigation()
11. DeeplinkHandler navega al deeplink guardado
12. SwiftUI renderiza MaterialDetailView
```

## Diagrama de Flujo

```
┌─────────────────────────────────────────────────────────────┐
│           URL / Universal Link / Push Notification          │
│  edugo://materials/123e4567-e89b-12d3-a456-426614174000     │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                 .onOpenURL { url in ... }                    │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│            DeeplinkHandler.handle(url)                       │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│              DeeplinkParser.parse(url)                       │
│  Returns: .materialDetail(materialId: UUID)                  │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
                   Authenticated?
                        │
        ┌───────────────┴───────────────┐
        │                               │
        ▼ YES                           ▼ NO
┌─────────────────┐          ┌──────────────────────┐
│ Navigate to     │          │ Save to              │
│ .materialDetail │          │ pendingDeeplink      │
└─────────────────┘          └──────────┬───────────┘
        │                               │
        │                               ▼
        │                    ┌──────────────────────┐
        │                    │ Show LoginView       │
        │                    └──────────┬───────────┘
        │                               │
        │                               ▼
        │                    ┌──────────────────────┐
        │                    │ User logs in         │
        │                    └──────────┬───────────┘
        │                               │
        │                               ▼
        │                    ┌──────────────────────┐
        │                    │ handlePostLogin      │
        │                    │ Navigation()         │
        │                    └──────────┬───────────┘
        │                               │
        └───────────────┬───────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│           AppCoordinator.navigate(to: screen)                │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│           SwiftUI renders MaterialDetailView                 │
└─────────────────────────────────────────────────────────────┘
```

## Ejemplos de URLs Soportadas

### URL Schemes

```swift
// Dashboard
edugo://dashboard

// Material detail
edugo://materials/123e4567-e89b-12d3-a456-426614174000

// Assessment
edugo://assessments/123e4567-e89b-12d3-a456-426614174000?userId=987fcdeb-51a2-43f7-8ec4-123456789abc

// Profile
edugo://profile/987fcdeb-51a2-43f7-8ec4-123456789abc

// Settings
edugo://settings
```

### Universal Links

```swift
// Dashboard
https://edugo.app/dashboard

// Material detail
https://edugo.app/materials/123e4567-e89b-12d3-a456-426614174000

// Assessment
https://edugo.app/assessments/123e4567-e89b-12d3-a456-426614174000?userId=987fcdeb-51a2-43f7-8ec4-123456789abc

// Profile
https://edugo.app/profile/987fcdeb-51a2-43f7-8ec4-123456789abc

// Settings
https://edugo.app/settings
```

## Testing Deep Links

### Simulador iOS

```bash
# URL Scheme
xcrun simctl openurl booted "edugo://dashboard"

# Universal Link
xcrun simctl openurl booted "https://edugo.app/materials/123e4567-e89b-12d3-a456-426614174000"
```

### Device

Desde Safari o Notes, crear un link y hacer clic.

### Unit Tests

```swift
func testParseValidMaterialDeeplink() throws {
    let url = URL(string: "edugo://materials/123e4567-e89b-12d3-a456-426614174000")!
    let deeplink = DeeplinkParser.parse(url)
    
    XCTAssertEqual(
        deeplink,
        .materialDetail(materialId: UUID(uuidString: "123e4567-e89b-12d3-a456-426614174000")!)
    )
}

func testHandleDeeplinkWhenAuthenticated() async throws {
    let appCoordinator = AppCoordinator(mediator: mockMediator, eventBus: mockEventBus)
    appCoordinator.isAuthenticated = true
    
    let handler = DeeplinkHandler(appCoordinator: appCoordinator)
    let url = URL(string: "edugo://dashboard")!
    
    let handled = handler.handle(url)
    
    XCTAssertTrue(handled)
    XCTAssertEqual(appCoordinator.navigationPath.count, 1)
}

func testHandleDeeplinkWhenNotAuthenticatedSavesPending() async throws {
    let appCoordinator = AppCoordinator(mediator: mockMediator, eventBus: mockEventBus)
    appCoordinator.isAuthenticated = false
    
    let handler = DeeplinkHandler(appCoordinator: appCoordinator)
    let url = URL(string: "edugo://dashboard")!
    
    let handled = handler.handle(url)
    
    XCTAssertTrue(handled)
    XCTAssertEqual(appCoordinator.navigationPath.count, 0)
    
    // Simular login
    appCoordinator.isAuthenticated = true
    handler.handlePostLoginNavigation()
    
    XCTAssertEqual(appCoordinator.navigationPath.count, 1)
}
```

## Mejores Prácticas

### 1. Validar UUIDs

Siempre validar que los UUIDs en URLs sean válidos:

```swift
guard let materialId = UUID(uuidString: pathComponents[1]) else {
    return nil // UUID inválido
}
```

### 2. Guardar Deep Links Pendientes

Si el usuario no está autenticado, guardar el deeplink para después:

```swift
guard appCoordinator.isAuthenticated else {
    pendingDeeplink = deeplink
    return true
}
```

### 3. Limpiar Deep Links Pendientes

Después de navegar, limpiar el deeplink pendiente:

```swift
public func handlePostLoginNavigation() {
    guard let deeplink = pendingDeeplink else { return }
    pendingDeeplink = nil // Limpiar
    appCoordinator.navigate(to: deeplink.toScreen())
}
```

### 4. Manejo de Errores

Retornar `false` si el deeplink no puede ser manejado:

```swift
public func handle(_ url: URL) -> Bool {
    guard let deeplink = DeeplinkParser.parse(url) else {
        return false // URL no soportada
    }
    // ...
}
```

## Temas Relacionados

- <doc:NavigationArchitecture>
- <doc:CoordinatorPattern>
- <doc:BestPractices>
