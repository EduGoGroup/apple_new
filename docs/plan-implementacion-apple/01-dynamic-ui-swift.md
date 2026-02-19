# Sistema Dynamic UI - Especificación Swift 6.2

> Documento de implementación para el sistema de UI dinámica (Server-Driven UI) de EduGo Apple.
> Todo el renderizado de pantallas es dirigido por el servidor. El backend define QUÉ mostrar y CÓMO se comporta. El cliente solo sabe CÓMO renderizar cada componente nativo con SwiftUI + Liquid Glass.

---

## 1. Arquitectura General

### Jerarquía de Definición

```
Screen Template (estructura reutilizable, almacenada en BD como JSONB)
  → Screen Instance (datos específicos por pantalla, screen_key único)
    → Screen Definition (template + instance combinados vía API /v1/screens/:key)
      → Renderer SwiftUI (componentes nativos con Liquid Glass)
```

### Flujo de Renderizado

```
1. DynamicScreenView recibe screenKey
2. ScreenLoader → GET /v1/screens/{screenKey}?platform=ios (con ETag/304)
3. Parsear respuesta → ScreenDefinition
4. SlotBindingResolver resuelve bindings (field > slot:key > estático)
5. PlaceholderResolver reemplaza {user.firstName}, {context.roleName}, etc.
6. Si hay dataEndpoint → DataLoader carga datos (dual API routing)
7. PatternRouter selecciona renderer según pattern
8. Renderer genera vista SwiftUI: zones → slots → componentes nativos
```

### Diagrama de Componentes

```
DynamicUI/
├── Models/          → Estructuras de datos (Codable + Sendable)
├── Loader/          → ScreenLoader (actor), DataLoader (actor)
├── Resolvers/       → SlotBindingResolver, PlaceholderResolver
├── Renderers/       → PatternRouter, ZoneRenderer, SlotRenderer, Patterns/
├── Actions/         → ActionRegistry, ScreenHandlerRegistry, Handlers/
├── ViewModels/      → DynamicScreenViewModel
└── Views/           → DynamicScreenView, DynamicDashboardView
```

---

## 2. Modelos Swift

Todos los modelos son `Sendable`, `Codable`, con `CodingKeys` en snake_case. Se integran con el `JSONValue` existente en `EduModels`.

### 2.1 ScreenDefinition

```swift
struct ScreenDefinition: Codable, Sendable, Identifiable {
    let screenId: String
    let screenKey: String
    let screenName: String
    let pattern: ScreenPattern
    let version: Int
    let template: ScreenTemplate
    let slotData: [String: JSONValue]?
    let dataEndpoint: String?
    let dataConfig: DataConfig?
    let actions: [ActionDefinition]
    let handlerKey: String?
    let updatedAt: String

    var id: String { screenId }

    enum CodingKeys: String, CodingKey {
        case screenId = "screen_id"
        case screenKey = "screen_key"
        case screenName = "screen_name"
        case pattern, version, template
        case slotData = "slot_data"
        case dataEndpoint = "data_endpoint"
        case dataConfig = "data_config"
        case actions
        case handlerKey = "handler_key"
        case updatedAt = "updated_at"
    }
}
```

### 2.2 ScreenPattern

```swift
enum ScreenPattern: String, Codable, Sendable, CaseIterable {
    case login
    case form
    case list
    case dashboard
    case settings
    case detail
    case search
    case profile
    case modal
    case notification
    case onboarding
    case emptyState = "empty-state"
}
```

### 2.3 ScreenTemplate

```swift
struct ScreenTemplate: Codable, Sendable {
    let navigation: NavigationConfig?
    let zones: [Zone]
    let platformOverrides: [String: PlatformOverride]?

    enum CodingKeys: String, CodingKey {
        case navigation, zones
        case platformOverrides = "platform_overrides"
    }
}

struct NavigationConfig: Codable, Sendable {
    let topBar: TopBarConfig?

    enum CodingKeys: String, CodingKey {
        case topBar = "top_bar"
    }
}

struct TopBarConfig: Codable, Sendable {
    let title: String?
    let showBack: Bool?

    enum CodingKeys: String, CodingKey {
        case title
        case showBack = "show_back"
    }
}

struct PlatformOverride: Codable, Sendable {
    let distribution: String?
    let zones: [String: ZoneOverride]?
}

struct ZoneOverride: Codable, Sendable {
    let visible: Bool?
    let height: Int?
    let distribution: String?
}
```

### 2.4 Zone

