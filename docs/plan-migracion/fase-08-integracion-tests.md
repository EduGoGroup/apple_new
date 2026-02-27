# Fase 8: Integración Final + Tests E2E

## Objetivo
Integrar todas las fases anteriores en un flujo cohesivo end-to-end, verificar que todo funciona junto, y crear una suite de tests comprensiva que cubra los flujos principales.

## Dependencias
- **TODAS las fases anteriores** (0-7)

---

## Pasos de Implementación

### Paso 8.1: Flujo E2E completo — Splash → Login → Main

**Paquete**: `Apps/DemoApp/`

**Archivos a modificar:**
- `DemoApp.swift`
- `Screens/SplashView.swift`
- `ServiceContainer.swift`

**Requisitos:**
- Flujo completo verificado:
  1. **App Launch → Splash**:
     - Restaurar sesión (tokens de storage)
     - Si tiene tokens → restaurar sync bundle local → pre-popular cache
     - En paralelo: delta sync en background
     - Splash mínimo 1.5s para branding
  2. **Si no autenticado → Login**:
     - Email + password
     - Llamar POST `/api/v1/auth/login`
     - Recibir tokens + user + contexts
     - Si multiple schools → SchoolSelectionScreen
     - Full sync bundle
  3. **Main Screen**:
     - Menú dinámico desde sync bundle (filtrado RBAC)
     - Navegación adaptativa (iPhone/iPad/Mac)
     - Dashboard por rol como pantalla inicial
     - Toolbar dinámico por patrón
  4. **CRUD Flow**:
     - Lista → tap item → detalle → editar → guardar → volver a lista
     - Lista → crear → formulario → guardar → volver a lista con item nuevo
     - Lista → buscar → resultados filtrados
     - Lista → scroll → paginación
  5. **Offline Flow**:
     - Activar modo avión → banner offline
     - Navegar por cache → stale indicators
     - Crear/editar item → se encola en MutationQueue
     - Desactivar modo avión → sync mutations → delta sync → refresh

---

### Paso 8.2: ServiceContainer final

**Paquete**: `Apps/DemoApp/`

**Archivos a modificar:**
- `ServiceContainer.swift`

**Requisitos:**
- DI completo con todos los servicios:
  ```swift
  @MainActor @Observable
  final class ServiceContainer {
      // Network
      let plainNetworkClient: NetworkClient        // sin interceptors
      let authenticatedNetworkClient: NetworkClient // con auth interceptor

      // Auth
      let authService: AuthService

      // Sync
      let syncService: SyncService
      let localSyncStore: LocalSyncStore

      // DynamicUI
      let screenLoader: ScreenLoader
      let dataLoader: DataLoader

      // Contracts
      let contractRegistry: ContractRegistry
      let eventOrchestrator: EventOrchestrator

      // Menu
      let menuService: MenuService

      // Offline
      let networkObserver: NetworkObserver
      let mutationQueue: MutationQueue
      let syncEngine: SyncEngine
      let connectivitySyncManager: ConnectivitySyncManager

      // i18n
      let serverStringResolver: ServerStringResolver
      let glossaryProvider: GlossaryProvider
      let localeService: LocaleService

      // Toast
      let toastManager: ToastManager
  }
  ```

- Inicialización en orden correcto respetando dependencias
- Inyección vía `@Environment` en la view hierarchy

---

### Paso 8.3: Environment injection

**Paquete**: `Apps/DemoApp/`

**Archivos a crear/modificar:**
- `Environment/AppEnvironmentKeys.swift`

**Requisitos:**
- Custom `EnvironmentKey` para cada servicio que la UI necesite:
  ```swift
  // Solo los que la UI usa directamente
  struct EventOrchestratorKey: EnvironmentKey { ... }
  struct ToastManagerKey: EnvironmentKey { ... }
  struct GlossaryProviderKey: EnvironmentKey { ... }
  struct NetworkStatusKey: EnvironmentKey { ... }
  struct MenuServiceKey: EnvironmentKey { ... }
  ```
- Inyectar desde `DemoApp.swift`:
  ```swift
  ContentView()
      .environment(serviceContainer.toastManager)
      .environment(serviceContainer.glossaryProvider)
      // ...
  ```

---

### Paso 8.4: Error Boundaries globales

**Paquete**: `Apps/DemoApp/`

**Archivos a crear:**
- `Components/ErrorBoundary.swift`

**Requisitos:**
- ViewModifier que captura errores no manejados y muestra fallback:
  ```swift
  struct ErrorBoundary<Fallback: View>: ViewModifier {
      let fallback: (Error) -> Fallback
      @State private var error: Error?

      func body(content: Content) -> some View {
          if let error {
              fallback(error)
          } else {
              content
                  .task {
                      // Capturar errores no manejados
                  }
          }
      }
  }
  ```
- Aplicar a nivel de cada pantalla dinámica
- Fallback muestra error + botón retry + botón "volver al inicio"
- Loggear el error con EduLogger

---

### Paso 8.5: Deep linking básico

**Paquete**: `Apps/DemoApp/`

**Archivos a crear/modificar:**
- `Navigation/DeepLinkHandler.swift`

**Requisitos:**
- Soportar URL scheme: `edugo://screen/{screenKey}`
- Al recibir deep link:
  1. Verificar autenticación
  2. Si autenticado → navegar a la pantalla
  3. Si no → login → luego navegar
- Ejemplo: `edugo://screen/materials:list` → navega a lista de materiales
- Soportar parámetros: `edugo://screen/materials:detail?id=xxx`
- Registrar URL scheme en Info.plist

---

