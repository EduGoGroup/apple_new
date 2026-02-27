# Fase 4: Renderers SDUI + Formularios CRUD

## Objetivo
Implementar los renderers completos para cada ScreenPattern (List, Form, Detail, Settings) y el sistema de formularios CRUD con validación, integrando los 22+ ControlTypes con controles SwiftUI nativos con Liquid Glass.

## Dependencias
- **Fase 3** (Contracts + Orchestrator)

## Contexto KMP (referencia)

### Renderers en KMP
- PatternRouter despacha por ScreenPattern → Renderer especializado
- ListPatternRenderer: toolbar, search bar, LazyColumn de items, paginación
- FormPatternRenderer: toolbar con back+guardar, form fields agrupados por zona, validación
- DetailPatternRenderer: back + título + contenido read-only
- Cada Renderer itera zonas → renderiza slots → resuelve ControlType → composable

### ControlTypes implementados en KMP (22)
- text-input, email-input, password-input, number-input, search-bar
- select (dropdown con opciones fijas), checkbox, switch, radio-group, chip
- filled-button, outlined-button, text-button, icon-button
- label, icon, avatar, image, divider
- list-item, list-item-navigation, metric-card

---

## Pasos de Implementación

### Paso 4.1: SlotRenderer completo — todos los ControlTypes

**Paquete**: `Apps/DemoApp/`

**Archivos a crear/modificar:**
- `Renderers/SlotRenderer.swift` — reescribir completamente
- `Renderers/Controls/TextInputControl.swift`
- `Renderers/Controls/SelectControl.swift`
- `Renderers/Controls/ButtonControl.swift`
- `Renderers/Controls/DisplayControl.swift`
- `Renderers/Controls/ListItemControl.swift`

**Requisitos:**
- `SlotRenderer` hace switch sobre `ControlType` y renderiza el control SwiftUI apropiado:

  ```swift
  @ViewBuilder
  static func render(
      slot: Slot,
      data: [String: JSONValue],
      fieldValues: Binding<[String: String]>,
      onEvent: @escaping (String) -> Void
  ) -> some View {
      switch slot.controlType {
      case .textInput:     TextInputControl(slot: slot, fieldValues: fieldValues)
      case .emailInput:    TextInputControl(slot: slot, fieldValues: fieldValues, keyboard: .emailAddress)
      case .passwordInput: PasswordInputControl(slot: slot, fieldValues: fieldValues)
      case .numberInput:   TextInputControl(slot: slot, fieldValues: fieldValues, keyboard: .numberPad)
      case .searchBar:     SearchBarControl(slot: slot, fieldValues: fieldValues)
      case .select:        SelectControl(slot: slot, fieldValues: fieldValues)
      case .checkbox:      CheckboxControl(slot: slot, fieldValues: fieldValues)
      case .switchControl: SwitchControl(slot: slot, fieldValues: fieldValues)
      case .radioGroup:    RadioGroupControl(slot: slot, fieldValues: fieldValues)
      case .chip:          ChipControl(slot: slot, fieldValues: fieldValues)
      case .filledButton:  ButtonControl(slot: slot, style: .filled, onEvent: onEvent)
      case .outlinedButton: ButtonControl(slot: slot, style: .outlined, onEvent: onEvent)
      case .textButton:    ButtonControl(slot: slot, style: .text, onEvent: onEvent)
      case .iconButton:    ButtonControl(slot: slot, style: .icon, onEvent: onEvent)
      case .label:         LabelControl(slot: slot, data: data)
      case .icon:          IconControl(slot: slot)
      case .avatar:        AvatarControl(slot: slot, data: data)
      case .image:         ImageControl(slot: slot, data: data)
      case .divider:       Divider()
      case .listItem:      ListItemControl(slot: slot, data: data)
      case .listItemNavigation: ListItemNavigationControl(slot: slot, data: data, onEvent: onEvent)
      case .metricCard:    MetricCardControl(slot: slot, data: data)
      case .rating:        RatingControl(slot: slot, fieldValues: fieldValues)
      }
  }
  ```

- Cada control usa componentes existentes de `EduPresentation` (EduTextField, EduButton, etc.) con Liquid Glass
- Los controles de input usan `binding` a `fieldValues[slot.field ?? slot.id]`
- Los controles de display resuelven datos vía `SlotBindingResolver`
- Los botones emiten `onEvent(slot.eventId)` al hacer tap

