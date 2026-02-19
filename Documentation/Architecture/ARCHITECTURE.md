# Arquitectura del Workspace EduGo Apple Modules

**Decisiones de diseño, justificaciones técnicas y trade-offs**

---

## 📐 Principios de Diseño

### 1. Clean Architecture + Protocol-Oriented Programming

**Decisión**: Implementar arquitectura en capas con inversión de dependencias.

**Justificación**:
- **Testabilidad**: Protocolos permiten inyectar mocks/stubs sin cambiar código de producción
- **Mantenibilidad**: Separación clara de responsabilidades (SRP)
- **Extensibilidad**: Nuevas implementaciones sin modificar código existente (OCP)
- **Reusabilidad**: Componentes de lower tiers reutilizables en múltiples features

**Implementación**:
```swift
// Protocolo en TIER-1 (abstracción)
public protocol UserRepository: Sendable {
    func fetchUser(id: UUID) async throws -> User
}

// Implementación real en TIER-1 (Internal)
final class DefaultUserRepository: UserRepository {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    func fetchUser(id: UUID) async throws -> User {
        let dto = try await networkClient.request(.getUser(id))
        return UserMapper.toDomain(dto)
    }
}

// Mock en Tests
final class MockUserRepository: UserRepository {
    var fetchUserResult: Result<User, Error> = .failure(TestError.notSet)

    func fetchUser(id: UUID) async throws -> User {
        try fetchUserResult.get()
    }
}
```

**Trade-offs**:
- ✅ **Pro**: Código altamente testable y mantenible
- ✅ **Pro**: Fácil reemplazar implementaciones (ej. mock NetworkClient con local cache)
- ❌ **Con**: Más boilerplate (protocolos + implementaciones + mocks)
- ❌ **Con**: Curva de aprendizaje para devs juniors

---

### 2. Arquitectura de 4 Tiers

**Decisión**: Organizar código en 4 capas jerárquicas (TIER-0 a TIER-3).

**Justificación**:
```
┌─────────────────────────────────────────────────────┐
│ TIER-3: Features (UI + ViewModels)                  │
│  - SwiftUI views, ViewModels, Navigation            │
│  - Depende de: Services (TIER-2)                    │
│  - Ejemplo: LoginView, DashboardViewModel           │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│ TIER-2: Domain Services (Orquestación)              │
│  - Casos de uso, lógica de negocio compleja         │
│  - Coordina múltiples repositories                  │
│  - Ejemplo: AuthService.login() llama UserRepo +    │
│              KeychainManager + Logger                │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│ TIER-1: Data Layer (Repositorios + Clientes)        │
│  - CRUD de entidades, HTTP calls, persistencia      │
│  - Implementaciones concretas de protocolos         │
│  - Ejemplo: NetworkClient, UserRepository,          │
│              KeychainManager                         │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│ TIER-0: Foundation (Modelos + Utilidades)           │
│  - Modelos de dominio (User, Course, AuthToken)     │
│  - Extensiones de Foundation, helpers               │
│  - Protocolos de repositorios (sin implementación)  │
│  - SIN dependencias internas                        │
└─────────────────────────────────────────────────────┘
```

**Reglas de Dependencias**:
1. **Flujo unidireccional**: TIER-3 → TIER-2 → TIER-1 → TIER-0
2. **TIER-0 es foundation**: No puede importar ningún tier superior
3. **No saltar tiers**: TIER-3 no debe llamar directamente TIER-1 (usar TIER-2 como intermediario)
4. **No dependencias circulares**: Entre módulos del mismo tier

**Ejemplo de violación (PROHIBIDO)**:
```swift
// ❌ MAL: LoginViewModel (TIER-3) llama directamente UserRepository (TIER-1)
@MainActor
final class LoginViewModel: ObservableObject {
    private let userRepository: UserRepository // ❌ Saltar TIER-2

    func login() async {
        let user = try await userRepository.login(...) // ❌ Lógica debería estar en AuthService
    }
}

// ✅ BIEN: LoginViewModel usa AuthService (TIER-2)
@MainActor
final class LoginViewModel: ObservableObject {
    private let authService: AuthService // ✅ Usar TIER-2

    func login() async {
        let user = try await authService.login(...) // ✅ AuthService orquesta repos
    }
}
```

**Trade-offs**:
- ✅ **Pro**: Escalabilidad (agregar features sin afectar data layer)
- ✅ **Pro**: Testabilidad (cada tier se testea aisladamente)
- ✅ **Pro**: Claridad (responsabilidades bien definidas)
- ❌ **Con**: Más archivos y módulos (overhead inicial)
- ❌ **Con**: Puede parecer over-engineering en proyectos pequeños

---

### 3. Swift Package Manager (SPM) Multi-Módulo

