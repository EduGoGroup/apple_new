# Fase 6: i18n + Glosario Dinámico

## Objetivo
Implementar el sistema de internacionalización de 2 capas (local + server-driven) y el glosario dinámico que permite a cada institución personalizar su terminología.

## Dependencias
- **Fase 0** (Sync Bundle contiene glossary y strings)

## Contexto KMP (referencia)

### i18n en KMP — 2 capas
- **L1 (Local)**: `composeResources` con archivos de strings:
  - `values/` (English fallback)
  - `values-es/` (Spanish base)
  - `values-pt-rBR/` (Portuguese)
  - 43 strings framework: Guardar, Cancelar, Eliminar, acciones, conectividad, formularios
- **L2 (Server)**: Strings del sync bundle:
  - Títulos de pantalla (`page_title`, `edit_title`)
  - Labels de campos
  - Mensajes de acción
  - Pre-traducidos por el backend según locale del usuario

### Glosario Dinámico en KMP
- Problema: cada institución usa terminología diferente
- `concept_types` → templates de terminología
- `school_concepts` → personalización por escuela
- Term keys: `unit.level1`, `unit.level2`, `member.student`, `member.teacher`, etc.
- Sync bundle incluye bucket `glossary`: `[String: String]` (term_key → term_value)
- `GlossaryProvider` resuelve términos en la UI

---

## Pasos de Implementación

### Paso 6.1: Strings locales del framework

**Paquete**: `Packages/Presentation/Sources/`

**Archivos a crear:**
- `Localization/EduStrings.swift`

**Requisitos:**
- Usar `String(localized:)` de Swift (nativo iOS 26, sin bibliotecas externas):
  ```swift
  enum EduStrings {
      // Acciones
      static let save = String(localized: "action.save", defaultValue: "Guardar")
      static let cancel = String(localized: "action.cancel", defaultValue: "Cancelar")
      static let delete = String(localized: "action.delete", defaultValue: "Eliminar")
      static let edit = String(localized: "action.edit", defaultValue: "Editar")
      static let create = String(localized: "action.create", defaultValue: "Crear")
      static let search = String(localized: "action.search", defaultValue: "Buscar")
      static let retry = String(localized: "action.retry", defaultValue: "Reintentar")
      static let back = String(localized: "action.back", defaultValue: "Volver")
      static let close = String(localized: "action.close", defaultValue: "Cerrar")
      static let confirm = String(localized: "action.confirm", defaultValue: "Confirmar")
      static let logout = String(localized: "action.logout", defaultValue: "Cerrar sesión")

      // Conectividad
      static let offline = String(localized: "connectivity.offline", defaultValue: "Sin conexión")
      static let syncing = String(localized: "connectivity.syncing", defaultValue: "Sincronizando...")
      static let synced = String(localized: "connectivity.synced", defaultValue: "Sincronizado")

      // Formularios
      static let requiredField = String(localized: "form.required", defaultValue: "Campo requerido")
      static let invalidEmail = String(localized: "form.invalidEmail", defaultValue: "Email inválido")
      static let saveSuccess = String(localized: "form.saveSuccess", defaultValue: "Guardado exitosamente")
      static let deleteConfirmTitle = String(localized: "form.deleteConfirmTitle", defaultValue: "¿Eliminar?")
      static let deleteConfirmMessage = String(localized: "form.deleteConfirmMessage", defaultValue: "Esta acción no se puede deshacer")

      // Estados
      static let loading = String(localized: "state.loading", defaultValue: "Cargando...")
      static let emptyList = String(localized: "state.emptyList", defaultValue: "No hay elementos")
      static let errorOccurred = String(localized: "state.error", defaultValue: "Ocurrió un error")
      static let noPermission = String(localized: "state.noPermission", defaultValue: "Sin permiso para esta acción")

      // Auth
      static let loginTitle = String(localized: "auth.loginTitle", defaultValue: "Iniciar sesión")
      static let email = String(localized: "auth.email", defaultValue: "Correo electrónico")
      static let password = String(localized: "auth.password", defaultValue: "Contraseña")
      static let loginButton = String(localized: "auth.loginButton", defaultValue: "Ingresar")
      static let loginError = String(localized: "auth.loginError", defaultValue: "Credenciales inválidas")

      // Navigation
      static let settings = String(localized: "nav.settings", defaultValue: "Configuración")
      static let dashboard = String(localized: "nav.dashboard", defaultValue: "Inicio")
      static let selectSchool = String(localized: "nav.selectSchool", defaultValue: "Seleccionar escuela")
  }
  ```

- Crear archivos `.xcstrings` (String Catalogs de Xcode) para:
  - Español (es) — idioma base
  - Inglés (en)
  - Portugués (pt-BR)

**Verificar:** `make build`

---

### Paso 6.2: ServerStringResolver (L2)

**Paquete**: `Packages/Domain/Sources/`

**Archivos a crear:**
- `Services/i18n/ServerStringResolver.swift`

