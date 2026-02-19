# 07 - Dynamic UI - Sistema de Acciones

## 7.1 Arquitectura de Acciones

Las acciones conectan interacciones del usuario con comportamientos. Cada pantalla define sus acciones en el JSON, y la app las ejecuta.

### ActionDefinition (del JSON)
```
{
  "id": "submit-login",              // ID unico de la accion
  "trigger": "button_click",         // Que dispara la accion
  "triggerSlotId": "login_btn",      // Que slot la dispara (opcional)
  "type": "SUBMIT_FORM",            // Tipo de accion
  "config": {                        // Parametros especificos
    "endpoint": "/v1/auth/login",
    "method": "POST",
    "fieldMapping": {"email": "email", "password": "password"},
    "onSuccess": {"type": "NAVIGATE", "config": {"target": "dashboard-home"}}
  }
}
```

### Triggers
| Trigger | Cuando se dispara |
|---------|-------------------|
| `button_click` | Tap en un boton (matchea con triggerSlotId) |
| `item_click` | Tap en un item de lista |
| `pull_refresh` | Pull-to-refresh gesture |
| `fab_click` | Tap en floating action button |
| `swipe` | Swipe gesture en un item |
| `long_press` | Long press en un item |

### Action Types
| Tipo | Descripcion |
|------|-------------|
| `NAVIGATE` | Navegar a otra pantalla |
| `NAVIGATE_BACK` | Volver atras |
| `API_CALL` | Llamada a API (GET, sin form data) |
| `SUBMIT_FORM` | Enviar formulario (POST/PUT con field values) |
| `REFRESH` | Recargar datos de la pantalla |
| `CONFIRM` | Mostrar dialogo de confirmacion |
| `LOGOUT` | Cerrar sesion |

## 7.2 Flujo de Ejecucion

```
1. Usuario interactua (tap boton, tap item, pull-refresh)
   |
2. Identificar que accion corresponde
   - Buscar en screen.actions por trigger + triggerSlotId
   |
3. Crear ActionContext
   {
     screenKey: "material-create",
     actionId: "submit-material",
     config: { ... },          // config de la action definition
     fieldValues: { ... },     // valores actuales del form
     selectedItemId: "123",    // ID del item si es item_click
     selectedItem: { ... }     // JSON del item seleccionado
   }
   |
4. Buscar handler CUSTOM primero (ScreenActionHandler)
   - Buscar en registry por screenKey
   - Si handler.canHandle(action): ejecutar handler.handle()
   |
5. Si no hay handler custom: usar handler GENERICO (ActionRegistry)
   - Buscar por action.type
   - NAVIGATE → NavigateHandler
   - SUBMIT_FORM → SubmitFormHandler
   - etc.
   |
6. Obtener ActionResult
   |
7. Procesar resultado
   - NavigateTo(screenKey, params) → navegar
   - Success(message) → mostrar snackbar/toast
   - Error(message) → mostrar error
   - Logout → ejecutar logout flow
   - Cancelled → no hacer nada
```

## 7.3 Handlers Genericos

### NavigateHandler
```
Input: action.config = {"target": "material-detail", "params": {"id": "{item.id}"}}
Proceso:
  1. Extraer target screenKey del config
  2. Extraer params, resolver placeholders ({item.id} → ID real)
Output: ActionResult.NavigateTo("material-detail", {"id": "abc-123"})
```

### SubmitFormHandler
```
Input: action.config = {"endpoint": "/v1/materials", "method": "POST", "fieldMapping": {...}}
Proceso:
  1. Construir JSON body con fieldValues segun fieldMapping
  2. POST/PUT al endpoint via DataLoader
  3. Parsear respuesta
Output: ActionResult.Success(data) o ActionResult.Error(message)
```

### ApiCallHandler
```
Input: action.config = {"endpoint": "/v1/materials/{id}/download-url", "method": "GET"}
Proceso:
  1. Resolver endpoint (reemplazar {id} con valor real)
  2. GET al endpoint
  3. Extraer URL de respuesta si aplica
Output: ActionResult.Success(data)
```

### RefreshHandler
```
Proceso: Retorna ActionResult.Success("refresh")
El screen principal interpreta esto como: recargar datos del dataEndpoint
```