```swift
struct Zone: Codable, Sendable, Identifiable {
    let id: String
    let type: ZoneType
    let distribution: Distribution?
    let condition: String?
    let slots: [Slot]?
    let zones: [Zone]?       // Composición recursiva
    let itemLayout: ItemLayout?

    enum CodingKeys: String, CodingKey {
        case id, type, distribution, condition, slots, zones
        case itemLayout = "item_layout"
    }
}

struct ItemLayout: Codable, Sendable {
    let slots: [Slot]
}

enum ZoneType: String, Codable, Sendable {
    case container
    case formSection = "form-section"
    case simpleList = "simple-list"
    case groupedList = "grouped-list"
    case metricGrid = "metric-grid"
    case actionGroup = "action-group"
    case cardList = "card-list"
}

enum Distribution: String, Codable, Sendable {
    case stacked
    case sideBySide = "side-by-side"
    case grid
    case flowRow = "flow-row"
}
```

### 2.5 Slot

```swift
struct Slot: Codable, Sendable, Identifiable {
    let id: String
    let controlType: ControlType
    let bind: String?
    let field: String?
    let label: String?
    let value: JSONValue?
    let placeholder: String?
    let icon: String?
    let required: Bool?
    let readOnly: Bool?
    let style: String?
    let width: String?
    let weight: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case controlType = "control_type"
        case bind, field, label, value, placeholder, icon
        case required
        case readOnly = "read_only"
        case style, width, weight
    }
}

enum ControlType: String, Codable, Sendable {
    // Inputs
    case textInput = "text-input"
    case emailInput = "email-input"
    case passwordInput = "password-input"
    case numberInput = "number-input"
    case searchBar = "search-bar"
    // Selección
    case checkbox
    case `switch`
    case radioGroup = "radio-group"
    case select
    // Botones
    case filledButton = "filled-button"
    case outlinedButton = "outlined-button"
    case textButton = "text-button"
    case iconButton = "icon-button"
    // Display
    case label
    case icon
    case avatar
    case image
    case divider
    case chip
    case rating
    // Compuestos
    case listItem = "list-item"
    case listItemNavigation = "list-item-navigation"
    case metricCard = "metric-card"
}
```

### 2.6 ActionDefinition

```swift
struct ActionDefinition: Codable, Sendable, Identifiable {
    let id: String
    let trigger: ActionTrigger
    let triggerSlotId: String?
    let type: ActionType
    let config: [String: JSONValue]?

    enum CodingKeys: String, CodingKey {
        case id, trigger
        case triggerSlotId = "trigger_slot_id"
        case type, config
    }
}

enum ActionTrigger: String, Codable, Sendable {
    case buttonClick = "BUTTON_CLICK"
    case itemClick = "ITEM_CLICK"
    case pullRefresh = "PULL_REFRESH"
    case fabClick = "FAB_CLICK"
    case swipe = "SWIPE"
    case longPress = "LONG_PRESS"
}

enum ActionType: String, Codable, Sendable {
    case navigate = "NAVIGATE"
    case navigateBack = "NAVIGATE_BACK"
    case apiCall = "API_CALL"
    case submitForm = "SUBMIT_FORM"
    case refresh = "REFRESH"
    case confirm = "CONFIRM"
    case logout = "LOGOUT"
    case custom = "CUSTOM"
    case openUrl = "OPEN_URL"
}
```

### 2.7 DataConfig

```swift
struct DataConfig: Codable, Sendable {
    let defaultParams: [String: String]?
    let pagination: PaginationConfig?
    let refreshInterval: Int?

    enum CodingKeys: String, CodingKey {
        case defaultParams = "default_params"
        case pagination
        case refreshInterval = "refresh_interval"
    }
}

struct PaginationConfig: Codable, Sendable {
    let pageSize: Int
    let limitParam: String
    let offsetParam: String

    enum CodingKeys: String, CodingKey {
        case pageSize = "page_size"
        case limitParam = "limit_param"
        case offsetParam = "offset_param"
    }
}
```

### 2.8 NavigationDefinition

```swift
struct NavigationDefinition: Codable, Sendable {
    let bottomNav: [NavItem]
    let drawerItems: [NavItem]?
    let version: Int

    enum CodingKeys: String, CodingKey {
        case bottomNav = "bottom_nav"
        case drawerItems = "drawer_items"
        case version
    }
}

struct NavItem: Codable, Sendable, Identifiable {
    let key: String
    let label: String
    let icon: String
    let screenKey: String
    let sortOrder: Int
    let children: [NavItem]?

    var id: String { key }

    enum CodingKeys: String, CodingKey {
        case key, label, icon
        case screenKey = "screen_key"
        case sortOrder = "sort_order"
        case children
    }
}
```

### 2.9 ActionContext y ActionResult

