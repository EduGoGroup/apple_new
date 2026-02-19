# 09 - Dual API Routing

## 9.1 Concepto

La app se conecta a dos APIs separadas que comparten la misma base de datos. El cliente determina a cual conectar segun el prefijo del endpoint.

### Regla de enrutamiento
```
endpoint empieza con "admin:" → Admin API (puerto 8081)
endpoint empieza con "mobile:" → Mobile API (puerto 8080, explicito)
endpoint sin prefijo → Mobile API (default)
```

### Ejemplos
| endpoint en screen definition | API | URL final |
|-------------------------------|-----|-----------|
| `/v1/materials` | Mobile | `https://mobile.edugo.com/v1/materials` |
| `mobile:/v1/materials` | Mobile | `https://mobile.edugo.com/v1/materials` |
| `admin:/v1/users` | Admin | `https://admin.edugo.com/v1/users` |
| `admin:/v1/schools/{id}` | Admin | `https://admin.edugo.com/v1/schools/{id}` |

## 9.2 Base URLs por Entorno

| Entorno | Mobile API | Admin API |
|---------|-----------|-----------|
| LOCAL | http://localhost:8080 | http://localhost:8081 |
| DEV | https://dev-mobile.edugo.com | https://dev-admin.edugo.com |
| STAGING | https://staging-mobile.edugo.com | https://staging-admin.edugo.com |
| PROD | https://api-mobile.edugo.com | https://api-admin.edugo.com |

## 9.3 Implementacion del Router

```
func resolveEndpoint(rawEndpoint: String) → (baseUrl: String, path: String) {
  if rawEndpoint.starts(with: "admin:") {
    let path = rawEndpoint.dropFirst("admin:".count)
    return (adminBaseUrl, path)
  } else if rawEndpoint.starts(with: "mobile:") {
    let path = rawEndpoint.dropFirst("mobile:".count)
    return (mobileBaseUrl, path)
  } else {
    return (mobileBaseUrl, rawEndpoint)
  }
}
```

## 9.4 Validacion de Endpoints

Antes de ejecutar un request, validar:
- El path debe empezar con `/`
- No debe contener `..` (path traversal)
- No debe contener `://` (URL completa)

## 9.5 Autenticacion en ambas APIs

Ambas APIs usan el mismo JWT. El interceptor de auth agrega `Authorization: Bearer {token}` a todos los requests autenticados, sin importar a que API van.

La diferencia es como VALIDAN el token:
- **Admin API**: Validacion local (verifica firma del JWT directamente)
- **Mobile API**: Validacion remota (llama al Admin API para verificar)

Esto es transparente para el cliente - solo envia el Bearer token.

## 9.6 Endpoints Completos

### Admin API - Autenticacion (Publicos)

| Metodo | Endpoint | Body | Respuesta |
|--------|----------|------|-----------|
| POST | `/v1/auth/login` | `{email, password}` | `{access_token, refresh_token, expires_in, token_type, user, active_context}` |
| POST | `/v1/auth/refresh` | `{refresh_token}` | `{access_token, expires_in, token_type}` |
| POST | `/v1/auth/logout` | - (Bearer header) | `{message}` |
| POST | `/v1/auth/verify` | `{token}` | `{valid, user_id, email, role, ...}` |
| POST | `/v1/auth/switch-context` | `{school_id, role_id}` | Nuevo token + context |

### Admin API - Users

| Metodo | Endpoint | Permiso |
|--------|----------|---------|
| GET | `/v1/users/:id/memberships` | users:read |
| GET | `/v1/users/:id/roles` | users:read |
| POST | `/v1/users/:id/roles` | users:update |
| DELETE | `/v1/users/:id/roles/:role_id` | users:update |

### Admin API - Schools

| Metodo | Endpoint | Permiso |
|--------|----------|---------|
| POST | `/v1/schools` | schools:create |
| GET | `/v1/schools` | schools:read |
| GET | `/v1/schools/:id` | schools:read |
| GET | `/v1/schools/code/:code` | schools:read |
| PUT | `/v1/schools/:id` | schools:update |
| DELETE | `/v1/schools/:id` | schools:delete |

### Admin API - Academic Units

| Metodo | Endpoint | Permiso |
|--------|----------|---------|
| POST | `/v1/schools/:id/units` | units:create |
| GET | `/v1/schools/:id/units` | units:read |
| GET | `/v1/schools/:id/units/tree` | units:read |
| GET | `/v1/units/:id` | units:read |
| PUT | `/v1/units/:id` | units:update |
| DELETE | `/v1/units/:id` | units:delete |

### Admin API - Memberships

