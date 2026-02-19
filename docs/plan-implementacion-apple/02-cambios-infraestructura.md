# Cambios Requeridos en Infraestructura

> **Estado**: Parcialmente completado. Ver seccion 9 para detalle.

Este documento define los cambios necesarios en infraestructura (BD, APIs, shared) para soportar la plataforma Apple (iOS/iPadOS/macOS). Todos los cambios propuestos son retrocompatibles con los clientes existentes.

---

## 1. Analisis de Impacto

### Estado Actual de las Tablas de UI Dinamica

El esquema `ui_config` en PostgreSQL contiene 4 tablas que conforman el sistema de Dynamic UI:

```sql
-- ui_config.screen_templates (estructura: 016_create_screen_templates.sql)
CREATE TABLE ui_config.screen_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pattern VARCHAR(50) NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    version INT NOT NULL DEFAULT 1,
    definition JSONB NOT NULL,  -- Contiene platformOverrides como JSON interno
    is_active BOOLEAN DEFAULT true,
    created_by UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(name, version)
);

-- ui_config.screen_instances (estructura: 017_create_screen_instances.sql)
CREATE TABLE ui_config.screen_instances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    screen_key VARCHAR(100) NOT NULL UNIQUE,
    template_id UUID NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    slot_data JSONB NOT NULL DEFAULT '{}',
    actions JSONB NOT NULL DEFAULT '[]',
    data_endpoint VARCHAR(500),
    data_config JSONB DEFAULT '{}',
    scope VARCHAR(20) DEFAULT 'school',
    required_permission VARCHAR(100),
    handler_key VARCHAR(100) DEFAULT NULL,
    is_active BOOLEAN DEFAULT true,
    created_by UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ui_config.resource_screens (estructura: 018_create_resource_screens.sql)
CREATE TABLE ui_config.resource_screens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resource_id UUID NOT NULL,
    resource_key VARCHAR(100) NOT NULL,
    screen_key VARCHAR(100) NOT NULL,
    screen_type VARCHAR(50) NOT NULL,
    is_default BOOLEAN DEFAULT false,
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(resource_id, screen_type)
);

-- ui_config.screen_user_preferences (estructura: 019_create_screen_user_preferences.sql)
CREATE TABLE ui_config.screen_user_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    screen_instance_id UUID NOT NULL,
    user_id UUID NOT NULL,
    preferences JSONB NOT NULL DEFAULT '{}',
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(screen_instance_id, user_id)
);
```

### Decision: NO se necesitan cambios en la estructura de tablas

La estructura actual ya soporta multi-plataforma a traves del campo `definition` JSONB en `screen_templates`. El campo `platformOverrides` dentro del JSON permite definir overrides por plataforma sin necesidad de columnas adicionales.

**Estado actual de platformOverrides en los seeds** (006_seed_screen_templates.sql):

Los 6 templates base usan `platformOverrides` solo para `desktop` y `web`:

| Template | platformOverrides presentes |
|---|---|
| login-basic-v1 | `desktop`, `web` |
| dashboard-basic-v1 | `desktop` |
| list-basic-v1 | `desktop`, `web` |
| detail-basic-v1 | `desktop` |
| settings-basic-v1 | `desktop` |
| form-basic-v1 | `desktop`, `web` |

Ningun template tiene override para `mobile`, `ios` ni `android`. El comportamiento actual es que mobile recibe el template sin overrides (el JSON base es el layout mobile por defecto).

### Expansion de platformOverrides

**Cambio propuesto**: Expandir los valores soportados en `platformOverrides` para diferenciar `ios` de `android`:

```json
{
  "zones": [...],
  "platformOverrides": {
    "ios": { "zones": { ... } },
    "android": { "zones": { ... } },
    "mobile": { "zones": { ... } },
    "desktop": { "zones": { ... } },
    "web": { "zones": { ... } }
  }
}
```

**Cadena de resolucion de prioridad en la API**:
- Si `platform=ios` y existe `platformOverrides.ios` -> aplicar
- Si no, si existe `platformOverrides.mobile` -> aplicar como fallback
- Si no, usar template sin overrides (el JSON base)

Para Android seria analogo: `android` -> `mobile` -> default.

Esto permite configuraciones especificas para iOS cuando haya diferencias reales, con fallback a la configuracion generica mobile.