```swift
struct ActionContext: Sendable {
    let screenKey: String
    let actionId: String
    let config: [String: JSONValue]?
    let fieldValues: [String: String]
    let selectedItemId: String?
    let selectedItem: [String: JSONValue]?
}

enum ActionResult: Sendable {
    case navigateTo(screenKey: String, params: [String: String]?)
    case success(message: String?)
    case error(message: String)
    case logout
    case cancelled
    case refresh
}
```

### 2.10 Estados

```swift
enum ScreenState: Sendable {
    case loading
    case ready(ScreenDefinition)
    case error(String)
}

enum DataState: Sendable {
    case idle
    case loading
    case success(items: [[String: JSONValue]], hasMore: Bool, loadingMore: Bool)
    case error(String)
}
```

---

## 3. ScreenLoader

Actor responsable de cargar y cachear definiciones de pantalla.

```swift
actor ScreenLoader {
    private let networkClient: NetworkClientProtocol
    private var memoryCache: [String: CachedScreen] = [:]  // LRU, max 20
    private var etagCache: [String: String] = [:]

    struct CachedScreen {
        let screen: ScreenDefinition
        let cachedAt: Date
        let etag: String?
    }

    /// Carga una pantalla con soporte de cache y ETag
    func loadScreen(key: String) async throws -> ScreenDefinition {
        // 1. Buscar en memoria (si < 1 hora)
        // 2. GET /v1/screens/{key}?platform=ios con If-None-Match
        // 3. Si 304 → retornar de cache
        // 4. Si 200 → parsear, cachear, retornar
        // 5. Si error y hay cache → retornar cache (stale)
    }

    func invalidateCache(key: String) { memoryCache.removeValue(forKey: key) }
    func clearCache() { memoryCache.removeAll() }
}
```

**Integración**: Usa el `NetworkClientProtocol` existente en `EduNetwork` con `AuthenticationInterceptor` para inyectar Bearer token automáticamente.

---

## 4. DataLoader

Actor responsable de cargar datos dinámicos con soporte dual-API.

```swift
actor DataLoader {
    private let networkClient: NetworkClientProtocol
    private let adminBaseURL: URL   // Puerto 8081
    private let mobileBaseURL: URL  // Puerto 9091

    /// Carga datos de un endpoint con routing dual-API
    func loadData(
        endpoint: String,
        config: DataConfig?,
        params: [String: String]? = nil
    ) async throws -> [String: JSONValue] {
        // Routing: "admin:" prefix → adminBaseURL, else → mobileBaseURL
        // Inyectar defaultParams de config
        // Ejecutar GET con networkClient
    }

    /// Carga siguiente página (offset-based)
    func loadNextPage(
        endpoint: String,
        config: DataConfig?,
        currentOffset: Int
    ) async throws -> [String: JSONValue] {
        // Calcular offset: currentOffset + config.pagination.pageSize
        // GET con limit y offset params
    }
}
```

**Routing Dual-API**:
- `endpoint` empieza con `admin:` → quitar prefijo, usar `adminBaseURL`
- `endpoint` empieza con `mobile:` → quitar prefijo, usar `mobileBaseURL`
- Sin prefijo → usar `mobileBaseURL` (default)

---

## 5. Resolvers

### 5.1 SlotBindingResolver

Resuelve el valor de un slot usando 3 fuentes en orden de prioridad:

```swift
struct SlotBindingResolver: Sendable {
    /// Resuelve el valor de un slot
    /// Prioridad: 1) field → datos del dataEndpoint
    ///            2) bind "slot:key" → slotData estático
    ///            3) value → valor literal del slot
    func resolve(
        slot: Slot,
        data: [String: JSONValue]?,
        slotData: [String: JSONValue]?
    ) -> JSONValue? {
        // 1. Si slot.field != nil → buscar en data[slot.field]
        // 2. Si slot.bind?.hasPrefix("slot:") → buscar en slotData[key]
        // 3. Retornar slot.value
    }
}
```

### 5.2 PlaceholderResolver

Reemplaza placeholders `{...}` en strings con valores del contexto.

```swift
struct PlaceholderResolver: Sendable {
    let user: AuthUserInfo
    let context: UserContext

    /// Reemplaza placeholders en un string
    func resolve(_ text: String, itemData: [String: JSONValue]? = nil) -> String {
        // {user.firstName} → user.firstName
        // {user.lastName} → user.lastName
        // {user.email} → user.email
        // {user.fullName} → user.fullName
        // {context.roleName} → context.roleName
        // {context.schoolName} → context.schoolName
        // {context.academicUnitName} → context.academicUnitName
        // {today_date} → Date formatted
        // {current_year} → Calendar year
        // {item.fieldName} → itemData["fieldName"]
    }
}
```