**Decisión**: Usar un solo `Package.swift` con múltiples productos/targets.

**Justificación**:
- **Compilación incremental**: Cambios en TIER-3 no recompilan TIER-0
- **Encapsulación**: Acceso `internal` previene uso accidental de APIs privadas
- **Reutilización**: Módulos de lower tiers pueden usarse en otros proyectos
- **Compilación paralela**: Xcode puede compilar módulos independientes en paralelo

**Estructura de `Package.swift`**:
```swift
// Package.swift
let package = Package(
    name: "EduGoModules",
    platforms: [.iOS(.v26), .macOS(.v15)],
    products: [
        // TIER-0
        .library(name: "EduFoundation", targets: ["EduFoundation"]),

        // TIER-1
        .library(name: "EduNetworking", targets: ["EduNetworking"]),
        .library(name: "EduPersistence", targets: ["EduPersistence"]),
        .library(name: "EduRepositories", targets: ["EduRepositories"]),

        // TIER-2
        .library(name: "EduAuthService", targets: ["EduAuthService"]),
        .library(name: "EduCourseService", targets: ["EduCourseService"]),

        // TIER-3
        .library(name: "EduAuthFeature", targets: ["EduAuthFeature"]),
        .library(name: "EduDashboardFeature", targets: ["EduDashboardFeature"]),
    ],
    targets: [
        // TIER-0
        .target(name: "EduFoundation", dependencies: []),

        // TIER-1
        .target(name: "EduNetworking", dependencies: ["EduFoundation"]),
        .target(name: "EduPersistence", dependencies: ["EduFoundation"]),
        .target(name: "EduRepositories", dependencies: [
            "EduFoundation",
            "EduNetworking",
            "EduPersistence"
        ]),

        // TIER-2
        .target(name: "EduAuthService", dependencies: [
            "EduFoundation",
            "EduRepositories"
        ]),
        .target(name: "EduCourseService", dependencies: [
            "EduFoundation",
            "EduRepositories"
        ]),

        // TIER-3
        .target(name: "EduAuthFeature", dependencies: [
            "EduFoundation",
            "EduAuthService"
        ]),
        .target(name: "EduDashboardFeature", dependencies: [
            "EduFoundation",
            "EduCourseService"
        ]),

        // Tests (espejo de estructura)
        .testTarget(name: "EduFoundationTests", dependencies: ["EduFoundation"]),
        .testTarget(name: "EduNetworkingTests", dependencies: ["EduNetworking"]),
        // ... más tests
    ]
)
```

**Trade-offs**:
- ✅ **Pro**: Compilación incremental (ahorra tiempo)
- ✅ **Pro**: Dependencias explícitas (detecta ciclos en build time)
- ✅ **Pro**: Reutilización fácil (importar solo lo necesario)
- ❌ **Con**: Setup inicial más complejo
- ❌ **Con**: Refactors de módulos pueden ser disruptivos

**Alternativa considerada**: Monolito (un solo target)
- ❌ Rechazada porque recompila todo el código en cada cambio
- ❌ No previene dependencias circulares

---

### 4. Swift 6.2 Strict Concurrency

**Decisión**: Habilitar strict concurrency checking en todos los módulos.

**Justificación**:
- **Thread-safety**: Detecta data races en compile-time
- **Modernidad**: Aprovechar `async/await` y `actor` model
- **Mantenibilidad**: Código concurrente más predecible

**Configuración obligatoria**:
```swift
// En cada target de Package.swift
swiftSettings: [
    .enableUpcomingFeature("StrictConcurrency"),
    .enableUpcomingFeature("BareSlashRegexLiterals")
]
```

**Patrones obligatorios**:

#### 4.1 ViewModels con `@MainActor`
```swift
@MainActor
public final class LoginViewModel: ObservableObject {
    @Published private(set) var state: State = .idle

    private let authService: AuthService

    public init(authService: AuthService) {
        self.authService = authService
    }

    public func login(email: String, password: String) async {
        state = .loading

        do {
            let user = try await authService.login(email: email, password: password)
            state = .success(user)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
```

#### 4.2 Servicios con `actor` para estado compartido
```swift
public actor AuthStore {
    private var currentUser: User?
    private var authToken: AuthToken?

    public func setUser(_ user: User, token: AuthToken) {
        self.currentUser = user
        self.authToken = token
    }

    public func getUser() -> User? {
        currentUser
    }

    public func logout() {
        currentUser = nil
        authToken = nil
    }
}
```

#### 4.3 Modelos con `Sendable`
```swift
public struct User: Sendable, Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let email: String

    public init(id: UUID, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }
}
```

#### 4.4 Protocolos de repositorios con `Sendable`
```swift
public protocol UserRepository: Sendable {
    func fetchUser(id: UUID) async throws -> User
    func updateUser(_ user: User) async throws
}
```

