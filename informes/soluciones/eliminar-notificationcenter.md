# Solucion: Eliminar NotificationCenter

**Problema**: [CON-01 HIGH](../problemas/concurrencia.md) - 9 archivos, 8 usos de NotificationCenter en produccion.

**Resumen**: El proyecto prohibe NotificationCenter. Se usa en 3 areas: SwitchSchoolContextUseCase (emision), AccessibilityPreferences (suscripcion), ReducedMotion/HighContrast (suscripcion Combine implicita).

---

## Solucion A: Migrar cada uso a su alternativa correcta (RECOMENDADA)

### 1. SwitchSchoolContextUseCase -> EventBus/DomainEventBus

**Archivo**: `Packages/Domain/Sources/UseCases/User/SwitchSchoolContextUseCase.swift:439`

**Plan**:
- Reemplazar `NotificationCenter.default.post(name: SchoolContextChangedEvent.notificationName, ...)` con emision via el `EventBus` de CQRS que ya existe en el proyecto
- Crear `SchoolContextChangedEvent` conforme a `DomainEvent`
- Los listeners se suscriben via `EventBus.subscribe()`

### 2. AccessibilityPreferences -> @Environment de SwiftUI

**Archivos**:
- `Packages/Presentation/Sources/DesignSystem/Accessibility/Preferences/AccessibilityPreferences.swift`
- `modulos/DesignSystemSDK/Sources/DesignSystemSDK/Accessibility/Preferences/AccessibilityPreferences.swift`

**Plan**:
- SwiftUI ya trackea cambios de accesibilidad via `@Environment(\.accessibilityReduceMotion)`, `@Environment(\.accessibilityReduceTransparency)`, `@Environment(\.colorSchemeContrast)`
- Reemplazar los 5 `addObserver` por propiedades `@Environment` en las Views
- Si se necesita fuera de SwiftUI views, usar `AsyncStream` wrapping UIAccessibility

### 3. ReducedMotionSupport / HighContrastSupport -> AsyncStream

**Archivos**:
- `Packages/Presentation/Sources/DesignSystem/Accessibility/Motion/ReducedMotionSupport.swift:137`
- `Packages/Presentation/Sources/DesignSystem/Accessibility/Contrast/HighContrastSupport.swift:200`

**Plan**:
- Reemplazar `.onReceive(NotificationCenter.default.publisher(for:))` (que usa Combine implicito) con `.task { for await _ in NotificationCenter.default.notifications(named:) { ... } }` o mejor aun, con `@Environment`

**Archivos a modificar**: 6 archivos (3 en Packages/Presentation, 3 en modulos/DesignSystemSDK)

---

## Solucion Recomendada: A

Razon: Cada uso tiene su alternativa natural. No es un refactor masivo — son cambios puntuales en 6 archivos.