### Paso 8.6: Tests unitarios por paquete (revisión)

Verificar cobertura de tests en cada paquete:

**Core (ya tiene 717+ tests):**
- [ ] Nuevos DTOs de Auth tienen tests de decodificación
- [ ] Nuevos DTOs de Sync tienen tests de decodificación
- [ ] AuthToken.shouldRefresh testeado
- [ ] UserContext.hasPermission testeado

**Infrastructure:**
- [ ] NetworkObserver testeado
- [ ] AuthenticationInterceptor refresh flow testeado

**Domain:**
- [ ] SyncService tests (full sync + delta)
- [ ] MenuService tests (filtrado RBAC)
- [ ] MutationQueue tests (enqueue, dequeue, persist, dedup, limit)
- [ ] ConflictResolver tests (cada caso)
- [ ] SyncEngine tests (process queue con backoff)
- [ ] EventOrchestrator tests (permisos, contracts, execution)
- [ ] GlossaryProvider tests
- [ ] ServerStringResolver tests

**DynamicUI:**
- [ ] ScreenLoader seedFromBundle testeado
- [ ] ScreenLoader TTL por patrón testeado
- [ ] DataLoader offline testeado
- [ ] FieldMapper testeado
- [ ] PlaceholderResolver con glossary tokens testeado

---

### Paso 8.7: Test de integración — Full Flow

**Archivos a crear:**
- `Apps/DemoApp/Tests/IntegrationTests/FullFlowTests.swift`

**Requisitos:**
- Test con MockNetworkClient que simula el backend completo:
  1. Login → recibe tokens mock → auth state cambia a authenticated
  2. Full sync → recibe bundle mock → menu se construye
  3. Cargar dashboard → screen loaded → data loaded
  4. Navegar a lista → screen loaded → data con items
  5. Buscar → datos filtrados
  6. Crear item → formulario → guardar → POST enviado
  7. Offline → enqueue mutation → online → sync mutation

---

### Paso 8.8: Performance checks

**Verificaciones:**
- [ ] Memory leaks: verificar con Instruments que no hay retain cycles en actors/streams
- [ ] ScreenLoader cache no crece indefinidamente (LRU con max 20)
- [ ] AsyncStream continuations se cancelan correctamente al navegar
- [ ] Splash → Main no tarda más de 3s
- [ ] Lista de 100+ items scrollea a 60fps
- [ ] Formulario con 20+ campos no causa lag al escribir
- [ ] Delta sync no bloquea la UI

---

### Paso 8.9: Audit final de código

**Verificaciones estrictas:**
- [ ] `nonisolated` NO aparece en ningún archivo: `grep -r "nonisolated" Packages/ Apps/`
- [ ] `@Published` NO aparece: `grep -r "@Published" Packages/ Apps/`
- [ ] `@ObservableObject` NO aparece: `grep -r "ObservableObject" Packages/ Apps/`
- [ ] `@EnvironmentObject` NO aparece: `grep -r "@EnvironmentObject" Packages/ Apps/`
- [ ] `import Combine` NO aparece: `grep -r "import Combine" Packages/ Apps/`
- [ ] `NotificationCenter` NO aparece: `grep -r "NotificationCenter" Packages/ Apps/`
- [ ] `XCTest` NO aparece en tests: `grep -r "import XCTest" Packages/ Apps/`
- [ ] Todas las `CodingKeys` usan snake_case
- [ ] `JSONValue` solo definido en EduModels (no duplicados)
- [ ] `swift-tools-version: 6.2` en todos los Package.swift
- [ ] Targets >= iOS 26, macOS 26 en todos los Package.swift
- [ ] Zero deprecation warnings al compilar
- [ ] `make build` exitoso
- [ ] `make test` todos los tests pasan

---

### Paso 8.10: Documentación de la migración

**Archivos a crear:**
- `docs/plan-migracion/COMPLETADO.md`

**Requisitos:**
- Resumen de todo lo implementado
- Lista de features migradas desde KMP
- Lista de features pendientes (del doc 09 de KMP)
- Diagramas de arquitectura actualizados
- Instrucciones para nuevos desarrolladores

---

## Features pendientes POST-MIGRACIÓN (del doc 09 KMP)

### Seguridad (futuro)
- Cifrado de tokens en Keychain
- Certificate pinning
- Cifrado de cache local

### UX (futuro)
- Deep-linking avanzado (con universal links)
- Undo/redo en formularios
- Optimistic UI (mostrar cambio antes de confirmar server)
- Breadcrumb navigation completo

### Arquitectura (futuro)
- Feature flags desde servidor
- Deduplicación de requests en vuelo
- Compresión de payloads (gzip)

### Observabilidad (futuro)
- Crashlytics/crash reporting
- Métricas de cache hit rate
- Analytics de user flows
- Performance monitoring

### Performance (futuro)
- Paginación infinita con prefetch
- Imágenes SVG/optimizadas
- SQLite/SwiftData para cache offline (en lugar de JSON storage)

---

## Criterios de Completitud FINAL

- [ ] Flujo E2E funciona: splash → login → main → CRUD → offline → sync
- [ ] ServiceContainer con todos los servicios inyectados
- [ ] Environment injection para toda la view hierarchy
- [ ] Error boundaries en cada pantalla dinámica
- [ ] Deep linking básico funciona
- [ ] Tests cubren todos los flujos principales
- [ ] Performance verificada (scroll 60fps, splash <3s)
- [ ] Audit de código limpio (zero deprecated, zero anti-patterns)
- [ ] `make build` sin errores ni warnings
- [ ] `make test` todos pasan
- [ ] Documentación completa
