# Migración KMP → apple_new — COMPLETADA

**Fecha de finalización:** 2026-02-27
**PRs de migración:** #1 (setup), #2 (fases 1,2,6), #4 (fases 3,4,7), #6 (fases 5,8)

---

## Resumen

Migración completa de todas las funcionalidades del proyecto KMP (`kmp_new`) al proyecto Swift nativo (`apple_new`). 9 fases ejecutadas (0-8), cada una compilando y pasando tests antes de avanzar.

### Cifras Finales

| Métrica | Valor |
|---------|-------|
| Archivos Swift (Packages + Apps) | 580 |
| Archivos fuente (Packages) | 431 |
| Archivos de test (Packages) | 117 |
| Archivos app (DemoApp) | 32 |
| Tests totales | 1,473 |
| Suites de test | 143 |
| Paquetes SPM principales | 7 (6-tier + DynamicUI) |
| Módulos SDK standalone | 7 |
| Warnings de deprecación | 0 |
| Uso de código prohibido | 0 |

---

## Fases Implementadas

### Fase 0 — Auth completo + Sync Bundle
- AuthService con login/logout, JWT tokens, persistencia en storage
- AuthenticationInterceptor con auto-refresh de tokens
- SyncService con full sync + delta sync
- LocalSyncStore para persistencia offline del bundle
- UserDataBundle con menu, permissions, screens, glossary, strings
- SchoolSelectionScreen para multi-escuela

### Fase 1 — Menu Dinámico + Navegación Adaptativa
- MenuService con filtrado RBAC por permisos del usuario
- Navegación adaptativa: sidebar (iPad/Mac) / tab bar (iPhone)
- Breakpoints de layout: compact / regular / expanded
- Toolbar dinámico contextual por patrón de pantalla
- MenuItem con jerarquía padre/hijos, iconos SF Symbol

### Fase 2 — Offline-First
- NetworkObserver con NWPathMonitor (detección nativa de conectividad)
- MutationQueue persistente (máx 50, deduplicación, estados)
- ConflictResolver (404→skip, 409→applyLocal, 400→fail, 5xx→retry)
- SyncEngine con exponential backoff (1s, 2s, 4s)
- ConnectivitySyncManager: orquesta reconexión (sync mutations + delta sync)
- ConnectivityBanner con estados offline/syncing/synced
- DataLoader con modo offline (cache stale como fallback)

### Fase 3 — ScreenContracts + EventOrchestrator
- ScreenContract protocol con endpoints, permisos, field mapping
- 24+ contratos registrados: 5 dashboards, 14 CRUD pairs, auth, settings
- ContractRegistry con registerDefaults()
- EventOrchestrator (actor): routing de eventos, verificación RBAC, field mapping
- EventContext con screenKey, userContext, selectedItem, fieldValues
- EventResult: success, navigateTo, permissionDenied, error

### Fase 4 — Renderers SDUI + Formularios CRUD
- PatternRouter con 12 patrones: login, list, form, detail, dashboard, settings, search, profile, modal, notification, onboarding, emptyState
- ListPatternRenderer con paginación, búsqueda, pull-to-refresh
- FormPatternRenderer con validación, campos dinámicos
- DetailPatternRenderer con zonas y acciones
- SlotRenderer con 22+ tipos de control
- ZoneRenderer para composición de zonas

### Fase 5 — Dashboards Dinámicos por Rol
- DashboardPatternRenderer con LazyVGrid adaptativo (2 cols iPhone, 3-4 cols iPad/Mac)
- MetricCardControl con slot bindings, Liquid Glass, trend indicators
- QuickActionControl para acciones rápidas por rol con RBAC
- 5 contratos de dashboard: superadmin, school_admin, teacher, student, guardian
- GlobalStatsDTO con campos dinámicos
- Welcome fallback cuando no hay dashboard definido
- Skeleton loader que deriva conteo de las zonas reales

### Fase 6 — i18n + Glosario Dinámico
- EduStrings con 43+ strings localizados (es, en, pt-BR)
- ServerStringResolver para strings server-driven (L2)
- GlossaryProvider con 16+ term keys tipados (GlossaryKey enum)
- PlaceholderResolver soporta `{glossary.*}` tokens
- LocaleService con cadena de fallback (es-CO→es→en)
- i18n se actualiza automáticamente después de fullSync

### Fase 7 — UX Avanzado
- StaleDataIndicator con tiempo relativo y tap-to-refresh
- Skeleton loaders por patrón: List, Form, Dashboard, Detail
- Toolbar dinámico mejorado: badges, search expandible, breadcrumbs
- Pull-to-refresh con haptic feedback
- ToastManager: success, error, warning, info con auto-dismiss
- Confirmación para acciones destructivas (delete)
- Empty states contextuales con acción

### Fase 8 — Integración Final + Tests E2E
- ServiceContainer completo con 15+ servicios inyectados en orden
- Environment injection: isOnline, EventOrchestrator, ToastManager, GlossaryProvider
- ErrorBoundary ViewModifier con retry funcional + navegación a home
- DeepLinkHandler: `edugo://screen/{screenKey}?params` con pending links
- Code audit: 0 nonisolated, 0 @Published, 0 ObservableObject, 0 Combine, 0 XCTest
- 21 tests de integración E2E en 5 suites
- 13 tests nuevos para auth refresh + offline mode

---

## Arquitectura Final

