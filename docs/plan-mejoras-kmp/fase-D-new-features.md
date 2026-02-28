# Fase D — Features: REMOTE_SELECT + Buckets Filter

**Complejidad**: Alta
**Archivos estimados**: ~20
**Prerequisitos**: Ninguno (independiente de A, B, C)

---

## D1: REMOTE_SELECT ControlType

**Origen**: KMP PR #19 — New `REMOTE_SELECT` ControlType end-to-end

**Qué hace**: Nuevo tipo de control SDUI para dropdowns cuyas opciones se cargan desde un endpoint API. Cuando el formulario se renderiza, el campo hace un request al endpoint configurado en el slot y presenta las opciones como un picker/select.

### Diseño End-to-End

#### 1. Modelo — Extensión del Slot

Agregar propiedades al struct `Slot` para soportar opciones remotas:

```swift
// En Slot.swift (EduDynamicUI)
public struct Slot: Codable, Sendable, Hashable {
    // ... propiedades existentes ...
    public let optionsEndpoint: String?   // API endpoint para cargar opciones
    public let optionLabel: String?       // Campo JSON para label (default: "name")
    public let optionValue: String?       // Campo JSON para value (default: "id")
}
```

CodingKeys:
```swift
case optionsEndpoint = "options_endpoint"
case optionLabel = "option_label"
case optionValue = "option_value"
```

#### 2. ControlType — Nuevo case

```swift
// En ControlType.swift (EduDynamicUI)
public enum ControlType: String, Codable, Sendable {
    // ... cases existentes ...
    case remoteSelect = "remote_select"
}
```

#### 3. Estado de opciones remotas

```swift
// Nuevo enum en DynamicUI o Presentation
public enum SelectOptionsState: Sendable {
    case loading
    case success(options: [SlotOption])
    case error(message: String)
}
```

#### 4. ViewModel — Carga de opciones

