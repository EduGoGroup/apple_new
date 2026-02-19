# Paso 4: DesignSystem SDK

**Prioridad:** Cuarta (sin dependencias, el UI Components SDK lo necesita)
**Dificultad:** Baja
**Archivos fuente:** 44
**Tests existentes:** No hay (crear basicos)

---

## 1. Crear el proyecto

```bash
mkdir -p DesignSystemSDK
cd DesignSystemSDK
swift package init --name DesignSystemSDK --type library
```

## 2. Configurar Package.swift

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "DesignSystemSDK",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "DesignSystemSDK", targets: ["DesignSystemSDK"])
    ],
    targets: [
        .target(
            name: "DesignSystemSDK",
            path: "Sources/DesignSystemSDK"
        ),
        .testTarget(
            name: "DesignSystemSDKTests",
            dependencies: ["DesignSystemSDK"],
            path: "Tests/DesignSystemSDKTests"
        )
    ]
)
```

## 3. Copiar archivos fuente

Desde `Packages/Presentation/Sources/DesignSystem/` copiar **todo el directorio**:

```bash
cp -R Packages/Presentation/Sources/DesignSystem/* Sources/DesignSystemSDK/
```

### Estructura esperada

```
Sources/DesignSystemSDK/
  Theme/
    Theme.swift
    ThemeManager.swift
    ColorTokens.swift
    SemanticColors.swift
    ColorPalette.swift
    ThemeEnvironment.swift
  Effects/
    LiquidGlass/
    Shadows/
    Shapes/
    VisualEffects/
    GlassModifiers.swift
  Accessibility/
    Foundation/
      AccessibilityConfiguration.swift
      AccessibilityPreferences.swift
      AccessibilityTraits.swift
      AccessibilityLabel.swift
      AccessibilityHint.swift
      AccessibilityIdentifiers.swift
    DynamicType/
    ReducedMotion/
    HighContrast/
    FocusManager/
    View+Accessibility.swift
```

### Archivo a modificar

| Archivo | Modificacion |
|---|---|
| `Accessibility/Foundation/AccessibilityIdentifiers.swift` | Eliminar la extension `AccessibilityIdentifier.Common` que tiene identifiers predefinidos de EduGo (auth_login_*, profile_settings_*, nav_tab_*) |

## 4. Verificar imports

```bash
grep -r "import Edu" Sources/DesignSystemSDK/
```

**Resultado esperado: 0 coincidencias.** Este modulo no importa nada de EduGo.

Los imports validos son:
- `import SwiftUI`
- `import Foundation`
- `import Observation`
- `import os.log`
- `import UIKit` (condicional iOS)
- `import AppKit` (condicional macOS)

## 5. Compilar

```bash
swift build
```

No deberia haber problemas. Es completamente independiente.

## 6. Tests

No hay tests existentes en el proyecto original. Crear tests basicos:

```swift
// Tests/DesignSystemSDKTests/ThemeTests.swift
import Testing
import SwiftUI
@testable import DesignSystemSDK

@Test func themeManagerHasDefaultTheme() async {
    await MainActor.run {
        let manager = ThemeManager.shared
        #expect(manager.currentTheme != nil)
    }
}

@Test func accessibilityIdentifierIsValid() {
    let id = AccessibilityIdentifier.button(module: "test", screen: "main", action: "save")
    #expect(id.isValid)
    #expect(id.id == "test_main_button_save")
}

@Test func accessibilityLabelCreation() {
    let label = AccessibilityLabel.button(action: "Save")
    #expect(!label.text.isEmpty)
}
```

## 7. Checklist final

- [ ] `swift build` compila sin errores
- [ ] `swift test` pasa tests basicos
- [ ] Cero imports de `Edu*`
- [ ] Eliminados identifiers predefinidos de EduGo (AccessibilityIdentifier.Common)
- [ ] Theme system funcional
- [ ] Accessibility system funcional
