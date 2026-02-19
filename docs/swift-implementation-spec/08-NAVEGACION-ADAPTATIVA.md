# 08 - Navegacion Adaptativa

## 8.1 Principio

La navegacion se adapta al dispositivo Apple:
- **iPhone**: TabView inferior (hasta 5 tabs)
- **iPad**: Sidebar con NavigationSplitView
- **Mac**: Sidebar permanente con NavigationSplitView

La estructura de navegacion viene del backend y se adapta en el cliente.

## 8.2 Carga de Navegacion

### Request
```
GET /v1/screens/navigation?platform=ios
Authorization: Bearer {token}
```

### Respuesta
```json
{
  "bottom_nav": [
    {"key": "dashboard", "label": "Dashboard", "icon": "dashboard", "screen_key": "dashboard-home", "sort_order": 1},
    {"key": "materials", "label": "Materials", "icon": "folder", "screen_key": "materials-list", "sort_order": 2},
    {"key": "settings", "label": "Settings", "icon": "settings", "screen_key": "app-settings", "sort_order": 3}
  ],
  "drawer_items": [
    {
      "key": "admin",
      "label": "Administration",
      "icon": "settings",
      "sort_order": 1,
      "children": [
        {"key": "users", "label": "Users", "icon": "users", "screen_key": "users-list", "sort_order": 1},
        {"key": "schools", "label": "Schools", "icon": "school", "screen_key": "schools-list", "sort_order": 2},
        {"key": "roles", "label": "Roles", "icon": "shield", "screen_key": "roles-list", "sort_order": 3}
      ]
    }
  ],
  "version": 1
}
```

### Fallback
Si el request falla, usar navegacion hardcodeada:
- Dashboard, Materials, Settings (tabs basicos)

## 8.3 Adaptacion por Dispositivo

### iPhone (Compact)

```
TabView {
  DynamicDashboardScreen()
    .tabItem { Label("Dashboard", systemImage: "square.grid.2x2") }

  DynamicScreen(screenKey: "materials-list")
    .tabItem { Label("Materials", systemImage: "folder") }

  DynamicScreen(screenKey: "app-settings")
    .tabItem { Label("Settings", systemImage: "gearshape") }
}
```

- Max 5 tabs visibles
- Navegacion push dentro de cada tab (NavigationStack)
- Items que no caben van al tab "More"

### iPad (Medium/Expanded)

```
NavigationSplitView {
  // Sidebar
  List(selection: $selectedItem) {
    Section("Dashboard") {
      Label("Home", systemImage: "house")
    }
    Section("Content") {
      Label("Materials", systemImage: "folder")
      Label("Assessments", systemImage: "doc.on.clipboard")
    }
    Section("Admin") {
      Label("Users", systemImage: "person.2")
      Label("Schools", systemImage: "building.columns")
    }
  }
} detail: {
  // Content area
  DynamicScreen(screenKey: selectedScreenKey)
}
```

- Sidebar colapsable
- Drawer items del backend mapean a secciones del sidebar
- Children se muestran como sub-items
- Detail area muestra la pantalla seleccionada

### Mac (Expanded)

```
NavigationSplitView {
  // Sidebar permanente
  List(selection: $selectedItem) {
    // Misma estructura que iPad pero siempre visible
  }
} detail: {
  DynamicScreen(screenKey: selectedScreenKey)
}
.navigationSplitViewStyle(.balanced)
```

- Sidebar siempre visible
- Puede usar 3 columnas (master-detail-inspector)
- Menu bar items para navegacion rapida

## 8.4 Deteccion de Size Class

```
@Environment(\.horizontalSizeClass) var horizontalSizeClass

switch horizontalSizeClass {
  case .compact:  // iPhone portrait
    TabView layout
  case .regular:  // iPad, Mac
    NavigationSplitView layout
}
```

### Tambien considerar
```
#if os(iOS)
  // iPhone/iPad
  if UIDevice.current.userInterfaceIdiom == .pad {
    // iPad specific
  }
#elseif os(macOS)
  // Mac specific
#endif
```

## 8.5 Navegacion Interna (Push)

Cuando una accion produce `NavigateTo(screenKey, params)`:

### En iPhone
```
NavigationStack {
  DynamicScreen(screenKey: currentScreenKey)
    .navigationDestination(for: ScreenRoute.self) { route in
      DynamicScreen(screenKey: route.screenKey, params: route.params)
    }
}
```

### En iPad/Mac
La pantalla se muestra en el detail area del NavigationSplitView.

## 8.6 Pantallas Especiales

Algunas pantallas tienen logica especial que NO se maneja con DynamicScreen generico:

| Screen Key | Logica especial |
|-----------|-----------------|
| `dashboard-*` | Selecciona screenKey segun rol del usuario |
| `app-settings` | Puede tener logica local (tema, idioma) |
| `app-login` | Se muestra fuera del shell de navegacion |

### Dashboard: seleccion por rol
```
let screenKey: String
switch activeContext.roleName {
  case "super_admin", "platform_admin": screenKey = "dashboard-superadmin"
  case "school_admin", "school_director": screenKey = "dashboard-schooladmin"
  case "teacher": screenKey = "dashboard-teacher"
  case "guardian": screenKey = "dashboard-guardian"
  default: screenKey = "dashboard-student"
}
```

## 8.7 Mapeo de Iconos para Navegacion

| Backend icon | SF Symbol (filled) | SF Symbol (outlined) |
|-------------|-------------------|---------------------|
| `home` | house.fill | house |
| `dashboard` | square.grid.2x2.fill | square.grid.2x2 |
| `folder`, `materials` | folder.fill | folder |
| `settings`, `gear` | gearshape.fill | gearshape |
| `person`, `profile` | person.fill | person |
| `people`, `users` | person.2.fill | person.2 |
| `school` | building.columns.fill | building.columns |
| `shield` | shield.fill | shield |
| `key` | key.fill | key |
| `clipboard` | doc.on.clipboard.fill | doc.on.clipboard |
| `trending_up` | chart.line.uptrend.xyaxis | chart.line.uptrend.xyaxis |
| `bar_chart` | chart.bar.fill | chart.bar |

### En SwiftUI
Usar `Image(systemName:)` con el SF Symbol correspondiente. El tab seleccionado usa la variante `.fill`, el no seleccionado la regular.

## 8.8 Deep Linking

Las pantallas se identifican por `screenKey`. Esto permite deep links:

```
edugo://screen/materials-list
edugo://screen/material-detail?id=abc-123
edugo://screen/user-detail?id=xyz-789
```

Cada deep link se traduce a: navegar al tab correcto + push la pantalla con los params.