---

## 2. Cambios en edugo-shared

Repositorio: `/edugo-shared`

### 2.1 Agregar tipo Platform al paquete screenconfig

**Archivo**: `screenconfig/types.go`

Actualmente el archivo define `Pattern`, `ScreenType` y `ActionType` como tipos con constantes. No existe un tipo `Platform`. Se debe agregar:

```go
// Platform enumera las plataformas soportadas para overrides de UI
type Platform string

const (
    PlatformIOS     Platform = "ios"
    PlatformAndroid Platform = "android"
    PlatformMobile  Platform = "mobile"  // fallback generico para apps moviles
    PlatformDesktop Platform = "desktop"
    PlatformWeb     Platform = "web"
)
```

### 2.2 Agregar validacion de Platform

**Archivo**: `screenconfig/validation.go`

Siguiendo el patron existente de `validPatterns`, `validActionTypes` y `validScreenTypes`, agregar:

```go
var validPlatforms = map[Platform]bool{
    PlatformIOS:     true,
    PlatformAndroid: true,
    PlatformMobile:  true,
    PlatformDesktop: true,
    PlatformWeb:     true,
}

// ValidatePlatform valida que el string sea un Platform valido
func ValidatePlatform(p string) error {
    if p == "" {
        return nil // platform es opcional
    }
    if !validPlatforms[Platform(p)] {
        return fmt.Errorf("invalid platform: %q", p)
    }
    return nil
}
```

### 2.3 Agregar funcion de resolucion de cadena de fallback

**Archivo**: `screenconfig/validation.go` (o un nuevo `screenconfig/platform.go`)

```go
// PlatformFallbackChain retorna la cadena de fallback para una plataforma.
// Ejemplo: "ios" -> ["ios", "mobile"], "android" -> ["android", "mobile"],
// "mobile" -> ["mobile"], "desktop" -> ["desktop"], "web" -> ["web"]
func PlatformFallbackChain(platform string) []string {
    switch Platform(platform) {
    case PlatformIOS:
        return []string{"ios", "mobile"}
    case PlatformAndroid:
        return []string{"android", "mobile"}
    default:
        return []string{platform}
    }
}
```

### 2.4 Impacto en existente

- **Cero breaking changes**: Solo se agregan constantes y funciones nuevas
- Los DTOs existentes (`ScreenTemplateDTO`, `CombinedScreenDTO`, etc.) no cambian
- El campo `Definition json.RawMessage` sigue siendo generico (JSONB)
- Ningun codigo existente se modifica, solo se agregan exports nuevos

---

## 3. Cambios en edugo-api-mobile

Repositorio: `/edugo-api-mobile`

### 3.1 Actualizar applyPlatformOverrides con cadena de fallback

**Archivo**: `internal/application/service/screen_service.go`

La funcion actual `applyPlatformOverrides` busca el override exacto por nombre de plataforma:

```go
// Codigo ACTUAL (linea 416-474 de screen_service.go)
func applyPlatformOverrides(definition json.RawMessage, platform string) json.RawMessage {
    // ...
    platformOverride, ok := overridesMap[platform]  // <-- solo busca match exacto
    if !ok {
        return definition
    }
    // ...
}
```

**Cambio requerido**: Implementar la cadena de fallback usando `PlatformFallbackChain`:

```go
func applyPlatformOverrides(definition json.RawMessage, platform string) json.RawMessage {
    var defMap map[string]interface{}
    if err := json.Unmarshal(definition, &defMap); err != nil {
        return definition
    }

    overrides, ok := defMap["platformOverrides"]
    if !ok {
        return definition
    }

    overridesMap, ok := overrides.(map[string]interface{})
    if !ok {
        return definition
    }

    // Buscar override usando cadena de fallback
    chain := screenconfig.PlatformFallbackChain(platform)
    var platformMap map[string]interface{}
    for _, p := range chain {
        if override, ok := overridesMap[p]; ok {
            if pm, ok := override.(map[string]interface{}); ok {
                platformMap = pm
                break
            }
        }
    }

    if platformMap == nil {
        // Sin override aplicable, remover platformOverrides y retornar
        delete(defMap, "platformOverrides")
        result, _ := json.Marshal(defMap)
        return result
    }

    // Aplicar overrides de zonas (logica existente sin cambios)
    // ...
}
```

