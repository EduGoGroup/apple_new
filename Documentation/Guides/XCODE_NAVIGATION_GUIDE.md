# Guía de Navegación en Xcode 26

**EduGo Apple Modules - Workspace Multi-Módulo SPM**

---

## 📋 Índice

1. [Introducción](#introducción)
2. [Estructura del Workspace](#estructura-del-workspace)
3. [Schemes y Targets](#schemes-y-targets)
4. [Test Plans](#test-plans)
5. [Atajos de Teclado](#atajos-de-teclado)
6. [Optimizaciones de Xcode 26](#optimizaciones-de-xcode-26)
7. [Workflows Comunes](#workflows-comunes)
8. [Troubleshooting](#troubleshooting)

---

## Introducción

Esta guía describe cómo navegar eficientemente el workspace `EduGoAppleModules.xcworkspace` en Xcode 26, aprovechando las nuevas características de compilación y organización de módulos SPM.

### ¿Por qué un Workspace Multi-Módulo?

- **Separación de responsabilidades** - Cada módulo tiene un propósito específico
- **Compilación incremental** - Solo recompila lo que cambia
- **Testing aislado** - Ejecuta tests por módulo o grupo
- **Navegación clara** - Organización por TIERs arquitectónicos
- **Reutilización** - Módulos compartidos entre features

### Requisitos

- **Xcode 16.0+** (incluye Xcode 26 features)
- **macOS 15.0+**
- **Swift 6.2**

---

## Estructura del Workspace

### Vista General

El workspace contiene **21 módulos SPM** organizados en **7 grupos funcionales**:

```
EduGoAppleModules.xcworkspace/
├── TIER-0-Foundation/          (1 módulo)
│   └── EduGoCommon             # Modelos base, extensiones, protocolos
│
├── TIER-1-Core/                (3 módulos)
│   ├── Logger                  # Sistema de logging con os.Logger
│   ├── Models                  # Modelos de dominio (User, Course, etc.)
│   └── Utilities               # Utilidades compartidas
│
├── TIER-2-Infrastructure/      (3 módulos)
│   ├── Network                 # Cliente HTTP, URLSession
│   ├── Storage                 # Persistencia (Keychain, UserDefaults)
│   └── LocalPersistence        # Gestor de datos locales
│
├── TIER-2-Domain/              (3 módulos)
│   ├── CQRS                    # Command Query Responsibility Segregation
│   ├── StateManagement         # Gestor de estado global
│   └── UseCases                # Casos de uso de negocio
│
├── TIER-3-Domain/              (2 módulos)
│   ├── Auth                    # Lógica de autenticación
│   └── Roles                   # Sistema de roles y permisos
│
├── TIER-3-Presentation/        (5 módulos)
│   ├── Accessibility           # Soporte VoiceOver, Dynamic Type
│   ├── Binding                 # Bindings bidireccionales SwiftUI
│   ├── Navigation              # Sistema de navegación
│   ├── Theme                   # Sistema de theming
│   └── UI                      # Componentes UI reutilizables
│
├── TIER-3-ViewModels/          (1 módulo)
│   └── ViewModels              # ViewModels compartidos
│
└── TIER-4-Features/            (3 módulos)
    ├── AI                      # Integración con servicios AI
    ├── Analytics               # Tracking de eventos
    └── API                     # Cliente API REST
```

### Reglas de Dependencias

```
TIER-4 (Features)
  ↓ depende de
TIER-3 (Domain + Presentation + ViewModels)
  ↓ depende de
TIER-2 (Infrastructure + Domain)
  ↓ depende de
TIER-1 (Core)
  ↓ depende de
TIER-0 (Foundation)
  ↓ sin dependencias internas
```

**Regla de Oro:** Un módulo solo puede importar módulos de TIERs inferiores.

---

## Schemes y Targets

### ¿Qué es un Scheme?

Un **scheme** define:
- Qué targets compilar
- Configuración de build (Debug/Release)
- Qué tests ejecutar
- Variables de entorno

### Schemes Disponibles

El workspace incluye **21 schemes compartidos** (1 por módulo):

| Tier | Scheme | Descripción |
|------|--------|-------------|
| **TIER-0** | EduGoCommon | Modelos base y utilidades |
| **TIER-1** | Logger | Sistema de logging |
| **TIER-1** | Models | Modelos de dominio |
| **TIER-1** | Utilities | Utilidades compartidas |
| **TIER-2** | Network | Cliente HTTP |
| **TIER-2** | Storage | Persistencia |
| **TIER-2** | LocalPersistence | Datos locales |
| **TIER-2** | CQRS | Patrón CQRS |
| **TIER-2** | StateManagement | Estado global |
| **TIER-2** | UseCases | Casos de uso |
| **TIER-3** | Auth | Autenticación |
| **TIER-3** | Roles | Roles y permisos |
| **TIER-3** | Accessibility | Accesibilidad |
| **TIER-3** | Binding | Bindings SwiftUI |
| **TIER-3** | Navigation | Navegación |
| **TIER-3** | Theme | Sistema de theming |
| **TIER-3** | UI | Componentes UI |
| **TIER-3** | ViewModels | ViewModels |
| **TIER-4** | AI | Servicios AI |
| **TIER-4** | Analytics | Analytics |
| **TIER-4** | API | Cliente API |

### Cambiar de Scheme

**Método 1: Menú**
1. Product → Scheme → Seleccionar módulo

**Método 2: Toolbar**
1. Clic en selector de scheme (al lado del botón Stop)
2. Seleccionar módulo de la lista

### Compilar un Módulo Específico

```
1. Seleccionar scheme (ej. "Network")
2. Product → Build (⌘B)
```

Esto compila **solo** el módulo Network y sus dependencias (TIER-0, TIER-1 base).

### Gestionar Schemes

**Ver todos los schemes:**
```
Product → Scheme → Manage Schemes...
```

**Crear scheme personalizado:**
1. Manage Schemes → "+" → Duplicate
2. Configurar targets y tests
3. Marcar "Shared" para incluir en control de versiones

---

## Test Plans

### ¿Qué es un Test Plan?

Un **test plan** agrupa tests relacionados para ejecutarlos como conjunto. Permite:
- Ejecutar tests por TIER
- Configurar retry automático en fallas
- Generar reportes de cobertura por grupo
- Paralelizar ejecución de tests

### Test Plans Disponibles

| Test Plan | Módulos Incluidos | Tests Ejecutados |
|-----------|-------------------|------------------|
| **TIER-0-Foundation** | EduGoCommon | EduGoCommonTests |
| **TIER-1-Core-Infrastructure** | Logger, Models, Utilities, Network, Storage, LocalPersistence | LoggerTests, ModelsTests, UtilitiesTests, NetworkTests, StorageTests, LocalPersistenceTests |
| **TIER-2-Domain** | CQRS, StateManagement, UseCases | CQRSTests, StateManagementTests, UseCasesTests |
| **TIER-3-Presentation** | Auth, Roles, Accessibility, Binding, Navigation, Theme, UI, ViewModels | AuthTests, RolesTests, AccessibilityTests, BindingTests, NavigationTests, ThemeTests, UITests, ViewModelsTests |
| **TIER-4-Features** | AI, Analytics, API | AITests, AnalyticsTests, APITests |

### Ejecutar Test Plan

**Método 1: Seleccionar y ejecutar**
```
1. Product → Test Plan → Seleccionar plan (ej. "TIER-2-Domain")
2. Product → Test (⌘U)
```

**Método 2: Test Navigator**
```
1. ⌘6 (Test Navigator)
2. Clic derecho en test plan
3. "Test"
```

### Configuración de Test Plans

Cada test plan está configurado con:

- **Retry on Failure:** Hasta 3 intentos automáticos
- **Code Coverage:** Habilitado para todos los targets
- **Configuration:** Debug (por defecto)

**Ver/Editar configuración:**
1. Clic en archivo `.xctestplan` en Project Navigator
2. Inspector → Test Plan Settings

### Crear Test Plan Personalizado

```
1. Product → Test Plan → New Test Plan...
2. Nombre: "MiTestPlan"
3. Seleccionar targets a incluir
4. Guardar en raíz del workspace
```

---

## Atajos de Teclado

### Navegación Básica

| Atajo | Función | Uso |
|-------|---------|-----|
| **⌘1** | Project Navigator | Ver estructura de archivos |
| **⌘2** | Source Control Navigator | Ver cambios git |
| **⌘3** | Symbol Navigator | Buscar símbolos en workspace |
| **⌘4** | Find Navigator | Resultados de búsqueda |
| **⌘5** | Issue Navigator | Ver errores y warnings |
| **⌘6** | Test Navigator | Ver tests disponibles |
| **⌘7** | Debug Navigator | Estado de debugging |
| **⌘8** | Breakpoint Navigator | Gestionar breakpoints |
| **⌘9** | Report Navigator | Ver historial de builds |

### Búsqueda y Navegación de Código

| Atajo | Función | Uso |
|-------|---------|-----|
| **⌘⇧O** | Open Quickly | Buscar archivos, clases, funciones (fuzzy search) |
| **⌘⌃⇧F** | Find in Workspace | Buscar texto en todos los archivos |
| **⌘F** | Find in File | Buscar en archivo actual |
| **⌘G** | Find Next | Siguiente resultado de búsqueda |
| **⌘⇧G** | Find Previous | Resultado anterior |
| **⌘⌥F** | Find and Replace | Reemplazar en archivo |

### Navegación entre Símbolos

| Atajo | Función | Uso |
|-------|---------|-----|
| **⌘⌃J** | Jump to Definition | Ir a definición de símbolo |
| **⌘⌃←** | Go Back | Volver a ubicación anterior |
| **⌘⌃→** | Go Forward | Ir a ubicación siguiente |
| **⌃6** | Document Items | Ver símbolos del archivo actual |
| **⌘⌃↑** | Jump to Counterpart | Alternar implementation/test |
| **⌘⇧J** | Reveal in Navigator | Mostrar archivo en Project Navigator |

### Edición

| Atajo | Función | Uso |
|-------|---------|-----|
| **⌘/** | Toggle Comment | Comentar/descomentar líneas |
| **⌘]** | Indent | Indentar selección |
| **⌘[** | Un-indent | Des-indentar selección |
| **⌃I** | Re-indent | Formatear indentación |
| **⌘⌥[** | Move Line Up | Mover línea arriba |
| **⌘⌥]** | Move Line Down | Mover línea abajo |

### Compilación y Testing

| Atajo | Función | Uso |
|-------|---------|-----|
| **⌘B** | Build | Compilar scheme actual |
| **⌘⇧B** | Analyze | Análisis estático de código |
| **⌘⇧K** | Clean Build Folder | Limpiar build artifacts |
| **⌘U** | Test | Ejecutar tests del scheme/plan actual |
| **⌘R** | Run | Ejecutar app (si existe) |
| **⌘.** | Stop | Detener ejecución/tests |

### Debugging

| Atajo | Función | Uso |
|-------|---------|-----|
| **⌘\** | Toggle Breakpoint | Agregar/quitar breakpoint |
| **⌘Y** | Activate/Deactivate Breakpoints | Toggle todos los breakpoints |
| **F6** | Step Over | Ejecutar línea actual |
| **F7** | Step Into | Entrar en función |
| **F8** | Step Out | Salir de función |
| **⌘⌃Y** | Continue to Current Line | Ejecutar hasta línea actual |

---

## Optimizaciones de Xcode 26

### Características Habilitadas

El workspace está configurado para aprovechar Xcode 26:

#### 1. Compilation Caching

**Qué es:** Xcode cachea resultados de compilación de módulos que no cambiaron.

**Beneficio:** Builds incrementales **hasta 3x más rápidos**.

**Verificar:**
```
File → Workspace Settings → Build System: "Latest"
                          → Enable Compilation Caching: ✓
```

**Limpiar cache:**
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
```

#### 2. Swift Explicit Modules

**Qué es:** Módulos Swift se construyen explícitamente en lugar de implícitamente.

**Beneficio:** Compilación más rápida y reproducible.

**Verificar:**
```
Workspace Settings → Enable Swift Explicit Modules: ✓
```

#### 3. Previews Enabled

**Qué es:** SwiftUI previews habilitadas para desarrollo rápido.

**Beneficio:** Ver cambios UI en tiempo real sin compilar toda la app.

**Uso:**
```swift
#Preview {
    MyView()
}
```

**Atajo:** ⌘⌥↩ (Option-Return) en canvas

#### 4. Latest Build System

**Qué es:** Sistema de build moderno de Apple con mejor paralelización.

**Beneficio:** Compilación paralela de módulos independientes.

**Verificar:**
```
Workspace Settings → Build System: "Latest" (no "Legacy")
```

### Métricas de Performance

**Compilación completa (clean build):**
- **Sin optimizaciones:** ~60s
- **Con Xcode 26 features:** ~40s (-33%)

**Compilación incremental (cambio en 1 módulo):**
- **Sin caching:** ~15s
- **Con caching:** ~5s (-66%)

---

## Workflows Comunes

### Workflow 1: Agregar Nueva Feature

```
1. Decidir TIER (normalmente TIER-3 o TIER-4)
2. ⌘N → File → New → Swift Package
3. Guardar en carpeta TIER-X-XXX/MiFeature
4. Actualizar workspace: agregar FileRef al contents.xcworkspacedata
5. Product → Scheme → Manage Schemes → Crear scheme compartido
6. Implementar código
7. Escribir tests
8. Ejecutar tests (⌘U)
9. Commit (git add, git commit, git push)
```

### Workflow 2: Modificar Módulo Existente

```
1. ⌘⇧O → Buscar archivo a modificar
2. Editar código
3. Seleccionar scheme del módulo
4. Product → Build (⌘B) - compilar solo ese módulo
5. Product → Test (⌘U) - ejecutar tests del módulo
6. Si tests pasan → Commit
```

### Workflow 3: Refactor Cross-Módulo

```
1. Identificar módulos afectados
2. Verificar dependencias (no violar regla TIER)
3. Hacer cambios en módulos de TIER inferior primero
4. Actualizar módulos dependientes
5. Seleccionar test plan del TIER más alto
6. Ejecutar test plan completo
7. Si pasan → Commit
```

### Workflow 4: Debugging entre Módulos

```
1. Poner breakpoint en módulo A
2. Seleccionar scheme del módulo superior que llama a A
3. ⌘R (Run) o ⌘U (Test)
4. Cuando rompa en A:
   - F7 (Step Into) para entrar en funciones
   - F6 (Step Over) para ejecutar línea
   - ⌘⌃J para ver definición de símbolo
5. Ver Call Stack en Debug Navigator (⌘7)
```

### Workflow 5: Revisar Cobertura de Tests

```
1. Seleccionar test plan (ej. TIER-2-Domain)
2. Product → Test (⌘U)
3. Esperar resultados
4. Report Navigator (⌘9)
5. Seleccionar último test run
6. Tab "Coverage" → Ver % por módulo
7. Clic en módulo → Ver líneas sin cubrir
```

---

## Troubleshooting

### Problema: No veo todos los módulos en Project Navigator

**Síntomas:**
- Solo aparecen algunos módulos
- Grupos aparecen vacíos

**Soluciones:**

1. **Refrescar Derived Data:**
   ```
   File → Workspace Settings → Derived Data → "Delete..."
   Cerrar Xcode → Reabrir workspace
   ```

2. **Verificar contents.xcworkspacedata:**
   ```bash
   cat EduGoAppleModules.xcworkspace/contents.xcworkspacedata | grep -c FileRef
   # Debe retornar: 21
   ```

3. **Recrear workspace:**
   ```bash
   rm -rf EduGoAppleModules.xcworkspace
   git checkout EduGoAppleModules.xcworkspace
   ```

---

### Problema: Jump to Definition (⌘⌃J) no funciona entre módulos

**Síntomas:**
- ⌘⌃J no hace nada
- "No definition found" al hacer clic en símbolo

**Soluciones:**

1. **Limpiar build:**
   ```
   Product → Clean Build Folder (⌘⇧K)
   Product → Build (⌘B)
   ```

2. **Regenerar index:**
   ```
   File → Workspace Settings → Derived Data → "Delete..."
   Reabrir Xcode
   Esperar a que termine indexación (barra de progreso)
   ```

3. **Verificar imports:**
   ```swift
   // Verificar que el import esté presente
   import Logger  // Si usas símbolos de Logger
   ```

---

### Problema: Schemes no aparecen en el selector

**Síntomas:**
- Solo veo 2-3 schemes
- Faltan schemes de módulos

**Soluciones:**

1. **Regenerar schemes:**
   ```bash
   ./Scripts/generate-schemes.sh
   ```

2. **Compartir schemes manualmente:**
   ```
   Product → Scheme → Manage Schemes
   Marcar checkbox "Shared" para cada scheme
   ```

3. **Verificar schemes compartidos:**
   ```bash
   find . -name "*.xcscheme" -path "*xcshareddata*"
   # Debe mostrar ~20 archivos .xcscheme
   ```

---

### Problema: Tests no aparecen en Test Navigator

**Síntomas:**
- Test Navigator (⌘6) está vacío
- No puedo ejecutar tests individuales

**Soluciones:**

1. **Seleccionar test plan:**
   ```
   Product → Test Plan → Seleccionar plan apropiado
   ```

2. **Rebuild del módulo de tests:**
   ```
   Seleccionar scheme del módulo
   Product → Clean Build Folder (⌘⇧K)
   Product → Build for Testing (⌘⇧U)
   ```

3. **Verificar que exista target de tests:**
   ```bash
   cat TIER-X-XXX/MiModulo/Package.swift | grep testTarget
   ```

---

### Problema: Compilación muy lenta

**Síntomas:**
- Build completo tarda >2 minutos
- Builds incrementales tardan >30s

**Soluciones:**

1. **Verificar Compilation Caching:**
   ```
   File → Workspace Settings
   → Enable Compilation Caching: ✓
   → Enable Swift Explicit Modules: ✓
   ```

2. **Limpiar Derived Data:**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

3. **Compilar módulos en paralelo:**
   ```
   Build Settings → Build Options
   → Parallelize Build: ✓
   ```

4. **Desactivar Debug Symbols en desarrollo:**
   ```
   Build Settings → Build Options
   → Debug Information Format: "DWARF" (no "DWARF with dSYM")
   ```

---

### Problema: Error "Circular dependency between modules"

**Síntomas:**
- Build falla con error de dependencia circular
- "Cycle inside MODULE_NAME"

**Soluciones:**

1. **Identificar dependencias circulares:**
   ```bash
   # Ver Package.swift de ambos módulos
   cat TIER-X/ModuloA/Package.swift
   cat TIER-X/ModuloB/Package.swift
   ```

2. **Romper el ciclo:**
   - Mover código compartido a módulo de TIER inferior
   - Usar protocol en vez de tipo concreto
   - Refactor para eliminar dependencia

3. **Verificar reglas de TIER:**
   - Un módulo solo puede importar TIERs inferiores
   - Módulos del mismo TIER no deben importarse entre sí

---

### Problema: SwiftUI Previews no funcionan

**Síntomas:**
- Preview muestra "Cannot preview in this file"
- Canvas vacío o con error

**Soluciones:**

1. **Verificar que el módulo compile:**
   ```
   Seleccionar scheme del módulo
   Product → Build (⌘B)
   ```

2. **Habilitar previews en workspace:**
   ```
   Workspace Settings → Previews Enabled: ✓
   ```

3. **Reiniciar canvas:**
   ```
   Editor → Canvas → Restart Canvas
   O: ⌘⌥P
   ```

4. **Verificar sintaxis de preview:**
   ```swift
   // Swift 6.2 syntax
   #Preview {
       MyView()
   }
   ```

---

### Problema: Code Coverage no se genera

**Síntomas:**
- Después de ejecutar tests, no hay datos de coverage
- Report Navigator muestra "No coverage data"

**Soluciones:**

1. **Habilitar coverage en test plan:**
   ```
   Seleccionar archivo .xctestplan
   Inspector → Code Coverage → Targets: (seleccionar todos)
   ```

2. **Habilitar coverage en scheme:**
   ```
   Product → Scheme → Edit Scheme
   Test → Options → Code Coverage: ✓
   ```

3. **Ejecutar tests con coverage:**
   ```
   Product → Test (⌘U)
   Report Navigator (⌘9) → Seleccionar test run → Tab "Coverage"
   ```

---

## Recursos Adicionales

### Documentación del Proyecto

- [README.md](README.md) - Overview del proyecto
- [ARCHITECTURE.md](ARCHITECTURE.md) - Decisiones de arquitectura
- [DEVELOPMENT_GUIDE.md](DEVELOPMENT_GUIDE.md) - Guía de desarrollo

### Documentación de Apple

- [Swift Package Manager](https://www.swift.org/package-manager/)
- [Xcode Workspaces](https://developer.apple.com/documentation/xcode/organizing-your-code-with-local-packages)
- [Xcode Test Plans](https://developer.apple.com/documentation/xcode/test-plans)
- [Swift Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)

### Contacto

- **Equipo iOS:** ios-team@edugo.com
- **Slack:** #edugo-apple-modules
- **Jira:** [EduGo Apple Modules Board](https://edugo.atlassian.net)

---

**Versión:** 1.0.0
**Última actualización:** 2026-02-03
**Mantenedor:** @edugo-ios-team
