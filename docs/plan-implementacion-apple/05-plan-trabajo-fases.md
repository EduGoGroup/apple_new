# Plan de Trabajo por Fases

## Fase 0: Preparacion (Pre-requisitos)
**Duracion estimada: Sprint 0**
**Dependencias: Ninguna**

### 0.1 Modernizacion Base
- [ ] Actualizar deployment target a iOS 26 / macOS 26 en todos los Package.swift
- [ ] Verificar que el proyecto compila sin errores con el nuevo target
- [ ] Auditar @Published -> @Observable en ViewModels existentes
- [ ] Auditar @EnvironmentObject -> @Environment
- [ ] Verificar Sendable conformance en todos los modelos

### 0.2 Design System - Liquid Glass Nativo
- [ ] Re-implementar EduLiquidGlass usando .glassEffect() de iOS 26
- [ ] Actualizar EduVisualEffects para iOS 26
- [ ] Verificar que todos los componentes Edu* rendericen correctamente con glass nativo
- [ ] Actualizar design tokens (colors, typography, spacing, elevation, shapes)

### 0.3 Resiliencia de Red
- [ ] Implementar CircuitBreaker (3 estados: CLOSED -> OPEN -> HALF_OPEN, 5 fallos -> open, 30s reset)
- [ ] Implementar RateLimiter (sliding window, configurable por entorno)
- [ ] Componer: RateLimiter -> CircuitBreaker -> RetryPolicy -> HTTP Request (para login)
- [ ] Componer: CircuitBreaker -> RetryPolicy -> HTTP Request (para refresh)
- [ ] Tests unitarios de resiliencia

### 0.4 Coordinacion con Infraestructura
- [ ] Solicitar al equipo de infraestructura los cambios en edugo-shared (constantes platform ios/android)
- [ ] Solicitar actualizacion de resolucion de platformOverrides en APIs (fallback ios -> mobile -> default)
- [ ] Verificar que los endpoints respondan correctamente con `platform=ios`

**Entregable**: Proyecto compilando en iOS 26, design system con glass nativo, resiliencia de red, APIs listas para iOS.

---

## Fase 1: Dynamic UI - Modelos y Loaders
**Duracion estimada: Sprint 1**
**Dependencias: Fase 0**

### 1.1 Modelos de Dynamic UI
- [ ] Crear `DynamicUI/Models/ScreenDefinition.swift`
- [ ] Crear `DynamicUI/Models/ScreenPattern.swift` (enum con 12 patterns)
- [ ] Crear `DynamicUI/Models/Zone.swift` + ZoneType + Distribution
- [ ] Crear `DynamicUI/Models/Slot.swift` + ControlType (22+ tipos)
- [ ] Crear `DynamicUI/Models/ActionDefinition.swift` + ActionTrigger + ActionType
- [ ] Crear `DynamicUI/Models/DataConfig.swift` + PaginationConfig
- [ ] Crear `DynamicUI/Models/NavigationDefinition.swift` + NavItem
- [ ] Verificar/reusar JSONValue existente en EduModels
- [ ] Tests de parsing JSON para cada modelo (usar fixtures del backend)

### 1.2 ScreenLoader
- [ ] Crear `DynamicUI/Loader/ScreenLoader.swift` (actor)
- [ ] Implementar cache en memoria (LRU, max 20 entries)
- [ ] Implementar cache en disco (FileManager, expiracion 1 hora)
- [ ] Implementar soporte ETag / If-None-Match / 304 Not Modified
- [ ] Integrar con NetworkClient existente (usar AuthInterceptor)
- [ ] Tests unitarios con mocks

### 1.3 DataLoader
- [ ] Crear `DynamicUI/Loader/DataLoader.swift` (actor)
- [ ] Implementar dual API routing (admin: -> 8081, default -> mobile)
- [ ] Implementar soporte de paginacion offset-based
- [ ] Implementar inyeccion de defaultParams desde DataConfig
- [ ] Tests unitarios con mocks

### 1.4 Resolvers
- [ ] Crear `DynamicUI/Resolvers/SlotBindingResolver.swift`
  - Prioridad: field data > slot:key > valor estatico
- [ ] Crear `DynamicUI/Resolvers/PlaceholderResolver.swift`
  - Soportar: {user.*}, {context.*}, {today_date}, {current_year}, {item.*}
- [ ] Tests unitarios

**Entregable**: Modelos parseando correctamente JSON del backend, loaders cargando screens y datos, resolvers funcionando.

---

## Fase 2: Dynamic UI - Renderers
**Duracion estimada: Sprint 2**
**Dependencias: Fase 1**

