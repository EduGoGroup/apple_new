# Problemas de Concurrencia

## CON-01: HIGH - NotificationCenter en codigo de produccion

**Archivos afectados**:

**A) Emision via NotificationCenter.post:**
- `Packages/Domain/Sources/UseCases/User/SwitchSchoolContextUseCase.swift:439`

**B) Suscripciones con addObserver (patron legado):**
- `Packages/Presentation/Sources/DesignSystem/Accessibility/Preferences/AccessibilityPreferences.swift:101-136` (5 suscripciones)

**C) .onReceive con NotificationCenter.publisher (Combine implicito):**
- `Packages/Presentation/Sources/DesignSystem/Accessibility/Motion/ReducedMotionSupport.swift:137`
- `Packages/Presentation/Sources/DesignSystem/Accessibility/Contrast/HighContrastSupport.swift:200`

**D) NotificationCenter en modulos/DesignSystemSDK:**
- `modulos/DesignSystemSDK/Sources/DesignSystemSDK/Accessibility/Preferences/AccessibilityPreferences.swift:101-136`
- `modulos/DesignSystemSDK/Sources/DesignSystemSDK/Accessibility/Contrast/HighContrastSupport.swift:199`
- `modulos/DesignSystemSDK/Sources/DesignSystemSDK/Accessibility/Motion/ReducedMotionSupport.swift:136`

**Descripcion**: 9 archivos, 8 usos en produccion. Viola la regla "No NotificationCenter" del proyecto.

**Ver solucion**: [Eliminar NotificationCenter](../soluciones/eliminar-notificationcenter.md)

---

## CON-02: HIGH - DispatchQueue en produccion (justificado)

**Archivo**: `Packages/Infrastructure/Sources/Network/Connectivity/NetworkObserver.swift:31,59`

**Descripcion**: `NWPathMonitor` requiere un `DispatchQueue`. El handler usa `Task { await self.handlePathUpdate(path) }` para bridge correcto al actor. Violacion justificada por limitacion del API de Apple.

**Recomendacion**: Documentar con comentario. Investigar si iOS 26 ofrece alternativa async.

---

## CON-03: MEDIUM - @unchecked Sendable en produccion

**Archivos**:
1. `Packages/Domain/Sources/CQRS/Events/DomainEvent.swift:86` - `AnyDomainEvent`
2. `Packages/Infrastructure/Sources/Network/Interceptors/InterceptableNetworkClient.swift:404` - `NetworkClientBuilder`

**Riesgo**: `NetworkClientBuilder` tiene estado mutable sin sincronizacion, marcado @unchecked Sendable. Si se comparte entre Tasks, hay data race.

---

## CON-04: MEDIUM - nonisolated = 0 ocurrencias (PASS)

Verificacion completa: grep nonisolated en todos los .swift -> **0 resultados**. Regla cumplida.

---

## CON-05: MEDIUM - Task{} fire-and-forget sin cancellation

**Archivos**:
- `Apps/DemoApp/Sources/DemoApp.swift:71`
- `Apps/DemoApp/Sources/Components/ErrorBoundary.swift:15`
- `Apps/DemoApp/Sources/Screens/MainScreen.swift:48,85,243`
- `Apps/DemoApp/Sources/Renderers/FormPatternRenderer.swift:73,228`
- `Apps/DemoApp/Sources/Renderers/ListPatternRenderer.swift:47,58,83`

**Recomendacion**: Para network calls desde Views, usar `.task { }` modifier de SwiftUI que cancela automaticamente.

---

## CON-06: LOW - ViewModels con @MainActor (PASS)

Todos los 9 ViewModels de produccion tienen @MainActor correctamente.

---

## CON-07: LOW - @Observable correctamente usado (PASS)

- `@Published`: 0 resultados
- `@ObservableObject`: 0 resultados
- `@EnvironmentObject`: 0 resultados
- `@Observable`: 35+ usos correctos