**Verificar:** `make build`

---

### Paso 4.2: ZoneRenderer completo

**Paquete**: `Apps/DemoApp/`

**Archivos a modificar:**
- `Renderers/ZoneRenderer.swift`

**Requisitos:**
- Renderiza una `Zone` según su tipo:
  - **TOOLBAR**: renderizado por `EduDynamicToolbar` (ya existe de fase 1)
  - **FORM_SECTION**: `Section` de SwiftUI con slots de input agrupados
  - **SIMPLE_LIST**: `LazyVStack` con items
  - **ACTION_GROUP**: `HStack/VStack` de botones
  - **CONTENT**: `VStack` genérico con slots
  - **HEADER**: Encabezado de sección
  - **FOOTER**: Pie de sección
- Soporta zonas anidadas (`zone.zones`)
- Cada zona itera sus `slots` y llama a `SlotRenderer.render()`

**Verificar:** `make build`

---

### Paso 4.3: ListPatternRenderer

**Paquete**: `Apps/DemoApp/`

**Archivos a modificar:**
- `Renderers/ListPatternRenderer.swift`

**Requisitos:**
- Renderiza pantallas con patrón `list`:
  1. **Toolbar**: título desde `slotData["page_title"]` + botón "Crear" (si permiso `{resource}:create`)
  2. **Search bar**: si hay zona de tipo SEARCH o slot searchBar → campo de búsqueda con debounce 300ms
  3. **Lista**: `List` de SwiftUI con items de datos
     - Cada item usa `ListItemControl` o `ListItemNavigationControl`
     - Datos desde `DataLoader` resueltos con `SlotBindingResolver`
  4. **Paginación**: al llegar al final de la lista → `executeEvent(.loadMore)`
  5. **Pull-to-refresh**: `.refreshable { executeEvent(.refresh) }`
  6. **Empty state**: si no hay datos → `EduEmptyStateView`
  7. **Loading**: durante carga → `EduSkeletonLoader` o `ProgressView`
  8. **Error**: si error → `EduErrorStateView` con retry
- Al tap en item → `executeEvent(.selectItem)` con item seleccionado → navegar a detail/edit

**Verificar:** `make build`

---

### Paso 4.4: FormPatternRenderer

**Paquete**: `Apps/DemoApp/`

**Archivos a crear:**
- `Renderers/FormPatternRenderer.swift`

**Requisitos:**
- Renderiza pantallas con patrón `form`:
  1. **Toolbar**: botón back + título (slotData["edit_title"] o "page_title") + botón "Guardar"
  2. **Form fields**: agrupados por zonas FORM_SECTION
     - Cada slot de input renderizado con `SlotRenderer`
     - Campos vinculados a `fieldValues` del ViewModel
     - Labels desde slot.label
     - Placeholders desde slot.placeholder
     - Required indicators si slot.required == true
  3. **Validación**:
     - Al tap "Guardar" → validar campos required
     - Email fields → validar formato
     - Mostrar errores inline (`fieldErrors`)
     - Si válido → `executeEvent(.saveNew)` o `executeEvent(.saveExisting)`
  4. **Modo edición vs creación**:
     - Si hay `selectedItem` en context → es edición, pre-popular campos
     - Si no → es creación, campos vacíos
  5. **Keyboard management**: keyboard dismiss on tap outside, scroll to focused field
- Usar `Form {}` de SwiftUI con Liquid Glass sections

**Verificar:** `make build`

---

### Paso 4.5: DetailPatternRenderer

**Paquete**: `Apps/DemoApp/`

**Archivos a crear:**
- `Renderers/DetailPatternRenderer.swift`

**Requisitos:**
- Renderiza pantallas con patrón `detail`:
  1. **Toolbar**: botón back + título del item
  2. **Contenido read-only**: muestra datos del item seleccionado
     - Labels con valores resueltos via SlotBindingResolver
     - Formateo por tipo de dato (fechas, números, booleanos)
  3. **Acciones**: botones de editar/eliminar si tiene permisos
     - Editar → navegar a form con item pre-populated
     - Eliminar → confirmar → `executeEvent(.delete)`
  4. **Liquid Glass**: cards para secciones de información