```
┌─────────────────────────────────────────────────┐
│                   DemoApp (32 files)              │
│  ServiceContainer · Renderers · Screens · Nav    │
├─────────────────────────────────────────────────┤
│                                                   │
│  EduFeatures ─── EduPresentation ─── EduDomain   │
│                       │                  │        │
│                  EduDynamicUI       EduDomain      │
│                       │                  │        │
│                  EduInfrastructure                 │
│                       │                           │
│                    EduCore (re-exports EduModels)  │
│                       │                           │
│                  EduFoundation                     │
│                                                   │
├─────────────────────────────────────────────────┤
│  modulos/ (standalone SDKs)                       │
│  CQRSKit · DesignSystemSDK · FormsSDK ·          │
│  FoundationToolkit · LoggerSDK · NetworkSDK ·     │
│  UIComponentsSDK                                  │
└─────────────────────────────────────────────────┘
```

### Flujo E2E

```
App Launch → Splash (restore session / branding)
  ├── Token válido → Delta Sync → Main
  └── Sin token → Login → Full Sync → Main
          │
          ├── Menu dinámico (RBAC) → Sidebar/TabBar
          ├── Dashboard por rol (5 variantes)
          ├── CRUD: List → Detail → Form → Save
          ├── Offline: MutationQueue → SyncEngine → Reconnect
          ├── i18n: Local (L1) + Server (L2) + Glossary
          └── Deep Links: edugo://screen/{key}?params
```

---

## Principios Aplicados (verificado en code audit)

| Regla | Cumplimiento |
|-------|-------------|
| Swift 6.2 en todos los Package.swift | 16/16 ✅ |
| iOS 26 / macOS 26 como target mínimo | 16/16 ✅ |
| `@Observable` (nunca @Published/@ObservableObject) | ✅ 0 violaciones |
| `nonisolated` prohibido | ✅ 0 violaciones |
| `actor` para estado compartido | ✅ NetworkClient, ScreenLoader, DataLoader, CircuitBreaker, RateLimiter, NetworkObserver, MutationQueue, SyncEngine, ConnectivitySyncManager |
| `AsyncSequence`/`AsyncStream` (nunca Combine) | ✅ 0 import Combine |
| Swift Testing (nunca XCTest) | ✅ 0 import XCTest |
| JSONValue solo en EduModels | ✅ definición única |
| CodingKeys con snake_case | ✅ todos los DTOs |
| Liquid Glass para UI | ✅ |

---

## Cobertura de Tests por Paquete

| Paquete | Tests | Suites | Areas cubiertas |
|---------|-------|--------|-----------------|
| Core | 754 | 67 | DTOs, Models, Mappers, Validation, JSONValue, Serializers |
| Infrastructure | 434 | 37 | NetworkClient, Interceptors, CircuitBreaker, RateLimiter, Repositories, NetworkObserver, Storage, Persistence |
| Domain | 197 | 31 | CQRS, UseCases, AuthService, SyncService, MenuService, MutationQueue, ConflictResolver, SyncEngine, EventOrchestrator, ContractRegistry, GlossaryProvider, ServerStringResolver, Integration E2E |
| DynamicUI | 88 | 8 | ScreenLoader, DataLoader, SlotBindingResolver, PlaceholderResolver, ScreenDefinition |

---

## Features Pendientes POST-MIGRACIÓN

Estas features fueron documentadas en fase-08 como trabajo futuro, no son parte de la migración KMP:

### Seguridad
- Cifrado de tokens en Keychain
- Certificate pinning
- Cifrado de cache local

### UX
- Deep-linking avanzado (universal links)
- Undo/redo en formularios
- Optimistic UI (mostrar cambio antes de confirmar server)
- Breadcrumb navigation completo

### Arquitectura
- Feature flags desde servidor
- Deduplicación de requests en vuelo
- Compresión de payloads (gzip)
- Migrar NotificationCenter en AccessibilityPreferences a AsyncSequence
- Migrar SwitchSchoolContextUseCase de NotificationCenter a EventBus

### Observabilidad
- Crashlytics/crash reporting
- Métricas de cache hit rate
- Analytics de user flows
- Performance monitoring

### Performance
- Paginación infinita con prefetch
- Imágenes SVG/optimizadas

---

## Para Nuevos Desarrolladores

### Prerequisitos
- Xcode 26
- macOS 26
- Swift 6.2+

### Primeros pasos

```bash
# Clonar y compilar
git clone https://github.com/EduGoGroup/apple_new.git
cd apple_new
make build

# Correr la app (macOS, staging)
make run

# Correr tests
cd Packages/Core && swift test
cd Packages/Infrastructure && swift test
cd Packages/Domain && swift test
cd Packages/DynamicUI && swift test

# Correr con diferentes ambientes
make run-dev   # localhost
make run-prod  # producción
```

### Credenciales de staging
- Email: `super@edugo.test`
- Password: `EduGoTest123!`

### Estructura clave
- `Packages/` — 6 paquetes SPM con dependencia one-way estricta
- `modulos/` — 7 SDKs standalone
- `Apps/DemoApp/` — App ejecutable con ServiceContainer
- `docs/plan-migracion/` — Documentación de cada fase

### Reglas NO negociables
1. Nunca bajar de iOS 26 / macOS 26
2. Nunca usar `nonisolated` — usar `static func` o aceptar `await`
3. Nunca usar `@Published`, `ObservableObject`, `Combine`, `NotificationCenter`
4. Nunca usar `XCTest` — solo Swift Testing
5. `JSONValue` solo existe en `EduModels` — nunca duplicar
6. Cada cambio debe compilar (`make build`) y pasar tests
