# 06 - Dynamic UI - Pipeline de Renderizado

## 6.1 Pipeline Completo

```
1. Solicitar pantalla
   GET /v1/screens/{screenKey}?platform=ios
   → Recibir ScreenDefinition JSON

2. Parsear respuesta
   JSON → ScreenDefinition (modelo local)

3. Resolver bindings
   SlotBindingResolver: slot.bind "slot:key" → buscar en slotData
   PlaceholderResolver: "Hello {user.firstName}" → "Hello Juan"

4. Seleccionar renderer por pattern
   pattern == "list"   → ListRenderer
   pattern == "form"   → FormRenderer
   pattern == "detail" → DetailRenderer
   ...

5. Renderizar zones recursivamente
   Para cada zone en template.zones:
     - Evaluar condition (mostrar/ocultar)
     - Aplicar distribution (stacked, side-by-side, grid)
     - Renderizar slots o sub-zones

6. Cargar datos (si tiene dataEndpoint)
   GET {dataEndpoint} con dataConfig params
   → Popular los field bindings con datos reales

7. Esperar interaccion del usuario
   Click boton → buscar action → ejecutar handler → resultado
```

## 6.2 Estado de la Pantalla

Cada pantalla dinamica mantiene estos estados reactivos:

### ScreenState
```
Loading           → Cargando definicion de pantalla
Ready(screen)     → Pantalla lista para renderizar
Error(message)    → Error cargando la definicion
```

### DataState
```
Idle              → No se ha solicitado data aun
Loading           → Cargando datos
Success(items, hasMore, loadingMore)  → Datos listos
Error(message)    → Error cargando datos
```

### Form State
```
fieldValues: {fieldId: value}    → Valores actuales de los campos
fieldErrors: {fieldId: error}    → Errores de validacion por campo
```

### Flujo de estados
```
App → loadScreen(key)
  ScreenState = Loading
  → fetch /v1/screens/{key}
  ScreenState = Ready(screen)
    → si screen.dataEndpoint != nil:
      DataState = Loading
      → fetch dataEndpoint
      DataState = Success(items)

User → edita campo
  fieldValues["title"] = "Nuevo Titulo"
  fieldErrors["title"] = nil (limpiar error)

User → click submit
  → validar → ejecutar action → resultado
```

## 6.3 Renderers por Pattern

### LoginPatternRenderer
- Layout centrado, max width 480dp
- Zones: brand (logo + nombre), form (email + password), social (google btn)
- No carga datos externos

### DashboardPatternRenderer
- Scroll vertical completo
- Zones: greeting, kpis (metric-grid), recent_activity (simple-list), quick_actions
- Carga datos de stats endpoint

### ListPatternRenderer
- Zones: search_zone, filters (chips), empty_state (condicional), list_content (simple-list con itemLayout)
- Soporta paginacion (load more al final)
- Soporta pull-to-refresh
- Muestra loading indicator durante carga
- Muestra empty state cuando no hay datos

### DetailPatternRenderer
- Scroll vertical
- Zones: hero (icono + status), header (titulo + info), details, description, summary (condicional), actions
- Carga datos de un solo item

### FormPatternRenderer
- Centrado con max width 600dp
- Zones: form_header (titulo + descripcion), form_fields (campos dinamicos), form_actions (cancel + submit)
- Los campos del form vienen en slotData.form_fields
- Maneja fieldValues y fieldErrors

### SettingsPatternRenderer
- Zones con form-section type
- Cada seccion tiene titulo + controles (switches, nav items)
- Separados por dividers

## 6.4 Renderizado de Zones

### Proceso recursivo
```
renderZone(zone):
  1. Evaluar zone.condition → si false, no renderizar
  2. Si zone tiene sub-zones: renderizar cada sub-zone recursivamente
  3. Si zone.type es SIMPLE_LIST con itemLayout:
     a. Renderizar zone.slots (header de la seccion)
     b. Para cada item en data:
        Renderizar itemLayout.slots con item como contexto
  4. Si zone.type es METRIC_GRID:
     Renderizar slots en grid 2x2
  5. Else: renderizar zone.slots con distribution
```

### Renderizado por distribution
```
STACKED:      VStack(spacing: 16) { slots.forEach { renderSlot($0) } }
SIDE_BY_SIDE: HStack(spacing: 16) { slots.forEach { renderSlot($0, weight) } }
GRID:         LazyVGrid(columns: 2) { slots.forEach { renderSlot($0) } }
FLOW_ROW:     FlowLayout { slots.forEach { renderSlot($0) } }
```

## 6.5 Renderizado de Slots

### Resolucion de valor para un slot
```
1. Si hay itemData (dentro de una lista):
   valor = itemData[slot.field]

2. Si no, buscar en fieldValues del formulario:
   valor = fieldValues[slot.field ?? slot.id]

3. Si no, usar valor estatico:
   valor = slot.value ?? ""
```

### Label del slot
```
Si slot.label != nil: usar slot.label
Si slot.bind empieza con "slot:": buscar en slotData
Si no: usar slot.id como fallback
```

### Estilos de texto
| Style | SwiftUI |
|-------|---------|
| `headline-large` | .largeTitle |
| `headline-medium` | .title |
| `headline-small` | .title3 |
| `title-medium` | .headline |
| `body` | .body |
| `body-small` | .subheadline |
| `caption` | .caption |

### Mapeo de iconos
| Backend icon | SF Symbol |
|-------------|-----------|
| `home` | house.fill |
| `dashboard` | square.grid.2x2.fill |
| `folder`, `materials` | folder.fill |
| `settings`, `gear` | gearshape.fill |
| `person`, `profile` | person.fill |
| `people` | person.2.fill |
| `school` | building.columns.fill |
| `shield` | shield.fill |
| `key` | key.fill |
| `layers` | square.3.layers.3d |
| `trending_up` | chart.line.uptrend.xyaxis |
| `clipboard` | doc.on.clipboard |
| `upload` | arrow.up.doc.fill |
| `download` | arrow.down.doc.fill |
| `bar_chart` | chart.bar.fill |
| `check_circle` | checkmark.circle.fill |
| `star` | star.fill |
| `lock` | lock.fill |
| `language` | globe |

## 6.6 Paginacion

### Proceso
1. Primer carga: `GET {endpoint}?limit=20&offset=0`
2. Scroll al final de la lista: detectar "load more"
3. Siguiente pagina: `GET {endpoint}?limit=20&offset=20`
4. Combinar: items existentes + nuevos items
5. hasMore = (nuevos items count == pageSize)

### Parametros de DataConfig
```json
{
  "pagination": {
    "type": "offset",
    "pageSize": 20,
    "pageParam": "offset",
    "limitParam": "limit"
  }
}
```

## 6.7 Cache de Datos

### Screen definitions
- Cache en memoria (20 entries LRU)
- Cache en disco (1 hora expiracion)
- Invalidacion global posible

### Data (items de listas, etc.)
- No se cachea por default
- Pull-to-refresh siempre recarga
- refreshInterval en DataConfig puede definir recarga automatica