### 3.2 Actualizar validacion de platform en el handler

**Archivo**: `internal/infrastructure/http/handler/screen_handler.go`

Actualmente el handler no valida el valor del query param `platform`. El Swagger documenta solo `mobile, desktop, web`. Se debe:

1. Agregar validacion usando `screenconfig.ValidatePlatform()` del shared
2. Actualizar documentacion Swagger para incluir `ios` y `android`

```go
// En GetScreen (linea 45):
platform := c.Query("platform")
if err := screenconfig.ValidatePlatform(platform); err != nil {
    c.JSON(http.StatusBadRequest, ErrorResponse{
        Error: err.Error(),
        Code:  "INVALID_PLATFORM",
    })
    return
}
```

Actualizar el comentario Swagger:
```go
// @Param platform query string false "Platform (ios, android, mobile, desktop, web)"
```

### 3.3 Navegacion - buildNavigationTree

**Archivo**: `internal/application/service/screen_service.go`

La funcion `buildNavigationTree` (linea 202) ya maneja correctamente el caso de bottom nav:

```go
// Codigo ACTUAL:
maxBottomNav := 5
if platform == "desktop" || platform == "web" {
    maxBottomNav = 0
}
```

Para `platform=ios`, la logica actual deja `maxBottomNav = 5` (no entra en el `if`), lo cual es correcto para iPhone. Para iPad con sidebar, esto se maneja en el cliente iOS (no en el backend).

**Cambio minimo requerido**: Solo asegurar que el comentario documente el comportamiento:

```go
// Separar: mobile/ios/android obtienen max 5 en bottomNav, el resto en drawer
// desktop/web obtienen todo en drawer (sin bottom nav)
// Para iPad sidebar: el cliente iOS decide si usar bottomNav o sidebar
maxBottomNav := 5
if platform == "desktop" || platform == "web" {
    maxBottomNav = 0
}
```

### 3.4 Cache - incluir platform en la cache key

**Archivo**: `internal/application/service/screen_service.go`

El cache actual usa solo `screenKey`:

```go
// Codigo ACTUAL (linea 78):
cacheKey := fmt.Sprintf("screen:%s", screenKey)
```

**Cambio requerido**: Incluir platform en la cache key porque diferentes plataformas generan diferentes respuestas:

```go
cacheKey := fmt.Sprintf("screen:%s:platform:%s", screenKey, platform)
```

---

## 4. Cambios en edugo-api-administracion

Repositorio: `/edugo-api-administracion`

### 4.1 Validacion de templates al crear/actualizar

Actualmente la API de administracion no tiene logica de platform en su handler (`test/integration/setup.go` es la unica referencia). Si existe un endpoint de creacion/edicion de templates, agregar validacion:

Al crear/actualizar un `screen_template`, validar que las keys dentro de `platformOverrides` del `definition` JSONB sean valores validos:

```go
// En el servicio/handler de templates de administracion:
func validatePlatformOverrideKeys(definition json.RawMessage) error {
    var defMap map[string]interface{}
    if err := json.Unmarshal(definition, &defMap); err != nil {
        return err
    }
    overrides, ok := defMap["platformOverrides"]
    if !ok {
        return nil // no hay overrides, ok
    }
    overridesMap, ok := overrides.(map[string]interface{})
    if !ok {
        return fmt.Errorf("platformOverrides debe ser un objeto JSON")
    }
    for key := range overridesMap {
        if err := screenconfig.ValidatePlatform(key); err != nil {
            return fmt.Errorf("key invalida en platformOverrides: %s", key)
        }
    }
    return nil
}
```

### 4.2 Endpoint de resolucion (si existe)

Si la API de administracion tiene un endpoint de tipo `resolve/preview` que aplica overrides para previsualizar templates, debe usar la misma cadena de fallback que la API mobile (seccion 3.1).

---

## 5. Cambios en Seeds/Datos Iniciales

Repositorio: `/edugo-infrastructure`

### 5.1 Principio: Override de iOS solo cuando hay diferencia real

Los seeds actuales (`006_seed_screen_templates.sql`) definen 6 templates base. El JSON base de cada template es el layout mobile por defecto (los overrides `desktop`/`web` modifican la distribucion para pantallas grandes).

