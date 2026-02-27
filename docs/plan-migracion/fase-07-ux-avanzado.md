# Fase 7: UX Avanzado — Stale Data, Skeleton, Toolbar Dinámico

## Objetivo
Implementar mejoras de UX que diferencian una app nativa premium: indicadores de datos stale, skeleton loaders para loading states, toolbar dinámico contextual, y refinamientos visuales con Liquid Glass.

## Dependencias
- **Fase 2** (Offline-First)
- **Fase 4** (Renderers + CRUD)

---

## Pasos de Implementación

### Paso 7.1: StaleDataIndicator

**Paquete**: `Packages/Presentation/Sources/`

**Archivos a crear:**
- `Components/Feedback/EduStaleDataIndicator.swift`

**Requisitos:**
- Badge sutil que indica cuándo los datos vienen de cache:
  ```
  ┌─────────────────────────────────────────┐
  │ 🕐 Datos de hace 5 min · Tap para actualizar │
  └─────────────────────────────────────────┘
  ```
- Aparece debajo del toolbar/search bar cuando `isStale == true`
- Muestra tiempo relativo desde última sincronización ("hace 2 min", "hace 1 hora")
- Tap → ejecutar refresh
- Fade in/out con animación
- Estilo: fondo amarillo/ámbar translúcido, texto pequeño
- Usar `RelativeDateTimeFormatter` para el texto temporal
- Dismissable manualmente

---

### Paso 7.2: Skeleton Loaders específicos por patrón

**Paquete**: `Packages/Presentation/Sources/`

**Archivos a crear:**
- `Components/Loading/EduListSkeleton.swift`
- `Components/Loading/EduFormSkeleton.swift`
- `Components/Loading/EduDashboardSkeleton.swift`
- `Components/Loading/EduDetailSkeleton.swift`

**Requisitos:**
- **EduListSkeleton**: Simula lista con 5-8 rows skeleton
  - Cada row: rectángulo para avatar + 2 líneas de texto animadas
  - Animación de shimmer (gradient que se mueve de izquierda a derecha)
  - Se adapta al ancho de pantalla

- **EduFormSkeleton**: Simula formulario
  - 4-6 campos: rectángulo label + rectángulo input
  - Botón de guardar al final (rectángulo más ancho)
  - Shimmer animation

- **EduDashboardSkeleton**: Simula grid de metric cards
  - 4-6 cards en grid (2 cols iPhone, 3 cols iPad)
  - Cada card: icono circular + texto + número
  - Shimmer animation

- **EduDetailSkeleton**: Simula vista de detalle
  - Header con avatar + nombre
  - 4-6 filas de label + valor
  - Shimmer animation

- Todos usan `EduSkeletonLoader` base existente como building block
- Animación con `Animation.linear(duration: 1.5).repeatForever(autoreverses: false)`
- Liquid Glass background en las cards skeleton

---

### Paso 7.3: Integrar skeletons en PatternRouter

**Paquete**: `Apps/DemoApp/`

**Archivos a modificar:**
- `Renderers/PatternRouter.swift`
- `Renderers/ListPatternRenderer.swift`
- `Renderers/FormPatternRenderer.swift`
- `Renderers/DashboardPatternRenderer.swift`
- `Renderers/DetailPatternRenderer.swift`

**Requisitos:**
- Cada renderer muestra su skeleton correspondiente durante `ScreenState.loading`:
  ```swift
  // En ListPatternRenderer:
  switch viewModel.screenState {
  case .loading:
      EduListSkeleton()
  case .loaded(let screen):
      // ... renderizar contenido
  case .error(let error):
      EduErrorStateView(error: error, onRetry: { viewModel.retry() })
  case .empty:
      EduEmptyStateView(message: EduStrings.emptyList)
  }
  ```
- Transición suave de skeleton → contenido con `.transition(.opacity)`

---

### Paso 7.4: Toolbar dinámico mejorado

**Paquete**: `Packages/Presentation/Sources/`

**Archivos a modificar:**
- `Components/Navigation/EduDynamicToolbar.swift` (de fase 1)

**Requisitos:**
- Mejoras sobre fase 1:
  - **Badge de pending mutations**: si hay mutaciones pendientes, mostrar badge naranja con count en el toolbar
  - **Search expandible**: en modo LIST, la búsqueda empieza colapsada (solo icono) y se expande al tap
  - **Animación de transición**: al cambiar entre patrones, el toolbar anima suavemente
  - **Breadcrumbs**: en modo EXPANDED (iPad/Mac), mostrar ruta de navegación: "Inicio > Escuelas > Editar Escuela"
  - **Acciones contextuales**: en DETAIL, mostrar menú "..." con opciones (editar, eliminar, compartir) según permisos
  - Liquid Glass para fondo del toolbar