**Trade-offs**:
- ✅ **Pro**: Elimina clases enteras de bugs (data races)
- ✅ **Pro**: Código concurrente más legible (`async/await` vs callbacks)
- ❌ **Con**: Curva de aprendizaje (actor isolation, Sendable)
- ❌ **Con**: Algunos patrones legacy requieren refactor (`@unchecked Sendable`)

**Lista negra de atributos** (requieren justificación escrita):
- `@unchecked Sendable` → Solo con auditoría thread-safety documentada
- `@preconcurrency import` → Puente temporal para deps legacy (crear ticket)
- `nonisolated(unsafe)` → Casos extremos con tests e invariantes documentados

---

### 5. Cero Dependencias Externas

**Decisión**: No usar paquetes de terceros (solo frameworks del sistema).

**Justificación**:
- **Seguridad**: No dependemos de mantenedores externos
- **Estabilidad**: No hay breaking changes inesperados
- **Tamaño binario**: Reducir footprint de la app
- **Control total**: Podemos auditar/modificar código

**Frameworks del sistema permitidos**:
- `Foundation` → Tipos base, Date, URL, JSONEncoder
- `Network.framework` → HTTP/2, TLS, socket networking
- `Security` → Keychain, certificates
- `os` → `os.Logger` para logging estructurado
- `SwiftUI` → UI framework
- `Combine` → Reactive programming (`@Published`)

**Ejemplo de implementación propia (sin Alamofire)**:
```swift
// Sources/TIER-1/EduNetworking/Internal/URLSessionClient.swift
final class URLSessionClient: NetworkClient {
    private let session: URLSession

    init(configuration: URLSessionConfiguration = .default) {
        self.session = URLSession(configuration: configuration)
    }

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let urlRequest = try endpoint.asURLRequest()
        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }

        return try await CodableSerializer.dtoSerializer.decode(T.self, from: data)
    }
}
```

**Trade-offs**:
- ✅ **Pro**: Control total, sin dependencias de terceros
- ✅ **Pro**: Binario más pequeño
- ✅ **Pro**: Sin breaking changes inesperados
- ❌ **Con**: Más código a mantener (reinventar rueda en algunos casos)
- ❌ **Con**: No aprovechar optimizaciones de libs populares (ej. Alamofire retries)

**Alternativa considerada**: Usar Alamofire + Kingfisher + SwiftKeychainWrapper
- ❌ Rechazada por dependencias externas y tamaño binario

---

## 🧱 Decisiones Específicas por Tier

### TIER-0: Foundation

**Responsabilidades**:
- Modelos de dominio (`User`, `Course`, `AuthToken`)
- Extensiones de Foundation (`String+Validation`, `Date+Format`)
- Protocolos de repositorios (sin implementación)
- Tipos de error (`AuthError`, `NetworkError`)

**Reglas**:
- ✅ Puede importar solo frameworks del sistema (`Foundation`, `os`)
- ❌ NO puede importar ningún tier superior
- ✅ Todos los modelos deben ser `Sendable`
- ✅ Todos los tipos públicos deben tener DocC comments

**Ejemplo de modelo**:
```swift
/// Representa un usuario autenticado en el sistema.
///
/// Este modelo es inmutable y thread-safe (Sendable).
public struct User: Sendable, Identifiable, Codable {
    /// Identificador único del usuario.
    public let id: UUID

    /// Nombre completo del usuario.
    public let name: String

    /// Email del usuario (usado para login).
    public let email: String

    /// Inicializa un nuevo usuario.
    ///
    /// - Parameters:
    ///   - id: Identificador único
    ///   - name: Nombre completo
    ///   - email: Email del usuario
    public init(id: UUID, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }
}
```

---

### TIER-1: Data Layer

**Responsabilidades**:
- Implementaciones de repositorios (`DefaultUserRepository`)
- Clientes de red (`URLSessionClient`)
- Gestores de persistencia (`KeychainManager`, `UserDefaultsManager`)
- Mappers (DTO → Domain model)

**Reglas**:
- ✅ Puede importar TIER-0 y frameworks del sistema
- ❌ NO puede importar TIER-2 o TIER-3
- ✅ Implementaciones deben estar en carpeta `Internal/`
- ✅ APIs públicas deben ser protocolos (definidos en TIER-0)

**Estructura típica**:
```
Sources/TIER-1/EduRepositories/
├── Public/
│   └── (vacío, protocolos están en TIER-0)
└── Internal/
    ├── UserRepository/
    │   ├── DefaultUserRepository.swift
    │   └── UserMapper.swift
    ├── CourseRepository/
    │   ├── DefaultCourseRepository.swift
    │   └── CourseMapper.swift
    └── DTOs/
        ├── UserDTO.swift
        └── CourseDTO.swift
```

