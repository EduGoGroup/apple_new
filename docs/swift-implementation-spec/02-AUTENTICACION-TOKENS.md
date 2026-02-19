# 02 - Autenticacion y Tokens

## 2.1 Estructura del JWT

El backend genera JWTs con la siguiente estructura en el payload:

```
{
  "sub": "user-uuid",           // ID del usuario
  "email": "user@email.com",
  "active_context": {
    "role_id": "uuid",
    "role_name": "teacher",
    "school_id": "uuid",        // nullable
    "school_name": "School X",  // nullable
    "academic_unit_id": "uuid", // nullable
    "academic_unit_name": "5A", // nullable
    "permissions": ["materials:read", "materials:create", ...]
  },
  "iat": 1708300000,
  "exp": 1708303600,
  "nbf": 1708300000,
  "jti": "unique-token-id",
  "iss": "edugo-auth"
}
```

**IMPORTANTE**: El rol y permisos NO estan en el usuario directamente. Estan en `active_context`. Un usuario puede tener multiples roles en diferentes escuelas, y el `active_context` representa el contexto ACTIVO actual.

## 2.2 Modelos de Datos

### LoginResponse (lo que devuelve POST /v1/auth/login)
```
{
  "access_token": "eyJ...",     // JWT
  "refresh_token": "rt_...",    // Opaque token
  "expires_in": 3600,           // Segundos hasta expiracion
  "token_type": "Bearer",
  "user": {
    "id": "uuid",
    "email": "user@email.com",
    "first_name": "Juan",
    "last_name": "Perez",
    "full_name": "Juan Perez",
    "school_id": "uuid"         // nullable
  },
  "active_context": {
    "role_id": "uuid",
    "role_name": "teacher",
    "school_id": "uuid",
    "school_name": "Colegio Central",
    "academic_unit_id": null,
    "academic_unit_name": null,
    "permissions": ["materials:read", "materials:create", "assessments:read"]
  }
}
```

### AuthToken (modelo interno de la app)
- `token`: String (el JWT)
- `expiresAt`: Date (calculado: now + expires_in)
- `refreshToken`: String? (el refresh token)

### AuthUserInfo (modelo interno)
- `id`: String
- `email`: String
- `firstName`: String
- `lastName`: String
- `fullName`: String
- `schoolId`: String? (nullable)
- **NO tiene campo `role`** - el rol esta en UserContext

### UserContext (RBAC - modelo interno)
- `roleId`: String
- `roleName`: String (ej: "teacher", "student", "school_admin", "super_admin", "guardian")
- `schoolId`: String?
- `schoolName`: String?
- `academicUnitId`: String?
- `academicUnitName`: String?
- `permissions`: [String] (ej: ["materials:read", "assessments:attempt"])

## 2.3 Estado de Autenticacion

La app mantiene un estado reactivo (Published/Observable) con 3 posibles valores:

### AuthState
```
- Loading                    → App esta verificando sesion
- Authenticated              → Usuario autenticado
    - user: AuthUserInfo
    - token: AuthToken
    - activeContext: UserContext
- Unauthenticated            → No hay sesion activa
```

### Propiedades de conveniencia sobre AuthState
- `isAuthenticated` → Bool
- `currentUser` → AuthUserInfo?
- `currentToken` → AuthToken?
- `activeContext` → UserContext?
- `currentUserRole` → String? (via activeContext.roleName)
- `currentPermissions` → [String] (via activeContext.permissions)
- `isTokenExpired` → Bool
- `canRefreshToken` → Bool

## 2.4 Proceso de Login

### Paso a paso:

1. **Validar credenciales localmente**
   - Email: no vacio, contiene `@` y `.`
   - Password: minimo 8 caracteres
   - Si falla: mostrar error inmediatamente (no llamar API)

2. **Verificar Rate Limiter**
   - Si se excedio el limite de intentos por minuto: rechazar
   - Configuracion por entorno (ver seccion 2.8)

3. **Enviar request**
   - `POST {adminApiBaseUrl}/v1/auth/login`
   - Body: `{"email": "...", "password": "..."}`
   - Content-Type: application/json
   - Sin header de Authorization (es endpoint publico)

4. **Manejar respuesta**
   - **200 OK**: Parsear LoginResponse
   - **400**: Error de validacion (input malformado)
   - **401**: Credenciales invalidas
   - **403**: Usuario inactivo
   - **404**: Usuario no encontrado
   - **423**: Cuenta bloqueada
   - **500+**: Error del servidor

5. **En caso de exito**:
   - Crear AuthToken con `expiresAt = now + expires_in`
   - Guardar 3 items en Keychain:
     - `edugo_auth_token` → AuthToken serializado
     - `edugo_auth_user` → AuthUserInfo serializado
     - `edugo_auth_context` → UserContext serializado
   - Transicionar estado a `Authenticated(user, token, activeContext)`
   - Iniciar auto-refresh de token (ver seccion 2.5)

6. **En caso de error**:
   - Transicionar estado a `Unauthenticated`
   - Retornar error tipado para mostrar mensaje al usuario

### Errores tipados
```
AuthError:
  .invalidCredentials          // 401
  .userNotFound                // 404
  .accountLocked               // 423
  .userInactive                // 403
  .networkError(cause: String) // Sin conexion, timeout
  .unknownError(message: String)
```

## 2.5 Auto-Refresh de Token