---

## 6. Renderers

### 6.1 PatternRouter

```swift
struct PatternRouter: View {
    let screen: ScreenDefinition
    let data: [[String: JSONValue]]
    let formState: FormState
    let onAction: (ActionDefinition, ActionContext) async -> ActionResult

    var body: some View {
        switch screen.pattern {
        case .login:      LoginPatternRenderer(screen: screen, formState: formState, onAction: onAction)
        case .dashboard:  DashboardPatternRenderer(screen: screen, data: data, onAction: onAction)
        case .list:       ListPatternRenderer(screen: screen, data: data, onAction: onAction)
        case .detail:     DetailPatternRenderer(screen: screen, data: data, onAction: onAction)
        case .form:       FormPatternRenderer(screen: screen, formState: formState, onAction: onAction)
        case .settings:   SettingsPatternRenderer(screen: screen, onAction: onAction)
        default:          FallbackRenderer(screen: screen)
        }
    }
}
```

### 6.2 ZoneRenderer

Renderiza una `Zone` según su `type` y `distribution`. Soporta composición recursiva.

```swift
struct ZoneRenderer: View {
    let zone: Zone
    let data: [String: JSONValue]?
    let slotData: [String: JSONValue]?
    let formState: FormState
    let onAction: (ActionDefinition, ActionContext) async -> ActionResult

    var body: some View {
        // 1. Evaluar zone.condition (si existe)
        // 2. Según zone.distribution:
        //    stacked → VStack
        //    sideBySide → HStack
        //    grid → LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())])
        //    flowRow → Layout protocol custom
        // 3. Renderizar zone.slots con SlotRenderer
        // 4. Renderizar zone.zones recursivamente con ZoneRenderer
    }
}
```

**Evaluación de condiciones**:
- `"data.isEmpty"` → data == nil o data vacío
- `"data.isNotEmpty"` → data tiene elementos
- `"field != null"` → campo específico no es nil

### 6.3 SlotRenderer

Mapea cada `ControlType` a un componente SwiftUI nativo del Design System existente:

| ControlType | Componente SwiftUI | Notas |
|-------------|-------------------|-------|
| `text-input` | `EduTextField` | Keyboard .default |
| `email-input` | `EduTextField` | Keyboard .emailAddress, contentType .emailAddress |
| `password-input` | `EduSecureField` | |
| `number-input` | `EduTextField` | Keyboard .numberPad |
| `search-bar` | `EduSearchField` | |
| `checkbox` | `Toggle` | `.toggleStyle(.checkbox)` |
| `switch` | `Toggle` | `.toggleStyle(.switch)` |
| `radio-group` | `Picker(.segmented)` o custom | iOS no tiene radio nativo |
| `select` | `Picker(.menu)` | |
| `filled-button` | `EduButton(.filled)` | |
| `outlined-button` | `EduButton(.outlined)` | |
| `text-button` | `EduButton(.text)` | |
| `icon-button` | `EduButton(.icon)` | |
| `label` | `Text` | Estilo según `slot.style` (headline-large, body, caption, etc.) |
| `icon` | `Image(systemName:)` | Usar IconMapper para SF Symbols |
| `avatar` | `AsyncImage` | Circular, con placeholder |
| `image` | `AsyncImage` | |
| `divider` | `Divider()` | |
| `chip` | Custom `EduChip` | |
| `rating` | Custom estrellas | |
| `list-item` | `EduRow` | Sin chevron |
| `list-item-navigation` | `EduRow` | Con chevron disclosure |
| `metric-card` | Card con valor destacado | Usa `EduLiquidGlass` |

---

## 7. Pattern Renderers

### 7.1 LoginPatternRenderer
- Renderiza form con email, password, botón de login
- Usa `FormState` para field values y errors
- Trigger: `BUTTON_CLICK` → handler `login`
- Layout: centrado con branding zone arriba

### 7.2 DashboardPatternRenderer
- Renderiza métricas (metric-grid), listas rápidas, acciones
- Si hay `dataEndpoint` (ej: `/v1/stats/global`) → carga KPIs
- Adapta layout por `horizontalSizeClass`:
  - compact → VStack stacked
  - regular → Grid de 2-3 columnas

### 7.3 ListPatternRenderer
- `.searchable()` nativo si hay slot `search-bar`
- Paginación infinita: `.onAppear` en último item → `loadNextPage()`
- Pull-to-refresh: `.refreshable { await refreshData() }`
- Empty state: zone con `condition: "data.isEmpty"`
- Items: zone `simple-list` con `itemLayout` para cada fila

