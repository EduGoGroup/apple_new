# DesignSystem SDK

**Estado de extraccion:** Listo (100% generico)
**Dependencias externas:** Ninguna (solo SwiftUI de Apple)
**Origen en proyecto:** `Packages/Presentation/Sources/DesignSystem/`

---

## a) Que hace este SDK

Sistema de diseno completo para aplicaciones SwiftUI con temas, efectos visuales y accesibilidad. Proporciona:

### Theme System
- **ThemeManager**: Singleton observable para cambio de tema en runtime
- **Theme**: Struct con paletas de color, tipografia, espaciado, bordes, sombras
- **ColorTokens**: Sistema Material Design completo (escalas 50-900) con soporte glass
- **SemanticColors**: Abstraccion sobre tokens (background, text, interactive, state)
- **ColorPalette**: Paletas intercambiables (default, highContrast, grayscale, custom)

### Effects System
- **LiquidGlass**: Efecto glass con intensidades, animaciones y estados interactivos
- **Shadows**: Niveles predefinidos (sm, md, lg, xl) con glass-awareness
- **Shapes**: LiquidRoundedRectangle, BlobShape, SquircleShape, morphing
- **Visual Effects**: Factory con materiales adaptativos (iOS 26+)

### Accessibility System
- **VoiceOver**: Labels, hints y traits type-safe con builders
- **DynamicType**: Escalado con curvas configurables (linear, logarithmic, exponential, clamped)
- **ReducedMotion**: Deteccion cross-platform con helpers condicionales
- **HighContrast**: Adaptaciones automaticas
- **AccessibilityIdentifiers**: Sistema de naming para UI testing con builder pattern
- **FocusManager**: Gestion de foco para navegacion por teclado

### Uso tipico por el consumidor

```swift
// 1. Aplicar theme en la raiz
ContentView()
    .theme(.custom(palette: miPaleta))
    .themedApp()

// 2. Usar colores semanticos
Text("Titulo")
    .foregroundStyle(Color.theme.textPrimary)
    .background(Color.theme.background)

// 3. Aplicar efectos
Card()
    .eduLiquidGlass(intensity: .standard)
    .eduShadow(.md)
    .eduSquircle(cornerRadius: 16)

// 4. Accesibilidad fluida
Button("Guardar") { }
    .accessibleLabel(.button(action: "Save"))
    .accessibleHint(.saves("your changes"))
    .accessibleIdentifier(.button(module: "app", screen: "main", action: "save"))
```

---

## b) Compila como proyecto independiente?

**Si.** Cero dependencias de modulos EduGo:

- No importa `EduFoundation`, `EduCore`, ni `EduDomain`
- Solo usa `import SwiftUI` y `import os.log` (condicional)
- Verificado con grep: 0 resultados de `import.*Edu` en todo el directorio

Nota: El `Package.swift` de Presentation declara dependencias a Foundation/Core/Domain, pero el subdirectorio DesignSystem no las usa. Solo otros subdirectorios de Presentation (ViewModels, Navigation) las necesitan.

---

## c) Dependencias si se extrae

| Dependencia | Tipo | Notas |
|---|---|---|
| SwiftUI | Framework Apple | Unico requerimiento |
| os.log | Framework Apple | Condicional, para debugging |

---

## d) Que se fusionaria con este SDK

**UI Components** (EduButton, EduTextField, EduCard, etc.) podrian fusionarse aqui para crear un SDK unificado de "UI Kit" que incluya:
- Sistema de temas
- Efectos visuales
- Accesibilidad
- Componentes pre-construidos

Esto tiene sentido porque los componentes ya dependen de los DesignTokens del theme system.

---

## e) Interfaces publicas (contrato del SDK)

### Theme

```swift
@MainActor @Observable
public final class ThemeManager {
    public static let shared: ThemeManager
    public func setTheme(_ theme: Theme)
    public func setColorScheme(_ scheme: ColorSchemePreference)
    public var currentTheme: Theme { get }
}

public struct Theme: Sendable {
    public let palette: ColorPalette
    public let typography: Typography
    public let spacing: Spacing
    public let cornerRadius: CornerRadius
    public let shadows: ShadowScale
    public static func custom(...) -> Theme
}
```

### Effects

```swift
// ViewModifiers (chainable)
.eduLiquidGlass(intensity: EduLiquidGlassIntensity)
.eduLiquidGlass(configuration: EduLiquidGlassConfiguration)
.eduShadow(_ level: EduShadowLevel)
.eduGlassAwareShadow(level:glassIntensity:)
.eduSquircle(cornerRadius:)
.eduLiquidClip(cornerRadius:smoothness:)
.eduMorphShape(_ shape:)
.eduVisualEffect(style:shape:)
```

### Accessibility

```swift
// ViewModifiers (chainable)
.accessibleLabel(_ label: AccessibilityLabel)
.accessibleHint(_ hint: AccessibilityHint)
.accessibleTraits(_ traits: AccessibilityTraits)
.accessibleIdentifier(_ id: AccessibilityIdentifier)
.accessibleConfiguration(label:hint:traits:identifier:)
.asAccessibleButton(label:hint:)
.asAccessibleHeader(title:)

// Builders
AccessibilityLabel.button(action:)
AccessibilityHint.saves(_:), .opens(_:), .navigatesTo(_:)
AccessibilityIdentifier.button(module:screen:action:)
AccessibilityIdentifierBuilder().module(_:).screen(_:).component(_:).build()
```

---

## f) Que necesita personalizar el consumidor

### Personalizacion de Theme

```swift
// Crear paleta custom con escalas de color propias
let miPaleta = ColorPalette.custom(
    id: "miapp",
    name: "Mi App Theme",
    palette: ColorPalette(
        primary: miEscalaPrimaria,    // 50-900
        secondary: miEscalaSecundaria,
        // ...
    )
)

// O solo ajustar tokens individuales
extension ColorTokens {
    public static let customPrimary500 = ColorToken(
        light: Color(red: 0.2, green: 0.5, blue: 0.8),
        dark: Color(red: 0.4, green: 0.7, blue: 1.0)
    )
}
```

### Que se lleva tal cual vs que adapta

| Componente | Se lleva tal cual? | Adaptacion necesaria |
|---|---|---|
| ThemeManager | Si | - |
| Theme, ColorTokens, SemanticColors | Si | Definir su propia paleta |
| ColorPalette | Si | - |
| LiquidGlass, Shadows, Shapes | Si | - |
| Accessibility (todo) | Si | - |
| AccessibilityIdentifier.Common | No | Identifiers predefinidos de EduGo (auth_login_*, profile_*) |

### Cambios necesarios para portabilidad

1. **Renombrar prefijo "Edu"**: `EduLiquidGlass` -> nombre generico (o dejarlo como brand del SDK)
2. **Eliminar `AccessibilityIdentifier.Common`**: Son identifiers predefinidos para pantallas de EduGo (auth, profile, nav). El consumidor define los suyos
3. **Opcional**: Separar Accessibility en sub-modulo si se quiere granularidad

Estimacion de cambios: ~10 lineas (solo los predefined identifiers).
