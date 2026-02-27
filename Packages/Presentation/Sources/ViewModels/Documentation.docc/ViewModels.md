# ``ViewModels``

Capa de presentación con ViewModels @Observable para la aplicación EduGo.

## Overview

El módulo ViewModels implementa la capa de presentación de EduGo siguiendo una arquitectura moderna basada en:

- **@Observable macro** (Swift 6) para observación reactiva de estado
- **@MainActor isolation** para garantizar thread-safety en UI
- **CQRS Mediator pattern** para comunicación con el dominio
- **EventBus** para sincronización entre ViewModels

Todos los ViewModels siguen un patrón consistente que facilita el testing y la mantenibilidad.

### Dependencias del Módulo

```
ViewModels
├── EduGoCommon (Foundation)
├── Models (Domain Models)
├── CQRS (Commands/Queries)
├── UseCases (Business Logic)
├── Roles (Role Management)
└── LocalPersistence (Caching)
```

## Topics

### Fundamentos

- <doc:CreatingAViewModel>
- <doc:ObservablePatterns>
- <doc:MainActorIsolation>

### Integración CQRS

- <doc:MediatorIntegration>
- <doc:EventBusUsage>

### Testing

- <doc:ViewModelTesting>

### ViewModels de Autenticación

- ``LoginViewModel``

### ViewModels de Dashboard

- ``DashboardViewModel``

### ViewModels de Materiales

- ``MaterialListViewModel``
- ``MaterialUploadViewModel``
- ``MaterialAssignmentViewModel``

### ViewModels de Evaluación

- ``AssessmentViewModel``

### ViewModels de Usuario

- ``UserProfileViewModel``
- ``ContextSwitchViewModel``
