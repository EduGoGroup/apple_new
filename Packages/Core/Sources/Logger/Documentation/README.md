# Logger Module Documentation

Sistema de logging centralizado para EduGo Apple Modules basado en `os.Logger` de Apple con soporte completo para Swift 6.2 Strict Concurrency.

---

## Documentación Disponible

### 🚀 Para Empezar

**[QuickStart.md](QuickStart.md)** - Guía de inicio rápido
- Instalación y configuración inicial
- Uso básico en 3 pasos
- Configuración por environment
- Ejemplos prácticos
- **Empieza aquí si es tu primera vez usando Logger**

### 📐 Arquitectura y Diseño

**[Architecture.md](Architecture.md)** - Documentación técnica completa
- Visión general del sistema
- Componentes core (LoggerProtocol, OSLoggerAdapter, LoggerRegistry)
- Patrones de diseño (Protocol-Oriented, Actor-based, Builder)
- Flujo de datos
- Decisiones de arquitectura
- Extensibilidad y roadmap

### 🔧 Integración

**[Integration.md](Integration.md)** - Guía paso a paso de integración
- Integración en módulos nuevos (TIER 0-4)
- Patrones de Dependency Injection
- Configuración por tier
- Migración de código existente
- Testing con Logger
- Checklist de integración completa

### 📂 Categorías

**[CategoryGuide.md](CategoryGuide.md)** - Guía de categorías de logging
- Sistema de naming conventions (`com.edugo.tier<N>.<module>.<component>`)
- Categorías predefinidas por tier (TIER 0-1)
- Crear categorías custom
- CategoryBuilder y DynamicLogCategory
- Validación y mejores prácticas
- Ejemplos por tier

### ✅ Mejores Prácticas

**[BestPractices.md](BestPractices.md)** - Guía de mejores prácticas
- Qué loggear y qué no loggear
- Uso apropiado de log levels
- Escribir mensajes efectivos
- Optimización de performance
- Seguridad y redacción de datos sensibles
- Testing con MockLogger
- Anti-patterns a evitar
- Code review checklist

### 🔍 Troubleshooting

**[Troubleshooting.md](Troubleshooting.md)** - Solución de problemas
- Logs no aparecen
- Configuración de entorno no funciona
- Cómo usar Console.app
- Problemas de performance
- Errores de concurrencia
- Integración fallida
- Tests fallando
- FAQ (7 preguntas frecuentes)
- Herramientas de diagnóstico

---

## Flujo de Lectura Recomendado

### Para Desarrolladores Nuevos
1. **[QuickStart.md](QuickStart.md)** - Entender los conceptos básicos
2. **[CategoryGuide.md](CategoryGuide.md)** - Aprender sobre categorías
3. **[BestPractices.md](BestPractices.md)** - Escribir buen código de logging
4. **[Troubleshooting.md](Troubleshooting.md)** - Tener como referencia

### Para Integrar en un Módulo Nuevo
1. **[Integration.md](Integration.md)** - Seguir la guía paso a paso
2. **[CategoryGuide.md](CategoryGuide.md)** - Crear categorías apropiadas
3. **[BestPractices.md](BestPractices.md)** - Implementar correctamente

### Para Arquitectura y Diseño
1. **[Architecture.md](Architecture.md)** - Entender el diseño completo
2. **[Integration.md](Integration.md)** - Patrones de integración
3. **[BestPractices.md](BestPractices.md)** - Decisiones de diseño

### Para Debugging
1. **[Troubleshooting.md](Troubleshooting.md)** - Resolver el problema
2. **[QuickStart.md](QuickStart.md)** - Verificar configuración básica
3. **[CategoryGuide.md](CategoryGuide.md)** - Validar categorías

---

## Ejemplos Rápidos

### Uso Básico
```swift
import Logger

// 1. Obtener logger
let logger = await LoggerRegistry.shared.logger()

// 2. Loggear con categoría
await logger.info("User logged in", category: StandardLogCategory.TIER0.authentication)

// 3. Loggear error con contexto
await logger.error(
    "Failed to save user: \(error.localizedDescription)",
    category: StandardLogCategory.TIER0.repository
)
```