**Requisitos:**
- `@MainActor @Observable class ServerStringResolver`:
  - `var serverStrings: [String: String]` — strings del sync bundle
  - `func resolve(key: String, fallback: String) -> String`:
    - Busca en `serverStrings[key]`
    - Si no encuentra → retorna `fallback`
  - `func updateFromBundle(_ bundle: UserDataBundle)`:
    - Extrae `bundle.strings` y actualiza `serverStrings`
  - Usado para: page_title, edit_title, field labels que vienen del backend
  - Los strings del servidor ya vienen pre-traducidos al locale del usuario

**Verificar:** `cd Packages/Domain && swift test`

---

### Paso 6.3: GlossaryProvider

**Paquete**: `Packages/Domain/Sources/`

**Archivos a crear:**
- `Services/i18n/GlossaryProvider.swift`
- `Services/i18n/GlossaryKey.swift`

**Requisitos:**
- `GlossaryKey` — llaves tipadas para terminología:
  ```swift
  enum GlossaryKey: String, CaseIterable, Sendable {
      // Organización
      case orgNameSingular = "org.name_singular"
      case orgNamePlural = "org.name_plural"

      // Unidades académicas
      case unitLevel1 = "unit.level1"        // "Grado" / "Level" / "Módulo"
      case unitLevel2 = "unit.level2"        // "Sección" / "Group"
      case unitPeriod = "unit.period"        // "Periodo" / "Term" / "Semestre"

      // Miembros
      case memberStudent = "member.student"
      case memberStudentPlural = "member.student_plural"
      case memberTeacher = "member.teacher"
      case memberTeacherPlural = "member.teacher_plural"
      case memberGuardian = "member.guardian"
      case memberCoordinator = "member.coordinator"
      case memberAdmin = "member.admin"

      // Contenido
      case contentSubject = "content.subject"
      case contentAssessment = "content.assessment"
      case contentMaterial = "content.material"
      case contentGrade = "content.grade"
  }
  ```

- `@MainActor @Observable class GlossaryProvider`:
  - `var glossary: [String: String]` — del sync bundle
  - `func term(for key: GlossaryKey) -> String`:
    - Busca en `glossary[key.rawValue]`
    - Si no encuentra → retorna fallback por defecto (e.g., "Estudiante" para `.memberStudent`)
  - `func term(for key: String) -> String`:
    - Version string-based para flexibilidad
  - `func updateFromBundle(_ bundle: UserDataBundle)`:
    - Extrae `bundle.glossary` y actualiza `glossary`

**Verificar:** `cd Packages/Domain && swift test`

---

### Paso 6.4: Integrar en PlaceholderResolver

**Paquete**: `Packages/DynamicUI/`

**Archivos a modificar:**
- `Resolvers/PlaceholderResolver.swift`

**Requisitos:**
- Añadir resolución de glossary en placeholders:
  - `{glossary.member.student}` → `GlossaryProvider.term(for: .memberStudent)`
  - `{glossary.unit.level1}` → `GlossaryProvider.term(for: .unitLevel1)`
- La cadena de resolución de placeholder queda:
  1. `{user.*}` → datos del usuario
  2. `{context.*}` → contexto activo (rol, escuela)
  3. `{item.*}` → datos del item actual
  4. `{glossary.*}` → terminología dinámica
  5. `{date.*}` → tokens de fecha

**Verificar:** `cd Packages/DynamicUI && swift test`

---

### Paso 6.5: Cambio de idioma

**Paquete**: `Packages/Domain/Sources/`

**Archivos a crear:**
- `Services/i18n/LocaleService.swift`

**Requisitos:**
- `@MainActor @Observable class LocaleService`:
  - `var currentLocale: String` — "es", "en", "pt-BR"
  - `func changeLocale(_ locale: String) async`:
    1. Persistir preferencia de idioma
    2. Trigger full sync con nuevo locale en header `Accept-Language`
    3. Actualizar `ServerStringResolver` y `GlossaryProvider` con nuevo bundle
    4. Notificar UI para re-render
  - Cadena de fallback: `es-CO` → `es` → `en`
  - Se integra en Settings screen

**Verificar:** `cd Packages/Domain && swift test`

---

### Paso 6.6: Tests de Fase 6

**Archivos a crear:**
- `Packages/Domain/Tests/Services/i18n/GlossaryProviderTests.swift`
- `Packages/Domain/Tests/Services/i18n/ServerStringResolverTests.swift`
- `Packages/DynamicUI/Tests/Resolvers/PlaceholderGlossaryTests.swift`

**Requisitos mínimos:**
- GlossaryProvider resuelve term keys correctamente
- GlossaryProvider retorna fallback si key no existe
- ServerStringResolver prioriza server strings sobre fallback
- PlaceholderResolver resuelve `{glossary.*}` tokens
- EduStrings tiene todas las traducciones base

---

## Criterios de Completitud

- [ ] 43+ strings framework localizados (es, en, pt-BR)
- [ ] Server strings se cargan desde sync bundle
- [ ] GlossaryProvider resuelve terminología por institución
- [ ] PlaceholderResolver soporta `{glossary.*}`
- [ ] Cambio de idioma trigger full sync + re-render
- [ ] `make build` sin errores
- [ ] `make test` sin fallos
