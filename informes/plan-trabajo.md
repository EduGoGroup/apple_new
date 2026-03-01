# Plan de Trabajo Consolidado

## Prioridad 1: CRITICO (Seguridad - Implementar Antes de Release)

| # | Tarea | Solucion | Esfuerzo | Archivos |
|---|-------|----------|----------|----------|
| 1 | Implementar Keychain storage para tokens | [token-storage-seguro.md](soluciones/token-storage-seguro.md) | 1 dia | 3 archivos (1 nuevo, 1 mod, 1 test) |
| 2 | Implementar certificate pinning | [certificate-pinning.md](soluciones/certificate-pinning.md) | 1-2 dias | 4 archivos (2 nuevos, 1 mod, 1 test) |

## Prioridad 2: HIGH (Compliance - Corregir Pronto)

| # | Tarea | Solucion | Esfuerzo | Archivos | Estado |
|---|-------|----------|----------|----------|--------|
| 3 | Eliminar NotificationCenter de produccion | [eliminar-notificationcenter.md](soluciones/eliminar-notificationcenter.md) | 0.5 dia | 6 archivos | Pendiente |
| 4 | Fix NetworkClientBuilder Sendable | CAL-01 | 0.5 hora | 1 archivo | ✅ Completado |
| 5 | Fix InterceptableNetworkClient mutacion de URLSessionConfiguration | CAL-03 | 0.5 hora | 1 archivo | ✅ Completado |
| 6 | Documentar o fix StatePublisher single-consumer | CAL-04 | 1 hora | 2 archivos | Pendiente |
| 7 | Agregar issuedAt a StoredAuthToken | CAL-05 | 1 hora | 1 archivo + tests | ✅ Completado |
| 8 | Eliminar fake token en AuthManager o reforzar guard | SEC-02 | 0.5 hora | 1 archivo | ✅ Completado |

## Prioridad 3: MEDIUM (Estabilidad - Planificar)

| # | Tarea | Solucion | Esfuerzo | Archivos | Estado |
|---|-------|----------|----------|----------|--------|
| 9 | Resiliencia DynamicUI (unknown types) | [resiliencia-dynamicui.md](soluciones/resiliencia-dynamicui.md) | 0.5 dia | 3 archivos + tests | Pendiente |
| 10 | Fix LRU cache (acceso vs insercion) | REN-01 | 1 hora | 1 archivo | ✅ Completado |
| 11 | Agregar max cache size a DataLoader | REN-02 | 1 hora | 1 archivo | Pendiente |
| 12 | Fix CircuitBreaker CancellationError | EL-01 | 0.5 hora | 1 archivo | ✅ Completado |
| 13 | Fix URL concatenation doble slash | EL-04 | 0.5 hora | 2 archivos | ✅ Completado |
| 14 | Eliminar protocolos muertos Entity/Model | ARQ-01/02 | 0.5 hora | 2 archivos | ✅ Completado |
| 15 | Consolidar LogConfiguration.Environment | ARQ-05 | 1 hora | 2 archivos | Pendiente (8+ callsites, PR dedicado) |
| 16 | Fix make test para multi-package | TST-05 | 0.5 hora | 1 archivo | ✅ Completado |

## Prioridad 4: LOW (Mejoras Opcionales)

| # | Tarea | Ref | Esfuerzo | Estado |
|---|-------|-----|----------|--------|
| 17 | Eliminar typealias DynamicJSONValue | CAL-10 | 5 min | ✅ Completado |
| 18 | Eliminar metodo describeDecodingError muerto | CAL-11 | 5 min | ✅ Completado |
| 19 | Optimizar DateFormatter en PlaceholderResolver | REN-04 | 10 min | ✅ Completado |
| 20 | Eliminar duplicacion TTL en ScreenLoader | REN-07 | 10 min | ✅ Completado |
| 21 | Agregar Equatable a UseCaseError | CAL-09 | 15 min | ✅ Completado |
| 22 | Simplificar RepositoryError Equatable | CAL-14 | 10 min | ✅ Completado |
| 23 | Agregar CodingKeys a PaginatedResponse | CAL-13 | 15 min | ✅ Completado |
| 24 | Documentar NetworkClient.shared como internal | CAL-12 | 5 min | ✅ Completado |
| 25 | Reemplazar tests cosmeticos placeholder | TST-01 | 30 min | ✅ Completado |
| 26 | Agregar tests para gaps DynamicUI | TST-04 | 1 hora | Pendiente |

---

## Fase 2: Correcciones Automaticas (items 17-25)

Correcciones aplicadas en rama `fix/code-audit-minor-corrections`. Ver [correcciones-menores.md](soluciones/correcciones-menores.md).

**Resultado**: 10 de 11 correcciones aplicadas. 1,708 tests pasan en 7 paquetes.

**Pendiente del item 7** (CAL-05 `issuedAt` en `StoredAuthToken`): ✅ Completado tambien en esta rama.

**Reglas aplicadas**:
- Solo este proyecto (apple_new), no proyectos compartidos
- Rama `fix/code-audit-minor-corrections` desde dev
- Build y tests validados: **1,708 tests, 0 fallos**