### 7.4 DetailPatternRenderer
- Secciones de información (zones tipo `container`)
- Acciones en toolbar (editar, eliminar, descargar)
- Adaptativo: compact → stacked, regular → side-by-side

### 7.5 FormPatternRenderer
- `Form {}` nativo de SwiftUI
- Zones tipo `form-section` → `Section(header:)`
- Validación: `slot.required` → campo obligatorio
- Submit: zona `action-group` con `SUBMIT_FORM`
- Botones en toolbar, no inline

### 7.6 SettingsPatternRenderer
- `List` con secciones agrupadas
- Toggles para switches (tema dark/light)
- `list-item-navigation` para sub-pantallas
- Acción `LOGOUT` en sección inferior

---

## 8. Sistema de Acciones

### 8.1 ActionRegistry (acciones genéricas)

```swift
@Observable
final class ActionRegistry {
    private var handlers: [ActionType: (ActionContext) async -> ActionResult] = [:]

    init() {
        // Registrar handlers genéricos
        register(.navigate) { context in
            guard let screenKey = context.config?["screen_key"]?.stringValue else {
                return .error("screen_key requerido")
            }
            let params = context.config?["params"]?.objectValue?.compactMapValues(\.stringValue)
            return .navigateTo(screenKey: screenKey, params: params)
        }
        register(.navigateBack) { _ in .navigateTo(screenKey: "__back__", params: nil) }
        register(.refresh) { _ in .refresh }
        register(.logout) { _ in .logout }
    }

    func execute(action: ActionDefinition, context: ActionContext) async -> ActionResult
}
```

### 8.2 ScreenHandlerRegistry (acciones por pantalla)

Usa `handlerKey` del screen instance para delegar a handlers específicos:

```swift
@Observable
final class ScreenHandlerRegistry {
    private var handlers: [String: ScreenHandler] = [:]

    init(authService: AuthService, networkClient: NetworkClientProtocol) {
        register("login", LoginActionHandler(authService: authService))
        register("settings", SettingsActionHandler(authService: authService))
        register("material-create", MaterialCrudHandler(networkClient: networkClient, mode: .create))
        register("material-edit", MaterialCrudHandler(networkClient: networkClient, mode: .edit))
        register("user-create", UserCrudHandler(networkClient: networkClient, mode: .create))
        register("user-edit", UserCrudHandler(networkClient: networkClient, mode: .edit))
        register("school-create", SchoolCrudHandler(networkClient: networkClient, mode: .create))
        register("school-edit", SchoolCrudHandler(networkClient: networkClient, mode: .edit))
        register("unit-create", UnitCrudHandler(networkClient: networkClient, mode: .create))
        register("unit-edit", UnitCrudHandler(networkClient: networkClient, mode: .edit))
        register("membership-add", MembershipHandler(networkClient: networkClient))
        register("assessment-take", AssessmentTakeHandler(networkClient: networkClient))
        // progress-*, guardian-*, dashboard-* → handlers de navegación
    }
}

protocol ScreenHandler: Sendable {
    func handle(action: ActionDefinition, context: ActionContext) async -> ActionResult
}
```

### 8.3 Screen Handlers

| handlerKey | Endpoint | Método | Descripción |
|------------|----------|--------|-------------|
| `login` | `/v1/auth/login` | POST | Login, guardar token en Keychain |
| `settings` | `/v1/auth/logout` | POST | Logout, toggle tema |
| `material-create` | `/v1/materials` | POST | Crear material |
| `material-edit` | `/v1/materials/{id}` | PUT | Editar material |
| `user-create` | `admin:/v1/users` | POST | Crear usuario (API Admin) |
| `user-edit` | `admin:/v1/users/{id}` | PUT | Editar usuario (API Admin) |
| `school-create` | `admin:/v1/schools` | POST | Crear escuela (API Admin) |
| `school-edit` | `admin:/v1/schools/{id}` | PUT | Editar escuela (API Admin) |
| `unit-create` | `admin:/v1/schools/{id}/units` | POST | Crear unidad (API Admin) |
| `unit-edit` | `admin:/v1/units/{id}` | PUT | Editar unidad (API Admin) |
| `membership-add` | `admin:/v1/memberships` | POST | Agregar miembro (API Admin) |
| `assessment-take` | `/v1/materials/{id}/assessment/attempts` | POST | Enviar intento |
| `dashboard-*` | N/A | N/A | Navegación por rol |
| `progress-*` | N/A | N/A | Navegación entre vistas |
| `guardian-*` | N/A | N/A | Navegación de guardian |

---

## 9. DynamicScreenViewModel

