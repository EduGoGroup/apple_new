# Analisis de SDKs Extraibles - EduGoModules

Analisis de las piezas de infraestructura reutilizable que pueden extraerse como proyectos/paquetes Swift independientes (SDKs).

**Enfoque:** Cada SDK encapsula un *como* (como loguear, como conectarse, como guardar, como manejar estado) para que el proyecto principal solo se enfoque en el *que* (DTOs, modelos, logica de negocio).

---

## SDKs Identificados

| # | SDK | Estado | Dependencias | Doc |
|---|-----|--------|-------------|-----|
| 1 | [Foundation Toolkit](foundation-toolkit-sdk.md) | Listo (100%) | Foundation | Protocolos base, errores por capa, serialization, storage |
| 2 | [Logger](logger-sdk.md) | Listo (100%) | Foundation + OSLog | Logging profesional con categorias, presets y registry |
| 3 | [Network](network-sdk.md) | Casi listo (80%) | Foundation | Cliente HTTP con interceptores, auth y retry |
| 4 | [Persistence](persistence-sdk.md) | Parcial (60%) | Foundation + SwiftData | SwiftData container, migraciones, concurrencia |
| 5 | [DesignSystem](designsystem-sdk.md) | Listo (100%) | SwiftUI | Temas, efectos visuales, accesibilidad |
| 6 | [CQRS + State](cqrs-state-sdk.md) | Listo framework (70%) | Foundation | CQRS completo + estado reactivo |
| 7 | [UI Components + Forms](uicomponents-forms-sdk.md) | Listo (95%) | SwiftUI | Componentes SwiftUI + formularios reactivos |
| 8 | [Navigation](navigation-sdk.md) | Parcial (80%) | SwiftUI | Coordinadores + deep linking |

---

## Grafo de Dependencias entre SDKs

```
Foundation Toolkit (base, sin dependencias)
    |
    +-- Logger (independiente)
    |
    +-- Network (necesita CodableSerializer del Toolkit)
    |
    +-- Persistence (independiente del Toolkit si se extraen solo utilities)
    |
    +-- CQRS + State (independiente)

DesignSystem (independiente de todo)
    |
    +-- UI Components + Forms (usa DesignTokens del DesignSystem)
    |
    +-- Navigation (independiente del DesignSystem)
```

---

## Fusiones Recomendadas

Dependiendo del nivel de granularidad deseado:

### Opcion A: Granular (8 SDKs)
Cada uno como paquete Swift independiente. Maximo control, minimo acoplamiento.

### Opcion B: Agrupado (4 SDKs)
| SDK Agrupado | Contenido |
|---|---|
| **Core Toolkit** | Foundation Toolkit + Logger + CodableSerializer |
| **Networking** | Network SDK (con su propio serializer) |
| **Architecture** | CQRS + StateManagement + Persistence utilities |
| **UI Kit** | DesignSystem + UI Components + Forms + Navigation |

### Opcion C: Minimo (2 SDKs)
| SDK | Contenido |
|---|---|
| **Infrastructure SDK** | Todo lo de backend: Foundation, Logger, Network, Persistence, CQRS, State |
| **Presentation SDK** | Todo lo de frontend: DesignSystem, Components, Forms, Navigation |

---

## Que se queda en el proyecto EduGo (NO es SDK)

Todo lo que es logica de negocio especifica de EduGo:

| Componente | Ubicacion actual | Razon |
|---|---|---|
| Models (User, Material, School, etc.) | Core/Models | Entidades de dominio EduGo |
| DTOs (MaterialDTO, ProgressDTO, etc.) | Infrastructure/Network/DTOs | Contratos API de EduGo |
| Repositories concretos | Infrastructure/Persistence/Repositories | Implementaciones de EduGo |
| SwiftData Models (@Model) | Infrastructure/Persistence/Models | Esquema BD de EduGo |
| Mappers | Infrastructure/Persistence/Mappers | Mapeo domain<->persistence |
| Commands/Queries concretos | Domain/CQRS/Commands,Queries | Operaciones de negocio |
| Events concretos | Domain/CQRS/Events | Eventos de dominio EduGo |
| StateMachines | Domain/StateManagement/StateMachines | Flujos de negocio |
| UseCases | Domain/UseCases | Logica de negocio |
| Roles/Permisos | Domain/Services/Roles | Sistema de roles EduGo |
| Auth | Domain/Services/Auth | Autenticacion EduGo |
| ViewModels | Presentation/ViewModels | UI logic de EduGo |
| Screen, Deeplink enums | Presentation/Navigation | Pantallas de EduGo |
| Feature Coordinators | Presentation/Navigation | Navegacion de EduGo |

---

## Seccion por documento

Cada documento de SDK tiene las mismas secciones:

- **a) Que hace el SDK** - Funcionalidad y uso tipico
- **b) Compila independiente?** - Estado de compilacion standalone
- **c) Dependencias** - Que necesita el SDK para funcionar
- **d) Fusiones posibles** - Con que otros SDKs podria unirse
- **e) Interfaces publicas** - Contrato/API del SDK
- **f) Personalizacion** - Que adapta el consumidor vs que usa tal cual