### ConfirmHandler
```
Input: action.config = {"title": "Sign Out", "message": "Are you sure?", "confirmLabel": "Sign Out", "onConfirm": {"type": "LOGOUT"}}
Proceso:
  1. Retorna Success con el message
  2. La UI muestra un dialogo de confirmacion
  3. Si el usuario confirma: ejecutar la accion de onConfirm
```

### LogoutHandler
```
Proceso: Retorna ActionResult.Logout
La app ejecuta el flujo de logout completo
```

## 7.4 Handlers Custom por Pantalla

Los handlers custom interceptan acciones ANTES de los genericos. Permiten logica especifica por pantalla.

### Interfaz
```
ScreenActionHandler:
  screenKeys: Set<String>  // ej: {"material-create", "material-edit"}
  canHandle(action) → Bool  // puede manejar esta accion?
  handle(action, context) → ActionResult  // ejecutar
```

### Resolucion
```
1. ScreenHandlerRegistry busca handlers registrados para el screenKey actual
2. Para cada handler encontrado: si canHandle(action) es true, ejecutar
3. Si ningun handler custom puede manejar: caer al handler generico
```

### Handlers implementados

| Handler | Screen Keys | Maneja | Logica |
|---------|------------|--------|--------|
| LoginActionHandler | app-login | SUBMIT_FORM | Valida email/password, llama authService.login(), navega a dashboard |
| SettingsActionHandler | app-settings | LOGOUT, NAVIGATE_BACK, CONFIRM | Maneja toggle tema, logout con confirmacion |
| DashboardActionHandler | dashboard-teacher, dashboard-student | ALL | Test handler, intercepta todo |
| MaterialCreateHandler | material-create | SUBMIT_FORM | Valida title, POST /v1/materials, navega a material-detail |
| MaterialEditHandler | material-edit | SUBMIT_FORM | Valida title, PUT /v1/materials/{id}, navega a material-detail |
| AssessmentTakeHandler | assessment-take | SUBMIT_FORM | Valida respuestas, submit assessment |
| ProgressHandler | progress-my, progress-unit-list, progress-student-detail | NAVIGATE, REFRESH | Delegacion simple |
| UserCrudHandler | user-create, user-edit | SUBMIT_FORM | Valida nombre+email, POST/PUT admin:/v1/users |
| SchoolCrudHandler | school-create, school-edit | SUBMIT_FORM | Valida nombre, POST/PUT admin:/v1/schools |
| UnitCrudHandler | unit-create, unit-edit | SUBMIT_FORM | Valida nombre, POST/PUT admin:/v1/schools/{id}/units |
| MembershipHandler | membership-add | SUBMIT_FORM | Valida email+role, POST admin:/v1/memberships |
| GuardianHandler | dashboard-guardian, children-list, child-progress | NAVIGATE, REFRESH | Delegacion simple |

### Patron comun de CRUD Handler
```
1. Extraer fieldValues del context
2. Validar campos requeridos
3. Construir JSON body
4. Determinar si es create (POST) o edit (PUT)
5. Llamar dataLoader.submitData(endpoint, body, method)
6. Si exito: navegar al detail con el ID
7. Si error: retornar ActionResult.Error con mensaje
```

## 7.5 ActionResult

| Tipo | Campos | Uso |
|------|--------|-----|
| `NavigateTo` | screenKey, params | Navegar a otra pantalla |
| `Success` | message?, data? | Operacion exitosa, mostrar toast |
| `Error` | message, retry? | Error, mostrar alerta |
| `Logout` | - | Ejecutar flujo de logout |
| `Cancelled` | - | Usuario cancelo, no hacer nada |

## 7.6 Registro de Handlers (Dependency Injection)

Todos los handlers se registran centralmente. En Swift, esto seria un container de DI o un diccionario:

```
Registro actual:
  LoginActionHandler(authService)
  SettingsActionHandler(authService)
  DashboardActionHandler()
  MaterialCreateHandler(dataLoader)
  MaterialEditHandler(dataLoader)
  AssessmentTakeHandler()
  ProgressHandler()
  UserCrudHandler(dataLoader)
  SchoolCrudHandler(dataLoader)
  UnitCrudHandler(dataLoader)
  MembershipHandler(dataLoader)
  GuardianHandler()
```

Los que reciben `dataLoader` necesitan acceso al servicio de red para hacer POST/PUT.
Los que reciben `authService` necesitan acceso al servicio de autenticacion.
Los demas no tienen dependencias externas.