**Ejemplo de mapper**:
```swift
// Sources/TIER-1/EduRepositories/Internal/UserRepository/UserMapper.swift
enum UserMapper {
    static func toDomain(_ dto: UserDTO) -> User {
        User(
            id: dto.id,
            name: dto.fullName,
            email: dto.emailAddress
        )
    }

    static func toDTO(_ user: User) -> UserDTO {
        UserDTO(
            id: user.id,
            fullName: user.name,
            emailAddress: user.email
        )
    }
}
```

---

### TIER-2: Domain Services

**Responsabilidades**:
- Casos de uso complejos (login, refresh token, búsqueda de cursos)
- Orquestación de múltiples repositorios
- Lógica de negocio (validaciones, transformaciones)

**Reglas**:
- ✅ Puede importar TIER-0, TIER-1 y frameworks del sistema
- ❌ NO puede importar TIER-3
- ✅ Servicios deben ser `@MainActor` si mantienen estado UI-related
- ✅ Inyectar repositorios por constructor (dependency injection)

**Ejemplo de servicio**:
```swift
// Sources/TIER-2/EduAuthService/Public/AuthService.swift
@MainActor
public final class AuthService: ObservableObject {
    @Published private(set) public var currentUser: User?

    private let userRepository: UserRepository
    private let keychainManager: KeychainManager
    private let logger: Logger

    public init(
        userRepository: UserRepository,
        keychainManager: KeychainManager,
        logger: Logger = Logger(subsystem: "com.edugo", category: "Auth")
    ) {
        self.userRepository = userRepository
        self.keychainManager = keychainManager
        self.logger = logger
    }

    public func login(email: String, password: String) async throws -> User {
        logger.info("Login attempt for email: \(email)")

        let user = try await userRepository.login(email: email, password: password)

        // Almacenar token en Keychain
        if let token = user.authToken {
            try await keychainManager.save(token, forKey: "auth_token")
        }

        currentUser = user
        logger.info("Login successful for user: \(user.id)")

        return user
    }

    public func logout() async throws {
        logger.info("Logout for user: \(currentUser?.id ?? UUID())")

        try await keychainManager.delete(forKey: "auth_token")
        currentUser = nil
    }
}
```

---

### TIER-3: Features

**Responsabilidades**:
- SwiftUI Views
- ViewModels (state management)
- Navigation logic

**Reglas**:
- ✅ Puede importar cualquier tier inferior
- ✅ ViewModels deben ser `@MainActor` y `ObservableObject`
- ✅ No lógica de negocio en Views (delegar a ViewModel)
- ✅ Usar `@Published private(set)` para exponer estado

**Ejemplo de feature**:
```swift
// Sources/TIER-3/EduAuthFeature/Public/LoginView.swift
public struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel

    public init(authService: AuthService) {
        _viewModel = StateObject(wrappedValue: LoginViewModel(authService: authService))
    }

    public var body: some View {
        Form {
            TextField("Email", text: $viewModel.email)
            SecureField("Password", text: $viewModel.password)

            Button("Login") {
                Task {
                    await viewModel.login()
                }
            }
            .disabled(viewModel.isLoading)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

// Sources/TIER-3/EduAuthFeature/Public/LoginViewModel.swift
@MainActor
public final class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published private(set) var isLoading = false
    @Published var showError = false
    @Published private(set) var errorMessage = ""

    private let authService: AuthService

    public init(authService: AuthService) {
        self.authService = authService
    }

    public func login() async {
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await authService.login(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
```

---

## 📊 Trade-offs Finales

| Decisión | Beneficio | Costo |
|----------|-----------|-------|
| **4 Tiers** | Escalabilidad, testabilidad | Más archivos, overhead inicial |
| **SPM Multi-Módulo** | Compilación incremental | Setup complejo |
| **Strict Concurrency** | Thread-safety, elimina data races | Curva de aprendizaje |
| **Cero deps externas** | Control total, seguridad | Mantener código propio |
| **Protocol-Oriented** | Testabilidad, extensibilidad | Más boilerplate |

---

## 📚 Referencias

- [Swift Evolution - Strict Concurrency](https://github.com/apple/swift-evolution/blob/main/proposals/0302-concurrent-value-and-concurrent-closures.md)
- [Clean Architecture (Uncle Bob)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Protocol-Oriented Programming in Swift (WWDC 2015)](https://developer.apple.com/videos/play/wwdc2015/408/)
- [Swift Package Manager Documentation](https://swift.org/package-manager/)

---

**Versión**: 1.0.0
**Última actualización**: 2026-01-23
**Autor**: @edugo-ios-team