```swift
@Observable
@MainActor
final class DynamicScreenViewModel {
    // Estado
    private(set) var screenState: ScreenState = .loading
    private(set) var dataState: DataState = .idle
    let formState = FormState()

    // Dependencias
    private let screenLoader: ScreenLoader
    private let dataLoader: DataLoader
    private let actionRegistry: ActionRegistry
    private let handlerRegistry: ScreenHandlerRegistry
    private let bindingResolver: SlotBindingResolver
    private let placeholderResolver: PlaceholderResolver

    // Screen actual
    private var currentScreen: ScreenDefinition?
    private var currentOffset: Int = 0

    func loadScreen(key: String) async {
        screenState = .loading
        do {
            let screen = try await screenLoader.loadScreen(key: key)
            currentScreen = screen
            screenState = .ready(screen)
            if screen.dataEndpoint != nil {
                await loadData()
            }
        } catch {
            screenState = .error(error.localizedDescription)
        }
    }

    func loadData() async {
        guard let screen = currentScreen, let endpoint = screen.dataEndpoint else { return }
        dataState = .loading
        do {
            let result = try await dataLoader.loadData(endpoint: endpoint, config: screen.dataConfig)
            let items = extractItems(from: result)
            let hasMore = items.count >= (screen.dataConfig?.pagination?.pageSize ?? 20)
            dataState = .success(items: items, hasMore: hasMore, loadingMore: false)
            currentOffset = items.count
        } catch {
            dataState = .error(error.localizedDescription)
        }
    }

    func loadNextPage() async {
        guard let screen = currentScreen, let endpoint = screen.dataEndpoint,
              case .success(let items, let hasMore, false) = dataState, hasMore else { return }
        dataState = .success(items: items, hasMore: hasMore, loadingMore: true)
        do {
            let result = try await dataLoader.loadNextPage(
                endpoint: endpoint, config: screen.dataConfig, currentOffset: currentOffset
            )
            let newItems = extractItems(from: result)
            let allItems = items + newItems
            let stillHasMore = newItems.count >= (screen.dataConfig?.pagination?.pageSize ?? 20)
            dataState = .success(items: allItems, hasMore: stillHasMore, loadingMore: false)
            currentOffset = allItems.count
        } catch {
            dataState = .success(items: items, hasMore: false, loadingMore: false)
        }
    }

    func refreshData() async {
        currentOffset = 0
        await loadData()
    }

    func executeAction(_ action: ActionDefinition, context: ActionContext) async -> ActionResult {
        // 1. Si hay handlerKey → delegar a ScreenHandlerRegistry
        if let handlerKey = currentScreen?.handlerKey {
            if let result = await handlerRegistry.handle(
                handlerKey: handlerKey, action: action, context: context
            ) {
                return result
            }
        }
        // 2. Fallback a ActionRegistry genérico
        return await actionRegistry.execute(action: action, context: context)
    }
}
```

---

## 10. FormState

```swift
@Observable
@MainActor
final class FormState {
    var fieldValues: [String: String] = [:]
    var fieldErrors: [String: String] = [:]

    func setValue(fieldId: String, value: String) {
        fieldValues[fieldId] = value
        fieldErrors.removeValue(forKey: fieldId) // Limpiar error al editar
    }

    func getValue(fieldId: String) -> String {
        fieldValues[fieldId] ?? ""
    }

    func validate(slots: [Slot]) -> Bool {
        fieldErrors.removeAll()
        var isValid = true
        for slot in slots where slot.required == true {
            if let fieldId = slot.field ?? slot.id as String?,
               (fieldValues[fieldId] ?? "").trimmingCharacters(in: .whitespaces).isEmpty {
                fieldErrors[fieldId] = "\(slot.label ?? fieldId) es obligatorio"
                isValid = false
            }
        }
        return isValid
    }

    func clear() {
        fieldValues.removeAll()
        fieldErrors.removeAll()
    }
}
```

---

## 11. DynamicScreenView

```swift
struct DynamicScreenView: View {
    let screenKey: String
    @State private var viewModel: DynamicScreenViewModel
    @Environment(\.dismiss) private var dismiss

    init(screenKey: String, viewModel: DynamicScreenViewModel) {
        self.screenKey = screenKey
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.screenState {
            case .loading:
                ProgressView()
                    .glassEffect()
            case .ready(let screen):
                screenContent(screen)
            case .error(let message):
                EduErrorStateView(message: message) {
                    Task { await viewModel.loadScreen(key: screenKey) }
                }
            }
        }
        .task { await viewModel.loadScreen(key: screenKey) }
    }

    @ViewBuilder
    private func screenContent(_ screen: ScreenDefinition) -> some View {
        let data: [[String: JSONValue]] = {
            if case .success(let items, _, _) = viewModel.dataState { return items }
            return []
        }()

        PatternRouter(
            screen: screen,
            data: data,
            formState: viewModel.formState,
            onAction: { action, context in
                await viewModel.executeAction(action, context: context)
            }
        )
        .navigationTitle(screen.screenName)
    }
}
```

