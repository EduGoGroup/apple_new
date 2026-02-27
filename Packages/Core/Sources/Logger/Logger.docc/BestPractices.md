# Best Practices

Guia de mejores practicas para logging efectivo.

## Overview

Esta guia describe que loggear, que no loggear, y como hacerlo correctamente.

## Que Loggear

### Loggear

- Eventos significativos (login, logout, transacciones)
- Errores y excepciones
- Metricas de performance
- Cambios de estado importantes
- Inicio y fin de operaciones largas

### NO Loggear

- Contrasenas o tokens
- Informacion personal (PII)
- Numeros de tarjeta de credito
- Datos sensibles de usuarios

## Niveles Apropiados

### Debug

Informacion detallada para development:

```swift
await logger.debug("Processing item \(index) of \(total)")
await logger.debug("Cache hit for key: \(key)")
```

### Info

Eventos informativos normales:

```swift
await logger.info("User logged in")
await logger.info("Request completed in \(duration)ms")
```

### Warning

Situaciones anomalas pero no criticas:

```swift
await logger.warning("Cache miss, falling back to network")
await logger.warning("Retrying request, attempt \(attempt)")
```

### Error

Errores que afectan funcionalidad:

```swift
await logger.error("Failed to save user: \(error)")
await logger.error("Network request failed: \(statusCode)")
```

## Performance

### Logging Condicional

En hot paths, verifica el nivel antes de construir mensajes costosos:

```swift
// Si construir el mensaje es costoso
if await LoggerConfigurator.shared.globalLevel <= .debug {
    let expensiveInfo = computeExpensiveDebugInfo()
    await logger.debug("Info: \(expensiveInfo)")
}
```

### Configuracion de Production

```swift
// Deshabilitar metadata para mejor performance
await LoggerConfigurator.shared.setIncludeMetadata(false)

// Usar nivel warning o superior
await LoggerConfigurator.shared.setGlobalLevel(.warning)
```

## Seguridad

### Redactar Datos Sensibles

```swift
// MAL
await logger.info("Password: \(password)")

// BIEN
await logger.info("Password: [REDACTED]")
await logger.info("Login attempt for user")
```

### Tokens y Keys

```swift
// MAL
await logger.debug("API Key: \(apiKey)")

// BIEN
await logger.debug("API Key: \(apiKey.prefix(4))****")
```

## Anti-Patterns

### Evitar

1. **Log and Throw**: No loggear Y lanzar excepcion - deja que el caller loggee

```swift
// MAL
func doSomething() throws {
    do {
        try operation()
    } catch {
        await logger.error("Failed")  // Loggea
        throw error                    // Y lanza
    }
}

// BIEN
func doSomething() throws {
    try operation()  // Deja que el caller maneje
}
```

2. **Logging Excesivo**: No loggear en cada iteracion de un loop

```swift
// MAL
for item in items {
    await logger.debug("Processing \(item)")
}

// BIEN
await logger.debug("Processing \(items.count) items")
```

3. **Sin Categorias**: Siempre usa categorias apropiadas

```swift
// MAL
await logger.info("Request sent")

// BIEN
await logger.info("Request sent", category: NetworkCategory.request)
```
