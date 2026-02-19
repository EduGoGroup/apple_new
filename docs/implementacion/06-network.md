# Paso 6: Network SDK

**Prioridad:** Sexta (depende de Foundation Toolkit para CodableSerializer)
**Dificultad:** Media
**Archivos fuente:** ~12 (excluyendo repos y DTOs de EduGo)
**Tests existentes:** Completos (NetworkTests, InterceptorTests, ErrorHandlingTests)

---

## 1. Crear el proyecto

```bash
mkdir -p NetworkSDK
cd NetworkSDK
swift package init --name NetworkSDK --type library
```

## 2. Configurar Package.swift

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "NetworkSDK",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "NetworkSDK", targets: ["NetworkSDK"])
    ],
    dependencies: [
        // Opcion A: Depender del Foundation Toolkit SDK
        .package(path: "../FoundationToolkit"),
        // Opcion B: Si se publica como paquete remoto
        // .package(url: "https://github.com/tu-org/FoundationToolkit.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "NetworkSDK",
            dependencies: [
                .product(name: "FoundationToolkit", package: "FoundationToolkit")
            ],
            path: "Sources/NetworkSDK"
        ),
        .testTarget(
            name: "NetworkSDKTests",
            dependencies: ["NetworkSDK"],
            path: "Tests/NetworkSDKTests"
        )
    ]
)
```

**Alternativa sin dependencia:** Si prefieres que Network sea 100% independiente, copia `CodableSerializer.swift` directamente dentro del SDK en lugar de depender de FoundationToolkit.

## 3. Copiar archivos fuente

Desde `Packages/Infrastructure/Sources/Network/` copiar **solo lo generico**:

### SI copiar

| Archivo origen | Destino | Modificaciones |
|---|---|---|
| `Core/NetworkClientProtocol.swift` | `Core/NetworkClientProtocol.swift` | Cambiar `import EduCore` por `import FoundationToolkit` (para CodableSerializer) |
| `Core/HTTPRequest.swift` | `Core/HTTPRequest.swift` | Verificar imports |
| `Core/NetworkError.swift` | `Core/NetworkError.swift` | Ninguna |
| `Core/Network.swift` | `Core/Network.swift` | Cambiar `import EduCore` por `import FoundationToolkit` |
| `Interceptors/RequestInterceptor.swift` | `Interceptors/RequestInterceptor.swift` | Ninguna |
| `Interceptors/InterceptableNetworkClient.swift` | `Interceptors/InterceptableNetworkClient.swift` | Cambiar import EduCore |
| `Interceptors/AuthenticationInterceptor.swift` | `Interceptors/AuthenticationInterceptor.swift` | Ninguna |
| `Interceptors/LoggingInterceptor.swift` | `Interceptors/LoggingInterceptor.swift` | Ninguna |
| `Interceptors/RetryPolicy.swift` | `Interceptors/RetryPolicy.swift` | Ninguna |
| `Responses/APIResponse.swift` | `Responses/APIResponse.swift` | Ninguna |
| `Responses/PaginatedResponse.swift` | `Responses/PaginatedResponse.swift` | Ninguna |
| `Responses/EmptyResponse.swift` | `Responses/EmptyResponse.swift` | Ninguna |

### NO copiar (especifico de EduGo)

| Directorio/Archivo | Razon |
|---|---|
| `Repositories/MaterialsRepository.swift` | Repositorio de negocio EduGo |
| `Repositories/ProgressRepository.swift` | Repositorio de negocio EduGo |
| `Repositories/StatsRepository.swift` | Repositorio de negocio EduGo |
| `DTOs/MaterialDTO.swift` | DTO de negocio EduGo |
| `DTOs/ProgressDTO.swift` | DTO de negocio EduGo |
| `DTOs/StatsDTO.swift` | DTO de negocio EduGo |

## 4. Modificaciones clave

### 4.1 Reemplazar import de EduCore

En los 3 archivos que importan `EduCore`, el unico uso es `CodableSerializer`. Cambiar:

```swift
// Antes
import EduCore
// ...
let serializer = CodableSerializer.dtoSerializer

// Despues
import FoundationToolkit
// ...
let serializer = CodableSerializer.dtoSerializer
```

Si elegiste la alternativa sin dependencia (copiar CodableSerializer directamente), entonces no necesitas ningun import externo.

## 5. Compilar

```bash
swift build
```

**Posibles problemas:**
- `CodableSerializer` no encontrado -> verificar que la dependencia de FoundationToolkit esta correcta
- Tipos como `JSONValue` -> verificar si esta en Network o en DTOs. Si esta en DTOs pero es generico, copiarlo al SDK

## 6. Copiar tests

Desde `Packages/Infrastructure/Tests/InfrastructureTests/Network/`:

| Archivo origen | Destino | Modificaciones |
|---|---|---|
| `NetworkTests.swift` | `NetworkTests.swift` | Cambiar imports. Eliminar tests de repos EduGo |
| `NetworkClientTests.swift` | `NetworkClientTests.swift` | Cambiar imports |
| `InterceptorTests.swift` | `InterceptorTests.swift` | Cambiar imports |
| `ErrorHandlingTests.swift` | `ErrorHandlingTests.swift` | Cambiar imports |
| `Mocks/URLProtocolMock.swift` | `Mocks/URLProtocolMock.swift` | Cambiar imports |
| `Mocks/MockNetworkClient.swift` | `Mocks/MockNetworkClient.swift` | Cambiar imports |

**Excluir:** `RepositoriesTests.swift` (tests de repos de EduGo)

## 7. Ejecutar tests

```bash
swift test
```

## 8. Checklist final

- [ ] `swift build` compila sin errores
- [ ] `swift test` pasa todos los tests
- [ ] No contiene repos ni DTOs de EduGo
- [ ] `CodableSerializer` accesible (via FoundationToolkit o copia local)
- [ ] `import EduCore` eliminado de todos los archivos
- [ ] `TokenProvider` es un protocolo que el consumidor implementa
