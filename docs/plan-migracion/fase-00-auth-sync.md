# Fase 0: Cimientos — Auth Completo + Sync Bundle

## Objetivo
Completar el flujo de autenticación (token refresh con rotación JWT, switch context, restauración de sesión robusta) e implementar el mecanismo de Sync Bundle (full sync + delta sync) que es la base de todo el sistema offline-first y SDUI.

## Pre-requisitos
- Proyecto apple_new compila (`make build`)
- Tests actuales pasan (`make test`)
- APIs de backend accesibles (Azure o local)

## Contexto Backend

### Endpoints involucrados (IAM Platform)
```
POST /api/v1/auth/login           → LoginResponse (tokens + user + contexts)
POST /api/v1/auth/refresh         → RefreshResponse (nuevos tokens rotados)
POST /api/v1/auth/logout          → 204
POST /api/v1/auth/switch-context  → LoginResponse (nuevos tokens con nuevo contexto)
GET  /api/v1/auth/contexts        → AvailableContextsResponse
GET  /api/v1/sync/bundle          → SyncBundleResponse (menu + permissions + screens + contexts + hashes)
POST /api/v1/sync/delta           → DeltaSyncResponse (solo buckets cambiados)
```

### DTOs del Backend (referencia)
```go
LoginResponse {
  access_token, refresh_token, expires_in, token_type,
  user: { id, email, first_name, last_name, full_name, school_id },
  schools: []SchoolInfo,
  active_context: { role_id, role_name, school_id, school_name, permissions: [] }
}

SyncBundleResponse {
  menu: []MenuItemDTO,
  permissions: []string,
  screens: map[string]ScreenBundle,
  available_contexts: []UserContextDTO,
  hashes: map[string]string
}

DeltaSyncRequest { hashes: map[string]string }
DeltaSyncResponse {
  changed: map[string]{ data: json, hash: string },
  unchanged: []string
}
```

---

## Pasos de Implementación

### Paso 0.1: DTOs de Auth actualizados

**Paquete**: `Packages/Core/Sources/Models/`

Crear/actualizar los DTOs para alinearse con el backend real:

**Archivos a crear/modificar:**
- `DTOs/Auth/LoginRequestDTO.swift`
- `DTOs/Auth/LoginResponseDTO.swift`
- `DTOs/Auth/RefreshTokenRequestDTO.swift`
- `DTOs/Auth/RefreshTokenResponseDTO.swift`
- `DTOs/Auth/SwitchContextRequestDTO.swift`
- `DTOs/Auth/UserContextDTO.swift`
- `DTOs/Auth/AuthUserInfoDTO.swift`

**Requisitos:**
- Todos con `CodingKeys` explícitas y `snake_case` mapping
- Conforman a `Codable & Sendable`
- `LoginResponseDTO` incluye: `accessToken`, `refreshToken`, `expiresIn`, `tokenType`, `user: AuthUserInfoDTO`, `schools: [SchoolInfoDTO]`, `activeContext: UserContextDTO`
- `UserContextDTO` incluye: `roleId`, `roleName`, `schoolId?`, `schoolName?`, `academicUnitId?`, `permissions: [String]`

**Verificar:** `cd Packages/Core && swift test`

---

### Paso 0.2: DTOs de Sync Bundle

**Paquete**: `Packages/Core/Sources/Models/`

**Archivos a crear:**
- `DTOs/Sync/SyncBundleResponseDTO.swift`
- `DTOs/Sync/DeltaSyncRequestDTO.swift`
- `DTOs/Sync/DeltaSyncResponseDTO.swift`
- `DTOs/Sync/ScreenBundleDTO.swift`
- `DTOs/Sync/MenuItemDTO.swift`
- `DTOs/Sync/BucketDataDTO.swift`

**Requisitos:**
- `SyncBundleResponseDTO`: `menu: [MenuItemDTO]`, `permissions: [String]`, `screens: [String: ScreenBundleDTO]`, `availableContexts: [UserContextDTO]`, `hashes: [String: String]`
- `MenuItemDTO`: `key`, `displayName`, `icon?`, `scope`, `sortOrder`, `permissions: [String]`, `screens: [String: String]`, `children: [MenuItemDTO]?`
- `ScreenBundleDTO`: `screenKey`, `screenName`, `pattern`, `version`, `template: JSONValue`, `slotData: JSONValue?`, `handlerKey?`
- `DeltaSyncRequestDTO`: `hashes: [String: String]`
- `DeltaSyncResponseDTO`: `changed: [String: BucketDataDTO]`, `unchanged: [String]`
- `BucketDataDTO`: `data: JSONValue`, `hash: String`

