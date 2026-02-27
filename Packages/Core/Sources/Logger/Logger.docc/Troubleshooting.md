# Troubleshooting

Guia para resolver problemas comunes con el sistema de logging.

## Overview

Esta guia cubre los problemas mas frecuentes y sus soluciones.

## Logs No Aparecen

### Verificar Configuracion

```swift
// Verificar estado actual
let enabled = await LoggerConfigurator.shared.isEnabled
let level = await LoggerConfigurator.shared.globalLevel

print("Logging enabled: \(enabled)")
print("Global level: \(level)")
```

### Soluciones

1. **Verificar que logging esta habilitado**:
```swift
await LoggerConfigurator.shared.setEnabled(true)
```

2. **Verificar nivel minimo**:
```swift
// Si estas loggeando .debug pero nivel es .warning
await LoggerConfigurator.shared.setGlobalLevel(.debug)
```

3. **Verificar categoria**:
```swift
// Asegurar que la categoria esta registrada
await LoggerRegistry.shared.register(category: myCategory)
```

## Variables de Entorno No Funcionan

### Verificar en Xcode

1. **Product > Scheme > Edit Scheme**
2. **Run > Arguments > Environment Variables**
3. Asegurar que las variables estan activas (checkbox)

### Verificar Programaticamente

```swift
let envConfig = EnvironmentConfiguration.load()
print(envConfig)  // Muestra configuracion detectada
```

## Console.app No Muestra Logs

### Filtros Correctos

- Subsystem: `subsystem:com.edugo.apple`
- Categoria: `category:com.edugo.tier1.logger`
- Combinar: `subsystem:com.edugo.apple AND category:login`

### Habilitar Niveles

En Console.app:
1. **Action > Include Info Messages**
2. **Action > Include Debug Messages**

## Performance Issues

### Sintomas

- App lenta durante logging intensivo
- UI freezing

### Soluciones

1. **Deshabilitar metadata**:
```swift
await LoggerConfigurator.shared.setIncludeMetadata(false)
```

2. **Aumentar nivel minimo**:
```swift
await LoggerConfigurator.shared.setGlobalLevel(.warning)
```

3. **Evitar logging en loops**:
```swift
// MAL
for item in items {
    await logger.debug("Processing \(item)")
}

// BIEN
await logger.debug("Processing \(items.count) items")
```

## Tests Fallan

### MockLogger No Captura

```swift
// Asegurar que usas await
await logger.info("message")

// Verificar despues de la operacion
let hasLog = await mockLogger.contains(level: .info)
```

### Logs Interfieren con Tests

```swift
override func setUp() async throws {
    await LoggerConfigurator.shared.configureTesting()
}
```

## FAQ

### Como cambio el subsystem?

```swift
let logger = OSLoggerFactory.custom(
    globalLevel: .info,
    subsystem: "com.mycompany.myapp"
)
```

### Como loggeo solo para una categoria?

```swift
await LoggerConfigurator.shared.setGlobalLevel(.error)
await LoggerConfigurator.shared.setLevel(.debug, for: MyCategory.specific)
```

### Como deshabilito logging temporalmente?

```swift
await LoggerConfigurator.shared.setEnabled(false)
// ... codigo sin logs ...
await LoggerConfigurator.shared.setEnabled(true)
```

## Contacto

Si el problema persiste, consulta la documentacion de arquitectura en <doc:Architecture> o contacta al equipo de EduGo.