---

### Paso 7.5: Pull-to-refresh con haptic feedback

**Paquete**: `Apps/DemoApp/`

**Archivos a modificar:**
- `Renderers/ListPatternRenderer.swift`
- `Renderers/DashboardPatternRenderer.swift`

**Requisitos:**
- `.refreshable {}` con feedback háptico al completar:
  ```swift
  .refreshable {
      await viewModel.executeEvent(.refresh)
      // Haptic feedback nativo
      let generator = UINotificationFeedbackGenerator()
      generator.notificationOccurred(.success)
  }
  ```
- Mostrar timestamp de última actualización después del refresh
- Si offline → mostrar toast "Sin conexión, mostrando datos en caché"

---

### Paso 7.6: Snackbar/Toast para feedback de acciones

**Paquete**: `Packages/Presentation/Sources/`

**Archivos a modificar:**
- `Components/Feedback/EduToast.swift`

**Requisitos:**
- Mejorar el EduToast existente:
  - Tipos: `.success`, `.error`, `.warning`, `.info`
  - Auto-dismiss configurable (3s por defecto)
  - Animación desde abajo con spring
  - Liquid Glass background
  - Swipe to dismiss
  - Integrar con `EventResult`:
    - `.success(message)` → toast verde
    - `.error(message)` → toast rojo
    - `.permissionDenied` → toast naranja "Sin permiso"
    - `.navigateTo` → no toast (navegación)
- `@MainActor @Observable class ToastManager`:
  - `func show(_ message: String, type: ToastType)`
  - `var currentToast: Toast?`
  - Inyectar vía `@Environment`

---

### Paso 7.7: Confirmación de acciones destructivas

**Paquete**: `Apps/DemoApp/`

**Archivos a crear:**
- `Renderers/ConfirmationDialog.swift`

**Requisitos:**
- Antes de ejecutar `.delete`:
  - Mostrar `confirmationDialog` nativo de SwiftUI
  - Título: "¿Eliminar {nombre}?"
  - Mensaje: "Esta acción no se puede deshacer"
  - Botón destructivo: "Eliminar"
  - Botón cancel: "Cancelar"
- Solo proceder si el usuario confirma
- Usar `.confirmationDialog()` modifier de SwiftUI

---

### Paso 7.8: Empty States mejorados

**Paquete**: `Packages/Presentation/Sources/`

**Archivos a modificar:**
- `Components/Lists/EduEmptyStateView.swift`

**Requisitos:**
- Empty state contextual según el tipo de pantalla:
  - Lista sin resultados de búsqueda: "No se encontraron resultados para '{query}'"
  - Lista vacía (sin datos): "No hay {glossary.resource_plural} todavía" + botón "Crear" si permiso
  - Dashboard sin datos: "Aún no hay datos disponibles"
  - Error de red: icono de wifi + "No se pudieron cargar los datos" + botón retry
- Ilustración/icono grande (SF Symbol) + texto + acción
- Liquid Glass card centrada

---

### Paso 7.9: Tests de Fase 7

**Tests manuales/visuales:**
- Activar modo avión → StaleDataIndicator aparece
- Loading de lista → muestra skeleton → transiciona a contenido
- Guardar formulario → toast verde "Guardado exitosamente"
- Intentar acción sin permiso → toast naranja "Sin permiso"
- Eliminar item → confirmación dialog → toast de éxito/error
- Buscar en lista → expandir campo → resultados filtrados → empty state si no hay
- Badge de pending mutations visible en toolbar offline
- Pull-to-refresh con haptic feedback

---

## Criterios de Completitud

- [ ] StaleDataIndicator muestra tiempo relativo y es tappable
- [ ] Skeleton loaders para List, Form, Dashboard, Detail
- [ ] Transición suave skeleton → contenido
- [ ] Toolbar dinámico con badges, search expandible, breadcrumbs
- [ ] Pull-to-refresh con haptic feedback
- [ ] Toast/Snackbar para feedback de acciones (success/error/warning)
- [ ] Confirmación para acciones destructivas
- [ ] Empty states contextuales con acción
- [ ] `make build` sin errores
- [ ] `make test` sin fallos
