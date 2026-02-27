# Integración con CQRS Mediator

Cómo usar el Mediator para ejecutar Commands y Queries desde ViewModels.

## Overview

Los ViewModels en EduGo se comunican con la capa de dominio exclusivamente a través
del patrón CQRS Mediator. Este patrón separa las operaciones de lectura (Queries)
de las operaciones de escritura (Commands), proporcionando una arquitectura limpia
y testeable.

## Fundamentos del Mediator

### Arquitectura

```
┌─────────────────┐     ┌─────────────┐     ┌─────────────────┐
│   ViewModel     │────▶│   Mediator  │────▶│    Handler      │
│                 │◀────│             │◀────│                 │
└─────────────────┘     └─────────────┘     └─────────────────┘
                               │
                               ▼
                        ┌─────────────┐
                        │   EventBus  │
                        └─────────────┘
```

### Tipos de Operaciones

| Tipo | Método | Propósito | Retorno |
|------|--------|-----------|---------|
| Query | `mediator.send(_:)` | Lectura de datos | Resultado directo |
| Command | `mediator.execute(_:)` | Escritura/Mutación | `CommandResult<T>` |

## Queries (Operaciones de Lectura)

### Estructura Básica

```swift
public func loadData() async {
    isLoading = true
    error = nil
    
    do {
        // Crear query con parámetros necesarios
        let query = GetStudentDashboardQuery(
            userId: userId,
            includeProgress: true,
            forceRefresh: false
        )
        
        // Ejecutar query via Mediator
        let result = try await mediator.send(query)
        
        // Actualizar estado
        self.dashboard = result
        
    } catch {
        self.error = error
    }
    
    isLoading = false
}
```

### Queries con Cache

Muchas queries tienen cache automático con TTL:

```swift
public func loadDashboard(forceRefresh: Bool = false) async {
    let query = GetStudentDashboardQuery(
        userId: userId,
        includeProgress: includeProgress,
        forceRefresh: forceRefresh,  // true ignora cache
        metadata: [
            "source": "DashboardViewModel",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
    )
    
    // Si cache válido, retorna inmediatamente
    let dashboard = try await mediator.send(query)
}
```

### Queries Disponibles en EduGo

| Query | Propósito | Cache TTL |
|-------|-----------|-----------|
| `GetStudentDashboardQuery` | Dashboard del estudiante | 5 min |
| `GetUserContextQuery` | Contexto/membresías del usuario | 10 min |
| `ListMaterialsQuery` | Lista de materiales | 3 min |
| `GetAssessmentQuery` | Evaluación específica | No cache |
| `GetUserProfileQuery` | Perfil del usuario | 5 min |

## Commands (Operaciones de Escritura)

### Estructura Básica

```swift
public func saveData() async {
    isSaving = true
    error = nil
    
    do {
        // Crear command con datos
        let command = UpdateProfileCommand(
            userId: userId,
            name: editedName,
            bio: editedBio
        )
        
        // Ejecutar command via Mediator
        let result = try await mediator.execute(command)
        
        // Verificar resultado
        if result.isSuccess, let output = result.getValue() {
            self.profile = output.updatedProfile
        } else if let error = result.getError() {
            self.error = error
        }
        
    } catch {
        self.error = error
    }
    
    isSaving = false
}
```

### CommandResult

Los commands retornan `CommandResult<T>` con información completa:

```swift
let result = try await mediator.execute(command)

// Verificar éxito
if result.isSuccess {
    // Obtener valor
    if let output = result.getValue() {
        // Usar output
    }
    
    // Ver eventos publicados
    print("Eventos: \(result.events)")
}

// Verificar error
if let error = result.getError() {
    // Manejar error
}

// Verificar errores de validación
if !result.validationErrors.isEmpty {
    // Mostrar errores de validación
}
```

### Commands Disponibles en EduGo

