# Plan Post-Migracion — EduGo Apple

> Plan maestro de mejoras post-migracion KMP -> Swift nativo.
> Reemplaza los planes viejos en `docs/plan-migracion/`.

**Rama:** `feature/post-migration-ux-performance`
**Base:** `dev` (commit `e3663a5`)
**Fecha:** 2026-03-01

---

## Estado del Proyecto

La migracion KMP -> apple_new se completo en 9 fases (PRs #1, #2, #4, #6).
La auditoria de codigo se completo en PRs #10, #12, #14.

| Metrica | Valor |
|---------|-------|
| Tests totales | 2,142+ |
| Suites de test | 160+ |
| Paquetes SPM | 14 (7 principales + 7 modulos) |
| Fallos | 0 |

---

## Tabla de Mejoras Pendientes

| # | Area | Mejora | Prioridad | Complejidad | Fase | Estado | Informe |
|---|------|--------|-----------|-------------|------|--------|---------|
| 1 | UX | Optimistic UI | ALTA | ALTA | 1 | EN PROGRESO | [spec](spec-optimistic-ui.md) |
| 2 | UX | Breadcrumb Navigation | ALTA | MEDIA | 1 | EN PROGRESO | [spec](spec-breadcrumb-navigation.md) |
| 3 | Performance | Paginacion infinita + prefetch | ALTA | MEDIA | 1 | EN PROGRESO | [spec](spec-paginacion-prefetch.md) |
| 4 | UX | Deep-linking avanzado (Universal Links) | MEDIA | MEDIA | 2 | PENDIENTE | [informe](informe-ux.md) |
| 5 | UX | Undo/redo en formularios | BAJA | MEDIA | 3 | PENDIENTE | [informe](informe-ux.md) |
| 6 | Arquitectura | Feature flags desde servidor | ALTA | ALTA | 2 | PENDIENTE | [informe](informe-arquitectura.md) |
| 7 | Arquitectura | Deduplicacion de requests en vuelo | MEDIA | MEDIA | 2 | PENDIENTE | [informe](informe-arquitectura.md) |
| 8 | Arquitectura | Compresion de payloads (gzip) | BAJA | BAJA | 3 | PENDIENTE | [informe](informe-arquitectura.md) |
| 9 | Arquitectura | Cifrado de cache local | ALTA | MEDIA | 2 | PENDIENTE | [informe](informe-arquitectura.md) |
| 10 | Observabilidad | Crash reporting (MetricKit/OSLog) | MEDIA | MEDIA | 2 | PENDIENTE | [informe](informe-observabilidad.md) |
| 11 | Observabilidad | Metricas de cache hit rate | BAJA | BAJA | 3 | PENDIENTE | [informe](informe-observabilidad.md) |
| 12 | Observabilidad | Analytics de user flows | ALTA | ALTA | 2 | PENDIENTE | [informe](informe-observabilidad.md) |
| 13 | Observabilidad | Performance monitoring (signposts) | MEDIA | BAJA | 3 | PENDIENTE | [informe](informe-observabilidad.md) |
| 14 | Performance | Imagenes SVG/optimizadas | BAJA | MEDIA | 3 | PENDIENTE | [informe](informe-performance.md) |

---

## Fases de Implementacion

### Fase 1 — UX + Performance (esta sesion)

Tres features implementadas en paralelo:

1. **Optimistic UI** — Mostrar cambios en UI inmediatamente, confirmar con server, rollback si falla
2. **Breadcrumb Navigation** — Stack de navegacion visible con tap directo a cualquier nivel
3. **Paginacion Infinita con Prefetch** — Cargar siguiente pagina anticipadamente al acercarse al final

### Fase 2 — Arquitectura + Observabilidad (proxima sesion)

- Feature flags desde servidor
- Deduplicacion de requests en vuelo
- Cifrado de cache local (CryptoKit AES-256-GCM)
- Crash reporting via MetricKit
- Analytics backend (transmision batch de eventos)
- Deep-linking avanzado (Universal Links)

### Fase 3 — Polish (sesion posterior)

- Compresion de payloads (gzip)
- Metricas de cache hit rate
- Performance monitoring (os_signpost)
- Undo/redo en formularios
- Imagenes SVG/optimizadas

---

## Documentos

### Informes (analisis + plan por area)

| Documento | Area |
|-----------|------|
| [informe-ux.md](informe-ux.md) | Optimistic UI, Breadcrumbs, Deep-linking, Undo/redo |
| [informe-arquitectura.md](informe-arquitectura.md) | Feature flags, Request dedup, Gzip, Cache encryption |
| [informe-observabilidad.md](informe-observabilidad.md) | Crash reporting, Cache metrics, Analytics, Signposts |
| [informe-performance.md](informe-performance.md) | Paginacion infinita, Imagenes SVG |

### Specs detalladas (Fase 1)

| Documento | Feature |
|-----------|---------|
| [spec-optimistic-ui.md](spec-optimistic-ui.md) | Patron optimistic update con rollback |
| [spec-breadcrumb-navigation.md](spec-breadcrumb-navigation.md) | Stack de breadcrumbs SDUI |
| [spec-paginacion-prefetch.md](spec-paginacion-prefetch.md) | Paginacion infinita con prefetch |

---

## Principios

- Zero dependencias externas (todo nativo: CryptoKit, MetricKit, OSLog, etc.)
- Swift 6.2, iOS/macOS/iPadOS 26
- `@Observable`, `actor`, `async/await`, `AsyncSequence/AsyncStream`
- `nonisolated` PROHIBIDO
- Swift Testing (`@Suite`, `@Test`, `#expect`)
- Liquid Glass para UI
- Cada cambio compila y pasa tests
