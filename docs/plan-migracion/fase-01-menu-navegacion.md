# Fase 1: Menu Dinámico + Navegación Adaptativa

## Objetivo
Implementar el sistema de menú dinámico construido desde el Sync Bundle, filtrado por permisos RBAC, con navegación adaptativa según el tamaño de pantalla (iPhone compacto, iPad, Mac).

## Dependencias
- **Fase 0** completada (Auth + Sync Bundle funcional)

## Contexto KMP (referencia)

### Cómo funciona el menú en KMP
1. El menú viene del sync bundle: `UserDataBundle.menu`
2. Cada `MenuItemDTO` tiene: `key`, `displayName`, `icon`, `permissions`, `screens`, `children`
3. Se filtra por permisos del usuario: solo se muestran items donde el usuario tiene AL MENOS uno de los `permissions` requeridos
4. Adaptación por breakpoints:
   - **COMPACT** (<600dp): `BottomNavigationBar` con máximo 5 items
   - **MEDIUM** (600-840dp): `NavigationRail` con tabs laterales
   - **EXPANDED** (≥840dp): `PermanentNavigationDrawer` con header + secciones
5. El toolbar cambia según el `ScreenPattern` activo

### Mapeo de iconos
KMP usa nombres de Material Icons del backend → mapear a SF Symbols en Swift

---

## Pasos de Implementación

### Paso 1.1: Modelo de Menu filtrado

**Paquete**: `Packages/Domain/Sources/`

**Archivos a crear:**
- `Services/Menu/MenuService.swift`
- `Services/Menu/MenuItem.swift` (modelo de dominio)
- `Services/Menu/MenuFilter.swift`

**Requisitos:**
- `MenuItem` (modelo de dominio): `key`, `displayName`, `icon: String?`, `sortOrder`, `screens: [String: String]`, `children: [MenuItem]`, `requiredPermissions: [String]`
- `MenuFilter`:
  - `static func filter(items: [MenuItemDTO], permissions: [String]) -> [MenuItem]`
  - Recursivo: filtra hijos también
  - Un item es visible si el usuario tiene AL MENOS uno de sus `requiredPermissions`, o si el item no tiene permisos requeridos
  - Si un item padre tiene hijos visibles, el padre se muestra aunque él mismo no tenga permiso explícito
- `MenuService` (actor):
  - `var currentMenu: [MenuItem]` — menu filtrado activo
  - `updateMenu(from bundle: UserDataBundle, context: UserContext)` — reconstruye menú filtrado
  - `AsyncStream<[MenuItem]>` para observar cambios

**Verificar:** `cd Packages/Domain && swift test`

---

### Paso 1.2: Mapeo de iconos Backend → SF Symbols

**Paquete**: `Packages/Presentation/Sources/`

**Archivos a crear:**
- `Utilities/IconMapper.swift`

**Requisitos:**
- `static func sfSymbol(from backendIcon: String) -> String`
- Mapa de Material Icon names → SF Symbol names:
  ```swift
  "home" → "house.fill"
  "school" → "building.columns.fill"
  "people" → "person.2.fill"
  "person" → "person.fill"
  "settings" → "gearshape.fill"
  "assessment" → "checkmark.circle.fill"
  "book" → "book.fill"
  "folder" → "folder.fill"
  "dashboard" → "chart.bar.fill"
  "menu_book" → "text.book.closed.fill"
  "assignment" → "doc.text.fill"
  "group" → "person.3.fill"
  "admin_panel_settings" → "wrench.and.screwdriver.fill"
  "security" → "lock.shield.fill"
  "supervisor_account" → "person.badge.shield.checkmark.fill"
  // ... extender según necesidad
  ```
- Fallback: si no se encuentra mapeo, usar `"questionmark.circle"` y loguear warning

**Verificar:** `cd Packages/Presentation && swift test`

---

### Paso 1.3: Navegación adaptativa - Breakpoints

**Paquete**: `Packages/Presentation/Sources/`

**Archivos a crear:**
- `Navigation/Adaptive/AdaptiveLayoutType.swift`
- `Navigation/Adaptive/AdaptiveNavigationContainer.swift`

**Requisitos:**
- `AdaptiveLayoutType`:
  ```swift
  enum AdaptiveLayoutType {
      case compact    // iPhone portrait
      case medium     // iPhone landscape, iPad split
      case expanded   // iPad full, Mac
  }
  ```
- Usar `@Environment(\.horizontalSizeClass)` de SwiftUI para determinar layout:
  - `.compact` → `AdaptiveLayoutType.compact`
  - `.regular` → `AdaptiveLayoutType.expanded` (en Mac siempre expanded)
  - iPad split → `.medium` (detectar con GeometryReader)

- `AdaptiveNavigationContainer`:
  - Contenedor que cambia la estructura de navegación según layout:
    - **Compact**: `TabView` con máximo 5 items del menú (los primeros por sortOrder) + "Más" si hay más
    - **Medium**: `NavigationSplitView` con sidebar colapsable
    - **Expanded**: `NavigationSplitView` con sidebar permanente (3 columnas en Mac)
  - Recibe `[MenuItem]` como input
  - Cada selección navega a la pantalla dinámica correspondiente