### 2.1 SlotRenderer
- [ ] Crear `DynamicUI/Renderers/SlotRenderer.swift`
- [ ] Mapear cada ControlType a componente SwiftUI existente (EduButton, EduTextField, etc.)
- [ ] Implementar slots de input: text-input, email-input, password-input, number-input, search-bar
- [ ] Implementar slots de seleccion: checkbox, switch, radio-group, select
- [ ] Implementar slots de boton: filled-button, outlined-button, text-button, icon-button
- [ ] Implementar slots de display: label, icon, avatar, image, divider, chip, rating
- [ ] Implementar slots compuestos: list-item, list-item-navigation, metric-card
- [ ] Conectar bindings/placeholders resueltos con valores de los slots

### 2.2 ZoneRenderer
- [ ] Crear `DynamicUI/Renderers/ZoneRenderer.swift`
- [ ] Implementar distribucion stacked -> VStack
- [ ] Implementar distribucion side-by-side -> HStack
- [ ] Implementar distribucion grid -> LazyVGrid (2 columnas)
- [ ] Implementar distribucion flow-row -> Layout protocol custom
- [ ] Implementar renderizado recursivo (zone dentro de zone)
- [ ] Implementar evaluacion de condiciones (data.isEmpty, data.isNotEmpty, field != null)

### 2.3 PatternRouter
- [ ] Crear `DynamicUI/Renderers/PatternRouter.swift`
- [ ] Implementar routing: ScreenPattern -> Renderer correspondiente

### 2.4 Pattern Renderers (los 6 principales)
- [ ] `LoginPatternRenderer` - Form con email, password, boton. Usa FormState.
- [ ] `DashboardPatternRenderer` - Grid de metricas, listas rapidas. Adapta por size class.
- [ ] `ListPatternRenderer` - Lista con .searchable(), paginacion infinita, pull-to-refresh.
- [ ] `DetailPatternRenderer` - Secciones de detalle con acciones.
- [ ] `FormPatternRenderer` - Formulario con Form{}, validacion, toolbar submit.
- [ ] `SettingsPatternRenderer` - Lista de opciones con toggles, navegacion.

**Entregable**: Todas las pantallas server-driven renderizandose con componentes nativos SwiftUI + Liquid Glass.

---

## Fase 3: Dynamic UI - Sistema de Acciones
**Duracion estimada: Sprint 3**
**Dependencias: Fase 2**

### 3.1 ActionRegistry (acciones genericas)
- [ ] Crear `DynamicUI/Actions/ActionRegistry.swift`
- [ ] Implementar NAVIGATE -> push screenKey en NavigationStack
- [ ] Implementar NAVIGATE_BACK -> pop
- [ ] Implementar REFRESH -> recargar screen + datos
- [ ] Implementar LOGOUT -> limpiar sesion, navegar a login
- [ ] Implementar CONFIRM -> mostrar alert de confirmacion antes de ejecutar

### 3.2 ScreenHandlerRegistry
- [ ] Crear `DynamicUI/Actions/ScreenHandlerRegistry.swift`
- [ ] Registrar handlers por handlerKey

### 3.3 Screen Handlers
- [ ] `LoginActionHandler` - POST /v1/auth/login, guardar token en Keychain, navegar a dashboard
- [ ] `SettingsActionHandler` - Logout, toggle tema
- [ ] `DashboardActionHandler` - Navegacion por rol
- [ ] `MaterialCreateHandler` - POST /v1/materials + upload S3
- [ ] `MaterialEditHandler` - PUT /v1/materials/{id}
- [ ] `UserCrudHandler` - POST/PUT admin:/v1/users
- [ ] `SchoolCrudHandler` - POST/PUT admin:/v1/schools
- [ ] `UnitCrudHandler` - POST/PUT admin:/v1/schools/{id}/units
- [ ] `MembershipHandler` - POST admin:/v1/memberships
- [ ] `AssessmentTakeHandler` - Validacion y envio de respuestas
- [ ] `ProgressHandler` - Navegacion entre vistas de progreso
- [ ] `GuardianHandler` - Navegacion de guardian/hijos

### 3.4 API_CALL y SUBMIT_FORM
- [ ] Implementar accion API_CALL generica (method, endpoint, body desde config)
- [ ] Implementar SUBMIT_FORM (recoger fieldValues del FormState, validar, enviar)

**Entregable**: Todas las acciones del usuario funcionando end-to-end (navegacion, CRUD, login, logout, forms).

---

## Fase 4: Navegacion Dinamica y Dashboard
**Duracion estimada: Sprint 4**
**Dependencias: Fase 3**

