# Getting Started

Configura y usa el sistema de logging en tu aplicacion EduGo.

## Overview

Esta guia te ayudara a configurar el sistema de logging y empezar a registrar mensajes en tu aplicacion.

## Configuracion Inicial

### Opcion 1: Configuracion Automatica

La forma mas simple de configurar el logger es usando variables de entorno:

```swift
import Logger

@main
struct EduGoApp: App {
    init() {
        Task {
            await LoggerConfigurator.shared.configureFromEnvironment()
        }
    }
}
```

### Opcion 2: Usar Presets

Si no usas variables de entorno, puedes aplicar un preset directamente:

```swift
// Development (debug level, metadata habilitado)
await LoggerConfigurator.shared.configureDevelopment()

// Production (warning level, metadata deshabilitado)
await LoggerConfigurator.shared.configureProduction()

// Testing (logging deshabilitado)
await LoggerConfigurator.shared.configureTesting()
```

## Uso Basico

### Obtener un Logger

```swift
import Logger

// Desde el registry (recomendado)
let logger = await LoggerRegistry.shared.logger()

// Con categoria especifica
let logger = await LoggerRegistry.shared.logger(for: SystemLogCategory.network)

// Usando factory
let logger = OSLoggerFactory.development()
```

### Registrar Mensajes

```swift
await logger.debug("Informacion detallada de debugging")
await logger.info("Evento informativo")
await logger.warning("Situacion anomala")
await logger.error("Error critico")

// Con categoria
await logger.info("Request completado", category: SystemLogCategory.network)
```

## Variables de Entorno

| Variable | Valores | Default |
|----------|---------|---------|
| `EDUGO_LOG_LEVEL` | debug, info, warning, error | Segun build |
| `EDUGO_LOG_ENABLED` | true, false, 1, 0 | true |
| `EDUGO_LOG_METADATA` | true, false | Segun build |
| `EDUGO_ENVIRONMENT` | development, staging, production | Auto |
| `EDUGO_LOG_SUBSYSTEM` | string | com.edugo.apple |

## Siguiente Paso

Aprende a integrar el logger en tus modulos en <doc:Integration>.