### Configuración Inicial
```swift
@main
struct MyApp: App {
    init() {
        Task {
            // Configurar desde variables de entorno
            await LoggerConfigurator.shared.configureFromEnvironment()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Testing con MockLogger
```swift
@Test func testUserLogin() async {
    let mockLogger = MockLogger()
    let service = UserService(logger: mockLogger)
    
    await service.login(username: "test")
    
    let hasLog = await mockLogger.contains(
        level: .info,
        message: "User logged in",
        category: StandardLogCategory.TIER0.authentication
    )
    #expect(hasLog)
}
```

---

## Características Principales

### ✨ Características Core
- **Protocol-Oriented Design**: Abstracción con `LoggerProtocol`
- **Thread-Safe**: Implementación basada en actors
- **Swift 6.2 Strict Concurrency**: Compliance completo
- **os.Logger Integration**: Usa el sistema de logging de Apple
- **Environment-Aware**: Configuración automática por entorno
- **Dynamic Configuration**: Cambios de configuración en runtime
- **34+ Categorías Predefinidas**: Para TIER 0-1 modules
- **MockLogger para Testing**: Testing fácil y confiable

### 🎯 Niveles de Logging
```swift
.debug    // Desarrollo detallado
.info     // Eventos importantes
.warning  // Situaciones inesperadas pero manejables
.error    // Errores que requieren atención
```

### 🏗️ Arquitectura de Tiers
```
TIER-0 (Foundation) → EduGoCommon
TIER-1 (Core)       → Logger, Models, etc.
TIER-2 (Infrastructure)
TIER-3 (Domain)
TIER-4 (Features)
```

### 🌍 Environments
```swift
.development  // Debug completo, metadata incluida
.staging      // Info+, metadata incluida
.production   // Info+, sin metadata
.testing      // Warning+, optimizado para tests
```

---

## Variables de Entorno

Logger soporta las siguientes variables de entorno:

| Variable | Valores | Default | Descripción |
|----------|---------|---------|-------------|
| `EDUGO_LOG_ENABLED` | `true`, `false`, `1`, `0` | `true` | Habilitar/deshabilitar logging |
| `EDUGO_LOG_LEVEL` | `debug`, `info`, `warning`, `error` | Environment-dependent | Nivel mínimo de logging |
| `EDUGO_LOG_METADATA` | `true`, `false`, `1`, `0` | Environment-dependent | Incluir file/line/function |
| `EDUGO_ENVIRONMENT` | `development`, `staging`, `production`, `testing` | `development` | Environment activo |
| `EDUGO_LOG_SUBSYSTEM` | String | `com.edugo` | Subsystem para os.Logger |

### Configurar en Xcode
1. Product → Scheme → Edit Scheme
2. Run → Arguments → Environment Variables
3. Añadir las variables necesarias

---

## Comandos Útiles

### Ver logs en tiempo real (macOS)
```bash
log stream --predicate 'subsystem == "com.edugo"'
```

### Filtrar por categoría
```bash
log stream --predicate 'category == "com.edugo.tier1.logger.system"'
```

### Ver logs de un device conectado
```bash
# Listar devices
xcrun xctrace list devices

# Ver logs del device
log stream --device <device-id> --predicate 'subsystem == "com.edugo"'
```

### Ejecutar tests con logging debug
```bash
EDUGO_LOG_LEVEL=debug swift test
```

---

## Recursos Adicionales

### Archivos Importantes
- `LoggerProtocol.swift` - Protocolo base del sistema
- `OSLoggerAdapter.swift` - Implementación con os.Logger
- `LoggerRegistry.swift` - Singleton para gestión centralizada
- `LoggerConfigurator.swift` - Configuración dinámica
- `StandardLogCategory.swift` - Categorías predefinidas
- `MockLogger.swift` - Mock para testing

### Tests
- 87 tests unitarios en el módulo Logger
- Cobertura estimada: 85-90%
- Suite: `swift test --package-path TIER-1-Core/Logger`

### External Links
- [Apple os.Logger Documentation](https://developer.apple.com/documentation/os/logger)
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [Swift Testing Framework](https://developer.apple.com/documentation/testing)

---

## Contribuir

### Agregar Nueva Categoría
1. Abrir `StandardLogCategory.swift`
2. Añadir en el enum correspondiente al tier
3. Seguir naming convention: `com.edugo.tier<N>.<module>.<component>`
4. Documentar en `CategoryGuide.md`

### Agregar Nueva Configuración
1. Extender `LogConfiguration` con nueva propiedad
2. Actualizar `EnvironmentConfiguration` para parsear variable de entorno
3. Documentar en `QuickStart.md` y `Architecture.md`

### Reportar Issues
- Usar el script de diagnóstico de `Troubleshooting.md`
- Incluir versión de Swift/Xcode
- Incluir output de Console.app
- Describir pasos para reproducir

---

## FAQ Rápido

**P: ¿Cómo empiezo a usar Logger?**
R: Lee [QuickStart.md](QuickStart.md), son solo 3 pasos.

**P: ¿Mis logs no aparecen?**
R: Consulta la sección 1 de [Troubleshooting.md](Troubleshooting.md).

**P: ¿Cómo creo categorías para mi módulo?**
R: Sigue la guía en [CategoryGuide.md](CategoryGuide.md).

**P: ¿Cómo testeo código que usa Logger?**
R: Usa `MockLogger`, ver [Integration.md](Integration.md) sección 5.

**P: ¿Logger afecta la performance?**
R: Mínimamente. Ver optimizaciones en [BestPractices.md](BestPractices.md) sección 5.

**P: ¿Puedo usar Logger en extensiones (widgets)?**
R: Sí, ver FAQ en [Troubleshooting.md](Troubleshooting.md) sección 9.

---

## Versión

**Logger Module Version**: 1.0.0
**Swift Version**: 6.2+
**Platform**: macOS 13+, iOS 16+, tvOS 16+, watchOS 9+
**Last Updated**: 2026-01-27

---

## Licencia

Parte del proyecto EduGo Apple Modules.
Propiedad de EduGo Platform Team.

---

## Contacto

Para preguntas, issues o contribuciones, contacta al EduGo Platform Team.

---

**Tip**: Marca esta página para acceso rápido a toda la documentación del Logger module.
