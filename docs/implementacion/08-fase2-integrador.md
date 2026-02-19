# Fase 2: Proyecto Integrador

**Prerequisito:** Todos los SDKs de Fase 1 compilando y con tests pasando
**Objetivo:** Crear un proyecto que importe todos los SDKs y demuestre que funcionan juntos

---

## 1. Crear el proyecto

```bash
mkdir -p EduGoApp
cd EduGoApp
swift package init --name EduGoApp --type executable
```

## 2. Configurar Package.swift

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "EduGoApp",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    dependencies: [
        // SDKs locales (durante desarrollo)
        .package(path: "../FoundationToolkit"),
        .package(path: "../LoggerSDK"),
        .package(path: "../CQRSKit"),
        .package(path: "../DesignSystemSDK"),
        .package(path: "../FormsSDK"),
        .package(path: "../NetworkSDK"),
        .package(path: "../UIComponentsSDK"),
    ],
    targets: [
        .executableTarget(
            name: "EduGoApp",
            dependencies: [
                "FoundationToolkit",
                "LoggerSDK",
                "CQRSKit",
                "DesignSystemSDK",
                "FormsSDK",
                "NetworkSDK",
                "UIComponentsSDK",
            ],
            path: "Sources/EduGoApp"
        ),
        .testTarget(
            name: "EduGoAppTests",
            dependencies: ["EduGoApp"],
            path: "Tests/EduGoAppTests"
        )
    ]
)
```

## 3. Estructura del proyecto integrador

```
EduGoApp/
  Sources/EduGoApp/
    main.swift                    // Entry point
    Models/                       // Entidades de negocio EduGo (User, Material, etc.)
    DTOs/                         // DTOs para la API
    Repositories/                 // Implementaciones de repos (usan NetworkSDK)
    Persistence/                  // Modelos SwiftData + repos locales
    UseCases/                     // Logica de negocio
    CQRS/                         // Commands, Queries, Events concretos (usan CQRSKit)
    ViewModels/                   // ViewModels de la app
    Views/                        // Vistas SwiftUI (usan UIComponentsSDK + DesignSystemSDK)
    Navigation/                   // Coordinadores + Screen enum
    Services/                     // Auth, Roles, etc.
```

## 4. Ejemplo de integracion por SDK

### 4.1 Foundation Toolkit - Entidades de dominio

```swift
import FoundationToolkit

struct User: Entity {
    let id: UUID
    let createdAt: Date
    let updatedAt: Date
    let firstName: String
    let lastName: String
    let email: String

    init(firstName: String, lastName: String, email: String) throws {
        guard !firstName.isEmpty else {
            throw DomainError.validationFailed(field: "firstName", reason: "No puede estar vacio")
        }
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
    }
}
```

### 4.2 Logger - Configuracion inicial

```swift
import LoggerSDK

// En AppDelegate o @main
func configureLogger() async {
    await LoggerConfigurator.shared.applyPreset(.development)
    let logger = await LoggerRegistry.shared.logger()
    await logger.info("App iniciada")
}
```

### 4.3 Network - Repositorios remotos

```swift
import NetworkSDK
import FoundationToolkit

actor MaterialsRepository {
    private let client: NetworkClientProtocol

    init(client: NetworkClientProtocol) {
        self.client = client
    }

    func fetchMaterials() async throws -> [MaterialDTO] {
        try await client.get("https://api.edugo.com/v1/materials")
    }
}
```

### 4.4 CQRS - Commands y Queries

```swift
import CQRSKit

struct LoginCommand: Command {
    typealias Result = LoginOutput
    let email: String
    let password: String
    func validate() throws {
        guard !email.isEmpty else { throw ValidationError.emptyField(fieldName: "email") }
    }
}

actor LoginHandler: CommandHandler {
    typealias CommandType = LoginCommand
    private let authService: AuthService

    func handle(_ command: LoginCommand) async throws -> CommandResult<LoginOutput> {
        let output = try await authService.login(email: command.email, password: command.password)
        return .success(output, events: ["LoginSuccessEvent"])
    }
}
```

### 4.5 DesignSystem + Components - UI

```swift
import SwiftUI
import DesignSystemSDK
import UIComponentsSDK
import FormsSDK

struct LoginView: View {
    @BindableProperty(validation: Validators.email())
    var email: String = ""

    @BindableProperty(validation: Validators.password(minLength: 8))
    var password: String = ""

    var body: some View {
        VStack(spacing: 16) {
            EduTextField("Email", text: $email, icon: "envelope")
            EduTextField("Password", text: $password, icon: "lock")

            EduButton("Iniciar Sesion", style: .primary) {
                await viewModel.login()
            }
        }
        .padding()
        .background(Color.theme.background)
    }
}
```

## 5. Compilar

```bash
swift build
```

## 6. Tests de integracion

```swift
// Tests/EduGoAppTests/IntegrationTests.swift
import Testing
import FoundationToolkit
import LoggerSDK
import CQRSKit
import NetworkSDK

@Test func allSDKsImportCorrectly() async throws {
    // Foundation Toolkit
    let entity = try User(firstName: "John", lastName: "Doe", email: "john@test.com")
    #expect(entity.id != UUID())

    // Logger
    let logger = await LoggerRegistry.shared.logger()
    await logger.info("Test message")

    // CQRS
    let mediator = Mediator()
    #expect(mediator != nil)

    // Network
    let client = NetworkClient.shared
    #expect(client != nil)
}
```

## 7. Checklist final

- [ ] `swift build` compila sin errores
- [ ] Todos los SDKs importados correctamente
- [ ] Entidades de dominio EduGo usan `Entity` protocol del SDK
- [ ] Network usa `CodableSerializer` del SDK
- [ ] CQRS Mediator funciona con Commands/Queries propios
- [ ] UI usa componentes del SDK + DesignSystem
- [ ] Forms validation funciona en las vistas

---

## Notas sobre migracion gradual

No es necesario migrar todo el proyecto EduGo de golpe. Puedes:

1. **Empezar por un SDK**: Reemplazar la implementacion interna de Logger por `import LoggerSDK`
2. **Ir reemplazando gradualmente**: Uno por uno, verificando que nada se rompe
3. **Mantener compatibilidad**: Los SDKs exponen las mismas interfaces que el codigo original

La idea es que eventualmente el proyecto EduGo tenga:
- **SDKs importados**: Logger, Network, CQRS, DesignSystem, Components, Forms
- **Codigo propio**: Models, DTOs, Repositories, UseCases, ViewModels, Navigation, Auth
