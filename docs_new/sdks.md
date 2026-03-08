# SDKs Standalone — EduGo Apple

> Documentacion generada desde analisis directo del codigo fuente (marzo 2026).

---

## 1. Vision General

Ademas de los 7 paquetes principales en `Packages/`, el proyecto incluye 7 SDKs independientes en `modulos/`. Estos SDKs encapsulan el **como** (como loguear, como conectarse, como manejar estado) para que los paquetes principales se enfoquen en el **que** (logica de negocio).

Todos usan `swift-tools-version: 6.2` y soportan iOS 26 / macOS 26.

---

## 2. Grafo de Dependencias

```
FoundationToolkit (base, sin dependencias externas)
    │
    ├── LoggerSDK (independiente)
    │
    ├── NetworkSDK (depende de FoundationToolkit)
    │
    ├── CQRSKit (independiente)
    │
    ├── DesignSystemSDK (independiente)
    │
    ├── FormsSDK (independiente)
    │
    └── UIComponentsSDK (depende de DesignSystemSDK + FormsSDK)
```

---

## 3. Tabla de SDKs

| # | SDK | Estado | Archivos | Dependencias | Descripcion |
|---|-----|--------|----------|-------------|-------------|
| 1 | FoundationToolkit | Completo | ~6 | Ninguna | Protocolos base, errores por capa, entity base, storage |
| 2 | LoggerSDK | Completo | ~12 | Ninguna | Logging profesional con categorias, presets, registry |
| 3 | NetworkSDK | Completo | ~7 | FoundationToolkit | Cliente HTTP con interceptores, auth, retry |
| 4 | CQRSKit | Completo | ~32 | Ninguna | CQRS completo + estado reactivo + buffering + metricas |
| 5 | DesignSystemSDK | Completo | ~35 | Ninguna | Temas, efectos visuales, accesibilidad, Liquid Glass |
| 6 | FormsSDK | Completo | ~11 | Ninguna | Validacion de formularios, field binding, view modifiers |
| 7 | UIComponentsSDK | Completo | ~25 | DesignSystem, Forms | Componentes SwiftUI: botones, forms, navigation, listas |

---

## 4. Detalle por SDK

### 4.1 FoundationToolkit

**Ruta:** `modulos/FoundationToolkit/`

Capa base reutilizable con:
- Protocolos de entidad (`EntityProtocol`, `IdentifiableEntity`)
- Errores tipados por capa
- Abstracciones de storage
- Utilidades de serializacion

```swift
// Package.swift
.library(name: "FoundationToolkit", targets: ["FoundationToolkit"])
// Sin dependencias externas
```

---

### 4.2 LoggerSDK

**Ruta:** `modulos/LoggerSDK/`

Sistema de logging estructurado:
- Categorias predefinidas por subsistema
- Niveles: debug, info, warning, error
- Integracion con `os.Logger` de Apple
- Registry para multiples instancias
- Configuracion por ambiente

---

### 4.3 NetworkSDK

**Ruta:** `modulos/NetworkSDK/`

**Depende de:** FoundationToolkit

Cliente HTTP con patron interceptor:
- `HTTPRequest` builder fluido e inmutable
- Soporte para todos los metodos HTTP
- Interceptores: autenticacion, retry, logging
- Errores tipados con `NetworkError`
- Configuracion de timeout y cache

---

### 4.4 CQRSKit

**Ruta:** `modulos/CQRSKit/`

Framework CQRS completo:
- Command/Query/Event protocols
- Handlers con soporte de actor
- State management reactivo
- Buffering strategies (unbounded, bounded, dropping)
- Metricas de ejecucion
- Integracion con AsyncSequence

**Archivos:** ~32 (el SDK mas grande)

---

### 4.5 DesignSystemSDK

**Ruta:** `modulos/DesignSystemSDK/`

Sistema de diseno completo:
- Temas (claro/oscuro) con soporte Liquid Glass
- Componentes de accesibilidad (Dynamic Type, VoiceOver)
- Efectos visuales nativos de iOS 26
- Tokens de diseno (colores, tipografia, spacing)
- Animaciones y transiciones

**Archivos:** ~35 (segundo mas grande)

---

### 4.6 FormsSDK

**Ruta:** `modulos/FormsSDK/`

Framework de formularios reactivos:
- Validacion declarativa de campos
- Field binding con `@Observable`
- View modifiers para validacion en tiempo real
- Soporte de validacion cruzada entre campos
- Mensajes de error localizados

---

### 4.7 UIComponentsSDK

**Ruta:** `modulos/UIComponentsSDK/`

**Depende de:** DesignSystemSDK, FormsSDK

Biblioteca de componentes SwiftUI:
- Containers (cards, sections, panels)
- Formularios (inputs, selects, switches)
- Navegacion (toolbars, tabs, breadcrumbs)
- Listas (virtualizadas, con busqueda)
- Botones (estilos primario, secundario, destructivo)

---

## 5. Relacion con Packages/

Los SDKs en `modulos/` y los paquetes en `Packages/` comparten conceptos pero son independientes:

| Concepto | modulos/ (SDK) | Packages/ (Principal) |
|----------|---------------|----------------------|
| Logger | `LoggerSDK` | `EduLogger` en Core |
| Network | `NetworkSDK` | `EduNetwork` en Infrastructure |
| CQRS | `CQRSKit` | CQRS en Domain |
| Design | `DesignSystemSDK` | Design system en Presentation |
| Forms | `FormsSDK` | Validators en Presentation |

Los SDKs estan disenados para ser extraibles como paquetes Swift independientes reutilizables en otros proyectos Apple.

---

## 6. Testing

Cada SDK tiene un directorio de tests (`Tests/{SDK}Tests/`), con ~13 archivos de test en total. Los tests principales estan en `Packages/` (~133 archivos, ~2,083 tests).

Para ejecutar tests de un SDK:

```bash
cd modulos/CQRSKit && swift test
cd modulos/NetworkSDK && swift test
```

---

*Generado: marzo 2026 | Basado en analisis directo del codigo fuente*
