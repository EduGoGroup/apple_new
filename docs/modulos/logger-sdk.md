# Logger SDK

**Estado de extraccion:** Listo (100% generico)
**Dependencias externas:** Ninguna (solo Foundation + OSLog de Apple)
**Origen en proyecto:** `Packages/Core/Sources/Logger/`

---

## a) Que hace este SDK

Sistema de logging profesional basado en protocolos con soporte para `os.Logger` (Unified Logging System de Apple). Proporciona:

- **LoggerProtocol**: Interfaz async/await para logging con niveles (debug, info, warning, error)
- **Categorias**: Sistema jerarquico de categorias con convenciones de naming configurables
- **Registry centralizado**: Cache de instancias de loggers por categoria (actor thread-safe)
- **Presets de configuracion**: development, staging, production, testing - con niveles por defecto
- **Factory con builder fluido**: Creacion de loggers con configuracion encadenada
- **Categorias dinamicas**: Creacion de categorias en runtime con `DynamicLogCategory` y `CategoryBuilder`

### Uso tipico por el consumidor

```swift
// 1. Configurar al inicio de la app (una linea)
await LoggerConfigurator.shared.applyPreset(.production)

// 2. Registrar categorias propias (opcional)
await LoggerRegistry.shared.register(categories: MisCategoriasCustom.allCategories)

// 3. Usar en cualquier parte
let logger = await LoggerRegistry.shared.logger(for: MiCategoria.auth)
await logger.info("Usuario autenticado")
await logger.error("Fallo de conexion", category: MiCategoria.network)
```

---

## b) Compila como proyecto independiente?

**Si.** Solo depende de frameworks del sistema Apple:
- `Foundation` - Tipos base
- `OSLog` - Unified Logging System

No importa ningun otro modulo del proyecto EduGo.

---

## c) Dependencias si se extrae

| Dependencia | Tipo | Notas |
|---|---|---|
| Foundation | Sistema Apple | Siempre disponible |
| OSLog | Sistema Apple | Siempre disponible |

**Cero dependencias internas.** Es el modulo mas limpio para extraer.

---

## d) Que se fusionaria con este SDK

**Nada.** Este SDK es autocontenido y con responsabilidad unica. No necesita fusionarse con otros modulos.

Podria opcionalmente incluir `CodableSerializer` (actualmente en Core/Utilities) si se quiere un SDK de "herramientas base", pero no es necesario.

---

## e) Interfaces publicas (contrato del SDK)

### Protocolos

```swift
public protocol LoggerProtocol: Sendable {
    func debug(_ message: String, category: LogCategory?, ...) async
    func info(_ message: String, category: LogCategory?, ...) async
    func warning(_ message: String, category: LogCategory?, ...) async
    func error(_ message: String, category: LogCategory?, ...) async
}

public protocol LogCategory: Sendable {
    var identifier: String { get }
    var displayName: String { get }
}
```

### Tipos principales

| Tipo | Rol |
|---|---|
| `LogLevel` | Enum: debug, info, warning, error (Comparable) |
| `LogConfiguration` | Nivel global + overrides por categoria + environment |
| `LogConfigurationPreset` | Enum: development, staging, production, testing |
| `OSLoggerAdapter` | Actor: implementacion sobre os.Logger |
| `OSLoggerFactory` | Factory estatica con builder fluido |
| `LoggerRegistry` | Actor singleton: cache de loggers |
| `LoggerConfigurator` | Actor singleton: configuracion centralizada |
| `DynamicLogCategory` | Struct: categorias creadas en runtime |
| `CategoryBuilder` | Struct: builder para identifiers de categorias |

---

## f) Que necesita personalizar el consumidor

### Minimo (0 configuracion)
```swift
// Funciona out-of-the-box con defaults razonables
let logger = await LoggerRegistry.shared.logger()
await logger.info("Mensaje")
```

### Recomendado
1. **Elegir preset**: `.development` vs `.production` vs custom
2. **Definir categorias propias**: Crear enums que conformen `LogCategory`
3. **Cambiar subsystem base**: Actualmente hardcoded como `"com.edugo.apple"` - parametrizar a `"com.miapp"`

### Que se lleva tal cual vs que adapta

| Componente | Se lleva tal cual? | Adaptacion necesaria |
|---|---|---|
| LoggerProtocol | Si | - |
| LogLevel, LogConfiguration | Si | - |
| OSLoggerAdapter | Si | Cambiar subsystem default |
| OSLoggerFactory | Si | - |
| LoggerRegistry | Si | - |
| LoggerConfigurator | Si | - |
| CategoryBuilder | Si | Cambiar prefijo "com.edugo" |
| StandardLogCategory | No | Son categorias especificas de EduGo (TIER0, Logger, Models). El consumidor define las suyas |
| SystemLogCategory | No | Categorias predefinidas de EduGo |

### Cambios necesarios para portabilidad

1. **Parametrizar subsystem**: `"com.edugo.apple"` -> configurable por el consumidor
2. **Parametrizar prefijo de categorias**: `"com.edugo"` en `CategoryBuilder.build()` -> configurable
3. **Eliminar `StandardLogCategory`**: Son categorias especificas de EduGo. El consumidor crea las suyas
4. **Eliminar `SystemLogCategory`**: Mismo caso

Estimacion de cambios: ~15 lineas de codigo a modificar.
