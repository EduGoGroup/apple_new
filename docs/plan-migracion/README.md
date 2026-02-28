# Plan de Migración: KMP → apple_new

> **ESTADO: COMPLETADA** — Ver [COMPLETADO.md](COMPLETADO.md) para el resumen final.

## Objetivo

Portar todas las funcionalidades del proyecto KMP (`kmp_new`) al proyecto Swift nativo (`apple_new`), utilizando exclusivamente tecnología Apple de última generación (Swift 6.2, iOS 26, macOS 26, Liquid Glass, SwiftData). Sin código deprecado, sin retrocompatibilidad.

## Fases

| Fase | Nombre | PR | Estado |
|------|--------|----|--------|
| 0 | [Auth completo + Sync Bundle](fase-00-auth-sync.md) | #1 | ✅ Completada |
| 1 | [Menu Dinámico + Navegación Adaptativa](fase-01-menu-navegacion.md) | #2 | ✅ Completada |
| 2 | [Offline-First: NetworkObserver + MutationQueue + SyncEngine](fase-02-offline-first.md) | #2 | ✅ Completada |
| 3 | [ScreenContracts + EventOrchestrator](fase-03-contracts-orchestrator.md) | #4 | ✅ Completada |
| 4 | [Renderers SDUI + Formularios CRUD](fase-04-renderers-crud.md) | #4 | ✅ Completada |
| 5 | [Dashboards Dinámicos por Rol](fase-05-dashboards.md) | #6 | ✅ Completada |
| 6 | [i18n + Glosario Dinámico](fase-06-i18n-glosario.md) | #2 | ✅ Completada |
| 7 | [UX Avanzado: Stale Data, Skeleton, Toolbar Dinámico](fase-07-ux-avanzado.md) | #4 | ✅ Completada |
| 8 | [Integración Final + Tests E2E](fase-08-integracion-tests.md) | #6 | ✅ Completada |

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