**NO se necesita agregar `platformOverrides.ios` a los templates actuales** a menos que haya una diferencia real de layout para iOS. Si iOS se renderiza igual que mobile generico, no agregar override (usara el fallback: `ios` -> no encontrado -> `mobile` -> no encontrado -> JSON base sin overrides).

### 5.2 Cuando agregar override de iOS

Ejemplos de cuando si tendria sentido agregar un `platformOverrides.ios`:

```json
{
  "platformOverrides": {
    "ios": {
      "zones": {
        "form": {
          "keyboardAvoidingBehavior": "padding",
          "formStyle": "grouped"
        }
      }
    },
    "desktop": { "..." }
  }
}
```

Esto se haria solo si el backend necesita dictar comportamiento especifico de iOS que no puede resolverse en el cliente.

### 5.3 Iconos de navegacion - SF Symbols

Los iconos actuales en los seeds usan nombres genericos (ej: `people`, `folder`, `trending_up`, `check_circle`, `upload`, `bar_chart`, etc.) que no son SF Symbols.

**Opciones de mapeo**:

| Opcion | Descripcion | Cambio en BD |
|---|---|---|
| **A: Mapeo en cliente** | El cliente iOS mapea nombres genericos a SF Symbols con un `IconMapper` | Ninguno |
| **B: Iconos por plataforma en JSONB** | Agregar objeto de iconos por plataforma en `resource_screens` o en slot_data | Seeds nuevos |

**Recomendacion: Opcion A**. El cliente iOS ya tendra un sistema de mapeo de iconos genericos a SF Symbols. Sin cambios en BD necesarios.

Tabla de mapeo de referencia (para implementar en el cliente iOS):

| Icono generico (en seeds) | SF Symbol equivalente |
|---|---|
| `home` | `house.fill` |
| `people` | `person.2.fill` |
| `person` | `person.fill` |
| `folder` | `folder.fill` |
| `folder_open` | `folder.badge.plus` |
| `trending_up` | `chart.line.uptrend.xyaxis` |
| `check_circle` | `checkmark.circle.fill` |
| `upload` | `arrow.up.doc.fill` |
| `bar_chart` | `chart.bar.fill` |
| `school` | `building.columns.fill` |
| `layers` | `square.3.layers.3d` |
| `shield` | `shield.fill` |
| `key` | `key.fill` |
| `clipboard` | `doc.on.clipboard.fill` |
| `history` | `clock.arrow.circlepath` |
| `quiz` | `questionmark.circle.fill` |
| `lock` | `lock.fill` |
| `language` | `globe` |
| `privacy_tip` | `hand.raised.fill` |
| `description` | `doc.text.fill` |
| `settings` | `gearshape.fill` |
| `google` | Imagen custom (no SF Symbol) |
| `user_plus` | `person.badge.plus` |
| `download` | `arrow.down.circle.fill` |

---

## 6. Material Events - Tracking iOS

La coleccion `material_event` en MongoDB ya tiene el campo `device.platform` como parte del payload del evento. No se necesitan cambios en el schema de MongoDB.

La app iOS debe enviar los eventos con el siguiente formato en el campo `device`:

```json
{
  "device": {
    "platform": "ios",
    "os": "iOS 26",
    "os_version": "26.0",
    "device_type": "phone",
    "screen_resolution": "1170x2532"
  }
}
```

Valores de `device_type` para Apple:
- `"phone"` - iPhone
- `"tablet"` - iPad
- `"desktop"` - Mac (Catalyst / macOS nativo)

No se requieren cambios en BD ni en el worker de procesamiento.

---

## 7. Resumen de Cambios

