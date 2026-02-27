# Fase 5: Dashboards Dinámicos por Rol

## Objetivo
Implementar el sistema de dashboards que se adapta al rol del usuario (superadmin, school_admin, teacher, student, guardian), mostrando métricas, estadísticas y accesos directos relevantes.

## Dependencias
- **Fase 3** (Contracts + Orchestrator)
- **Fase 4** (Renderers + CRUD)

## Contexto KMP (referencia)

### Dashboards en KMP
- Cada rol tiene un contrato de dashboard específico con su endpoint de stats
- `DashboardSuperadminContract` → stats globales (total schools, users, materials)
- `DashboardSchoolAdminContract` → stats de la escuela (students, teachers, units)
- `DashboardTeacherContract` → stats del profesor (materials, assessments, students assigned)
- `DashboardStudentContract` → stats del estudiante (progress, assessments pending, materials)
- `DashboardGuardianContract` → stats del guardián (children progress)
- Los dashboards usan `MetricCard` para mostrar cada estadística
- Se cargan desde endpoint de stats + se renderizan con DashboardPatternRenderer

---

## Pasos de Implementación

### Paso 5.1: DashboardPatternRenderer completo

**Paquete**: `Apps/DemoApp/`

**Archivos a modificar:**
- `Renderers/DashboardPatternRenderer.swift`

**Requisitos:**
- Layout adaptativo:
  - **iPhone**: `LazyVGrid` con 2 columnas
  - **iPad/Mac**: `LazyVGrid` con 3-4 columnas
- Renderiza zonas de tipo CONTENT/DASHBOARD:
  - `MetricCardControl`: tarjeta con título, valor numérico, icono, color
  - `ChartControl` (futuro): placeholder para gráficas
- Metric cards con Liquid Glass effect
- Pull-to-refresh para recargar stats
- Loading skeleton mientras carga

---

### Paso 5.2: MetricCardControl mejorado

**Paquete**: `Apps/DemoApp/`

**Archivos a crear/modificar:**
- `Renderers/Controls/MetricCardControl.swift`

**Requisitos:**
- `MetricCardControl(slot: Slot, data: [String: JSONValue])`:
  - Título desde `slot.label` o `slot.bind` → `data[bind].stringValue`
  - Valor numérico desde `data[slot.field]`
  - Icono desde `slot.icon` → SF Symbol mapeado
  - Color de acento (opcional)
  - Layout:
    ```
    ┌──────────────────┐
    │ 📊  Estudiantes  │
    │                  │
    │     1,234        │
    │                  │
    │  ▲ +12% vs prev │
    └──────────────────┘
    ```
  - Liquid Glass background
  - Animación de entrada (fade + scale)
  - Tap → navegación a la lista del recurso (si definido en slot.eventId)

---

### Paso 5.3: Dashboard routing por rol

**Paquete**: `Apps/DemoApp/`

**Archivos a crear:**
- `Screens/DashboardScreen.swift`

**Requisitos:**
- Al cargar el dashboard desde el menú:
  1. Determinar screenKey basado en rol activo:
     - `superadmin` → `"dashboard:superadmin"`
     - `school_admin` → `"dashboard:school_admin"`
     - `teacher` → `"dashboard:teacher"`
     - `student` → `"dashboard:student"`
     - `guardian` → `"dashboard:guardian"`
  2. Cargar screen definition desde ScreenLoader (ya pre-cargado desde sync bundle)
  3. EventOrchestrator ejecuta `.loadData` con el contrato del dashboard
  4. DashboardPatternRenderer renderiza las metric cards

- Si el usuario no tiene un dashboard definido para su rol → mostrar dashboard genérico con mensaje de bienvenida

---

### Paso 5.4: Stats DTO refinado

**Paquete**: `Packages/Core/Sources/Models/`

**Archivos a crear/modificar:**
- `DTOs/Stats/GlobalStatsDTO.swift`

**Requisitos:**
- DTO que decodifica la respuesta de `/api/v1/stats/global`:
  ```swift
  struct GlobalStatsDTO: Codable, Sendable {
      let totalSchools: Int?
      let totalUsers: Int?
      let totalStudents: Int?
      let totalTeachers: Int?
      let totalMaterials: Int?
      let totalAssessments: Int?
      let totalUnits: Int?
      // ... otros campos según el backend

      enum CodingKeys: String, CodingKey {
          case totalSchools = "total_schools"
          case totalUsers = "total_users"
          // ...
      }
  }
  ```
- El DataLoader ya normaliza la respuesta a `[String: JSONValue]`, así que los slots del dashboard resuelven directamente via binding

---

### Paso 5.5: Quick Actions en Dashboard

**Paquete**: `Apps/DemoApp/`

**Archivos a crear:**
- `Renderers/Controls/QuickActionControl.swift`

**Requisitos:**
- Sección de acciones rápidas debajo de las métricas:
  - Botones/tarjetas para acciones frecuentes según rol:
    - Admin: "Crear escuela", "Agregar usuario"
    - Teacher: "Subir material", "Crear evaluación"
    - Student: "Ver materiales", "Evaluaciones pendientes"
  - Cada acción navega a la pantalla CRUD correspondiente
  - Solo muestra acciones donde el usuario tiene permiso
  - Definidas en el template de la pantalla (zonas de tipo ACTION_GROUP)

---

### Paso 5.6: Tests de Fase 5

**Tests manuales/visuales:**
- Login como superadmin → dashboard muestra stats globales
- Login como teacher → dashboard muestra stats del profesor
- Login como student → dashboard muestra progreso del estudiante
- Tap en metric card → navega a la lista correspondiente
- Pull-to-refresh → recarga stats
- Dashboard se adapta al tamaño de pantalla (2 cols iPhone, 3-4 cols iPad)

---

## Criterios de Completitud

- [ ] Dashboard rendering con grid adaptativo de metric cards
- [ ] MetricCard con Liquid Glass, icono, valor, trend
- [ ] Dashboard correcto por rol (5 variantes)
- [ ] Stats se cargan desde API y se muestran
- [ ] Quick actions con permisos RBAC
- [ ] Pull-to-refresh funciona
- [ ] Layout adaptativo (iPhone vs iPad vs Mac)
- [ ] `make build` sin errores
- [ ] `make test` sin fallos