---

## 12. Navegación Dinámica

La configuración de tabs y sidebar viene del servidor: `GET /v1/screens/navigation?platform=ios`

### iPhone (compact)
```swift
TabView {
    ForEach(navigation.bottomNav) { item in
        DynamicScreenView(screenKey: item.screenKey, viewModel: ...)
            .tabItem {
                Label(item.label, systemImage: IconMapper.sfSymbol(for: item.icon))
            }
    }
}
```

### iPad / Mac (regular)
```swift
NavigationSplitView {
    List(selection: $selectedScreenKey) {
        ForEach(navigation.drawerItems ?? navigation.bottomNav) { item in
            NavigationLink(value: item.screenKey) {
                Label(item.label, systemImage: IconMapper.sfSymbol(for: item.icon))
            }
        }
    }
    .navigationTitle("EduGo")
} detail: {
    if let key = selectedScreenKey {
        DynamicScreenView(screenKey: key, viewModel: ...)
    }
}
```

### Fallback (si falla la carga)
```swift
let fallbackNav = NavigationDefinition(
    bottomNav: [
        NavItem(key: "dashboard", label: "Inicio", icon: "home",
                screenKey: dashboardKeyForRole(context.roleName), sortOrder: 0, children: nil),
        NavItem(key: "materials", label: "Materiales", icon: "book",
                screenKey: "materials-list", sortOrder: 1, children: nil),
        NavItem(key: "settings", label: "Ajustes", icon: "settings",
                screenKey: "app-settings", sortOrder: 2, children: nil)
    ],
    drawerItems: nil,
    version: 0
)
```

### Dashboard por Rol
```swift
func dashboardKeyForRole(_ roleName: String) -> String {
    switch roleName {
    case "super_admin", "platform_admin": return "dashboard-superadmin"
    case "school_admin", "school_director": return "dashboard-schooladmin"
    case "teacher": return "dashboard-teacher"
    case "guardian": return "dashboard-guardian"
    default: return "dashboard-student"
    }
}
```

---

## 13. Caching Strategy

| Nivel | Mecanismo | Configuración |
|-------|-----------|---------------|
| Memoria | LRU dictionary en actor | Max 20 entries |
| Disco | FileManager JSON serializado | Expiración 1 hora |
| HTTP | ETag + If-None-Match | 304 Not Modified |
| HTTP | Cache-Control | Respetar max-age (3600s) |

**Invalidación**: Al ejecutar un SUBMIT_FORM o API_CALL exitoso que modifica datos, invalidar el cache de la pantalla afectada.

---

## 14. Screen Instances Disponibles (38)

Referencia de todas las pantallas dinámicas configuradas en el backend:

| screen_key | pattern | handlerKey | dataEndpoint |
|------------|---------|------------|-------------|
| app-login | login | login | - |
| dashboard-teacher | dashboard | dashboard-teacher | admin:/v1/stats/global |
| dashboard-student | dashboard | dashboard-student | admin:/v1/stats/global |
| dashboard-superadmin | dashboard | dashboard-superadmin | admin:/v1/stats/global |
| dashboard-schooladmin | dashboard | dashboard-schooladmin | admin:/v1/stats/global |
| dashboard-guardian | dashboard | dashboard-guardian | - |
| materials-list | list | - | mobile:/v1/materials |
| material-detail | detail | material-detail | mobile:/v1/materials/{id} |
| material-create | form | material-create | - |
| material-edit | form | material-edit | mobile:/v1/materials/{id} |
| assessments-list | list | - | - |
| assessment-take | form | assessment-take | mobile:/v1/materials/{id}/assessment |
| assessment-result | detail | - | mobile:/v1/attempts/{id}/results |
| attempts-history | list | - | mobile:/v1/users/me/attempts |
| progress-my | list | progress-my | mobile:/v1/progress |
| progress-unit-list | list | progress-unit-list | - |
| progress-student-detail | detail | progress-student-detail | - |
| users-list | list | - | admin:/v1/users |
| user-detail | detail | - | admin:/v1/users/{id} |
| user-create | form | user-create | - |
| user-edit | form | user-edit | admin:/v1/users/{id} |
| schools-list | list | - | admin:/v1/schools |
| school-detail | detail | - | admin:/v1/schools/{id} |
| school-create | form | school-create | - |
| school-edit | form | school-edit | admin:/v1/schools/{id} |
| units-list | list | - | admin:/v1/schools/{id}/units |
| unit-detail | detail | - | admin:/v1/units/{id} |
| unit-create | form | unit-create | - |
| unit-edit | form | unit-edit | admin:/v1/units/{id} |
| memberships-list | list | - | admin:/v1/memberships |
| membership-add | form | membership-add | - |
| children-list | list | guardian-children | - |
| child-progress | detail | guardian-progress | - |
| roles-list | list | - | admin:/v1/roles |
| role-detail | detail | - | admin:/v1/roles/{id} |
| resources-list | list | - | admin:/v1/resources |
| permissions-list | list | - | admin:/v1/permissions |
| app-settings | settings | settings | - |

