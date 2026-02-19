# 01 - Arquitectura General

## 1.1 Vision del Proyecto

EduGo es una plataforma educativa con UI 100% server-driven. Las pantallas, navegacion, y comportamientos se definen en el backend y el cliente las renderiza dinamicamente. Esto permite:

- Cambiar la UI sin publicar nueva version de la app
- Personalizar pantallas por rol (estudiante, profesor, admin, guardian)
- Controlar permisos y visibilidad desde el servidor
- Soportar multiples plataformas con la misma definicion

## 1.2 APIs del Ecosistema

La app se conecta a **dos APIs** independientes que comparten la misma base de datos:

### Mobile API (puerto 8080)
- **Proposito**: Operaciones del usuario final (estudiantes, profesores, guardians)
- **Autenticacion**: JWT validado remotamente contra Admin API
- **Endpoints principales**: materials, assessments, progress, stats, screens, navigation
- **Ejemplo base URL**: `https://api-mobile.edugo.com/v1`

### Admin API (puerto 8081)
- **Proposito**: Administracion del sistema (gestiones CRUD, RBAC, configuracion)
- **Autenticacion**: JWT validado localmente
- **Endpoints principales**: auth (login/refresh/logout), users, schools, units, memberships, roles, permissions, screen-config
- **Ejemplo base URL**: `https://api-admin.edugo.com/v1`

### Regla de enrutamiento
La app determina que API usar segun el prefijo del endpoint configurado en cada pantalla:
- Sin prefijo o `mobile:` → Mobile API
- `admin:` → Admin API

Ejemplo: `admin:/v1/users` enruta al Admin API, `/v1/materials` enruta al Mobile API.

## 1.3 Filosofia Server-Driven UI

### Jerarquia de definicion

```
Screen Template (estructura reutilizable)
    |
    v
Screen Instance (datos especificos por pantalla)
    |
    v
Screen Definition (template + instance combinados, lo que recibe el cliente)
    |
    v
Renderer del cliente (SwiftUI views)
```

### Conceptos clave

1. **Template**: Define la ESTRUCTURA de un tipo de pantalla (ej: "formulario con header, campos, y botones"). No tiene datos especificos.

2. **Instance**: Define una pantalla CONCRETA usando un template (ej: "formulario de crear material" con campos titulo, materia, grado).

3. **Screen Definition**: Lo que el endpoint `/v1/screens/:key` devuelve al cliente. Es la combinacion de template + instance ya resuelta.

4. **Pattern**: Tipo de pantalla (login, dashboard, list, detail, form, settings). Cada pattern tiene su propio renderer.

5. **Zone**: Seccion dentro de una pantalla. Puede contener slots u otras zones (composicion recursiva).

6. **Slot**: Componente UI atomico dentro de una zone (label, text-input, button, metric-card, etc.).

7. **Action**: Comportamiento asociado a un trigger (click de boton, pull-refresh, tap en item de lista).

## 1.4 Plataformas Apple Objetivo

| Plataforma | Equivale a | Navegacion | Layout |
|------------|-----------|------------|--------|
| iPhone | COMPACT | TabBar inferior | Stacked (Column) |
| iPad | MEDIUM/EXPANDED | Sidebar | Split View |
| Mac (Catalyst/Native) | EXPANDED | Sidebar permanente | Multi-panel |

## 1.5 Modulos de la App

```
App Shell (NavigationSplitView / TabView)
  |
  +-- Auth Module (login, token management, session)
  |
  +-- Dynamic UI Module (screen loading, rendering, actions)
  |     +-- Screen Loader (fetch screen definitions)
  |     +-- Data Loader (fetch data for screens, dual API)
  |     +-- Pattern Renderers (SwiftUI views per pattern)
  |     +-- Action System (handlers for user interactions)
  |
  +-- Network Module (HTTP client, interceptors, resilience)
  |     +-- Dual API routing
  |     +-- Auth interceptor (inject Bearer token)
  |     +-- Circuit Breaker
  |     +-- Rate Limiter
  |     +-- Retry Policy
  |
  +-- Storage Module (Keychain for tokens, UserDefaults for cache)
  |
  +-- Navigation Module (server-driven tabs/sidebar, role-based)
```

## 1.6 Flujo General de la App

```
1. App Launch
   → Restore session (leer tokens de Keychain)
   → Si token valido: ir a 3
   → Si token expirado pero hay refresh: intentar refresh
   → Si no hay session: ir a 2

2. Login Screen
   → POST /v1/auth/login (Admin API)
   → Recibir: access_token + refresh_token + user + active_context
   → Guardar en Keychain (3 items separados)
   → Iniciar auto-refresh de token
   → Ir a 3

3. Cargar Navegacion
   → GET /v1/screens/navigation (Mobile API)
   → Recibir: tabs/sidebar items filtrados por permisos del usuario
   → Renderizar shell adaptativo (TabBar en iPhone, Sidebar en iPad/Mac)

4. Seleccionar Tab/Item
   → Obtener screenKey del item seleccionado
   → Si es dashboard: seleccionar screenKey segun rol del usuario
   → GET /v1/screens/{screenKey} (Mobile API)
   → Recibir ScreenDefinition (pattern + zones + slots + actions + dataEndpoint)

5. Renderizar Pantalla
   → Seleccionar renderer segun pattern (list, form, dashboard, detail, etc.)
   → Resolver bindings (slot:value → slotData, {user.name} → placeholders)
   → Si tiene dataEndpoint: GET data desde la API correspondiente
   → Mostrar datos en los controles

6. Interaccion del Usuario
   → Click en boton / tap en item / pull-refresh
   → Buscar action definition que matchee el trigger
   → Ejecutar: handler custom (si existe) → handler generico (fallback)
   → Resultado: navegar, mostrar mensaje, recargar datos, logout

7. Token Auto-Refresh (Background)
   → Cada X segundos (configurable por entorno)
   → Si token esta por expirar: POST /v1/auth/refresh (Admin API)
   → Actualizar token en Keychain + estado de la app
   → Si falla irrecuperablemente: limpiar sesion → ir a 2
```
