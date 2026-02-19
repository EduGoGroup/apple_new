# UI Components + Forms SDK

**Estado de extraccion:** Listo (95% generico)
**Dependencias externas:** SwiftUI (framework Apple)
**Origen en proyecto:** `Packages/Presentation/Sources/Components/` y `Packages/Presentation/Sources/Utilities/`

---

## a) Que hace este SDK

Libreria de componentes SwiftUI reutilizables con sistema de formularios reactivos. Proporciona:

### Componentes UI
- **EduButton**: Boton con variantes (primary, secondary, destructive, link), tamanos (small, medium, large), iconos y estado loading
- **EduTextField**: Campo de texto con validacion visual, icono y estados de error
- **EduCard**: Contenedor con elevacion configurable, padding y corner radius
- **EduToast**: Sistema de notificaciones con `ToastManager` global (success, error, warning, info)
- **EduSkeletonLoader**: Loading placeholders con efecto shimmer (rectangle, circle, capsule)
- **EduListView<Item, Content>**: Lista generica con estados (loading, success, error, empty)

### Sistema de Formularios
- **FormState**: Gestion de estado multi-campo con validacion cruzada y submission
- **@BindableProperty**: Property wrapper con validacion en tiempo real para cualquier tipo `Sendable`
- **@DebouncedProperty**: Property wrapper con debounce configurable para busquedas
- **Validators**: Coleccion composable (email, password, nonEmpty, minLength, maxLength, pattern, all, when)
- **ValidationResult**: Tipo resultado con mensajes de error

### Uso tipico por el consumidor

```swift
// === Componentes ===
EduButton("Guardar", style: .primary, size: .large) {
    await guardar()
}
.loading(isGuardando)

EduTextField("Email", text: $email, icon: "envelope")
    .validation(emailValidation)

EduCard(elevation: .medium) {
    contenidoDelCard
}

// === Formularios ===
@BindableProperty(validation: Validators.email())
var email: String = ""

@DebouncedProperty(interval: 0.3)
var busqueda: String = ""

let form = FormState()
form.registerField("email") { Validators.email()(email) }
form.registerField("password") { Validators.password(minLength: 8)(password) }

await form.submit {
    try await enviarFormulario()
}
```

---

## b) Compila como proyecto independiente?

**Casi.** El unico acoplamiento detectado:

- **`EduListView`**: Importa `EduDomain` para usar `ViewState<T>` - pero `ViewState` es un enum generico trivial que se puede copiar al SDK
- **Componentes UI**: Usan `DesignTokens` que actualmente estan definidos en DesignSystem
- **Forms**: 100% standalone, cero dependencias externas

**Solucion**: Incluir DesignTokens basicos en el SDK, o depender del DesignSystem SDK.

---

## c) Dependencias si se extrae

| Dependencia | Tipo | Notas |
|---|---|---|
| SwiftUI | Framework Apple | Unico requerimiento |
| DesignSystem SDK | Opcional | Para tokens de diseno. O incluir tokens inline |

### Forms (sub-modulo):
| Dependencia | Tipo | Notas |
|---|---|---|
| Foundation | Sistema Apple | Solo Foundation |

---

## d) Que se fusionaria con este SDK

**DesignSystem SDK** es el candidato natural para fusion. El resultado seria un SDK unificado:

```
UIKit SDK
  DesignSystem/     (temas, efectos, accesibilidad)
  Components/       (botones, cards, toasts, skeletons)
  Forms/            (formularios reactivos)
```

Esto tiene sentido porque:
- Los componentes ya usan los tokens del DesignSystem
- Es la unidad logica que un consumidor importaria junta
- Mantiene la cohesion: "todo lo visual"

Alternativamente, **Forms** podria ser un SDK independiente ya que tiene cero dependencias.

---

## e) Interfaces publicas (contrato del SDK)

### Componentes

```swift
// Botones
EduButton(_ title: String, style: ButtonStyle, size: ButtonSize, icon: String?,
          iconPosition: IconPosition, action: () async -> Void)
    .loading(_ isLoading: Bool)
    .disabled(_ isDisabled: Bool)

// Campos de texto
EduTextField(_ placeholder: String, text: Binding<String>, icon: String?,
             validation: ValidationResult?)

// Cards
EduCard(elevation: CardElevation, backgroundColor: Color?, cornerRadius: CGFloat?) {
    @ViewBuilder content: () -> Content
}

// Toasts
ToastManager.shared.show(_ message: String, style: ToastStyle)

// Skeletons
EduSkeletonLoader(shape: SkeletonShape)
EduSkeletonCard()
EduSkeletonList(rows: Int)

// Listas
EduListView<Item: Identifiable, Content: View>(
    state: ViewState<[Item]>,
    emptyMessage: String,
    @ViewBuilder row: (Item) -> Content
)
```

### Formularios

```swift
@BindableProperty<Value: Sendable>(
    validation: ((Value) -> ValidationResult)?
)

@DebouncedProperty<Value: Sendable>(
    interval: TimeInterval,
    onChange: ((Value) async -> Void)?
)

public class FormState: ObservableObject {
    public func registerField(_ name: String, validator: () -> ValidationResult)
    public func validateAll() -> Bool
    public func submit(_ action: () async throws -> Void) async
    public var isSubmitting: Bool { get }
    public var isValid: Bool { get }
}

// Validators composables
Validators.email() -> (String) -> ValidationResult
Validators.password(minLength:requireUppercase:requireNumbers:requireSymbols:)
Validators.nonEmpty()
Validators.minLength(_:)
Validators.maxLength(_:)
Validators.pattern(_:message:)
Validators.all([...])
Validators.when(condition:then:)
```

---

## f) Que necesita personalizar el consumidor

### Para componentes UI

1. **DesignTokens**: Configurar colores, espaciados, bordes segun su marca
2. **Estilos custom**: Extender variantes de botones, cards, etc. si necesita mas

### Para formularios

1. **Nada obligatorio**: Funciona out-of-the-box
2. **Validators custom**: Crear sus propios validadores composables si los necesita
3. **Cross-field validation**: Registrar reglas que dependan de multiples campos

### Que se lleva tal cual vs que adapta

| Componente | Se lleva tal cual? | Adaptacion necesaria |
|---|---|---|
| EduButton | Si | Ajustar DesignTokens |
| EduTextField | Si | Ajustar DesignTokens |
| EduCard | Si | Ajustar DesignTokens |
| EduToast + ToastManager | Si | - |
| EduSkeletonLoader | Si | - |
| EduListView | Si | Copiar ViewState (5 lineas) |
| FormState | Si | - |
| @BindableProperty | Si | - |
| @DebouncedProperty | Si | - |
| Validators (todos) | Si | - |
| ValidationResult | Si | - |

### Cambios necesarios para portabilidad

1. **Copiar `ViewState<T>`**: Enum trivial de 5 lineas (loading, success, error, empty)
2. **Resolver DesignTokens**: Incluir tokens basicos inline o depender del DesignSystem SDK
3. **Renombrar prefijo "Edu"**: Opcional, depende de branding del SDK
