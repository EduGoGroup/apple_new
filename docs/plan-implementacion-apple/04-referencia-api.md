# Referencia de APIs para iOS

Referencia rapida de todos los endpoints que consume la app iOS de EduGo. Documento orientado a desarrolladores iOS nativos (Swift/SwiftUI).

---

## Configuracion de Ambientes

| Ambiente | API Admin (`:8081`) | API Mobile (`:9091`) |
|----------|---------------------|----------------------|
| LOCAL | `http://localhost:8081` | `http://localhost:9091` |
| DEV | `https://api-dev.example.com` | `https://api-mobile-dev.example.com` |
| STAGING | `https://api-staging.example.com` | `https://api-mobile-staging.example.com` |
| PROD | `https://api.example.com` | `https://api-mobile.example.com` |

---

## Dual API Routing

La app consume dos APIs distintas. El enrutamiento se determina por prefijo:

| Prefijo | Destino | Ejemplo |
|---------|---------|---------|
| Sin prefijo o `mobile:` | API Mobile (`:9091`) | `GET /v1/materials` |
| `admin:` | API Admin (`:8081`) | `POST /v1/auth/login` |

---

## Headers Comunes

Todos los requests autenticados deben incluir:

```
Authorization: Bearer {access_token}
Content-Type: application/json
Accept: application/json
```

---

## 1. Autenticacion (API Admin - 8081)

### POST `/v1/auth/login`

Inicio de sesion. Retorna tokens y contexto activo del usuario.

**Request:**
```json
{
  "email": "string",
  "password": "string"
}
```

**Response 200:**
```json
{
  "access_token": "string",
  "refresh_token": "string",
  "expires_in": 3600,
  "token_type": "Bearer",
  "user": {
    "id": "uuid",
    "email": "string",
    "first_name": "string",
    "last_name": "string",
    "full_name": "string",
    "school_id": "uuid | null"
  },
  "active_context": {
    "role_id": "uuid",
    "role_name": "string",
    "school_id": "uuid | null",
    "school_name": "string | null",
    "academic_unit_id": "uuid | null",
    "academic_unit_name": "string | null",
    "permissions": ["string"]
  }
}
```

**Errores:**

| Codigo | Significado |
|--------|-------------|
| 400 | Validacion fallida |
| 401 | Credenciales invalidas |
| 403 | Usuario inactivo |
| 404 | Usuario no encontrado |
| 423 | Cuenta bloqueada |
| 500 | Error interno del servidor |

---

### POST `/v1/auth/refresh`

Renueva el access token usando el refresh token.

**Request:**
```json
{
  "refresh_token": "string"
}
```

**Response 200:**
```json
{
  "access_token": "string",
  "expires_in": 3600,
  "token_type": "Bearer"
}
```

---

### POST `/v1/auth/logout`

Cierra la sesion e invalida el token actual.

**Headers:** `Authorization: Bearer {token}`

**Response 200:** Exito (sin cuerpo relevante).

---

### POST `/v1/auth/switch-context`

Cambia el contexto activo del usuario (por ejemplo, cambiar de escuela).

**Headers:** `Authorization: Bearer {token}`

**Request:**
```json
{
  "school_id": "uuid"
}
```

**Response 200:**
```json
{
  "access_token": "string",
  "refresh_token": "string",
  "expires_in": 3600,
  "token_type": "Bearer",
  "context": {
    "school_id": "uuid",
    "school_name": "string",
    "role": "string",
    "user_id": "uuid",
    "email": "string"
  }
}
```

---

### POST `/v1/auth/verify`

Verifica si un token es valido.

**Request:**
```json
{
  "token": "string"
}
```

**Response 200:**
```json
{
  "valid": true,
  "claims": { "..." }
}
```

---

## 2. Screens - UI Dinamica (API Mobile)

### GET `/v1/screens/:screenKey`

Carga la definicion completa de una pantalla del servidor.

**Query Params:** `?platform=ios`

**Headers opcionales:** `If-None-Match: "etag-value"` (para cache)

**Response 200:**
```json
{
  "screen_id": "string",
  "screen_key": "string",
  "screen_name": "string",
  "pattern": "string",
  "version": 1,
  "template": {
    "navigation": {},
    "zones": ["Zone"],
    "platformOverrides": {}
  },
  "slot_data": {},
  "data_endpoint": "string | null",
  "data_config": {},
  "actions": ["ActionDefinition"],
  "handler_key": "string | null",
  "updated_at": "ISO8601"
}
```

