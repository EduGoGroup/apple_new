# 04 - Resiliencia de Red

## 4.1 Capas de Proteccion

La app implementa 3 capas de resiliencia para proteger contra fallos de red y del servidor. Se aplican en orden:

```
Request del usuario
  → RateLimiter (solo login)
    → CircuitBreaker (login + refresh)
      → RetryPolicy (dentro del circuit breaker)
        → HTTP Request real
```

## 4.2 Circuit Breaker

### Proposito
Evitar cascadas de fallos cuando el backend esta caido. Si detecta muchos fallos seguidos, deja de enviar requests por un tiempo.

### Estados
```
CLOSED (normal)
  → Requests pasan normalmente
  → Cuenta fallos consecutivos
  → Si fallos >= threshold → cambia a OPEN

OPEN (rechazando)
  → Rechaza requests inmediatamente sin enviarlos
  → Espera un timeout
  → Despues del timeout → cambia a HALF_OPEN

HALF_OPEN (probando)
  → Permite requests limitados (uno a la vez)
  → Si es exitoso: cuenta exitos
  → Si exitos >= successThreshold → cambia a CLOSED
  → Si falla → vuelve a OPEN
```

### Diagrama de transiciones
```
         fallo >= threshold
CLOSED ─────────────────────→ OPEN
  ↑                            │
  │  exito >= successThreshold │ timeout elapsed
  │                            ↓
  └──────────────────────── HALF_OPEN
            fallo ────────→ OPEN
```

### Configuracion por entorno

| Param | DEV | STAGING | PROD |
|-------|-----|---------|------|
| failureThreshold | 10 | 5 | 3 |
| successThreshold | 1 | 2 | 3 |
| timeout | 15s | 30s | 60s |

### Donde se aplica
- Login (AuthRepository.login)
- Token refresh (AuthRepository.refresh)

### Thread Safety
Debe ser thread-safe (usar actor en Swift o locks). Multiples requests pueden intentar actualizar el estado simultaneamente.

## 4.3 Rate Limiter

### Proposito
Limitar la cantidad de intentos de login por periodo de tiempo. Previene brute-force accidental o intencional.

### Algoritmo (Sliding Window)
1. Mantener lista de timestamps de requests recientes
2. Ante nuevo request: limpiar timestamps mas viejos que `window`
3. Si cantidad de timestamps >= maxRequests: rechazar
4. Si pasa: agregar timestamp actual

### Configuracion por entorno

| Param | DEV | STAGING | PROD |
|-------|-----|---------|------|
| maxRequests | 20 | 10 | 5 |
| window | 1 min | 1 min | 1 min |

### Donde se aplica
- Solo en login (antes de enviar request)

## 4.4 Retry Policy

### Proposito
Reintentar requests que fallan por problemas transitorios (red, timeout, 5xx).

### Algoritmo (Exponential Backoff)
```
Intento 1: ejecutar request
Si falla con error retryable:
  delay = initialDelay * (backoffMultiplier ^ (attempt - 1))
  delay = min(delay, maxDelay)
  esperar delay
  Intento 2: ejecutar request
  ...
Repetir hasta maxAttempts
```

### Que errores son retryable
- Errores de red (sin conexion, timeout, reset)
- HTTP 502 Bad Gateway
- HTTP 503 Service Unavailable

### Que errores NO son retryable
- HTTP 400 (validacion)
- HTTP 401 (credenciales invalidas)
- HTTP 403 (prohibido)
- HTTP 404 (no encontrado)
- Cualquier error de negocio

### Configuracion por entorno

| Perfil | Intentos | Delay Inicial | Delay Max | Multiplicador |
|--------|----------|---------------|-----------|---------------|
| AGGRESSIVE (DEV) | 5 | 200ms | 3s | 1.5x |
| DEFAULT (STAGING) | 3 | 500ms | 5s | 2.0x |
| CONSERVATIVE (PROD) | 2 | 1s | 10s | 3.0x |
| NO_RETRY (tests) | 1 | - | - | - |

### Ejemplo de delays (DEFAULT)
```
Intento 1: inmediato
Intento 2: 500ms
Intento 3: 1000ms (500 * 2^1)
→ Fallo final
```

## 4.5 Composicion de las 3 Capas

### Para login:
```
1. RateLimiter.check()
   → Si excedido: Error("Rate limit exceeded")

2. CircuitBreaker.execute {
   3. RetryPolicy.withRetry {
      4. HTTP POST /v1/auth/login
   }
}
```

### Para refresh:
```
1. CircuitBreaker.execute {
   2. RetryPolicy.withRetry {
      3. HTTP POST /v1/auth/refresh
   }
}
```

### Para requests normales (data loading):
- No usan CircuitBreaker ni RateLimiter
- Pueden usar RetryPolicy opcionalmente

## 4.6 Configuracion Completa por Entorno

### DEV (desarrollo local)
```
Auth:
  refreshThreshold: 60s
  refreshMaxRetries: 10
  refreshInitialDelay: 500ms

CircuitBreaker:
  failureThreshold: 10
  successThreshold: 1
  timeout: 15s

RateLimiter:
  maxRequests: 20 per 1min

RetryPolicy:
  maxAttempts: 5
  initialDelay: 200ms
  maxDelay: 3s
  backoff: 1.5x
```

### STAGING
```
Auth:
  refreshThreshold: 300s (5 min)
  refreshMaxRetries: 3
  refreshInitialDelay: 1000ms

CircuitBreaker:
  failureThreshold: 5
  successThreshold: 2
  timeout: 30s

RateLimiter:
  maxRequests: 10 per 1min

RetryPolicy:
  maxAttempts: 3
  initialDelay: 500ms
  maxDelay: 5s
  backoff: 2.0x
```

### PROD
```
Auth:
  refreshThreshold: 600s (10 min)
  refreshMaxRetries: 5
  refreshInitialDelay: 2000ms

CircuitBreaker:
  failureThreshold: 3
  successThreshold: 3
  timeout: 60s

RateLimiter:
  maxRequests: 5 per 1min

RetryPolicy:
  maxAttempts: 2
  initialDelay: 1000ms
  maxDelay: 10s
  backoff: 3.0x
```