---

## 15. Estructura de Archivos Final

```
Packages/DynamicUI/
├── Sources/
│   └── DynamicUI/
│       ├── Models/
│       │   ├── ScreenDefinition.swift
│       │   ├── ScreenPattern.swift
│       │   ├── ScreenTemplate.swift
│       │   ├── Zone.swift
│       │   ├── Slot.swift
│       │   ├── ControlType.swift
│       │   ├── ActionDefinition.swift
│       │   ├── DataConfig.swift
│       │   ├── NavigationDefinition.swift
│       │   └── ScreenState.swift
│       ├── Loader/
│       │   ├── ScreenLoader.swift
│       │   └── DataLoader.swift
│       ├── Resolvers/
│       │   ├── SlotBindingResolver.swift
│       │   └── PlaceholderResolver.swift
│       ├── Renderers/
│       │   ├── PatternRouter.swift
│       │   ├── ZoneRenderer.swift
│       │   ├── SlotRenderer.swift
│       │   └── Patterns/
│       │       ├── LoginPatternRenderer.swift
│       │       ├── DashboardPatternRenderer.swift
│       │       ├── ListPatternRenderer.swift
│       │       ├── DetailPatternRenderer.swift
│       │       ├── FormPatternRenderer.swift
│       │       └── SettingsPatternRenderer.swift
│       ├── Actions/
│       │   ├── ActionRegistry.swift
│       │   ├── ScreenHandlerRegistry.swift
│       │   ├── ScreenHandler.swift
│       │   └── Handlers/
│       │       ├── LoginActionHandler.swift
│       │       ├── SettingsActionHandler.swift
│       │       ├── DashboardActionHandler.swift
│       │       ├── MaterialCrudHandler.swift
│       │       ├── UserCrudHandler.swift
│       │       ├── SchoolCrudHandler.swift
│       │       ├── UnitCrudHandler.swift
│       │       ├── MembershipHandler.swift
│       │       ├── AssessmentTakeHandler.swift
│       │       ├── ProgressHandler.swift
│       │       └── GuardianHandler.swift
│       ├── ViewModels/
│       │   ├── DynamicScreenViewModel.swift
│       │   └── FormState.swift
│       ├── Views/
│       │   ├── DynamicScreenView.swift
│       │   ├── DynamicDashboardView.swift
│       │   └── DynamicNavigationView.swift
│       └── Utilities/
│           └── IconMapper.swift
└── Tests/
    └── DynamicUITests/
        ├── Models/
        │   └── ScreenDefinitionTests.swift
        ├── Loader/
        │   ├── ScreenLoaderTests.swift
        │   └── DataLoaderTests.swift
        ├── Resolvers/
        │   ├── SlotBindingResolverTests.swift
        │   └── PlaceholderResolverTests.swift
        └── Actions/
            └── ActionRegistryTests.swift
```

---

## 16. Integración con Módulos Existentes

| Módulo Existente | Cómo se integra con Dynamic UI |
|-----------------|-------------------------------|
| `EduNetwork` (NetworkClientProtocol) | ScreenLoader y DataLoader usan el NetworkClient con interceptores |
| `EduModels` (JSONValue) | Reusar JSONValue existente para parsear JSONB genérico |
| `EduPresentation` (Componentes Edu*) | SlotRenderer mapea ControlType a EduButton, EduTextField, etc. |
| `EduPresentation` (Theme/LiquidGlass) | Renderers aplican glass effects del design system |
| `EduPresentation` (Coordinators) | ActionResult.navigateTo se integra con AppCoordinator |
| `EduDomain` (AuthService) | LoginActionHandler delega al AuthService/LoginUseCase existente |
| `EduInfrastructure` (Storage) | Tokens en Keychain, cache de screens en FileManager |
| `EduDomain` (RoleManager) | Dashboard por rol usa el contexto activo del AuthState |