### 4.1 Navegacion Server-Driven
- [ ] Implementar carga de navegacion: GET /v1/screens/navigation?platform=ios
- [ ] iPhone: TabView con items del bottomNav (max 5)
- [ ] iPad: NavigationSplitView con sidebar (drawer items)
- [ ] Mac: NavigationSplitView con sidebar permanente
- [ ] Fallback hardcodeado: Dashboard, Materials, Settings
- [ ] Adaptar AppCoordinator existente para usar navegacion dinamica

### 4.2 Dashboard por Rol
- [ ] Mapeo de rol -> screenKey del dashboard:
  - super_admin/platform_admin -> dashboard-superadmin
  - school_admin/school_director -> dashboard-schooladmin
  - teacher -> dashboard-teacher
  - student -> dashboard-student
  - guardian -> dashboard-guardian
- [ ] Cargar dashboard dinamico segun el rol del active_context
- [ ] Renderizar con DashboardPatternRenderer

### 4.3 Deep Linking
- [ ] Implementar deep link handler: `edugo://screen/{screenKey}?param=value`
- [ ] Conectar con DeeplinkParser existente
- [ ] Registrar URL scheme en Info.plist

### 4.4 Flujo Completo de la App
- [ ] App Launch -> Restaurar sesion (Keychain)
- [ ] Si no hay sesion -> Login screen (dinamico)
- [ ] Login exitoso -> Cargar navegacion -> Dashboard por rol
- [ ] Seleccionar tab/item -> DynamicScreenView(screenKey)
- [ ] Token auto-refresh en background
- [ ] Session expired -> Navegar a Login

**Entregable**: App completamente funcional con flujo end-to-end, navegacion dinamica, dashboards por rol.

---

## Fase 5: Integracion y Pulido
**Duracion estimada: Sprint 5**
**Dependencias: Fase 4**

### 5.1 Integracion End-to-End
- [ ] Test completo de flujo: Login -> Dashboard -> Navegacion -> CRUD -> Logout
- [ ] Verificar cada handler con el backend real
- [ ] Verificar paginacion infinita en listas
- [ ] Verificar pull-to-refresh
- [ ] Verificar switch-context (cambio de escuela/rol)

### 5.2 Persistencia y Offline
- [ ] Cache de screens para funcionamiento offline basico
- [ ] Indicadores de conectividad (NWPathMonitor)
- [ ] Retry automatico cuando se recupera conexion

### 5.3 Performance
- [ ] Profiling con Instruments
- [ ] Verificar 60fps con Liquid Glass effects
- [ ] Optimizar carga lazy de imagenes (AsyncImage)
- [ ] Verificar memory leaks en navegacion dinamica

### 5.4 Accesibilidad
- [ ] Verificar VoiceOver en todas las pantallas dinamicas
- [ ] Verificar Dynamic Type
- [ ] Verificar contraste con Liquid Glass
- [ ] Keyboard navigation (iPad/Mac)

### 5.5 Tests
- [ ] Tests unitarios de cada componente de Dynamic UI
- [ ] Tests de integracion con mocks de API
- [ ] Tests de UI (si aplica)
- [ ] Snapshot tests de renderers

### 5.6 Actualizar DemoApp
- [ ] DemoApp funcional con Dynamic UI contra backend local
- [ ] Demostrar todos los patterns (login, dashboard, list, detail, form, settings)

**Entregable**: App lista para QA con todos los flujos funcionando, accesible, performante.

---

## Fase 6: Features Avanzados (Futuro)
**Dependencias: Fase 5**

- [ ] Features module: AI assistant, Analytics
- [ ] Patterns adicionales: search, profile, modal, notification, onboarding, empty-state
- [ ] Envio de eventos a RabbitMQ (material.uploaded, assessment.attempt)
- [ ] Soporte de materiales (upload PDF a S3 con presigned URL)
- [ ] Notificaciones push
- [ ] Widget de iOS

---

## Resumen de Fases

| Fase | Nombre | Foco | Dependencias |
|------|--------|------|-------------|
| 0 | Preparacion | iOS 26, Liquid Glass nativo, resiliencia de red | Ninguna |
| 1 | Modelos y Loaders | Modelos Dynamic UI, ScreenLoader, DataLoader, Resolvers | Fase 0 |
| 2 | Renderers | SlotRenderer, ZoneRenderer, PatternRenderers (6) | Fase 1 |
| 3 | Acciones | ActionRegistry, ScreenHandlers (12+), CRUD | Fase 2 |
| 4 | Navegacion y Dashboard | Nav dinamica, dashboards por rol, deep linking, flujo completo | Fase 3 |
| 5 | Integracion | Tests, performance, accesibilidad, DemoApp | Fase 4 |
| 6 | Features Avanzados | AI, analytics, patterns extras, notificaciones | Fase 5 |