**Response 304:** Not Modified (el cache local sigue valido).

**Patterns disponibles:**

| Pattern | Uso tipico |
|---------|-----------|
| `login` | Pantalla de inicio de sesion |
| `form` | Formularios genericos |
| `list` | Listados con paginacion |
| `dashboard` | Paneles principales por rol |
| `settings` | Configuracion |
| `detail` | Vista de detalle de un recurso |
| `search` | Busqueda |
| `profile` | Perfil de usuario |
| `modal` | Dialogos modales |
| `notification` | Centro de notificaciones |
| `onboarding` | Flujo de bienvenida |
| `empty-state` | Estados vacios |

---

### GET `/v1/screens/resource/:resourceKey`

Carga una pantalla asociada a un recurso especifico.

**Query Params:** `?platform=ios`

---

### GET `/v1/screens/navigation`

Carga la estructura de navegacion completa (tab bar + drawer).

**Query Params:** `?platform=ios`

**Response 200:**
```json
{
  "bottom_nav": [
    {
      "key": "string",
      "label": "string",
      "icon": "string",
      "screen_key": "string",
      "sort_order": 0
    }
  ],
  "drawer_items": [
    {
      "key": "string",
      "label": "string",
      "icon": "string",
      "screen_key": "string",
      "sort_order": 0,
      "children": []
    }
  ],
  "version": 1
}
```

---

### PUT `/v1/screens/:screenKey/preferences`

Guarda preferencias de usuario para una pantalla especifica.

**Request:**
```json
{
  "preferences": { "..." }
}
```

---

## 3. Screen Config - CRUD (API Admin - 8081)

Endpoints de administracion para gestionar templates e instancias de pantallas.

### Templates

| Metodo | Endpoint | Permiso |
|--------|----------|---------|
| `POST` | `/v1/screen-config/templates` | `screen_templates:create` |
| `GET` | `/v1/screen-config/templates` | `screen_templates:read` |
| `GET` | `/v1/screen-config/templates/:id` | `screen_templates:read` |
| `PUT` | `/v1/screen-config/templates/:id` | `screen_templates:update` |
| `DELETE` | `/v1/screen-config/templates/:id` | `screen_templates:delete` |

### Instances

| Metodo | Endpoint | Permiso |
|--------|----------|---------|
| `POST` | `/v1/screen-config/instances` | `screen_instances:create` |
| `GET` | `/v1/screen-config/instances` | `screen_instances:read` |
| `GET` | `/v1/screen-config/instances/:id` | `screen_instances:read` |
| `GET` | `/v1/screen-config/instances/key/:key` | `screen_instances:read` |
| `PUT` | `/v1/screen-config/instances/:id` | `screen_instances:update` |
| `DELETE` | `/v1/screen-config/instances/:id` | `screen_instances:delete` |

### Resolucion

| Metodo | Endpoint | Permiso |
|--------|----------|---------|
| `GET` | `/v1/screen-config/resolve/key/:key` | `screen_instances:read` |

### Resource Screens

| Metodo | Endpoint | Permiso |
|--------|----------|---------|
| `POST` | `/v1/screen-config/resource-screens` | `screen_instances:create` |
| `GET` | `/v1/screen-config/resource-screens/:resourceId` | `screen_instances:read` |
| `DELETE` | `/v1/screen-config/resource-screens/:id` | `screen_instances:delete` |

---

## 4. Materials (API Mobile)

### Endpoints de Lectura

| Metodo | Endpoint | Permiso | Descripcion |
|--------|----------|---------|-------------|
| `GET` | `/v1/materials` | `materials:read` | Listar materiales (paginado) |
| `GET` | `/v1/materials/:id` | `materials:read` | Detalle de un material |
| `GET` | `/v1/materials/:id/versions` | `materials:read` | Historial de versiones |
| `GET` | `/v1/materials/:id/download-url` | `materials:download` | URL prefirmada de S3 |
| `GET` | `/v1/materials/:id/summary` | `materials:read` | Resumen generado por IA |
| `GET` | `/v1/materials/:id/assessment` | `assessments:read` | Quiz asociado al material |
| `GET` | `/v1/materials/:id/stats` | `stats:unit` | Estadisticas del material |

