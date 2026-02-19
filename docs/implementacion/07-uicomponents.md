# Paso 7: UI Components SDK

**Prioridad:** Septima (depende de DesignSystem SDK)
**Dificultad:** Media
**Archivos fuente:** ~35
**Tests existentes:** No hay (crear basicos)

---

## 1. Crear el proyecto

```bash
mkdir -p UIComponentsSDK
cd UIComponentsSDK
swift package init --name UIComponentsSDK --type library
```

## 2. Configurar Package.swift

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "UIComponentsSDK",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "UIComponentsSDK", targets: ["UIComponentsSDK"])
    ],
    dependencies: [
        .package(path: "../DesignSystemSDK"),
    ],
    targets: [
        .target(
            name: "UIComponentsSDK",
            dependencies: [
                .product(name: "DesignSystemSDK", package: "DesignSystemSDK")
            ],
            path: "Sources/UIComponentsSDK"
        ),
        .testTarget(
            name: "UIComponentsSDKTests",
            dependencies: ["UIComponentsSDK"],
            path: "Tests/UIComponentsSDKTests"
        )
    ]
)
```

## 3. Copiar archivos fuente

Desde `Packages/Presentation/Sources/Components/` copiar a `Sources/UIComponentsSDK/`:

### SI copiar

Copiar todo el directorio **excepto** los archivos problematicos:

```bash
cp -R Packages/Presentation/Sources/Components/* Sources/UIComponentsSDK/
```

### Archivos a modificar

| Archivo | Modificacion |
|---|---|
| `EduListView.swift` | Tiene `import EduDomain` para `ViewState<T>`. Crear `ViewState` localmente (ver abajo) |
| `PreviewMocks.swift` | Tiene `import EduDomain`. Eliminar el archivo o reescribir sin dependencia |
| Cualquier archivo con `import Edu*` | Cambiar o eliminar |

### 3.1 Crear ViewState localmente

`ViewState` es un enum generico trivial. Crear en `Sources/UIComponentsSDK/Support/ViewState.swift`:

```swift
/// Estado generico para vistas que cargan datos asincronamente.
public enum ViewState<T: Sendable>: Sendable {
    case idle
    case loading
    case success(T)
    case error(Error)
    case empty

    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    public var data: T? {
        if case .success(let data) = self { return data }
        return nil
    }

    public var error: Error? {
        if case .error(let error) = self { return error }
        return nil
    }
}
```

## 4. Verificar imports

```bash
grep -r "import Edu" Sources/UIComponentsSDK/
```

Reemplazar todos por:
- `import EduDomain` -> eliminar (ViewState ahora es local)
- `import EduCore` -> eliminar si existe
- `import EduFoundation` -> eliminar si existe

Imports validos:
- `import SwiftUI`
- `import Foundation`
- `import DesignSystemSDK` (para tokens de diseno)
- `import LocalAuthentication` (solo en EduBiometricButton)

## 5. Resolver DesignTokens

Los componentes usan `DesignTokens` para spacing, corner radius, etc. Verificar de donde vienen:

- Si `DesignTokens` esta en el directorio `Components/` -> ya esta copiado
- Si `DesignTokens` esta en `DesignSystem/` -> importar via `import DesignSystemSDK`

## 6. Compilar

```bash
swift build
```

**Posibles problemas:**
- Tipos faltantes de `EduDomain` -> asegurar que `ViewState` esta definido localmente
- `DesignTokens` no encontrado -> verificar ubicacion
- `PreviewMocks` referencia tipos de EduGo -> eliminar o reescribir con tipos dummy

## 7. Tests

Crear tests basicos de compilacion y snapshot:

```swift
// Tests/UIComponentsSDKTests/ComponentsTests.swift
import Testing
import SwiftUI
@testable import UIComponentsSDK

@Test func buttonCreatesWithAllStyles() {
    // Verifica que los estilos compilan
    _ = EduButton("Test", style: .primary) { }
    _ = EduButton("Test", style: .secondary) { }
    _ = EduButton("Test", style: .destructive) { }
}

@Test func viewStateTransitions() {
    var state: ViewState<String> = .idle
    #expect(!state.isLoading)

    state = .loading
    #expect(state.isLoading)

    state = .success("data")
    #expect(state.data == "data")
}

@Test func skeletonLoaderCreates() {
    _ = EduSkeletonLoader(shape: .rectangle)
    _ = EduSkeletonLoader(shape: .circle)
}
```

## 8. Checklist final

- [ ] `swift build` compila sin errores
- [ ] `swift test` pasa tests basicos
- [ ] Cero imports de `Edu*` (solo `DesignSystemSDK`)
- [ ] `ViewState` definido localmente
- [ ] `PreviewMocks` eliminado o reescrito
- [ ] Componentes: EduButton, EduTextField, EduCard, EduToast, EduSkeletonLoader, EduListView funcionan
