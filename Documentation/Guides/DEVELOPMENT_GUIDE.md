# Guía de Desarrollo - EduGo Apple Modules

**Manual práctico para trabajar con el workspace multi-módulo**

---

## 📋 Tabla de Contenidos

1. [Setup Inicial](#setup-inicial)
2. [Agregar un Nuevo Módulo](#agregar-un-nuevo-módulo)
3. [Modificar Dependencias](#modificar-dependencias)
4. [Testing](#testing)
5. [Convenciones de Código](#convenciones-de-código)
6. [Validar Dependencias](#validar-dependencias)
7. [Troubleshooting](#troubleshooting)

---

## 🚀 Setup Inicial

### Requisitos

- **Xcode 16.0+** (incluye Swift 6.2)
- **macOS 15.0+**
- **Git**

### Pasos

```bash
# 1. Clonar repositorio
git clone https://github.com/edugo/eduui-modules-apple.git
cd eduui-modules-apple

# 2. Abrir Package.swift en Xcode
open Package.swift

# 3. Xcode resuelve dependencias automáticamente
# Esperar a que termine la resolución (barra de progreso en Xcode)

# 4. Compilar todo
# Product → Build (⌘B)

# 5. Ejecutar tests
# Product → Test (⌘U)
```

### Configuración de Xcode (Una sola vez)

1. **Habilitar documentación en Quick Help**:
   - Xcode → Settings → Documentation
   - Marcar "Show documentation for modules in this workspace"

2. **Configurar SwiftLint (opcional)**:
```bash
brew install swiftlint

# Crear .swiftlint.yml en raíz del proyecto
cat > .swiftlint.yml << EOF
opt_in_rules:
  - force_try
  - force_unwrapping
  - implicitly_unwrapped_optional

excluded:
  - .build
  - DerivedData
EOF
```

---

## 📦 Agregar un Nuevo Módulo

### Flujo Completo

#### Paso 1: Decidir el Tier

**Pregunta clave**: ¿Qué responsabilidad tiene este módulo?

| Si el módulo... | Entonces es... | Ejemplo |
|-----------------|----------------|---------|
| Define modelos/protocolos sin dependencias | **TIER-0** | `EduFoundation` |
| Hace llamadas HTTP, lee Keychain, CRUD | **TIER-1** | `EduNetworking`, `EduRepositories` |
| Orquesta repositorios, lógica de negocio | **TIER-2** | `EduAuthService` |
| Contiene UI (SwiftUI views, ViewModels) | **TIER-3** | `EduAuthFeature` |

#### Paso 2: Crear Estructura de Carpetas

**Convención**: `Sources/TIER-X/NombreModulo/`

```bash
# Ejemplo: Crear módulo de notificaciones en TIER-2
mkdir -p "Sources/TIER-2/EduNotificationService/Public"
mkdir -p "Sources/TIER-2/EduNotificationService/Internal"
mkdir -p "Tests/TIER-2/EduNotificationServiceTests"
```

**Estructura esperada**:
```
Sources/TIER-2/EduNotificationService/
├── Public/
│   ├── NotificationService.swift        # API pública
│   └── NotificationModels.swift         # DTOs si aplica
└── Internal/
    ├── NotificationManager.swift        # Implementación interna
    └── NotificationMapper.swift         # Conversiones

Tests/TIER-2/EduNotificationServiceTests/
├── NotificationServiceTests.swift
└── Mocks/
    └── MockNotificationRepository.swift
```

#### Paso 3: Actualizar `Package.swift`

**Ubicación**: Raíz del proyecto

```swift
// Package.swift
let package = Package(
    name: "EduGoModules",
    // ... (platforms, etc.)

    products: [
        // ... productos existentes ...

        // AGREGAR NUEVO PRODUCTO
        .library(
            name: "EduNotificationService",
            targets: ["EduNotificationService"]
        ),
    ],

    targets: [
        // ... targets existentes ...

        // AGREGAR NUEVO TARGET
        .target(
            name: "EduNotificationService",
            dependencies: [
                "EduFoundation",        // TIER-0 siempre disponible
                "EduRepositories",      // TIER-1 si necesitas repos
            ],
            path: "Sources/TIER-2/EduNotificationService",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        ),

        // AGREGAR TEST TARGET
        .testTarget(
            name: "EduNotificationServiceTests",
            dependencies: ["EduNotificationService"],
            path: "Tests/TIER-2/EduNotificationServiceTests"
        ),
    ]
)
```

**Reglas de dependencias** (ver [Validar Dependencias](#validar-dependencias)):
- TIER-0 → Sin dependencias internas
- TIER-1 → Puede depender de TIER-0
- TIER-2 → Puede depender de TIER-0, TIER-1
- TIER-3 → Puede depender de TIER-0, TIER-1, TIER-2

#### Paso 4: Crear Código Inicial

```swift
// Sources/TIER-2/EduNotificationService/Public/NotificationService.swift

import Foundation
import EduFoundation  // TIER-0
import os

/// Servicio de gestión de notificaciones push.
///
/// Este servicio coordina el registro de dispositivos, recepción de notificaciones
/// y gestión de permisos.
@MainActor
public final class NotificationService: ObservableObject {
    private let logger: Logger

    /// Inicializa el servicio de notificaciones.
    public init() {
        self.logger = Logger(subsystem: "com.edugo", category: "Notifications")
    }

    /// Solicita permisos de notificaciones al usuario.
    ///
    /// - Returns: `true` si el usuario otorgó permisos, `false` en caso contrario.
    /// - Throws: `NotificationError` si hay error solicitando permisos.
    public func requestPermissions() async throws -> Bool {
        logger.info("Requesting notification permissions")

        // TODO: Implementar lógica

        return false
    }
}
```

#### Paso 5: Crear Tests

```swift
// Tests/TIER-2/EduNotificationServiceTests/NotificationServiceTests.swift

import XCTest
@testable import EduNotificationService

final class NotificationServiceTests: XCTestCase {
    private var sut: NotificationService!

    @MainActor
    override func setUp() {
        super.setUp()
        sut = NotificationService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    @MainActor
    func testRequestPermissions_WhenUserGrants_ReturnsTrue() async throws {
        // Given
        // (mock dependencies si aplica)

        // When
        let result = try await sut.requestPermissions()

        // Then
        XCTAssertTrue(result, "Should return true when user grants permissions")
    }
}
```

#### Paso 6: Compilar y Testear

```bash
# Compilar el nuevo módulo
swift build --target EduNotificationService

# Ejecutar tests
swift test --filter EduNotificationServiceTests
```

#### Paso 7: Integrar en Feature (TIER-3)

```swift
// Sources/TIER-3/EduDashboardFeature/Public/DashboardViewModel.swift

import EduNotificationService  // NUEVO IMPORT

@MainActor
public final class DashboardViewModel: ObservableObject {
    private let notificationService: NotificationService

    public init(notificationService: NotificationService) {
        self.notificationService = notificationService
    }

    public func requestNotificationPermissions() async {
        do {
            let granted = try await notificationService.requestPermissions()
            // Actualizar UI según resultado
        } catch {
            // Manejar error
        }
    }
}
```

---

## 🔗 Modificar Dependencias

### Agregar Dependencia a Módulo Existente

**Escenario**: `EduCourseService` (TIER-2) necesita usar `EduNetworking` (TIER-1).

#### Paso 1: Verificar Reglas de Tier

```
TIER-2 (EduCourseService) → TIER-1 (EduNetworking) ✅ PERMITIDO
```

#### Paso 2: Actualizar `Package.swift`

```swift
.target(
    name: "EduCourseService",
    dependencies: [
        "EduFoundation",
        "EduRepositories",
        "EduNetworking",  // ← AGREGAR ESTA LÍNEA
    ],
    path: "Sources/TIER-2/EduCourseService",
    swiftSettings: [
        .enableUpcomingFeature("StrictConcurrency"),
        .enableUpcomingFeature("BareSlashRegexLiterals")
    ]
),
```

#### Paso 3: Importar en Código

```swift
// Sources/TIER-2/EduCourseService/Public/CourseService.swift

import EduNetworking  // ← NUEVO IMPORT

public final class CourseService {
    private let networkClient: NetworkClient

    public init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
}
```

#### Paso 4: Compilar para Verificar

```bash
swift build --target EduCourseService
```

### Evitar Dependencias Circulares

**Ejemplo de violación (PROHIBIDO)**:

```swift
// ❌ MAL: TIER-1 depende de TIER-2
.target(
    name: "EduRepositories",  // TIER-1
    dependencies: [
        "EduAuthService",      // ❌ TIER-2 (TIER superior)
    ]
)
```

**Solución**: Invertir la dependencia usando protocolos.

```swift
// ✅ BIEN: Definir protocolo en TIER-0, implementar en TIER-1, usar en TIER-2

// Sources/TIER-0/EduFoundation/Public/Protocols/UserRepository.swift
public protocol UserRepository: Sendable {
    func fetchUser(id: UUID) async throws -> User
}

// Sources/TIER-1/EduRepositories/Internal/DefaultUserRepository.swift
final class DefaultUserRepository: UserRepository {
    func fetchUser(id: UUID) async throws -> User {
        // Implementación
    }
}

// Sources/TIER-2/EduAuthService/Public/AuthService.swift
public final class AuthService {
    private let userRepository: UserRepository  // Protocolo de TIER-0

    public init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }
}
```

---

## 🧪 Testing

### Estrategia por Tier

| Tier | Qué testear | Herramientas |
|------|-------------|--------------|
| **TIER-0** | Validaciones de modelos, extensiones | XCTest |
| **TIER-1** | Repositorios con mocks de NetworkClient | XCTest + Mocks |
| **TIER-2** | Lógica de negocio con mocks de repos | XCTest + Mocks |
| **TIER-3** | ViewModels con mocks de services | XCTest + Mocks |

### Crear Mock de Protocolo

**Ejemplo**: Mock de `UserRepository` para testear `AuthService`.

```swift
// Tests/TIER-2/EduAuthServiceTests/Mocks/MockUserRepository.swift

import Foundation
import EduFoundation

final class MockUserRepository: UserRepository {
    // Configuración de resultados
    var fetchUserResult: Result<User, Error> = .failure(TestError.notSet)
    var loginResult: Result<User, Error> = .failure(TestError.notSet)

    // Tracking de llamadas
    var fetchUserCallCount = 0
    var loginCallCount = 0
    var lastLoginEmail: String?

    func fetchUser(id: UUID) async throws -> User {
        fetchUserCallCount += 1
        return try fetchUserResult.get()
    }

    func login(email: String, password: String) async throws -> User {
        loginCallCount += 1
        lastLoginEmail = email
        return try loginResult.get()
    }
}

enum TestError: Error {
    case notSet
}
```

### Test con Mock

```swift
// Tests/TIER-2/EduAuthServiceTests/AuthServiceTests.swift

import XCTest
@testable import EduAuthService
import EduFoundation

final class AuthServiceTests: XCTestCase {
    private var mockUserRepository: MockUserRepository!
    private var mockKeychainManager: MockKeychainManager!
    private var sut: AuthService!

    @MainActor
    override func setUp() {
        super.setUp()
        mockUserRepository = MockUserRepository()
        mockKeychainManager = MockKeychainManager()
        sut = AuthService(
            userRepository: mockUserRepository,
            keychainManager: mockKeychainManager
        )
    }

    override func tearDown() {
        sut = nil
        mockKeychainManager = nil
        mockUserRepository = nil
        super.tearDown()
    }

    @MainActor
    func testLogin_WhenCredentialsValid_ReturnsUser() async throws {
        // Given
        let expectedUser = User(id: UUID(), name: "Test User", email: "test@edu.go")
        mockUserRepository.loginResult = .success(expectedUser)

        // When
        let user = try await sut.login(email: "test@edu.go", password: "password123")

        // Then
        XCTAssertEqual(user.id, expectedUser.id)
        XCTAssertEqual(mockUserRepository.loginCallCount, 1)
        XCTAssertEqual(mockUserRepository.lastLoginEmail, "test@edu.go")
    }

    @MainActor
    func testLogin_WhenCredentialsInvalid_ThrowsError() async {
        // Given
        mockUserRepository.loginResult = .failure(AuthError.invalidCredentials)

        // When/Then
        do {
            _ = try await sut.login(email: "test@edu.go", password: "wrong")
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is AuthError)
        }
    }
}
```

### Ejecutar Tests

```bash
# Todos los tests
swift test

# Tests de un módulo específico
swift test --filter EduAuthServiceTests

# Test específico
swift test --filter EduAuthServiceTests.testLogin_WhenCredentialsValid_ReturnsUser

# Con cobertura (requiere Xcode)
xcodebuild test -scheme EduGoModules-Package -enableCodeCoverage YES
```

---

## 📝 Convenciones de Código

### Naming

| Elemento | Convención | Ejemplo |
|----------|-----------|---------|
| **Tipos** (class, struct, enum) | PascalCase | `UserViewModel`, `AuthToken` |
| **Funciones/Variables** | camelCase | `fetchUser`, `userName` |
| **Protocolos** | Nombre limpio sin sufijo | `UserRepository` (no `UserRepositoryProtocol`) |
| **Implementaciones** | Sufijo descriptivo | `DefaultUserRepository`, `MockUserRepository` |
| **Booleanos** | Prefijos `is`, `has`, `should` | `isLoading`, `hasPermissions` |

### Access Control

| Nivel | Cuándo usar |
|-------|-------------|
| `public` | APIs expuestas a otros módulos |
| `internal` | Código dentro del mismo módulo (default) |
| `private` | Código dentro del mismo archivo |
| `private(set)` | Propiedad read-only desde fuera |

**Ejemplo**:
```swift
public final class AuthService {  // ← public: API expuesta
    private let userRepository: UserRepository  // ← private: detalle interno

    @Published private(set) public var currentUser: User?  // ← public get, private set

    public func login(...) async throws -> User {  // ← public: API expuesta
        // ...
    }

    private func refreshToken() async throws {  // ← private: helper interno
        // ...
    }
}
```

### DocC Comments (Obligatorio para APIs Públicas)

```swift
/// Servicio de autenticación que gestiona login, logout y refresh de tokens.
///
/// Este servicio coordina operaciones de autenticación utilizando un repositorio
/// de usuarios y un gestor de Keychain para almacenar tokens de forma segura.
///
/// ## Ejemplo de uso
///
/// ```swift
/// let authService = AuthService(
///     userRepository: DefaultUserRepository(),
///     keychainManager: KeychainManager()
/// )
///
/// do {
///     let user = try await authService.login(
///         email: "user@example.com",
///         password: "securePassword"
///     )
///     print("Logged in as \(user.name)")
/// } catch {
///     print("Login failed: \(error)")
/// }
/// ```
public final class AuthService {
    // ...

    /// Autentica un usuario con email y contraseña.
    ///
    /// Este método valida las credenciales contra el backend, obtiene un token
    /// de autenticación, lo almacena en Keychain y actualiza `currentUser`.
    ///
    /// - Parameters:
    ///   - email: Email del usuario (debe ser válido)
    ///   - password: Contraseña del usuario (mínimo 8 caracteres)
    /// - Returns: Usuario autenticado con perfil completo
    /// - Throws: `AuthError.invalidCredentials` si email/password son incorrectos,
    ///           `NetworkError` si hay error de red
    public func login(email: String, password: String) async throws -> User {
        // ...
    }
}
```

### Manejo de Errores

**Prohibido en producción**:
- `try!` → Puede crashear la app
- `fatalError()` → Crashea la app
- `!` (force unwrap) → Puede crashear la app

**Permitido**:
- `guard let` para unwrap optionals
- `try` con `do-catch` para manejar errores
- `try?` si el error no es crítico

**Ejemplo**:
```swift
// ❌ MAL
func fetchUser(id: UUID) -> User {
    let user = try! userRepository.fetchUser(id: id)  // ❌ Force try
    return user!  // ❌ Force unwrap
}

// ✅ BIEN
func fetchUser(id: UUID) async throws -> User {
    let user = try await userRepository.fetchUser(id: id)  // ✅ Propaga error
    return user
}
```

---

## ✅ Validar Dependencias

### Regla de Oro

```
TIER-X solo puede depender de TIER-(X-1), TIER-(X-2), ..., TIER-0
```

### Script de Validación (Bash)

Crear archivo `scripts/validate_dependencies.sh`:

```bash
#!/bin/bash

set -e

echo "🔍 Validating tier dependencies..."

# Leer Package.swift y buscar violaciones
# TIER-0 no puede importar nada
if grep -r "import Edu" Sources/TIER-0/ 2>/dev/null | grep -v "import Foundation" | grep -v "import os"; then
    echo "❌ TIER-0 has internal imports (should have none)"
    exit 1
fi

# TIER-1 solo puede importar TIER-0
if grep -r "import Edu" Sources/TIER-1/ 2>/dev/null | grep -v "EduFoundation"; then
    echo "❌ TIER-1 imports non-TIER-0 modules"
    exit 1
fi

# TIER-2 no puede importar TIER-3
if grep -r "import Edu.*Feature" Sources/TIER-2/ 2>/dev/null; then
    echo "❌ TIER-2 imports TIER-3 modules"
    exit 1
fi

echo "✅ All tier dependencies are valid"
```

**Ejecutar**:
```bash
chmod +x scripts/validate_dependencies.sh
./scripts/validate_dependencies.sh
```

### Validación Manual

**Checklist antes de merge**:
- [ ] TIER-0 no importa módulos internos
- [ ] TIER-1 solo importa TIER-0
- [ ] TIER-2 solo importa TIER-0 y TIER-1
- [ ] TIER-3 solo importa TIER-0, TIER-1 y TIER-2
- [ ] No hay dependencias circulares (A → B → A)

---

## 🐛 Troubleshooting

### Error: "Module 'X' not found"

**Causa**: Módulo no declarado en `Package.swift` o no compilado.

**Solución**:
```bash
# 1. Limpiar build folder
rm -rf .build

# 2. Resolver dependencias de nuevo
swift package resolve

# 3. Compilar módulo específico
swift build --target NombreModulo
```

### Error: "Circular dependency between modules"

**Causa**: Módulo A depende de B, y B depende de A.

**Solución**: Invertir dependencia usando protocolo en TIER-0.

```swift
// Antes (CIRCULAR):
// TIER-1/ModuloA → TIER-1/ModuloB
// TIER-1/ModuloB → TIER-1/ModuloA

// Después (CORRECTO):
// TIER-0 define protocolo: RepositoryProtocol
// TIER-1/ModuloA implementa: DefaultRepository: RepositoryProtocol
// TIER-1/ModuloB depende de: RepositoryProtocol (TIER-0)
```

### Error: "Data race detected" (Strict Concurrency)

**Causa**: Acceso concurrente a estado mutable sin sincronización.

**Solución**: Usar `actor` o `@MainActor`.

```swift
// ❌ ANTES (DATA RACE)
class AuthStore {
    var currentUser: User?  // Mutable, accessible desde múltiples threads
}

// ✅ DESPUÉS (THREAD-SAFE)
actor AuthStore {
    private var currentUser: User?

    func setUser(_ user: User) {
        self.currentUser = user
    }

    func getUser() -> User? {
        currentUser
    }
}
```

### Tests Fallan en CI pero Pasan Localmente

**Causa**: Diferencias de timing (race conditions en tests).

**Solución**: Usar `Task.yield()` o `XCTestExpectation`.

```swift
// ❌ ANTES (FLAKY TEST)
func testAsync() async {
    await service.doSomething()
    XCTAssertTrue(service.isDone)  // Puede fallar por timing
}

// ✅ DESPUÉS (ROBUST TEST)
func testAsync() async {
    await service.doSomething()
    await Task.yield()  // Asegurar que el estado se actualizó
    XCTAssertTrue(service.isDone)
}
```

---

## 📚 Recursos Adicionales

- [ARCHITECTURE.md](ARCHITECTURE.md) - Decisiones de diseño
- [README.md](README.md) - Overview del proyecto
- [docs/tier-architecture-diagram.md](docs/tier-architecture-diagram.md) - Diagrama de arquitectura

---

**Versión**: 1.0.0
**Última actualización**: 2026-01-23
**Mantenedor**: @edugo-ios-team