**Verificar:** `cd Packages/Core && swift test`

---

### Paso 0.3: Modelo de dominio AuthToken + UserDataBundle

**Paquete**: `Packages/Core/Sources/Models/`

**Archivos a crear:**
- `Domain/AuthToken.swift`
- `Domain/UserContext.swift` (modelo de dominio, no DTO)
- `Domain/UserDataBundle.swift`

**Requisitos:**
- `AuthToken`: `accessToken`, `refreshToken`, `expiresAt: Date`, `tokenType`. Computed: `isExpired`, `shouldRefresh(thresholdMinutes: Int = 5)`
- `UserContext`: `roleId`, `roleName`, `schoolId?`, `schoolName?`, `academicUnitId?`, `permissions: [String]`. Methods: `hasPermission(_:)`, `hasAnyPermission(_:)`, `hasAllPermissions(_:)`
- `UserDataBundle`: `menu: [MenuItemDTO]`, `permissions: [String]`, `screens: [String: ScreenBundleDTO]`, `availableContexts: [UserContextDTO]`, `hashes: [String: String]`, `syncedAt: Date`

**Verificar:** `cd Packages/Core && swift test`

---

### Paso 0.4: AuthService completo (actor)

**Paquete**: `Apps/DemoApp/` (o mover a `Packages/Domain/`)

Refactorizar el `AuthService` existente para soportar el flujo completo:

**Archivos a modificar/crear:**
- `Services/AuthService.swift` — refactorizar completamente

**Requisitos:**
- `actor AuthService` conforme a `TokenProvider`
- Estado: `authState: AuthState` (enum: `.unauthenticated`, `.authenticated(AuthToken, AuthUserInfo, UserContext)`, `.loading`)
- Login: `POST /api/v1/auth/login` → decodificar `LoginResponseDTO` → crear `AuthToken` + `UserContext` → persistir
- Refresh: `POST /api/v1/auth/refresh` → decodificar → rotar tokens → persistir. Trigger automático 5 min antes de expiración
- Switch Context: `POST /api/v1/auth/switch-context` → nuevos tokens con nuevo contexto → actualizar estado
- Logout: `POST /api/v1/auth/logout` (best-effort) → limpiar tokens → limpiar storage
- Session Restore: al arrancar, verificar token persistido, si `shouldRefresh` → hacer refresh, si expired → forzar login
- Persistencia: tokens en storage (preparar para Keychain futuro pero usando storage actual)
- `var currentToken: AuthToken?` — para el interceptor
- `var currentContext: UserContext?` — para RBAC en UI
- AsyncStream<AuthState> para que la UI observe cambios

**Verificar:** `make build`

---

### Paso 0.5: Token Refresh automático con interceptor

**Paquete**: `Packages/Infrastructure/Sources/Network/`

Actualizar el `AuthenticationInterceptor` para soportar refresh real:

**Archivos a modificar:**
- `Interceptors/AuthenticationInterceptor.swift`

**Requisitos:**
- El `TokenProvider` protocol ya tiene `refreshToken()` — implementar en `AuthService`
- Cuando `shouldRefresh` sea true antes de una request → hacer refresh transparente
- Cuando reciba 401 → intentar refresh una vez → reintentar la request original
- Mutex/lock para evitar múltiples refresh concurrentes (usar actor isolation)
- Si refresh falla → emitir evento de sesión expirada

**Verificar:** `cd Packages/Infrastructure && swift test`

---

### Paso 0.6: SyncService (actor)

**Paquete**: `Packages/Domain/Sources/`

**Archivos a crear:**
- `Services/Sync/SyncService.swift`
- `Services/Sync/SyncState.swift`
- `Services/Sync/LocalSyncStore.swift`