**Paginacion:** `?limit=20&offset=0`

### Endpoints de Escritura

| Metodo | Endpoint | Permiso | Descripcion |
|--------|----------|---------|-------------|
| `POST` | `/v1/materials` | `materials:create` | Crear nuevo material |
| `POST` | `/v1/materials/:id/upload-url` | `materials:create` | Obtener URL de subida a S3 |
| `POST` | `/v1/materials/:id/upload-complete` | `materials:create` | Notificar subida completada |
| `PUT` | `/v1/materials/:id` | `materials:update` | Editar material existente |

### Flujo de Subida de Archivos

1. `POST /v1/materials` - Crear el registro del material
2. `POST /v1/materials/:id/upload-url` - Obtener URL prefirmada de S3
3. Subir archivo directamente a S3 con `PUT` al URL obtenido
4. `POST /v1/materials/:id/upload-complete` - Notificar al backend que la subida termino

---

## 5. Assessments (API Mobile)

| Metodo | Endpoint | Permiso | Descripcion |
|--------|----------|---------|-------------|
| `POST` | `/v1/materials/:id/assessment/attempts` | `assessments:attempt` | Enviar un intento de quiz |
| `GET` | `/v1/attempts/:id/results` | `assessments:view_results` | Ver resultados de un intento |
| `GET` | `/v1/users/me/attempts` | `assessments:view_results` | Listar mis intentos |

---

## 6. Progress (API Mobile)

### PUT `/v1/progress`

Actualiza el progreso de lectura de un material.

**Permiso:** `progress:update`

**Request:**
```json
{
  "material_id": "uuid",
  "percentage": 75,
  "last_page": 12,
  "status": "in_progress"
}
```

**Valores validos para `status`:**

| Valor | Significado |
|-------|-------------|
| `not_started` | No iniciado |
| `in_progress` | En progreso |
| `completed` | Completado |

---

## 7. Stats (API Mobile / Admin)

### GET `/v1/stats/global`

Retorna los KPIs principales del dashboard.

**Permiso:** `stats:global`

---

## 8. Gestion de Usuarios (API Admin - 8081)

| Metodo | Endpoint | Permiso | Descripcion |
|--------|----------|---------|-------------|
| `GET` | `/v1/users/:user_id/memberships` | JWT only | Listar membresias del usuario |
| `GET` | `/v1/users/:user_id/roles` | `users:read` | Listar roles asignados |
| `POST` | `/v1/users/:user_id/roles` | `users:update` | Asignar rol al usuario |
| `DELETE` | `/v1/users/:user_id/roles/:role_id` | `users:update` | Remover rol del usuario |

---

## 9. Schools (API Admin - 8081)

| Metodo | Endpoint | Permiso | Descripcion |
|--------|----------|---------|-------------|
| `POST` | `/v1/schools` | `schools:create` | Crear escuela |
| `GET` | `/v1/schools` | `schools:read` | Listar escuelas |
| `GET` | `/v1/schools/code/:code` | `schools:read` | Buscar escuela por codigo |
| `GET` | `/v1/schools/:id` | `schools:read` | Detalle de escuela |
| `PUT` | `/v1/schools/:id` | `schools:update` | Actualizar escuela |
| `DELETE` | `/v1/schools/:id` | `schools:delete` | Eliminar escuela |

---

## 10. Academic Units (API Admin - 8081)

| Metodo | Endpoint | Permiso | Descripcion |
|--------|----------|---------|-------------|
| `POST` | `/v1/schools/:id/units` | `units:create` | Crear unidad academica |
| `GET` | `/v1/schools/:id/units` | `units:read` | Listar unidades de una escuela |
| `GET` | `/v1/schools/:id/units/tree` | `units:read` | Arbol jerarquico de unidades |
| `GET` | `/v1/schools/:id/units/by-type` | `units:read` | Unidades agrupadas por tipo |
| `GET` | `/v1/units/:id` | `units:read` | Detalle de unidad |
| `PUT` | `/v1/units/:id` | `units:update` | Actualizar unidad |
| `DELETE` | `/v1/units/:id` | `units:delete` | Eliminar unidad (soft delete) |
| `POST` | `/v1/units/:id/restore` | `units:update` | Restaurar unidad eliminada |
| `GET` | `/v1/units/:id/hierarchy-path` | `units:read` | Ruta jerarquica de la unidad |

