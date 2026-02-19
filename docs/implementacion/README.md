# Guia de Implementacion - Extraccion de SDKs

Paso a paso para extraer los SDKs identificados en `docs/modulos/` como proyectos Swift Package independientes.

---

## Fases

### Fase 1: Crear SDKs independientes que compilen
Cada SDK como un Swift Package con su `Package.swift`, codigo fuente, y tests. El objetivo es que cada uno compile y pase tests de forma aislada.

### Fase 2: Proyecto integrador
Un proyecto que importe todos los SDKs como dependencias y demuestre que funcionan juntos.

---

## Orden de Implementacion (Fase 1)

El orden respeta las dependencias entre SDKs. Los que no dependen de nada van primero.

| Paso | SDK | Archivos fuente | Tests existentes | Dependencia de otro SDK |
|------|-----|-----------------|------------------|------------------------|
| 1 | [Foundation Toolkit](01-foundation-toolkit.md) | ~6 | Si (7 tests) | Ninguna |
| 2 | [Logger](02-logger.md) | 12 | Si (completos) | Ninguna |
| 3 | [CQRS + State](03-cqrs-state.md) | ~28 | Parciales | Ninguna |
| 4 | [DesignSystem](04-designsystem.md) | 44 | No | Ninguna |
| 5 | [Forms](05-forms.md) | 12 | No | Ninguna |
| 6 | [Network](06-network.md) | ~12 | Si (completos) | Foundation Toolkit (CodableSerializer) |
| 7 | [UI Components](07-uicomponents.md) | ~35 | No | DesignSystem |
| 8 | [Fase 2: Proyecto Integrador](08-fase2-integrador.md) | - | - | Todos los SDKs |

**Nota:** Navigation SDK no se extrae como independiente (demasiado acoplado al dominio EduGo). Se queda en el proyecto principal.

---

## Estructura de cada SDK

Todos siguen la misma estructura de Swift Package:

```
MiSDK/
  Package.swift
  Sources/
    MiSDK/
      ... archivos .swift
  Tests/
    MiSDKTests/
      ... archivos de test
  README.md
```

---

## Prerequisitos

- Swift 6.2+
- Xcode 16+
- macOS 15+ / iOS 18+ como plataformas target

---

## Convenciones

- Cada documento indica que archivos copiar del proyecto original y que modificaciones hacer
- Los archivos se copian, no se mueven (el proyecto original sigue funcionando mientras se crean los SDKs)
- Cuando un SDK esta listo y compilando, se puede ir reemplazando la implementacion interna del proyecto original por la dependencia del SDK
