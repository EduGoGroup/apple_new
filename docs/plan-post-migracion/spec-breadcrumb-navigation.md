# Spec: Breadcrumb Navigation

> Stack de navegacion visible con tap directo a cualquier nivel, construido automaticamente desde navegacion SDUI.

## Contexto

La app usa navegacion SDUI: el servidor define pantallas con `screenKey`, y las acciones de navegacion llevan de una pantalla a otra. Actualmente no hay trail de navegacion visible — el usuario solo ve el titulo de la pantalla actual.

Existe un componente `EduBreadcrumbs` parcial (solo macOS, desconectado de la navegacion real).

## Analisis del Codigo Actual

### Componente existente

**`Packages/Presentation/Sources/Components/Navigation/EduBreadcrumbs.swift`:**
- `EduBreadcrumbItem` (lineas 7-19) — Struct con id, title, icon, destination
- `EduBreadcrumbs` (lineas 31-95) — Vista macOS-only, max 7 niveles, chevron separador, Liquid Glass
- `EduBreadcrumbCoordinator` (lineas 148-185) — `@Observable`, push/pop/clear/update
- `EduBreadcrumbBuilder` (lineas 102-142) — Builder pattern fluido
- `EduPlatformBreadcrumbs` (lineas 245-272) — macOS=breadcrumbs, iOS=solo titulo

### Navegacion actual

**`Packages/Presentation/Sources/Navigation/AppCoordinator.swift`:**
- `@Observable`, `NavigationPath`, `Screen` enum con associated values
- `navigate(to:)`, `goBack()`, `popToRoot()`
- Reacciona a domain events via EventBus
- NO expone historial de navegacion para breadcrumbs

**`Apps/DemoApp/Sources/ViewModels/DynamicScreenViewModel.swift`:**
- Navega via callbacks `onNavigate?(screenKey, params)`
- NO tracking centralizado del trail

**`Apps/DemoApp/Sources/Screens/MainScreen.swift`:**
- `AdaptiveNavigationContainer` con sidebar/tab bar
- Menu items con `screens` dictionary
- Selection actualiza `selectedItemKey`
- NO breadcrumb integration

### Toolbar dinamico

**`Packages/Presentation/Sources/Components/Navigation/EduDynamicToolbar.swift`:**
- Modos: hidden, list, form, detail, titleOnly
- NO tiene zona para breadcrumbs

### ScreenDefinition

**`Packages/DynamicUI/Sources/DynamicUI/Models/ScreenDefinition.swift`:**
- `screenKey: String` — Identificador unico
- `screenName: String` — Nombre legible (puede usarse como label del breadcrumb)
- `pattern: ScreenPattern` — Tipo de pantalla
- NO tiene `parentScreenKey` ni metadata de breadcrumb

## Diseno Tecnico

### 1. BreadcrumbTracker (actor)

**Ubicacion:** `Packages/Domain/Sources/Services/Navigation/BreadcrumbTracker.swift`

```swift
public actor BreadcrumbTracker {

    public struct BreadcrumbEntry: Sendable, Identifiable, Hashable {
        public let id: String  // UUID
        public let screenKey: String
        public let title: String
        public let icon: String?  // SF Symbol name
        public let pattern: String  // ScreenPattern rawValue
    }

    private var trail: [BreadcrumbEntry] = []
    private let maxDepth: Int = 7

    // Stream para notificar cambios del trail a la UI
    private let trailContinuation: AsyncStream<[BreadcrumbEntry]>.Continuation
    public let trailStream: AsyncStream<[BreadcrumbEntry]>

    /// Agrega una pantalla al trail
    public func push(screenKey: String, title: String, icon: String?, pattern: String) {
        // Si la pantalla ya esta en el trail, podar hasta ese punto (evitar duplicados)
        if let existingIndex = trail.firstIndex(where: { $0.screenKey == screenKey }) {
            trail = Array(trail.prefix(existingIndex + 1))
        } else {
            let entry = BreadcrumbEntry(
                id: UUID().uuidString,
                screenKey: screenKey,
                title: title,
                icon: icon,
                pattern: pattern
            )
            trail.append(entry)

            // Respetar max depth — truncar desde el inicio
            if trail.count > maxDepth {
                trail = Array(trail.suffix(maxDepth))
            }
        }
        trailContinuation.yield(trail)
    }

    /// Poda el trail hasta el entry indicado (inclusive)
    public func navigateTo(entryId: String) -> BreadcrumbEntry? {
        guard let index = trail.firstIndex(where: { $0.id == entryId }) else { return nil }
        trail = Array(trail.prefix(index + 1))
        trailContinuation.yield(trail)
        return trail.last
    }

    /// Remueve la ultima entrada (back navigation)
    public func pop() {
        guard !trail.isEmpty else { return }
        trail.removeLast()
        trailContinuation.yield(trail)
    }

    /// Limpia todo el trail (cambio de seccion, logout)
    public func clear() {
        trail.removeAll()
        trailContinuation.yield(trail)
    }

    /// Trail actual
    public func currentTrail() -> [BreadcrumbEntry] {
        trail
    }
}
```

### 2. Integracion con DynamicScreenView

**Archivo:** `Apps/DemoApp/Sources/Screens/DynamicScreenView.swift`

Cuando una pantalla se carga, se registra automaticamente en el tracker:

```swift
.task {
    // Al cargar pantalla, registrar en breadcrumb tracker
    await breadcrumbTracker.push(
        screenKey: screenKey,
        title: screen.screenName,
        icon: iconForPattern(screen.pattern),
        pattern: screen.pattern.rawValue
    )
}
```