### Objetivo
Renovar el access_token ANTES de que expire, sin intervencion del usuario.

### Proceso

1. **Calcular momento de refresh**
   - `refreshAt = token.expiresAt - refreshThreshold`
   - Ejemplo: si el token expira en 1 hora y el threshold es 10 minutos, refrescar a los 50 minutos

2. **Programar tarea**
   - Usar Timer/Task con delay hasta `refreshAt`
   - Al llegar el momento, ejecutar refresh

3. **Ejecutar refresh**
   - `POST {adminApiBaseUrl}/v1/auth/refresh`
   - Body: `{"refresh_token": "rt_..."}`
   - Header: Sin Authorization (usa el refresh token en el body)

4. **Respuesta exitosa**:
   ```
   {
     "access_token": "eyJ...",
     "expires_in": 3600,
     "token_type": "Bearer"
   }
   ```
   - Actualizar AuthToken con nuevo token y expiracion
   - Guardar en Keychain
   - Reprogramar siguiente refresh

5. **Respuesta fallida**:
   - **Errores recuperables** (red, timeout, 5xx): loggear, reintentar despues
   - **Errores irrecuperables** (401 token expirado, 403 token revocado): limpiar sesion completa → `Unauthenticated`

### Concurrencia
- Si multiples partes de la app solicitan refresh simultaneamente, solo ejecutar UNO
- Usar un actor/lock para serializar requests de refresh
- Las solicitudes adicionales esperan el resultado del refresh en curso

### Configuracion por entorno
| Entorno | Threshold | Max Reintentos | Delay inicial |
|---------|-----------|----------------|---------------|
| DEV | 60s | 10 | 500ms |
| STAGING | 300s (5m) | 3 | 1000ms |
| PROD | 600s (10m) | 5 | 2000ms |

## 2.6 Restauracion de Sesion

### Se ejecuta al iniciar la app

1. **Leer Keychain**
   - Obtener los 3 items: token, user, context
   - Si alguno falta: no hay sesion → `Unauthenticated`

2. **Deserializar** los 3 items

3. **Evaluar token**:
   - **No expirado**: Establecer `Authenticated` + iniciar auto-refresh
   - **Expirado CON refresh token**: Intentar `forceRefresh()`
     - Exito: `Authenticated` con nuevo token + auto-refresh
     - Fallo: Limpiar todo → `Unauthenticated`
   - **Expirado SIN refresh token**: Limpiar todo → `Unauthenticated`

4. **Manejo de errores**: Si algo falla (JSON corrupto, etc.), limpiar y ir a `Unauthenticated`

## 2.7 Proceso de Logout

### Logout basico
1. Detener auto-refresh
2. Obtener token actual
3. `POST {adminApiBaseUrl}/v1/auth/logout` con `Authorization: Bearer {token}`
   - Es "best effort" - si falla remotamente, igual limpiar localmente
   - Tratar 401 como exito (token ya era invalido)
4. Limpiar Keychain (3 items)
5. Estado → `Unauthenticated`

### Logout detallado (con resultado)
Retorna uno de:
- **Success**: Remoto + local limpiados
- **PartialSuccess(remoteError)**: Local limpiado, remoto fallo (aceptable)
- **AlreadyLoggedOut**: Ya estaba desautenticado

## 2.8 Almacenamiento Seguro

### Por que 3 items separados en Keychain
- **Atomicidad**: Permite actualizar solo el token sin tocar user/context
- **Resistencia**: Si un item se corrompe, los otros siguen legibles
- **Rendimiento**: Leer solo lo necesario (ej: solo token para interceptor)

### Keys de almacenamiento
| Key | Contenido | Actualizado cuando |
|-----|-----------|-------------------|
| `edugo_auth_token` | AuthToken (JWT + expiracion + refresh) | Login, refresh |
| `edugo_auth_user` | AuthUserInfo (id, email, nombres) | Login |
| `edugo_auth_context` | UserContext (rol, permisos, escuela) | Login, switch-context |

### Recomendacion Apple
- Usar **Keychain** para tokens (encriptado por el OS)
- Access group compartido si hay extensiones (widgets, share extension)
- `kSecAttrAccessibleAfterFirstUnlock` para background refresh

## 2.9 Interceptor de Autenticacion

### Proceso por cada request HTTP

1. Verificar si el request ya tiene header `Authorization` → si lo tiene, skip
2. Obtener token actual del AuthService/TokenProvider
3. Si auto-refresh esta habilitado Y el token esta expirado:
   - Llamar `refreshToken()`
   - Usar el token nuevo
4. Agregar header: `Authorization: Bearer {token}`
5. Continuar con el request

### Orden de ejecucion
El interceptor de auth debe ejecutarse ANTES que otros interceptores (logging, etc.) para que los requests autenticados se logueen correctamente.

## 2.10 Eventos Reactivos

La app emite eventos que otros modulos pueden observar:

| Evento | Cuando | Accion esperada |
|--------|--------|-----------------|
| `onSessionExpired` | Token irrecuperable en auto-refresh | Mostrar pantalla de login |
| `onLogout` | Logout completado | Navegar a login |
| `onRefreshSuccess` | Token renovado exitosamente | Actualizar estado internamente |
| `onRefreshFailed` | Refresh fallo | Loggear; si irrecuperable, limpiar sesion |

### Recomendacion Apple
Usar `NotificationCenter`, `Combine Publisher`, o `AsyncSequence` para estos eventos.
