# Configuracion y Ambientes — EduGo Apple

> Documentacion generada desde analisis directo del codigo fuente (marzo 2026).

---

## 1. Ambientes

La app soporta 3 ambientes, configurados via variable de entorno `EDUGO_ENVIRONMENT`:

| Ambiente | Variable | IAM API | Admin API | Mobile API | Timeout |
|----------|----------|---------|-----------|------------|---------|
| Development | `development` | `localhost:8070` | `localhost:8060` | `localhost:8065` | 30s |
| Staging | `staging` | Azure Container Apps | Azure Container Apps | Azure Container Apps | 60s |
| Production | `production` | `api-iam.edugo.com` | `api.edugo.com` | `api-mobile.edugo.com` | 60s |

**Default:** `staging` en builds DEBUG.

### Deteccion Automatica

```swift
// Apps/DemoApp/Sources/ServiceContainer.swift
init(environment: AppEnvironment = .detect())

// AppEnvironment.detect() lee EDUGO_ENVIRONMENT del env
```

### Variables de Entorno Avanzadas

Se pueden sobrescribir URLs individuales:

```bash
EDUGO_IAM_API_URL=https://custom-iam.example.com
EDUGO_ADMIN_API_URL=https://custom-admin.example.com
EDUGO_MOBILE_API_URL=https://custom-mobile.example.com
EDUGO_API_TIMEOUT=45
```

---

## 2. Comandos de Ejecucion

### Makefile (raiz del proyecto)

```bash
# Ejecutar app
make run              # macOS con staging (default)
make run-dev          # macOS con development (localhost)
make run-prod         # macOS con production
make run ENV=staging  # Especificar ambiente manualmente

# Build y tests
make build            # Compilar sin ejecutar
make test             # Ejecutar TODOS los tests (Packages + modulos)
make clean            # Limpiar artefactos de build

# Utilidades
make info             # Mostrar URLs de cada ambiente
```

### Ejecucion Directa

```bash
# Compilar y ejecutar DemoApp
cd Apps/DemoApp && EDUGO_ENVIRONMENT=staging swift run DemoApp

# Compilar sin ejecutar
cd Apps/DemoApp && swift build

# Tests de un paquete especifico
cd Packages/Core && swift test
cd Packages/Infrastructure && swift test
cd modulos/NetworkSDK && swift test

# Test con filtro
cd Packages/Core && swift test --filter LoginViewModelTests
```

---

## 3. Estructura de Build

### SPM (Swift Package Manager)

El proyecto NO usa Xcode project files (`.xcodeproj`). Todo se maneja via `Package.swift`:

```
apple_new/
├── Package.swift              # Umbrella (EduGoModules)
├── Packages/
│   ├── Foundation/Package.swift
│   ├── Core/Package.swift
│   ├── Infrastructure/Package.swift
│   ├── Domain/Package.swift
│   ├── Presentation/Package.swift
│   ├── Features/Package.swift
│   └── DynamicUI/Package.swift
├── modulos/
│   ├── CQRSKit/Package.swift
│   ├── DesignSystemSDK/Package.swift
│   ├── FormsSDK/Package.swift
│   ├── FoundationToolkit/Package.swift
│   ├── LoggerSDK/Package.swift
│   ├── NetworkSDK/Package.swift
│   └── UIComponentsSDK/Package.swift
└── Apps/
    └── DemoApp/Package.swift  # Executable target
```

### Xcode Workspace

Existe `EduGoModules.xcworkspace` para abrir en Xcode 26, pero no es requerido. SPM CLI (`swift build`, `swift test`, `swift run`) funciona sin Xcode IDE.

### Xcode Schemes

Para desarrollo en Xcode:

1. **DemoApp** — scheme default
2. **DemoApp (Azure)** — con `EDUGO_ENVIRONMENT=staging`
3. **DemoApp (Localhost)** — con `EDUGO_ENVIRONMENT=development`

Configurar via: Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables.

---

## 4. Requisitos del Sistema

| Requisito | Version |
|-----------|---------|
| Swift | 6.2+ |
| Xcode | 26 |
| macOS (desarrollo) | macOS 26+ |
| iOS (deployment) | iOS 26 |
| macOS (deployment) | macOS 26 |
| iPadOS (deployment) | iPadOS 26 |

---

## 5. APIs Backend

La app consume 3 APIs del ecosistema EduGo:

| API | Responsabilidad | Prefijo DataLoader |
|-----|----------------|-------------------|
| IAM Platform | Autenticacion, roles, permisos, sync | `EDUGO_IAM_API_URL` |
| Admin API | CRUD de escuelas, materias, evaluaciones | `admin:` |
| Mobile API | Datos de estudiante, materiales, dashboard | `mobile:` (o sin prefijo) |

### Warm-up de APIs (Azure)

Las APIs en Azure tier free tienen cold start. Script de warm-up:

```bash
./kmp_new/warm-up-apis.sh
```

O esperar ~30-60 segundos en el primer request.

---

## 6. Estructura de Archivos de la App

```
Apps/DemoApp/
├── Package.swift
├── CONFIGURACION_AMBIENTES.md
└── Sources/
    ├── DemoApp.swift              # @main, App routes, lifecycle
    ├── ServiceContainer.swift     # DI container (@MainActor @Observable)
    ├── AppRoute.swift             # Enum: splash, login, main
    ├── SplashView.swift           # Restore session + delta sync
    ├── LoginScreen.swift          # Auth flow
    ├── MainScreen.swift           # Sidebar + content (SDUI)
    ├── DeepLinkHandler.swift      # URL scheme handling
    └── ...
```

---

## 7. CI/CD

### GitHub Actions

El workflow en `.github/workflows/` ejecuta:

1. `swift build` — verificar compilacion
2. `swift test` — ejecutar tests
3. Deploy a Azure Container Apps (staging)

### Validaciones Automaticas

- 0 warnings de deprecacion
- 0 usos de codigo prohibido (`nonisolated`, `@Published`, Combine)
- Todos los tests pasan
- Strict Concurrency Mode habilitado

---

*Generado: marzo 2026 | Basado en analisis directo del codigo fuente*
