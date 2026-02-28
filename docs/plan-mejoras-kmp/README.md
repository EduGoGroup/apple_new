# Plan de Mejoras: Adaptaciones KMP → apple_new (2026-02-27)

> **ESTADO: PENDIENTE** — Mejoras identificadas de los PRs de KMP (#13-#19) y API (#8-#11) del 27/02/2026.

## Contexto

Los PRs del proyecto hermano `EduUi-KMP` y la API `edugo-api-iam-platform` implementaron mejoras que no existían cuando se completó la migración original (fases 0-8). Este plan identifica las brechas y organiza la implementación en fases.

## Análisis de Brechas

| Feature (KMP PR) | apple_new Status | Acción |
|---|---|---|
| Event Bus cross-screen (#17/#18) | ✅ Ya existe EventBus actor + CacheInvalidationSubscriber | Ninguna |
| Undo DELETE con Snackbar (#17/#18) | ❌ Solo confirmation dialog | **Portar** |
| Error Boundaries por Zona (#15) | ❌ Solo screen-level ErrorBoundary | **Portar** |
| Parallel Serialization (#13/#14) | ❌ Sequential en LocalSyncStore + ScreenLoader | **Portar** |
| Reactive isOnline (#14) | ✅ Ya reactivo via AsyncStream | Ninguna |
| Incremental Delta Sync (#13/#14) | ✅ Ya incremental | Ninguna |
| Splash Parallelism (#13/#14) | ✅ Ya usa withTaskGroup | Ninguna |
| HTTP gzip (#19) | ✅ URLSession lo maneja transparentemente | Ninguna |
| Cache Hit/Miss Logging (#19) | ❌ Caching silencioso | **Portar** |
| Form Validation pre-submit (#19) | ✅ Ya en FormPatternRenderer | Ninguna |
| REMOTE_SELECT ControlType (#19) | ❌ No existe en ControlType | **Portar** |
| i18n Hardcoded Strings (#19) | ⚠️ Parcial — ConnectivityBanner, SchoolSelection hardcoded | **Portar** |
| Skeleton Loading por patrón (#19) | ⚠️ Dashboard tiene skeleton, List/Form no | **Portar** |
| Buckets Filter para Sync (API #8/#9) | ❌ Cliente no usa ?buckets= | **Portar** |
| Sorted Contexts (API #10/#11) | ⚠️ API ya ordena, cliente no ordena | **Bajo priority** |
| School Selection cache clearing (#14) | ❌ No limpia cache al cambiar escuela | **Portar** |
| Protected Restore on Logout (#14) | ✅ Auth check antes de restore | Ninguna |

## Fases

| Fase | Nombre | Complejidad | Archivos Est. |
|------|--------|-------------|---------------|
| A | [Quick Wins: Cache Logging + i18n + Cache Clear](fase-A-quick-wins.md) | Baja | ~10 |
| B | [UX: Skeleton Views + Undo Delete](fase-B-ux-improvements.md) | Media | ~15 |
| C | [Resiliencia: Error Boundaries + Parallel Serialization](fase-C-resiliencia.md) | Media | ~8 |
| D | [Features: REMOTE_SELECT + Buckets Filter](fase-D-new-features.md) | Alta | ~20 |

## Diagrama de Dependencias

```
Fase A (Quick Wins) ─── independiente
  │
  ├──→ Fase B (UX) ─── depende parcialmente de A (i18n strings para undo toast)
  │
  ├──→ Fase C (Resiliencia) ─── independiente de B
  │
  └──→ Fase D (Features) ─── independiente de B y C
```

**Nota**: Las fases A, C y D pueden ejecutarse en paralelo. Fase B depende parcialmente de que A complete los strings i18n.

## Principios (mismos que migración original)

1. **Swift 6.2+ / iOS 26 / macOS 26** — nunca menor
2. **Zero código deprecado** — eliminar y crear
3. **`nonisolated` PROHIBIDO** — usar `static func` o `await`
4. **`@Observable`** siempre — nunca `@Published`/`@ObservableObject`
5. **`actor`** para estado compartido concurrente
6. **`AsyncSequence`/`AsyncStream`** — nunca Combine
7. **Liquid Glass** para UI
8. **Swift Testing** — `@Suite`, `@Test`, `#expect`
9. **Cada fase DEBE compilar y pasar todos los tests**
10. **JSONValue** solo en EduModels
