# Plan de Migración: KMP → apple_new

## Objetivo

Portar todas las funcionalidades del proyecto KMP (`kmp_new`) al proyecto Swift nativo (`apple_new`), utilizando exclusivamente tecnología Apple de última generación (Swift 6.2, iOS 26, macOS 26, Liquid Glass, SwiftData). Sin código deprecado, sin retrocompatibilidad.

## Estado Actual

### Lo que YA existe en apple_new (95% estructura base)
- 6 paquetes SPM con jerarquía estricta (617 archivos Swift)
- NetworkClient con interceptors, CircuitBreaker, RateLimiter
- CQRS completo (Commands, Queries, Events, Mediator)
- DynamicUI base (ScreenLoader + DataLoader + Resolvers, 12 patterns, 31 control types)
- Presentation con 119 archivos (Liquid Glass, 42 archivos de accesibilidad, ViewModels, coordinadores)
- SwiftData persistence con 6 entidades
- Auth flow básico (login/logout, JWT, interceptor)
- DemoApp funcional con splash/login/main/dynamic-screen

### Lo que FALTA migrar desde KMP
- Sync Bundle completo (full sync + delta sync)
- Menu dinámico con RBAC y adaptación por breakpoints
- Offline-first completo (MutationQueue, SyncEngine, ConflictResolver)
- NetworkObserver nativo (NWPathMonitor)
- 30+ ScreenContracts con EventOrchestrator
- Dashboards dinámicos por rol
- Token refresh real con rotación JWT
- Cambio de contexto escuela (multi-escuela)
- i18n de 2 capas (local + server-driven)
- Glosario dinámico por institución
- Formularios CRUD completos con validación
- Paginación, búsqueda, filtros
- Indicadores de stale data y connectivity banner

## Fases

| Fase | Nombre | Archivos Estimados | Dependencias |
|------|--------|-------------------|--------------|
| 0 | [Cimientos: Auth completo + Sync Bundle](fase-00-auth-sync.md) | ~25 | Ninguna |
| 1 | [Menu Dinámico + Navegación Adaptativa](fase-01-menu-navegacion.md) | ~20 | Fase 0 |
| 2 | [Offline-First: NetworkObserver + MutationQueue + SyncEngine](fase-02-offline-first.md) | ~25 | Fase 0 |
| 3 | [ScreenContracts + EventOrchestrator](fase-03-contracts-orchestrator.md) | ~35 | Fase 1 |
| 4 | [Renderers SDUI + Formularios CRUD](fase-04-renderers-crud.md) | ~30 | Fase 3 |
| 5 | [Dashboards Dinámicos por Rol](fase-05-dashboards.md) | ~15 | Fase 3, 4 |
| 6 | [i18n + Glosario Dinámico](fase-06-i18n-glosario.md) | ~12 | Fase 0 |
| 7 | [UX Avanzado: Stale Data, Skeleton, Toolbar Dinámico](fase-07-ux-avanzado.md) | ~15 | Fase 2, 4 |
| 8 | [Integración Final + Tests E2E](fase-08-integracion-tests.md) | ~20 | Todas |

## Diagrama de Dependencias

```
Fase 0 (Auth + Sync)
  ├──→ Fase 1 (Menu + Nav)
  │      └──→ Fase 3 (Contracts + Orchestrator)
  │              ├──→ Fase 4 (Renderers + CRUD)
  │              │      └──→ Fase 5 (Dashboards)
  │              └──→ Fase 5 (Dashboards)
  ├──→ Fase 2 (Offline-First)
  │      └──→ Fase 7 (UX Avanzado) ←── Fase 4
  ├──→ Fase 6 (i18n + Glosario)
  └──→ Fase 8 (Integración + Tests) ←── Todas
```

## Principios Inmutables

1. **Swift 6.2+ / iOS 26 / macOS 26** — nunca menor
2. **Zero código deprecado** — eliminar y crear, nunca parchar
3. **`nonisolated` PROHIBIDO** — usar `static func` o `await`
4. **`@Observable`** siempre — nunca `@Published`/`@ObservableObject`
5. **`actor`** para estado compartido concurrente
6. **`AsyncSequence`/`AsyncStream`** — nunca Combine/NotificationCenter
7. **Liquid Glass** para UI — diseño nativo iOS 26
8. **Swift Testing** — `@Suite`, `@Test`, `#expect` (nunca XCTest)
9. **Cada fase DEBE compilar y pasar todos los tests** antes de continuar
10. **JSONValue** solo en EduModels — nunca duplicar

## Cómo ejecutar cada fase

1. Leer el archivo de fase correspondiente
2. Implementar en orden los pasos listados
3. Al final de cada paso, ejecutar `make build` y `make test`
4. Verificar que no hay warnings de deprecación
5. Solo avanzar a la siguiente fase cuando TODO compile y pase tests
