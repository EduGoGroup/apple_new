# Problemas de Arquitectura

## ARQ-01: MEDIUM - Protocolo Entity no utilizado por ningun modelo

**Archivo**: `Packages/Foundation/Sources/EduFoundation/Domain/Entity.swift`

**Descripcion**: El protocolo `Entity` requiere `id: UUID`, `createdAt: Date`, `updatedAt: Date` con `Identifiable, Equatable, Sendable`. Ningun modelo de dominio (User, Role, Permission, Document, School, AcademicUnit, Material, Membership) conforma este protocolo. Cada uno define sus propiedades independientemente.

**Impacto**: Codigo muerto. La Foundation define un contrato que nadie implementa.

---

## ARQ-02: MEDIUM - Protocolo Model no utilizado (codigo muerto)

**Archivo**: `Packages/Core/Sources/Models/Models.swift`

**Descripcion**: Define `Model: Sendable, Codable, Identifiable`. Ningun tipo conforma este protocolo.

---

## ARQ-03: MEDIUM - Duplicacion masiva Infrastructure/Network vs modulos/NetworkSDK

**Archivos duplicados**:
- `Network.swift` (identico excepto imports)
- `HTTPRequest.swift`
- `NetworkClientProtocol.swift`
- `NetworkError.swift`
- Todos los interceptors: `RequestInterceptor.swift`, `RetryPolicy.swift`, `LoggingInterceptor.swift`, `AuthenticationInterceptor.swift`

**Impacto**: Bug fixes en una copia no se propagan a la otra. Divergencia inevitable.

**Recomendacion**: Documentar que modulos/NetworkSDK es la version standalone para el SDK ecosystem, y Packages/Infrastructure es la version de produccion.

---

## ARQ-04: MEDIUM - InterceptableNetworkClient duplica ~90% de NetworkClient

**Archivo**: `Packages/Infrastructure/Sources/Network/Interceptors/InterceptableNetworkClient.swift`

**Descripcion**: Comparten implementaciones casi identicas de `performWithRetry`, `mapNetworkError`, `buildURLRequest`, `validateResponse`, `extractErrorMessage`.

**Recomendacion**: `NetworkClient` ya soporta interceptors. Considerar eliminar `InterceptableNetworkClient` o extraer logica compartida.

---

## ARQ-05: MEDIUM - LogConfiguration.Environment duplica AppEnvironment

**Archivo**: `Packages/Core/Sources/Logger/Configuration/LogConfiguration.swift`

**Descripcion**: Define su propio `Environment` enum identico a `AppEnvironment`. `EnvironmentConfiguration` mapea entre ambos con boilerplate innecesario.

**Recomendacion**: Usar `AppEnvironment` directamente.

---

## ARQ-06: MEDIUM - Logger actor basico vs LoggerRegistry infraestructura completa

**Archivo**: `Packages/Core/Sources/Logger/Logger.swift`

**Descripcion**: Coexisten dos sistemas de logging: un `Logger` actor basico (singleton con `print()`) y una infraestructura completa (LoggerProtocol, OSLoggerAdapter, LoggerRegistry, LoggerConfigurator).

**Recomendacion**: Eliminar el Logger actor basico si esta superseded.