**Verificar:** `make build`

---

### Paso 1.4: Componente de Sidebar/Menu

**Paquete**: `Packages/Presentation/Sources/`

**Archivos a crear:**
- `Components/Navigation/EduSidebar.swift`
- `Components/Navigation/EduMenuSection.swift`
- `Components/Navigation/EduMenuRow.swift`

**Requisitos:**
- `EduSidebar`:
  - Header con avatar del usuario, nombre, rol actual, nombre de escuela
  - Secciones del menú con `DisclosureGroup` para items con children
  - `EduMenuRow` para cada item: icono (SF Symbol mapeado) + displayName
  - Selección resaltada con Liquid Glass effect
  - Footer con botón de configuración y logout

- `EduMenuSection`:
  - Agrupa items del menú por sección (items de primer nivel sin children = una sección cada uno, items con children = sección expandible)
  - Soporta `DisclosureGroup` nativo de SwiftUI

- `EduMenuRow`:
  - Icono + Label + chevron si tiene children
  - Estado seleccionado con glassmorphism

**Verificar:** `make build`

---

### Paso 1.5: Toolbar dinámico por patrón

**Paquete**: `Packages/Presentation/Sources/`

**Archivos a crear:**
- `Components/Navigation/EduDynamicToolbar.swift`

**Requisitos:**
- El toolbar cambia según el `ScreenPattern` activo:
  - **LOGIN**: Sin toolbar
  - **LIST**: Título + botón "Crear" (si permiso) + búsqueda
  - **FORM**: Botón back + título (edit_title o page_title) + botón "Guardar"
  - **DETAIL**: Botón back + título
  - **DASHBOARD**: Solo título
  - **SETTINGS**: Solo título
- Usar `.toolbar {}` de SwiftUI con Liquid Glass effect
- Recibe: `ScreenPattern`, `slotData: [String: JSONValue]?`, `permissions: [String]`
- Emite acciones: `onBack`, `onSave`, `onCreate`, `onSearch(String)`

**Verificar:** `make build`

---

### Paso 1.6: MainScreen refactorizada

**Paquete**: `Apps/DemoApp/`

**Archivos a modificar:**
- `Screens/MainScreen.swift` — reescribir completamente

**Requisitos:**
- Usar `AdaptiveNavigationContainer` con el menú dinámico
- Escuchar `menuService.currentMenu` para actualizar navegación
- Al seleccionar un item del menú → cargar la pantalla dinámica correspondiente (`screenKey` desde `screens` del MenuItem)
- Header del sidebar: datos del usuario desde `authService.currentContext`
- Botón de cambio de escuela (si `availableContexts.count > 1`)
- Logout desde sidebar/menu

**Verificar:** `make build && make test`

---

### Paso 1.7: Selector de Escuela

**Paquete**: `Apps/DemoApp/`

**Archivos a crear:**
- `Screens/SchoolSelectionScreen.swift`

**Requisitos:**
- Pantalla modal/sheet que muestra las escuelas disponibles del usuario
- Lista con: nombre de escuela, rol del usuario en esa escuela
- Al seleccionar → `authService.switchContext(schoolId:)` → nuevos tokens → reload sync bundle → rebuild menú
- Se muestra desde el sidebar cuando hay más de 1 contexto disponible
- También se muestra después del login si el usuario tiene múltiples escuelas

**Verificar:** `make build`

---

### Paso 1.8: Tests de Fase 1

**Archivos a crear:**
- `Packages/Domain/Tests/Services/Menu/MenuFilterTests.swift`
- `Packages/Domain/Tests/Services/Menu/MenuServiceTests.swift`
- `Packages/Presentation/Tests/Navigation/IconMapperTests.swift`

**Requisitos mínimos:**
- MenuFilter filtra correctamente por permisos (items visibles/ocultos)
- MenuFilter maneja recursividad (hijos filtrados)
- MenuFilter maneja caso de items sin permisos requeridos (visibles para todos)
- IconMapper mapea correctamente Material → SF Symbol
- IconMapper retorna fallback para iconos desconocidos
- MenuService actualiza menú cuando cambia el contexto

---

## Criterios de Completitud

- [ ] Menu se construye desde sync bundle con filtrado RBAC
- [ ] Navegación adaptativa: TabView en iPhone, Sidebar en iPad/Mac
- [ ] Iconos del backend mapeados a SF Symbols
- [ ] Toolbar cambia según el patrón de pantalla activo
- [ ] Selección de menú navega a pantalla dinámica correcta
- [ ] Cambio de escuela funciona (switch context + reload)
- [ ] Sidebar muestra info del usuario (nombre, rol, escuela)
- [ ] `make build` sin errores
- [ ] `make test` sin fallos
- [ ] Zero warnings de deprecación