---

## 11. Memberships (API Admin - 8081)

Todos los endpoints requieren unicamente JWT valido (sin permisos RBAC adicionales).

| Metodo | Endpoint | Descripcion |
|--------|----------|-------------|
| `POST` | `/v1/memberships` | Crear membresia |
| `GET` | `/v1/memberships` | Listar membresias (`?unit_id=uuid`) |
| `GET` | `/v1/memberships/by-role` | Listar membresias por rol |
| `GET` | `/v1/memberships/:id` | Detalle de membresia |
| `PUT` | `/v1/memberships/:id` | Actualizar membresia |
| `DELETE` | `/v1/memberships/:id` | Eliminar membresia |
| `POST` | `/v1/memberships/:id/expire` | Expirar membresia |

---

## 12. Guardian Relations (API Admin - 8081)

Todos los endpoints requieren unicamente JWT valido.

| Metodo | Endpoint | Descripcion |
|--------|----------|-------------|
| `POST` | `/v1/guardian-relations` | Crear relacion tutor-estudiante |
| `GET` | `/v1/guardian-relations/:id` | Detalle de relacion |
| `PUT` | `/v1/guardian-relations/:id` | Actualizar relacion |
| `DELETE` | `/v1/guardian-relations/:id` | Eliminar relacion |
| `GET` | `/v1/guardians/:guardian_id/relations` | Listar relaciones de un tutor |
| `GET` | `/v1/students/:student_id/guardians` | Listar tutores de un estudiante |

---

## 13. Menu y Navegacion RBAC (API Admin - 8081)

| Metodo | Endpoint | Permiso | Descripcion |
|--------|----------|---------|-------------|
| `GET` | `/v1/menu` | JWT only | Menu filtrado por permisos del token |
| `GET` | `/v1/menu/full` | `permissions_mgmt:read` | Menu completo sin filtrar |

---

## 14. Resources, Permissions, Roles (API Admin - 8081)

### Resources

| Metodo | Endpoint | Permiso |
|--------|----------|---------|
| `GET` | `/v1/resources` | `permissions_mgmt:read` |
| `GET` | `/v1/resources/:id` | `permissions_mgmt:read` |
| `POST` | `/v1/resources` | `permissions_mgmt:update` |
| `PUT` | `/v1/resources/:id` | `permissions_mgmt:update` |

### Permissions

| Metodo | Endpoint | Permiso |
|--------|----------|---------|
| `GET` | `/v1/permissions` | `permissions_mgmt:read` |
| `GET` | `/v1/permissions/:id` | `permissions_mgmt:read` |

### Roles

| Metodo | Endpoint | Permiso |
|--------|----------|---------|
| `GET` | `/v1/roles` | `users:read` |
| `GET` | `/v1/roles/:id` | `users:read` |
| `GET` | `/v1/roles/:id/permissions` | `users:read` |

---

## 15. Subjects (API Admin - 8081)

Todos los endpoints requieren unicamente JWT valido.

| Metodo | Endpoint | Descripcion |
|--------|----------|-------------|
| `POST` | `/v1/subjects` | Crear materia |
| `GET` | `/v1/subjects` | Listar materias |
| `GET` | `/v1/subjects/:id` | Detalle de materia |
| `PATCH` | `/v1/subjects/:id` | Actualizar materia (parcial) |
| `DELETE` | `/v1/subjects/:id` | Eliminar materia |

---

## 16. Modelo de Error Estandar

Todas las APIs retornan errores con esta estructura:

```json
{
  "error": "NotFound",
  "message": "El recurso solicitado no existe",
  "code": 404
}
```

### Codigos de Error

| Codigo Error | HTTP Status | Descripcion |
|-------------|-------------|-------------|
| `Validation` | 400 | Datos de entrada invalidos |
| `Unauthorized` | 401 | Token ausente o expirado |
| `Forbidden` | 403 | Sin permisos suficientes |
| `NotFound` | 404 | Recurso no encontrado |
| `BusinessRule` | 409/422 | Violacion de regla de negocio |
| `RateLimit` | 429 | Demasiados requests |
| `DatabaseError` | 500 | Error de base de datos |
| `InternalError` | 500 | Error interno del servidor |

---

## 17. JWT Claims

Estructura del payload del JWT decodificado:

