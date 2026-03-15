# Offline y Sincronizacion — EduGo Apple

> Documentacion generada desde analisis directo del codigo fuente (marzo 2026).

---

## 1. Vision General

La app soporta operacion offline con sincronizacion automatica. Los datos del usuario se centralizan en un **sync bundle** que se descarga al login y se actualiza incrementalmente.

---

## 2. Sync Bundle

El sync bundle contiene toda la informacion del usuario autenticado:

| Dato | Descripcion |
|------|-------------|
| `menu` | Items del menu lateral con permisos |
| `screens` | Definiciones de pantallas SDUI (pre-cache) |
| `permissions` | Permisos del usuario segun rol activo |
| `availableContexts` | Escuelas/roles disponibles para switch |

### Flujo de Sincronizacion

```
Login exitoso
    │
    ▼
fullSync() ─────────────────────────────────────────────┐
    │                                                    │
    ├─ GET /api/v1/sync/bundle                          │
    │   └─ Retorna: menu + screens + permissions +      │
    │      contexts + hashes                             │
    │                                                    │
    ├─ screenLoader.seedFromBundle(screens)              │
    │   └─ Pre-carga definiciones en cache L1            │
    │                                                    │
    ├─ serverStringResolver.updateFromBundle(bundle)     │
    │                                                    │
    └─ glossaryProvider.updateFromBundle(bundle)         │
                                                         │
Splash (restaurar sesion) ──────────────────────────────┤
    │                                                    │
    ├─ restoreSession() ──→ token valido?               │
    │                                                    │
    └─ deltaSync() ─────────────────────────────────────┘
        │
        ├─ POST /api/v1/sync/delta
        │   Body: { hashes del bundle local }
        │   └─ Retorna: solo lo que cambio
        │
        └─ Actualiza cache incremental
```

### Servicios Involucrados

```swift
// SyncService — coordinator
let syncService = SyncService(
    networkClient: authenticatedClient,
    localStore: localSyncStore,
    apiConfig: config
)

// LocalSyncStore — persistencia local del bundle
let localSyncStore = LocalSyncStore()
```

---

## 3. Offline: MutationQueue + SyncEngine

### Arquitectura Offline

```
Usuario hace accion (crear/editar/eliminar)
    │
    ├─ Online → enviar directamente al backend
    │
    └─ Offline → encolar en MutationQueue
                    │
                    ▼
              ┌──────────────┐
              │ MutationQueue │  (cola persistente)
              └──────┬───────┘
                     │
                     ▼ (cuando red disponible)
              ┌──────────────┐
              │  SyncEngine   │  (procesa cola)
              └──────┬───────┘
                     │
                     ▼
              ┌──────────────────────┐
              │ ConnectivitySyncManager│  (orquesta)
              └──────────────────────┘
```

### MutationQueue

Cola de mutaciones pendientes:

```swift
public actor MutationQueue {
    // Encolar mutacion offline
    public func enqueue(_ mutation: Mutation)

    // Obtener pendientes
    public func pending() -> [Mutation]

    // Marcar como procesada
    public func dequeue(id: UUID)
}
```

### SyncEngine

Procesa la cola cuando hay conectividad:

```swift
public actor SyncEngine {
    public func processQueue() async
    // Itera mutaciones pendientes
    // Envia cada una al backend
    // Marca como completadas
}
```

### ConnectivitySyncManager

Orquesta la sincronizacion basada en conectividad:

```swift
public actor ConnectivitySyncManager {
    public func startObserving() async
    public var isOnlineStream: AsyncStream<Bool> { get }
}
```

Flujo:
1. Observa `NetworkObserver` (NWPathMonitor)
2. Al detectar reconexion → `syncEngine.processQueue()`
3. Emite estado online/offline via `isOnlineStream`

---

## 4. Optimistic UI

### OptimisticUpdateManager

Actualiza la UI inmediatamente antes de confirmar con el backend:

```swift
public final class OptimisticUpdateManager {
    // Aplicar update optimista (UI inmediata)
    // Si backend falla → revertir
    // Si backend exito → confirmar
}
```

Integrado con `EventOrchestrator` para actualizaciones SDUI.

---

## 5. Cache de Datos

### ScreenLoader Cache (L1)