El ViewModel que maneja pantallas dinámicas necesita:
- Diccionario `selectOptions: [String: SelectOptionsState]` (keyed by field ID)
- Método `loadSelectOptions(fieldKey:, endpoint:, labelField:, valueField:)`
- **Permite retry cuando estado es `.error`** (no quedarse stuck — fix PR #19)
- Guard solo bloquea si estado es `.loading` o `.success` (NO `.error`)
- Usa `DataLoader.loadData()` para hacer el request
- Mapea respuesta: extrae `labelField` y `valueField` de cada item
- **Scope dedicado** para operaciones background (no reusar scope de pending delete)

```swift
func loadSelectOptions(fieldKey: String, endpoint: String, labelField: String, valueField: String) async {
    // Permitir retry si el estado actual es .error (fix de PR #19)
    if let current = selectOptions[fieldKey], !(current is .error) { return }
    selectOptions[fieldKey] = .loading

    do {
        let data = try await dataLoader.loadData(endpoint: endpoint, config: DataConfig(), params: [:])
        let items = data.arrayValue ?? []
        let options = items.compactMap { item -> SlotOption? in
            guard let label = item.objectValue?[labelField]?.stringValue,
                  let value = item.objectValue?[valueField]?.stringValue else { return nil }
            return SlotOption(label: label, value: value)
        }
        selectOptions[fieldKey] = .success(options: options)
    } catch {
        selectOptions[fieldKey] = .error(message: error.localizedDescription)
    }
}
```

#### 5. Vista SwiftUI — RemoteSelectField

```swift
struct RemoteSelectField: View {
    let slot: Slot
    let state: SelectOptionsState?
    let selectedValue: String?
    let onValueChanged: (String) -> Void
    let onLoadOptions: () async -> Void

    var body: some View {
        Group {
            switch state {
            case .loading, .none:
                // Picker deshabilitado con placeholder (usar i18n — fix PR #19)
                TextField(EduStrings.Select.loading, text: .constant(""))
                    .disabled(true)
            case .success(let options):
                // Picker/Menu con las opciones cargadas
                Picker(slot.label ?? "", selection: binding) {
                    Text("Seleccionar...").tag("")
                    ForEach(options, id: \.value) { option in
                        Text(option.label).tag(option.value)
                    }
                }
            case .error(let message):
                // Campo con error (usar i18n — fix PR #19)
                TextField(EduStrings.Select.loadError, text: .constant(""))
                    .disabled(true)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .task { await onLoadOptions() }
    }
}
```

#### 6. Wiring en SlotRenderer (con fallback — fix PR #19)

En el switch de ControlType dentro de SlotRenderer, agregar case `.remoteSelect`.
**Importante**: Si `optionsEndpoint` es vacío/nil, hacer fallback a SELECT local con `slot.options`:

```swift
case .remoteSelect:
    let endpoint = slot.optionsEndpoint ?? ""
    let labelField = slot.optionLabel ?? "name"
    let valueField = slot.optionValue ?? "id"

    if endpoint.isEmpty || onLoadSelectOptions == nil {
        // Fallback a select local cuando no hay endpoint (fix PR #19)
        SelectControl(
            slot: slot,
            options: slot.options ?? [],
            selectedValue: fieldValues[slot.id] ?? "",
            onValueChanged: { onFieldChanged(slot.id, $0) }
        )
    } else {
        RemoteSelectField(
            slot: slot,
            state: selectOptions[slot.id],
            selectedValue: fieldValues[slot.id],
            onValueChanged: { onFieldChanged(slot.id, $0) },
            onLoadOptions: {
                await onLoadSelectOptions(slot.id, endpoint, labelField, valueField)
            }
        )
    }
```

#### 7. FormFieldsResolver — Validación de options_endpoint (fix PR #19)

Cuando el tipo de control es `remote_select`, **el slot debe tener `options_endpoint`**. Si no lo tiene, el resolver debe omitir ese slot (no crear un campo roto):

```swift
// En el resolver de form fields
if controlType == .remoteSelect {
    guard slot.optionsEndpoint != nil, !slot.optionsEndpoint!.isEmpty else {
        continue // Skip slot — remote_select sin endpoint no es válido
    }
}
```

### Pasos detallados

1. **Agregar propiedades a `Slot`** (`Packages/DynamicUI/Sources/DynamicUI/Models/Slot.swift`):
   - `optionsEndpoint`, `optionLabel`, `optionValue` como `String?`
   - CodingKeys con snake_case

2. **Agregar `.remoteSelect` a `ControlType`** (`Packages/DynamicUI/Sources/DynamicUI/Models/ControlType.swift`):
   - `case remoteSelect = "remote_select"`

3. **Crear `SelectOptionsState`** (`Packages/DynamicUI/Sources/DynamicUI/Models/SelectOptionsState.swift`):
   - Enum con `loading`, `success(options:)`, `error(message:)`

4. **Crear `SlotOption` si no existe** (verificar si ya existe en el modelo):
   - `struct SlotOption: Sendable, Hashable { let label: String; let value: String }`

5. **Agregar lógica al ViewModel**:
   - Diccionario `selectOptions: [String: SelectOptionsState]`
   - Método `loadSelectOptions(fieldKey:endpoint:labelField:valueField:)`
   - **Permitir retry cuando estado es `.error`** (fix PR #19) — NO bloquear si ya falló
   - **Scope dedicado** para operaciones background

6. **Crear `RemoteSelectField`** (`Apps/DemoApp/Sources/Renderers/Controls/RemoteSelectField.swift`):
   - Vista SwiftUI con 3 estados: loading, success (Picker), error
   - `.task { }` para trigger de carga
   - **Usar strings i18n**: `EduStrings.Select.loading` y `EduStrings.Select.loadError` (fix PR #19)

7. **Integrar en `SlotRenderer`** (`Apps/DemoApp/Sources/Renderers/SlotRenderer.swift`):
   - Case `.remoteSelect` con **fallback a SELECT local** cuando endpoint vacío (fix PR #19)
   - Threading de `selectOptions` y `onLoadSelectOptions` desde parent views

8. **Validación en FormFieldsResolver** (o equivalente):
   - **Skip slot si `options_endpoint` falta** cuando tipo es `remote_select` (fix PR #19)

9. **Threading del estado** por la cadena de vistas:
   - FormPatternRenderer → ZoneRenderer → SlotRenderer → RemoteSelectField
   - Pasar `selectOptions` dictionary y `onLoadSelectOptions` callback

10. **Tests**:
    - Test de decode de Slot con `options_endpoint`
    - Test de ControlType `.remoteSelect` serialization
    - Test de `loadSelectOptions` con mock DataLoader
    - Test de retry cuando estado previo es `.error`
    - Test de fallback a SELECT local cuando endpoint vacío
    - Test que slot sin `options_endpoint` es omitido por resolver
    - Test de RemoteSelectField en cada estado con strings i18n

### Archivos afectados
- `Packages/DynamicUI/Sources/DynamicUI/Models/Slot.swift`
- `Packages/DynamicUI/Sources/DynamicUI/Models/ControlType.swift`
- `Packages/DynamicUI/Sources/DynamicUI/Models/SelectOptionsState.swift` (nuevo)
- `Packages/DynamicUI/Sources/DynamicUI/Models/SlotOption.swift` (nuevo o verificar existente)
- `Apps/DemoApp/Sources/Renderers/Controls/RemoteSelectField.swift` (nuevo)
- `Apps/DemoApp/Sources/Renderers/SlotRenderer.swift`
- `Apps/DemoApp/Sources/Renderers/ZoneRenderer.swift`
- `Apps/DemoApp/Sources/Renderers/FormPatternRenderer.swift`
- `Packages/DynamicUI/Tests/DynamicUITests/Models/SlotTests.swift`
- `Packages/DynamicUI/Tests/DynamicUITests/Models/ControlTypeTests.swift`

---

## D2: Buckets Filter para Progressive Sync

**Origen**: API PR #8/#9 — `?buckets=` query parameter para sync bundle

**Qué hace**: Permitir que el cliente solicite solo buckets específicos al hacer sync (ej: `?buckets=menu,permissions,available_contexts` sin screens). Esto ahorra 2-5 segundos cuando solo se necesita metadata sin pantallas.

### Caso de uso principal

Al cambiar de escuela (context switch), no siempre es necesario recargar TODAS las pantallas. Se puede:
1. Primero cargar metadata rápida: `?buckets=menu,permissions,available_contexts`
2. Luego cargar screens en background

### Diseño

#### Extensión del SyncService

```swift
// Nuevo método en SyncService
func syncBuckets(_ buckets: [SyncBucket]) async throws -> UserDataBundle {
    var request = HTTPRequest.get(SyncEndpoints.bundle)
        .bearerToken(token)
        .acceptJSON()

    if !buckets.isEmpty {
        let bucketNames = buckets.map(\.rawValue).joined(separator: ",")
        request = request.queryParam("buckets", bucketNames)
    }

    let response = try await networkClient.execute(request, as: SyncBundleResponseDTO.self)
    // ... mapping ...
}
```

#### Enum de Buckets

```swift
public enum SyncBucket: String, Sendable, CaseIterable {
    case menu
    case permissions
    case availableContexts = "available_contexts"
    case screens
    case glossary
    case strings
}
```

### Pasos

1. **Crear `SyncBucket` enum** (`Packages/Domain/Sources/Services/Sync/SyncBucket.swift`):
   - Enum con rawValue String para cada bucket
   - Conforma a `Sendable`, `CaseIterable`

2. **Agregar `queryParam()` a `HTTPRequest`** (si no existe) (`Packages/Infrastructure/Sources/Network/HTTPRequest.swift`):
   - Método builder para agregar query parameters a la URL
   - Verificar si ya existe este builder method

3. **Extender `SyncService`** (`Packages/Domain/Sources/Services/Sync/SyncService.swift`):
   - Nuevo método: `syncBuckets(_ buckets: [SyncBucket]) async throws -> UserDataBundle`
   - El fullSync existente sigue sin parámetros (backward compatible)
   - El nuevo método construye `?buckets=...` query param

4. **Usar buckets filter en context switch** (`Apps/DemoApp/Sources/Screens/MainScreen.swift`):
   - En `switchContext()`: usar `syncBuckets([.menu, .permissions, .availableContexts])` para carga rápida
   - Luego en background: `syncBuckets([.screens])` para cargar pantallas

5. **Actualizar `LocalSyncStore`** para merge parcial:
   - Cuando se recibe un bundle parcial (sin screens), solo actualizar los buckets recibidos
   - No sobreescribir screens si no vinieron en la respuesta

6. **Tests**:
   - Test que `syncBuckets([.menu])` genera URL con `?buckets=menu`
   - Test que bundle parcial se mergea correctamente sin perder screens existentes
   - Test que fullSync sigue funcionando sin cambios

### Archivos afectados
- `Packages/Domain/Sources/Services/Sync/SyncBucket.swift` (nuevo)
- `Packages/Domain/Sources/Services/Sync/SyncService.swift`
- `Packages/Domain/Sources/Services/Sync/LocalSyncStore.swift`
- `Packages/Infrastructure/Sources/Network/HTTPRequest.swift` (si queryParam no existe)
- `Apps/DemoApp/Sources/Screens/MainScreen.swift`
- `Packages/Domain/Tests/DomainTests/Services/Sync/SyncServiceTests.swift`

---

## Verificación de Fase

```bash
make build
cd Packages/DynamicUI && swift test
cd Packages/Domain && swift test
cd Packages/Infrastructure && swift test
make run
```

**Criterio de éxito**:
- Campo `remote_select` en un formulario SDUI carga opciones desde API
- Picker muestra opciones cargadas, selección se guarda en fieldValues
- Estados de loading/error se muestran correctamente
- Context switch usa sync parcial (rápido) + screens en background
- `?buckets=` visible en logs de network
- 0 warnings, todos tests pasan