### 3. BreadcrumbBar (Vista)

**Ubicacion:** `Packages/Presentation/Sources/Components/Navigation/BreadcrumbBar.swift`

Vista multiplataforma (iOS + macOS) que reemplaza la limitacion macOS-only:

```swift
struct BreadcrumbBar: View {
    let entries: [BreadcrumbTracker.BreadcrumbEntry]
    let onNavigate: (String) -> Void  // entryId

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.small) {
                ForEach(entries) { entry in
                    BreadcrumbChip(entry: entry, isLast: entry == entries.last)
                        .onTapGesture {
                            if entry != entries.last {
                                onNavigate(entry.id)
                            }
                        }

                    if entry != entries.last {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.medium)
        }
    }
}

struct BreadcrumbChip: View {
    let entry: BreadcrumbTracker.BreadcrumbEntry
    let isLast: Bool

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            if let icon = entry.icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(entry.title)
                .font(.caption)
                .lineLimit(1)
        }
        .padding(.horizontal, DesignTokens.Spacing.small)
        .padding(.vertical, DesignTokens.Spacing.xs)
        .background {
            if isLast {
                // Ultimo item: Liquid Glass con enfasis
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                    .fill(.ultraThinMaterial)
            }
        }
        .foregroundStyle(isLast ? .primary : .secondary)
    }
}
```

### 4. Integracion en Toolbar

**Archivo:** `Packages/Presentation/Sources/Components/Navigation/EduDynamicToolbar.swift`

Agregar zona de breadcrumbs debajo del toolbar principal (cuando hay mas de 1 nivel):

```swift
// En el ViewModifier del toolbar
.safeAreaInset(edge: .top) {
    if breadcrumbEntries.count > 1 {
        BreadcrumbBar(entries: breadcrumbEntries, onNavigate: navigateToBreadcrumb)
            .padding(.vertical, DesignTokens.Spacing.xs)
    }
}
```

### 5. Mapeo de Iconos por Patron

```swift
func iconForPattern(_ pattern: ScreenPattern) -> String {
    switch pattern {
    case .dashboard: return "square.grid.2x2"
    case .list: return "list.bullet"
    case .detail: return "doc.text"
    case .form: return "square.and.pencil"
    case .settings: return "gearshape"
    case .search: return "magnifyingglass"
    case .profile: return "person"
    case .modal: return "rectangle.portrait"
    case .notification: return "bell"
    case .onboarding: return "hand.wave"
    case .emptyState: return "tray"
    case .login: return "person.badge.key"
    }
}
```

### 6. Flujo Completo

```
Usuario en Dashboard (root)
  Breadcrumbs: [Dashboard]  (solo 1 — no se muestra bar)

Tap en "Escuelas" (list)
  Breadcrumbs: [Dashboard] > [Escuelas]  (2 items — bar aparece)

Tap en "Escuela ABC" (detail)
  Breadcrumbs: [Dashboard] > [Escuelas] > [Escuela ABC]

Tap en "Editar" (form)
  Breadcrumbs: [Dashboard] > [Escuelas] > [Escuela ABC] > [Editar]

Tap en breadcrumb "Escuelas"
  -> BreadcrumbTracker.navigateTo("Escuelas")
  -> Trail se poda: [Dashboard] > [Escuelas]
  -> AppCoordinator navega a List de escuelas
  -> Items de Detail y Form se remueven del NavigationPath
```

## Archivos a Crear

| Archivo | Paquete | Descripcion |
|---------|---------|-------------|
| `BreadcrumbTracker.swift` | Domain | Actor que gestiona el trail de navegacion |
| `BreadcrumbBar.swift` | Presentation | Vista multiplataforma de breadcrumbs |

## Archivos a Modificar

| Archivo | Cambio |
|---------|--------|
| `Apps/DemoApp/Sources/Screens/DynamicScreenView.swift` | Auto-push al tracker cuando pantalla carga |
| `Apps/DemoApp/Sources/Screens/MainScreen.swift` | Clear breadcrumbs al cambiar seccion de menu |
| `Packages/Presentation/Sources/Components/Navigation/EduDynamicToolbar.swift` | Agregar zona de breadcrumbs |
| `Apps/DemoApp/Sources/Services/ServiceContainer.swift` | Registrar BreadcrumbTracker |

## Tests Requeridos

| Test | Descripcion |
|------|-------------|
| `testPushAddsEntry` | Push agrega entrada al trail |
| `testNavigateToTruncatesTrail` | Tap en breadcrumb poda el trail |
| `testPopRemovesLast` | Back navigation remueve ultimo |
| `testClearEmptiesTrail` | Cambio de seccion limpia trail |
| `testMaxDepthRespected` | Mas de 7 niveles trunca desde inicio |
| `testDuplicateScreenKeyPrunes` | Si se navega a pantalla ya en trail, poda |
| `testStreamNotifiesChanges` | Cada cambio emite en trailStream |
| `testEmptyTrailHidesBreadcrumbs` | Con 0-1 entries no se muestra bar |

## Adaptacion por Plataforma

| Plataforma | Comportamiento |
|------------|---------------|
| **iPhone** | Breadcrumb bar debajo del navigation title, scroll horizontal si es largo |
| **iPad** | Breadcrumb bar en area de toolbar, mas espacio horizontal |
| **macOS** | Breadcrumb bar integrado en title bar area, Liquid Glass completo |

## Estimacion

- **Complejidad:** MEDIA
- **Archivos nuevos:** 2
- **Archivos modificados:** 4
- **Tests nuevos:** 8+