**Requisitos:**
- `actor SyncService`:
  - `fullSync() async throws -> UserDataBundle` — GET `/api/v1/sync/bundle`
  - `deltaSync(currentHashes: [String: String]) async throws -> DeltaSyncResponse` — POST `/api/v1/sync/delta`
  - `var currentBundle: UserDataBundle?` — bundle activo
  - `var syncState: SyncState` — enum: `.idle`, `.syncing`, `.completed`, `.error(Error)`
  - AsyncStream<SyncState> para observar estado

- `LocalSyncStore` (actor):
  - Persiste el bundle completo en storage
  - `save(bundle:)` — serializa y guarda
  - `restore() -> UserDataBundle?` — carga desde storage
  - `updateBucket(name: String, data: JSONValue, hash: String)` — actualización parcial (delta)
  - Paraleliza deserialización de screens (TaskGroup)

- Flujo de arranque:
  1. `restoreFromLocal()` → cargar bundle persistido
  2. Si existe → pre-popular `ScreenLoader` cache, `Menu`, `Permissions`
  3. En background → `deltaSync` con hashes del bundle local
  4. Si cambiaron buckets → actualizar bundle + re-notificar UI

**Verificar:** `cd Packages/Domain && swift test`

---

### Paso 0.7: Integrar SyncService en ScreenLoader

**Paquete**: `Packages/DynamicUI/`

**Archivos a modificar:**
- `Loader/ScreenLoader.swift`

**Requisitos:**
- Nuevo método: `seedFromBundle(screens: [String: ScreenBundleDTO])` → pre-popular cache con screens del sync bundle
- El `loadScreen(key:)` existente debe:
  1. Primero buscar en cache (ya lo hace)
  2. Si no hay cache → intentar cargar del sync bundle local
  3. Si no → fetch desde API (ya lo hace)
- Añadir TTL por patrón (como KMP):
  - Dashboard: 60s
  - List: 5 min
  - Form: 60 min
  - Detail: 10 min
  - Settings: 30 min
  - Login: sin cache
- Añadir version check asíncrono: GET `/api/v1/screen-config/version/{key}` → comparar versión → invalidar si es más nueva

**Verificar:** `cd Packages/DynamicUI && swift test`

---

### Paso 0.8: ServiceContainer actualizado

**Paquete**: `Apps/DemoApp/`

**Archivos a modificar:**
- `ServiceContainer.swift`
- `DemoApp.swift`
- `Screens/SplashView.swift`

**Requisitos:**
- ServiceContainer expone: `authService`, `syncService`, `screenLoader`, `dataLoader`, `networkClient`
- SplashView nuevo flujo:
  1. `authService.restoreSession()` — restaurar sesión
  2. Si autenticado → `syncService.restoreFromLocal()` → pre-popular cache
  3. En paralelo con splash delay (1.5s): `syncService.deltaSync()`
  4. Navegar a Main con todo pre-cargado
  5. Si no autenticado → Login

**Verificar:** `make build && make test`

---

### Paso 0.9: Tests de Fase 0

**Archivos a crear:**
- `Packages/Core/Tests/Models/Auth/LoginResponseDTOTests.swift`
- `Packages/Core/Tests/Models/Auth/UserContextTests.swift`
- `Packages/Core/Tests/Models/Sync/SyncBundleDTOTests.swift`
- `Packages/Domain/Tests/Services/SyncServiceTests.swift`
- `Packages/DynamicUI/Tests/Loader/ScreenLoaderSeedTests.swift`

**Requisitos mínimos:**
- DTOs decodifican correctamente JSON de ejemplo del backend
- `AuthToken.shouldRefresh` funciona con threshold de 5 min
- `UserContext.hasPermission` funciona
- `SyncService.fullSync` y `deltaSync` con mock
- `ScreenLoader.seedFromBundle` pre-popula cache correctamente
- TTL por patrón respetado

---

## Criterios de Completitud

- [ ] Login responde con tokens + user + context
- [ ] Refresh rota tokens automáticamente 5 min antes de expiración
- [ ] Switch context cambia el contexto activo (rol + school)
- [ ] Sync bundle descarga menu + permissions + screens + contexts
- [ ] Delta sync solo descarga buckets cambiados
- [ ] Bundle se persiste localmente
- [ ] ScreenLoader pre-populado desde bundle
- [ ] Flujo splash → restore → delta sync → main funciona
- [ ] `make build` sin errores
- [ ] `make test` sin fallos
- [ ] Zero warnings de deprecación