| Metodo | Endpoint | Permiso |
|--------|----------|---------|
| POST | `/v1/memberships` | memberships:create |
| GET | `/v1/memberships?unit_id=X` | memberships:read |
| GET | `/v1/memberships/:id` | memberships:read |
| PUT | `/v1/memberships/:id` | memberships:update |
| DELETE | `/v1/memberships/:id` | memberships:delete |

### Admin API - Roles y Permisos

| Metodo | Endpoint | Permiso |
|--------|----------|---------|
| GET | `/v1/roles` | users:read |
| GET | `/v1/roles/:id` | users:read |
| GET | `/v1/roles/:id/permissions` | users:read |
| GET | `/v1/permissions` | permissions_mgmt:read |
| GET | `/v1/resources` | permissions_mgmt:read |

### Admin API - Subjects

| Metodo | Endpoint | Permiso |
|--------|----------|---------|
| POST | `/v1/subjects` | subjects:create |
| GET | `/v1/subjects` | subjects:read |
| GET | `/v1/subjects/:id` | subjects:read |
| PATCH | `/v1/subjects/:id` | subjects:update |
| DELETE | `/v1/subjects/:id` | subjects:delete |

### Admin API - Guardian Relations

| Metodo | Endpoint |
|--------|----------|
| POST | `/v1/guardian-relations` |
| GET | `/v1/guardian-relations/:id` |
| PUT | `/v1/guardian-relations/:id` |
| DELETE | `/v1/guardian-relations/:id` |
| GET | `/v1/guardians/:id/relations` |
| GET | `/v1/students/:id/guardians` |

### Admin API - Menu

| Metodo | Endpoint | Permiso |
|--------|----------|---------|
| GET | `/v1/menu` | JWT required |
| GET | `/v1/menu/full` | permissions_mgmt:read |

### Admin API - Screen Config

| Metodo | Endpoint | Permiso |
|--------|----------|---------|
| GET | `/v1/screen-config/resolve/key/:key` | screen_templates:read |
| POST/GET/PUT/DELETE | `/v1/screen-config/templates` | screen_templates:* |
| POST/GET/PUT/DELETE | `/v1/screen-config/instances` | screen_instances:* |

---

### Mobile API - Screens (Dynamic UI)

| Metodo | Endpoint | Respuesta |
|--------|----------|-----------|
| GET | `/v1/screens/:screenKey?platform=ios` | ScreenDefinition completa |
| GET | `/v1/screens/resource/:resourceKey` | Lista de screens para un recurso |
| GET | `/v1/screens/navigation?platform=ios` | NavigationDefinition |
| PUT | `/v1/screens/:screenKey/preferences` | User preferences actualizadas |

### Mobile API - Materials

| Metodo | Endpoint | Permiso |
|--------|----------|---------|
| GET | `/v1/materials` | materials:read |
| GET | `/v1/materials/:id` | materials:read |
| POST | `/v1/materials` | materials:create |
| PUT | `/v1/materials/:id` | materials:update |
| GET | `/v1/materials/:id/download-url` | materials:download |
| POST | `/v1/materials/:id/upload-url` | materials:create |
| POST | `/v1/materials/:id/upload-complete` | materials:create |
| GET | `/v1/materials/:id/summary` | materials:read |
| GET | `/v1/materials/:id/assessment` | assessments:read |
| GET | `/v1/materials/:id/stats` | stats:unit |

### Mobile API - Assessments

| Metodo | Endpoint | Permiso |
|--------|----------|---------|
| POST | `/v1/materials/:id/assessment/attempts` | assessments:attempt |
| GET | `/v1/attempts/:id/results` | assessments:view_results |
| GET | `/v1/users/me/attempts` | assessments:view_results |

### Mobile API - Progress

| Metodo | Endpoint | Permiso |
|--------|----------|---------|
| PUT | `/v1/progress` | progress:update |

### Mobile API - Stats

| Metodo | Endpoint | Permiso |
|--------|----------|---------|
| GET | `/v1/stats/global` | stats:global |

## 9.7 Formato de Error Estandar

Ambas APIs retornan errores con este formato:

```json
{
  "error": "VALIDATION_ERROR",
  "message": "Email is required",
  "code": 400
}
```

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| error | String | Codigo de error legible |
| message | String | Mensaje detallado |
| code | Int | HTTP status code |

## 9.8 Headers Comunes

### Request
```
Authorization: Bearer {jwt_token}   (para endpoints protegidos)
Content-Type: application/json
Accept: application/json
```

### Response
```
Content-Type: application/json
ETag: "version-hash"                (para caching de screens)
Cache-Control: max-age=3600         (para screens)
```

### Soporte de 304 Not Modified
Los endpoints de screens soportan `If-None-Match` / `ETag` para caching HTTP. Si la pantalla no cambio, retorna 304 sin body.