| Componente | Archivo(s) | Cambio | Estado |
|---|---|---|---|
| **edugo-shared** | `screenconfig/types.go` | Tipo `Platform` con constantes iOS, Android, Mobile, Desktop, Web | COMPLETADO (screenconfig/v0.51.0) |
| **edugo-shared** | `screenconfig/validation.go` | `validPlatforms`, `ValidatePlatform()`, `PlatformFallback`, `ResolvePlatformOverrideKey()` | COMPLETADO (screenconfig/v0.51.0) |
| **edugo-shared** | `screenconfig/validation_test.go` | 4 tests nuevos (validacion + fallback) | COMPLETADO (screenconfig/v0.51.0) |
| **edugo-api-mobile** | `internal/application/service/screen_service.go` | `applyPlatformOverrides()` con cadena de fallback via `ResolvePlatformOverrideKey()` | COMPLETADO (rama dev, pendiente commit) |
| **edugo-api-mobile** | `internal/application/service/screen_service.go` | Cache key incluye platform: `screen:%s:platform:%s` | COMPLETADO (rama dev, pendiente commit) |
| **edugo-api-mobile** | `internal/infrastructure/http/handler/screen_handler.go` | Swagger docs actualizados con ios/android | COMPLETADO (rama dev, pendiente commit) |
| **edugo-api-mobile** | `go.mod` | Nueva dependencia `screenconfig v0.51.0` | COMPLETADO (rama dev, pendiente commit) |
| **edugo-infrastructure** | `postgres/migrations/seeds/006_seed_screen_templates.sql` | `platformOverrides.ios` en los 6 templates | COMPLETADO (rama feature, pendiente commit) |
| **edugo-infrastructure** | `postgres/migrations/structure/016..019` | **Sin cambios en CREATE TABLE** | N/A |
| **MongoDB** | Coleccion `material_event` | **Sin cambios** | N/A |
| **edugo-api-administracion** | Handler de templates | Validar keys de `platformOverrides` contra `ValidatePlatform()` | PENDIENTE (opcional, baja prioridad) |

---

## 8. Directrices para Clientes Existentes

Los cambios propuestos son 100% retrocompatibles:

1. **Clientes que envian `platform=mobile`** seguiran funcionando exactamente igual. La cadena de fallback busca `mobile` en `platformOverrides`, y si no existe (como en los templates actuales), retorna el JSON base sin overrides, que es el comportamiento actual.

2. **El fallback `ios -> mobile -> default`** asegura que incluso si no hay override de iOS, se usa el de mobile (y si tampoco hay mobile, se usa el template base).

3. **No se requiere actualizacion inmediata** de ningun cliente existente. Los clientes existentes pueden seguir enviando `platform=mobile` indefinidamente.

4. **Los clientes existentes PUEDEN** opcionalmente actualizar a enviar `platform=android` para recibir overrides especificos de Android en el futuro, pero no es obligatorio.

5. **La app iOS enviara `platform=ios`** desde el inicio, lo cual requiere que los cambios en shared y las APIs esten desplegados antes de que iOS entre en desarrollo activo del Dynamic UI.

---

## 9. Estado de Implementacion

### Integrado

| Paso | Componente | Detalle | Release |
|------|-----------|---------|---------|
| 1 | edugo-shared | Tipo `Platform`, `ValidatePlatform()`, `ResolvePlatformOverrideKey()`, `PlatformFallback`, 4 tests | `screenconfig/v0.51.0` (main, publicado) |

### Implementado (pendiente commit/merge)

| Paso | Componente | Detalle | Rama |
|------|-----------|---------|------|
| 2 | edugo-api-mobile | `applyPlatformOverrides()` con fallback chain via shared | `dev` |
| 3 | edugo-api-mobile | Cache key incluye platform: `screen:%s:platform:%s` | `dev` |
| 4 | edugo-api-mobile | Swagger docs actualizados (ios, android) | `dev` |
| 5 | edugo-api-mobile | Dependencia `screenconfig v0.51.0` agregada | `dev` |
| 6 | edugo-infrastructure | `platformOverrides.ios` en 6 templates base | `feature/dynamic-ui-phase3-seeds` |

### Pendiente

| Paso | Componente | Detalle | Prioridad |
|------|-----------|---------|-----------|
| 7 | edugo-api-mobile | Tests de retrocompatibilidad (`platform=mobile` funciona igual) | Alta |
| 8 | edugo-api-mobile | Tests nuevos con `platform=ios` y `platform=android` | Alta |
| 9 | edugo-api-administracion | Validar keys de `platformOverrides` contra `ValidatePlatform()` | Baja (opcional) |

### Verificacion de retrocompatibilidad

Tests criticos a ejecutar despues de hacer commit:

```
# En edugo-shared (ya pasaron - 17/17)
cd screenconfig && go test ./... -v

# En edugo-api-mobile (ejecutar despues del commit)
go test ./internal/application/service/ -run TestGetScreen
go test ./internal/application/service/ -run TestNavigation
go test ./internal/infrastructure/http/handler/ -run TestScreenHandler
```
