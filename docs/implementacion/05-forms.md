# Paso 5: Forms SDK

**Prioridad:** Quinta (sin dependencias, totalmente standalone)
**Dificultad:** Baja
**Archivos fuente:** 12
**Tests existentes:** No hay (crear basicos)

---

## 1. Crear el proyecto

```bash
mkdir -p FormsSDK
cd FormsSDK
swift package init --name FormsSDK --type library
```

## 2. Configurar Package.swift

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "FormsSDK",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "FormsSDK", targets: ["FormsSDK"])
    ],
    targets: [
        .target(
            name: "FormsSDK",
            path: "Sources/FormsSDK"
        ),
        .testTarget(
            name: "FormsSDKTests",
            dependencies: ["FormsSDK"],
            path: "Tests/FormsSDKTests"
        )
    ]
)
```

## 3. Copiar archivos fuente

Desde `Packages/Presentation/Sources/Utilities/` copiar todo a `Sources/FormsSDK/`:

```bash
cp -R Packages/Presentation/Sources/Utilities/* Sources/FormsSDK/
```

### Archivos esperados

```
Sources/FormsSDK/
  FormState.swift
  BindableProperty.swift
  DebouncedProperty.swift
  Validators.swift
  ValidationResult.swift
  CrossFieldValidator.swift
  ... (ViewModifiers para forms)
```

## 4. Verificar imports

```bash
grep -r "import Edu" Sources/FormsSDK/
```

**Resultado esperado: 0 coincidencias.** Este modulo es 100% standalone.

Los imports validos son:
- `import Foundation`
- `import SwiftUI`
- `import Observation`

## 5. Compilar

```bash
swift build
```

No deberia haber problemas.

## 6. Tests

Crear tests para validadores y FormState:

```swift
// Tests/FormsSDKTests/ValidatorsTests.swift
import Testing
@testable import FormsSDK

@Test func emailValidatorAcceptsValidEmail() {
    let result = Validators.email()("user@example.com")
    #expect(result.isValid)
}

@Test func emailValidatorRejectsInvalidEmail() {
    let result = Validators.email()("not-an-email")
    #expect(!result.isValid)
}

@Test func passwordValidatorChecksMinLength() {
    let validator = Validators.password(minLength: 8)
    #expect(!validator("short").isValid)
    #expect(validator("longpassword123").isValid)
}

@Test func nonEmptyValidatorRejectsEmpty() {
    let result = Validators.nonEmpty()("")
    #expect(!result.isValid)
}

@Test func composedValidatorsWork() {
    let validator = Validators.all([
        Validators.nonEmpty(),
        Validators.minLength(3)
    ])
    #expect(!validator("ab").isValid)
    #expect(validator("abc").isValid)
}
```

## 7. Checklist final

- [ ] `swift build` compila sin errores
- [ ] `swift test` pasa todos los tests
- [ ] Cero imports de `Edu*`
- [ ] FormState, Validators, BindableProperty, DebouncedProperty funcionan