| Propiedad | Valor |
|-----------|-------|
| Tipo | LRU (Least Recently Used) |
| Capacidad | 20 entries |
| ETag | Si (304 revalidation) |
| Seed | Desde sync bundle |
| TTL | Variable por patron |

### DataLoader Cache

| Propiedad | Valor |
|-----------|-------|
| Tipo | LRU |
| Capacidad | 50 entries |
| Offline | Retorna cache stale |
| Paginacion | Soportada |

### Flujo de Cache Offline

```
DataLoader.loadData(endpoint)
    │
    ├─ Online
    │   ├─ Fetch del backend
    │   ├─ Guardar en cache
    │   └─ Retornar datos frescos
    │
    └─ Offline
        ├─ Buscar en cache
        ├─ Cache encontrado (aunque expirado)
        │   └─ Retornar datos stale
        └─ Cache no encontrado
            └─ Throw error
```

---

## 6. Menu y Navegacion

### MenuService

```swift
public final class MenuService {
    // Procesa menu items del sync bundle
    // Filtra segun permisos del usuario
    // Alimenta sidebar de la app
}
```

El menu se actualiza en cada `fullSync()` o `deltaSync()`.

---

## 7. i18n (Internacionalizacion)

Servicios de localizacion alimentados por el sync bundle:

| Servicio | Proposito |
|----------|-----------|
| `ServerStringResolver` | Resuelve strings del backend |
| `GlossaryProvider` | Terminos especificos del dominio educativo |
| `LocaleService` | Configuracion regional del usuario |

Todos se actualizan via `updateFromBundle(bundle)` despues de cada sync.

---

## 8. Flujo Completo de la App

```
1. App inicia
   │
2. SplashView
   │  ├─ restoreSession() → token en Keychain?
   │  │   ├─ Si → restoreFromLocal() + deltaSync()
   │  │   └─ No → navigate(.login)
   │  │
   │  └─ Resultado
   │      ├─ Authenticated → navigate(.main)
   │      └─ Not authenticated → navigate(.login)
   │
3. LoginScreen
   │  ├─ Login exitoso
   │  ├─ fullSync() → descargar bundle completo
   │  ├─ seedScreens + updateResolvers
   │  └─ navigate(.main)
   │
4. MainScreen
   │  ├─ Sidebar (menu del bundle)
   │  ├─ Content (SDUI renderizado)
   │  ├─ sessionStream → escuchar loggedOut/expired
   │  └─ connectivitySyncManager → sync automatico
   │
5. Deep Links
   │  ├─ Authenticated → navegar inmediatamente
   │  └─ Not authenticated → almacenar pendiente
   │
6. Context Switch
   │  ├─ Cambiar escuela/rol
   │  └─ fullSync() → refrescar todo el bundle
```

---

## 9. Servicios en ServiceContainer

Orden de inicializacion (respeta dependencias):

| # | Servicio | Tipo | Dependencias |
|---|----------|------|-------------|
| 1 | `apiConfiguration` | Config | AppEnvironment |
| 2 | `plainNetworkClient` | Actor | Ninguna |
| 3 | `networkObserver` | Actor | Ninguna |
| 4 | `authService` | Service | plainNetworkClient, config |
| 5 | `authenticatedNetworkClient` | Actor | AuthInterceptor(authService) |
| 6 | `localSyncStore` | Store | Ninguna |
| 7 | `menuService` | Service | Ninguna |
| 8 | `syncService` | Service | authenticatedClient, localStore, config |
| 9 | `screenLoader` | Actor | authenticatedClient, config |
| 10 | `dataLoader` | Actor | authenticatedClient, config |
| 11 | `contractRegistry` + `eventOrchestrator` | Registry | authenticatedClient, dataLoader |
| 12 | `mutationQueue` + `syncEngine` + `connectivitySyncManager` | Offline | authenticatedClient, syncService |
| 13 | `breadcrumbTracker` | Nav | Ninguna |
| 14 | `serverStringResolver` + `glossaryProvider` + `localeService` | i18n | Ninguna |
| 15 | `toastManager` | Feedback | Ninguna (singleton) |

---

*Generado: marzo 2026 | Basado en analisis directo del codigo fuente*
