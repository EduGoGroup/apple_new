# 05 - Dynamic UI - Filosofia y Modelo de Datos

## 5.1 Concepto Central

La UI de EduGo es **100% server-driven**. El backend define QUE mostrar y COMO se comporta. El cliente solo sabe COMO renderizar cada tipo de componente. Esto significa:

- El backend controla la estructura de cada pantalla
- El backend controla que campos tiene un formulario
- El backend controla que acciones estan disponibles
- El backend controla de donde viene la data
- El cliente traduce esa definicion a componentes nativos (SwiftUI)

### Ventajas
- Cambiar UI sin app update
- A/B testing desde el servidor
- Personalizar pantallas por rol/usuario/escuela
- Un solo backend sirve a multiples clientes (KMP, Swift, Web)

### Limites
- El cliente define el set de controles soportados (ControlType)
- El cliente define los patterns soportados (ScreenPattern)
- Si el backend manda un control o pattern desconocido, el cliente muestra fallback

## 5.2 Jerarquia del Modelo

```
ScreenDefinition
├── screenId: String (UUID)
├── screenKey: String (ej: "materials-list", "user-create")
├── screenName: String (nombre legible)
├── pattern: ScreenPattern (tipo de pantalla)
├── version: Int
├── template: ScreenTemplate
│   ├── navigation: NavigationConfig?
│   │   └── topBar: { title, showBack, actions }
│   ├── zones: [Zone]
│   │   ├── id: String
│   │   ├── type: ZoneType
│   │   ├── distribution: Distribution
│   │   ├── condition: String? (renderizado condicional)
│   │   ├── slots: [Slot]
│   │   │   ├── id: String
│   │   │   ├── controlType: ControlType
│   │   │   ├── bind: String? (binding a slotData)
│   │   │   ├── field: String? (binding a data items)
│   │   │   ├── label, value, placeholder, icon
│   │   │   ├── required: Bool
│   │   │   └── style: String?
│   │   ├── zones: [Zone] (recursion!)
│   │   └── itemLayout: ItemLayout? (para listas)
│   │       └── slots: [Slot] (layout de cada item)
│   └── platformOverrides: PlatformOverrides?
│       ├── android: JSON?
│       ├── ios: JSON?
│       ├── desktop: JSON?
│       └── web: JSON?
├── slotData: JSON? (valores estaticos para slots con bind "slot:key")
├── dataEndpoint: String? (de donde cargar datos, ej: "/v1/materials")
├── dataConfig: DataConfig?
│   ├── defaultParams: {key: value}
│   ├── pagination: { pageSize, limitParam, offsetParam }
│   └── refreshInterval: Int?
├── actions: [ActionDefinition]
│   ├── id: String
│   ├── trigger: ActionTrigger (button_click, item_click, pull_refresh, etc.)
│   ├── triggerSlotId: String? (que slot dispara la accion)
│   ├── type: ActionType (NAVIGATE, SUBMIT_FORM, API_CALL, REFRESH, etc.)
│   └── config: JSON (parametros especificos de la accion)
└── updatedAt: String
```

## 5.3 Screen Patterns

Cada pantalla tiene un pattern que determina su renderer:

| Pattern | Descripcion | Uso tipico |
|---------|-------------|-----------|
| `login` | Pantalla de login con marca + form | Login |
| `dashboard` | KPIs + actividad reciente + acciones rapidas | Home por rol |
| `list` | Busqueda + filtros + lista de items + estado vacio | Listas CRUD |
| `detail` | Hero + header + secciones + acciones | Detalle de entidad |
| `form` | Header + campos + botones submit/cancel | Crear/editar entidad |
| `settings` | Secciones agrupadas con switches y nav items | Configuracion |

### Patterns futuros (reservados pero no implementados)
- `search`, `profile`, `modal`, `notification`, `onboarding`, `empty-state`

## 5.4 Zone Types

| Tipo | Descripcion | Contenido |
|------|-------------|-----------|
| `container` | Agrupador generico | Slots en columna |
| `form-section` | Seccion de formulario | Input fields agrupados |
| `simple-list` | Lista plana de items | Header slots + data items con itemLayout |
| `grouped-list` | Lista agrupada | Items en cards separadas |
| `metric-grid` | Grid de metricas/KPIs | metric-card slots en grid 2x2 |
| `action-group` | Grupo de botones | Botones en flow layout |
| `card-list` | Lista en cards | Items como cards |

## 5.5 Distribution (Layout dentro de una Zone)

| Distribution | Descripcion | SwiftUI equivalente |
|-------------|-------------|-------------------|
| `stacked` | Apilado vertical | VStack |
| `side-by-side` | Lado a lado | HStack con weights |
| `grid` | Grid de 2 columnas | LazyVGrid(2 columns) |
| `flow-row` | Flow horizontal | FlowLayout / HStack wrapping |

## 5.6 Control Types (Componentes UI)

### Inputs
| Control | Descripcion | SwiftUI |
|---------|-------------|---------|
| `text-input` | Campo de texto | TextField |
| `email-input` | Campo de email | TextField con .keyboardType(.emailAddress) |
| `password-input` | Campo de password | SecureField |
| `number-input` | Campo numerico | TextField con .keyboardType(.numberPad) |
| `search-bar` | Barra de busqueda | .searchable() o TextField con icono |