```json
{
  "user_id": "uuid",
  "email": "string",
  "active_context": {
    "role_id": "uuid",
    "role_name": "super_admin",
    "school_id": "uuid | null",
    "school_name": "string | null",
    "academic_unit_id": "uuid | null",
    "academic_unit_name": "string | null",
    "permissions": ["users:read", "materials:create"]
  },
  "jti": "uuid",
  "iss": "edugo-central",
  "sub": "user_id",
  "iat": 1700000000,
  "exp": 1700003600
}
```

**Campos clave para la app iOS:**

| Campo | Tipo | Uso en la app |
|-------|------|---------------|
| `user_id` | UUID | Identificar al usuario actual |
| `active_context.role_name` | string | Determinar rol activo y dashboard |
| `active_context.school_id` | UUID? | Contexto de escuela actual |
| `active_context.permissions` | [string] | Control de acceso en la UI |
| `exp` | timestamp | Saber cuando renovar el token |

---

## 18. Roles del Sistema

| Rol | Dashboard Key | Scope | Descripcion |
|-----|--------------|-------|-------------|
| `super_admin` | `dashboard-superadmin` | system | Administrador global de la plataforma |
| `platform_admin` | `dashboard-superadmin` | system | Administrador de la plataforma |
| `school_admin` | `dashboard-schooladmin` | school | Administrador de escuela |
| `school_director` | `dashboard-schooladmin` | school | Director de escuela |
| `teacher` | `dashboard-teacher` | unit | Profesor |
| `student` | `dashboard-student` | unit | Estudiante |
| `guardian` | `dashboard-guardian` | unit | Tutor / Padre de familia |

**Uso en la app:** El `role_name` del JWT determina que `dashboard key` cargar como pantalla principal.

---

## 19. Permisos RBAC (40+)

### Por Dominio

**Usuarios:**
`users:create` `users:read` `users:update` `users:delete` `users:read:own` `users:update:own`

**Escuelas:**
`schools:create` `schools:read` `schools:update` `schools:delete` `schools:manage`

**Unidades Academicas:**
`units:create` `units:read` `units:update` `units:delete`

**Materiales:**
`materials:create` `materials:read` `materials:update` `materials:delete` `materials:publish` `materials:download`

**Evaluaciones:**
`assessments:create` `assessments:read` `assessments:update` `assessments:delete` `assessments:publish` `assessments:grade` `assessments:attempt` `assessments:view_results`

**Progreso:**
`progress:read` `progress:update` `progress:read:own`

**Estadisticas:**
`stats:global` `stats:school` `stats:unit`

**Screen Config:**
`screen_templates:create` `screen_templates:read` `screen_templates:update` `screen_templates:delete`
`screen_instances:create` `screen_instances:read` `screen_instances:update` `screen_instances:delete`

**Screens:**
`screens:read`

**Gestion de Permisos:**
`permissions_mgmt:read` `permissions_mgmt:update`

---

## Referencia Rapida: Endpoints por API

### API Mobile (`:9091`)

| Seccion | Prefijo | Cantidad |
|---------|---------|----------|
| Screens | `/v1/screens/` | 4 endpoints |
| Materials | `/v1/materials/` | 11 endpoints |
| Assessments | `/v1/materials/:id/assessment/`, `/v1/attempts/`, `/v1/users/me/` | 3 endpoints |
| Progress | `/v1/progress` | 1 endpoint |
| Stats | `/v1/stats/` | 1 endpoint |

### API Admin (`:8081`)

| Seccion | Prefijo | Cantidad |
|---------|---------|----------|
| Auth | `/v1/auth/` | 5 endpoints |
| Screen Config | `/v1/screen-config/` | 12 endpoints |
| Users | `/v1/users/` | 4 endpoints |
| Schools | `/v1/schools/` | 6 endpoints |
| Academic Units | `/v1/schools/:id/units/`, `/v1/units/` | 9 endpoints |
| Memberships | `/v1/memberships/` | 7 endpoints |
| Guardian Relations | `/v1/guardian-relations/`, `/v1/guardians/`, `/v1/students/` | 6 endpoints |
| Menu | `/v1/menu/` | 2 endpoints |
| Resources | `/v1/resources/` | 4 endpoints |
| Permissions | `/v1/permissions/` | 2 endpoints |
| Roles | `/v1/roles/` | 3 endpoints |
| Subjects | `/v1/subjects/` | 5 endpoints |