| Command | Propósito | Eventos Publicados |
|---------|-----------|-------------------|
| `LoginCommand` | Autenticación | `LoginSuccessEvent` |
| `SwitchContextCommand` | Cambio de contexto | `ContextSwitchedEvent` |
| `UploadMaterialCommand` | Subir material | `MaterialUploadedEvent` |
| `SubmitAssessmentCommand` | Enviar evaluación | `AssessmentSubmittedEvent` |
| `AssignMaterialCommand` | Asignar material | `MaterialAssignedEvent` |

## Manejo de Errores

### Patrón Estándar

```swift
catch {
    // Convertir a error de dominio si es posible
    self.error = error as? AppError ?? AppError(
        code: .unknown,
        message: error.localizedDescription
    )
}
```

### Errores del Mediator

```swift
extension MyViewModel {
    var errorMessage: String? {
        guard let error = error else { return nil }
        
        if let mediatorError = error as? MediatorError {
            switch mediatorError {
            case .handlerNotFound:
                return "Error de configuración del sistema."
            case .validationError(let message, _):
                return "Error de validación: \(message)"
            case .executionError(let message, _):
                return "Error: \(message)"
            case .registrationError:
                return "Error de configuración."
            }
        }
        
        return error.localizedDescription
    }
}
```

### Errores de Validación

```swift
if let validationError = error as? ValidationError {
    switch validationError {
    case .emptyField(let field):
        return "El campo '\(field)' es requerido."
    case .invalidFormat(let field, let reason):
        return "'\(field)' inválido: \(reason)"
    case .invalidLength(let field, let expected, let actual):
        return "'\(field)' debe tener \(expected), tiene \(actual)."
    }
}
```

## Ejemplo Completo: MaterialUploadViewModel

```swift
@MainActor
@Observable
public final class MaterialUploadViewModel {
    
    // MARK: - Published State
    
    public var title: String = ""
    public var description: String = ""
    public var selectedFileURL: URL?
    public var isUploading: Bool = false
    public var uploadProgress: Double = 0
    public var error: Error?
    public var uploadedMaterial: Material?
    
    // MARK: - Dependencies
    
    private let mediator: Mediator
    private let eventBus: EventBus
    
    // MARK: - Initialization
    
    public init(mediator: Mediator, eventBus: EventBus) {
        self.mediator = mediator
        self.eventBus = eventBus
    }
    
    // MARK: - Public Methods
    
    public func uploadMaterial(
        subjectId: UUID,
        gradeId: UUID
    ) async {
        guard let fileURL = selectedFileURL else {
            error = ValidationError.emptyField(fieldName: "archivo")
            return
        }
        
        isUploading = true
        uploadProgress = 0
        error = nil
        
        do {
            // Crear command
            let command = UploadMaterialCommand(
                title: title,
                description: description,
                fileURL: fileURL,
                subjectId: subjectId,
                gradeId: gradeId,
                metadata: ["source": "MaterialUploadViewModel"]
            )
            
            // Ejecutar con tracking de progreso
            let result = try await mediator.execute(command)
            
            if result.isSuccess, let output = result.getValue() {
                self.uploadedMaterial = output.material
                self.uploadProgress = 1.0
                
                // Limpiar formulario
                resetForm()
            } else if let error = result.getError() {
                self.error = error
            }
            
        } catch {
            self.error = error
        }
        
        isUploading = false
    }
    
    private func resetForm() {
        title = ""
        description = ""
        selectedFileURL = nil
    }
}
```

## Checklist de Integración

- [ ] Usar `mediator.send(_:)` para queries (lectura)
- [ ] Usar `mediator.execute(_:)` para commands (escritura)
- [ ] Manejar `CommandResult` correctamente
- [ ] Convertir errores a mensajes legibles
- [ ] Usar `forceRefresh` cuando sea necesario
- [ ] Incluir metadata para debugging

## See Also

- <doc:EventBusUsage>
- <doc:CreatingAViewModel>