**Verificar:** `make build`

---

### Paso 4.6: SettingsPatternRenderer

**Paquete**: `Apps/DemoApp/`

**Archivos a crear:**
- `Renderers/SettingsPatternRenderer.swift`

**Requisitos:**
- Renderiza pantallas con patrón `settings`:
  1. **Toolbar**: solo título
  2. **Secciones de configuración**:
     - Theme toggle (Light/Dark/System) usando `ThemeManager`
     - Language selector (si i18n implementado)
     - Logout button
     - App version info
  3. **Toggles**: checkbox/switch slots para preferencias
  4. **Navegación**: list-item-navigation para sub-pantallas de settings
- Usar `EduGroupBox` y `EduSection` con Liquid Glass

**Verificar:** `make build`

---

### Paso 4.7: PatternRouter actualizado

**Paquete**: `Apps/DemoApp/`

**Archivos a modificar:**
- `Renderers/PatternRouter.swift`

**Requisitos:**
- Dispatch completo por todos los patrones:
  ```swift
  @ViewBuilder
  static func route(
      screen: ScreenDefinition,
      data: [String: JSONValue],
      fieldValues: Binding<[String: String]>,
      viewModel: DynamicScreenViewModel
  ) -> some View {
      switch screen.pattern {
      case .login:        LoginPatternRenderer(...)
      case .list:         ListPatternRenderer(...)
      case .form:         FormPatternRenderer(...)
      case .detail:       DetailPatternRenderer(...)
      case .dashboard:    DashboardPatternRenderer(...)
      case .settings:     SettingsPatternRenderer(...)
      case .search:       ListPatternRenderer(...) // reusa list con search enfocado
      case .profile:      DetailPatternRenderer(...) // reusa detail
      case .modal:        ModalPatternRenderer(...)
      case .notification: FallbackRenderer(...)  // futuro
      case .onboarding:   FallbackRenderer(...)  // futuro
      case .emptyState:   EduEmptyStateView(...)
      }
  }
  ```

**Verificar:** `make build`

---

### Paso 4.8: Field mapping (API → template)

**Paquete**: `Packages/DynamicUI/`

**Archivos a crear:**
- `Utilities/FieldMapper.swift`

**Requisitos:**
- Transforma datos de API a nombres de template para binding:
  ```swift
  struct FieldMapper {
      // Dado un DataConfig.fieldMapping y datos del API
      static func map(
          data: [String: JSONValue],
          fieldMapping: [String: String]?
      ) -> [String: JSONValue] {
          guard let mapping = fieldMapping else { return data }
          var result = data
          for (apiField, templateField) in mapping {
              if let value = data[apiField] {
                  result[templateField] = value
              }
          }
          return result
      }
  }
  ```
- Ejemplo: `{"full_name": "title", "code": "subtitle"}` → convierte `data["full_name"]` a `data["title"]` para que el slot con `bind: "title"` lo encuentre

**Verificar:** `cd Packages/DynamicUI && swift test`

---

### Paso 4.9: Tests de Fase 4

**Archivos a crear:**
- `Packages/DynamicUI/Tests/Utilities/FieldMapperTests.swift`

**Tests manuales/visuales:**
- Cargar pantalla `schools:list` → muestra lista de escuelas con search
- Cargar pantalla `schools:form` → muestra formulario con campos
- Crear escuela → POST funciona → lista se actualiza
- Editar escuela → PUT funciona → detail muestra cambios
- Buscar en lista → filtra resultados
- Paginación → carga más items al scroll

---

## Criterios de Completitud

- [ ] Todos los 22+ ControlTypes renderizan correctamente
- [ ] ListPatternRenderer: search, pagination, pull-to-refresh, empty state
- [ ] FormPatternRenderer: validación, modo create/edit, keyboard management
- [ ] DetailPatternRenderer: display read-only, acciones edit/delete
- [ ] SettingsPatternRenderer: theme toggle, logout
- [ ] PatternRouter despacha a todos los patterns
- [ ] Field mapping transforma datos API → template correctamente
- [ ] SlotBindingResolver funciona con datos reales del API
- [ ] `make build` sin errores
- [ ] `make test` sin fallos
- [ ] Zero warnings de deprecación