### Seleccion
| Control | SwiftUI |
|---------|---------|
| `checkbox` | Toggle con estilo checkbox |
| `switch` | Toggle |
| `radio-group` | Picker con .radioGroup (placeholder, por implementar) |
| `select` | Picker (placeholder, por implementar) |

### Botones
| Control | SwiftUI |
|---------|---------|
| `filled-button` | Button con .buttonStyle(.borderedProminent) |
| `outlined-button` | Button con .buttonStyle(.bordered) |
| `text-button` | Button con .buttonStyle(.plain) |
| `icon-button` | Button con solo icono |

### Display
| Control | SwiftUI |
|---------|---------|
| `label` | Text con estilo segun `style` |
| `icon` | Image(systemName:) |
| `avatar` | Circle con iniciales |
| `image` | AsyncImage |
| `divider` | Divider() |
| `chip` | Capsule con texto (filtro togglable) |
| `rating` | Estrellas (placeholder) |

### Compuestos
| Control | SwiftUI |
|---------|---------|
| `list-item` | HStack con headline + supporting text |
| `list-item-navigation` | NavigationLink o list-item con chevron |
| `metric-card` | Card con label + valor grande |

## 5.7 Bindings y Resolucion de Valores

Cada slot puede tener su valor de 3 fuentes (en orden de prioridad):

### 1. Field binding (datos dinamicos)
```
slot.field = "title"
→ Busca "title" en los datos cargados del dataEndpoint
→ Para items de lista: busca en cada item del array
```

### 2. Slot binding (datos estaticos de la instancia)
```
slot.bind = "slot:page_title"
→ Busca "page_title" en screen.slotData
→ Usado para textos fijos: titulos, labels, placeholders
```

### 3. Valor estatico
```
slot.value = "Hello World"
→ Usa el valor directamente
```

### Pipeline de resolucion
```
1. SlotBindingResolver:
   - Para cada slot con bind "slot:key"
   - Buscar key en slotData
   - Asignar a slot.label (para inputs/switches) o slot.value (para labels/buttons)

2. PlaceholderResolver:
   - Para cada texto con {placeholder}
   - Reemplazar {user.firstName} → "Juan"
   - Reemplazar {today_date} → "February 19, 2026"
   - Reemplazar {context.roleName} → "teacher"
   - Si no encuentra el placeholder, dejar el texto original
```

### Placeholders disponibles
```
{user.firstName}     → Nombre del usuario
{user.lastName}      → Apellido
{user.fullName}      → Nombre completo
{user.email}         → Email
{user.initials}      → Iniciales (2 chars)
{today_date}         → Fecha actual formateada
{context.roleName}   → Nombre del rol activo
{context.schoolName} → Nombre de la escuela activa
{item.id}            → ID del item seleccionado (en listas)
{item.field_name}    → Campo del item seleccionado
```

## 5.8 Renderizado Condicional

Las zones pueden tener una condicion que determina si se muestran:

| Condicion | Significado |
|-----------|-------------|
| `data.isEmpty` | Mostrar solo si no hay datos cargados |
| `!data.isEmpty` o `data.isNotEmpty` | Mostrar solo si hay datos |
| `data.summary != null` | Mostrar si el campo summary existe |
| `field != null` | Campo especifico no es null |
| `field == null` | Campo especifico es null |

### Ejemplo: Empty State
```json
{
  "id": "empty_state",
  "type": "container",
  "condition": "data.isEmpty",
  "slots": [
    {"id": "empty_icon", "controlType": "icon", "bind": "slot:empty_icon"},
    {"id": "empty_title", "controlType": "label", "bind": "slot:empty_state_title"},
    {"id": "empty_desc", "controlType": "label", "bind": "slot:empty_state_description"}
  ]
}
```

## 5.9 Platform Overrides

Cada template puede definir overrides por plataforma:

```json
"platformOverrides": {
  "ios": {
    "distribution": "stacked",
    "maxWidth": null
  },
  "desktop": {
    "distribution": "side-by-side",
    "maxWidth": 700,
    "zones": {
      "brand": {"panel": "left"},
      "form": {"panel": "right"}
    }
  }
}
```

### Para Apple
- `ios` aplica a iPhone y iPad (COMPACT/MEDIUM)
- `desktop` aplica a Mac
- La app puede tambien usar window size classes para decidir layout

## 5.10 Caching de Screen Definitions

### Estrategia de dos niveles
1. **Memoria**: LRU cache con max 20 entries
2. **Disco**: Serializado con timestamp de expiracion

### Validacion del cache
- Expiracion por tiempo (default: 1 hora)
- Invalidacion global via key especial en storage
- `clearCache()` invalida todo el cache
- `evict(screenKey)` invalida una pantalla especifica

### Recomendacion Apple
- Memoria: NSCache o Dictionary con LRU
- Disco: FileManager con JSON files o UserDefaults
- No usar Keychain para cache (es para datos sensibles)
