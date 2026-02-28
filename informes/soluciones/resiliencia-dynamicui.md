# Solucion: Resiliencia DynamicUI ante Tipos Desconocidos

**Problema**: [EL-02 MEDIUM](../problemas/errores-logicos.md) - Unknown ControlType/ScreenPattern/ActionType causa fallo total de decodificacion.

**Resumen**: Los enums `ControlType`, `ScreenPattern`, `ActionTrigger`, `ActionType` son cerrados. Si el backend agrega un nuevo valor, el JSON decoder falla y toda la pantalla no se renderiza.

---

## Solucion A: Caso .unknown(String) con fallback (RECOMENDADA)

**Descripcion**: Agregar un caso `.unknown(String)` a cada enum que capture valores no reconocidos, permitiendo que el resto de la pantalla se decodifique correctamente.

**Plan de trabajo**:

### 1. ControlType
```swift
// Agregar caso:
case unknown(String)

// Custom decoder:
public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let rawValue = try container.decode(String.self)
    self = ControlType(rawValue: rawValue) ?? .unknown(rawValue)
}
```

**Archivo**: `Packages/DynamicUI/Sources/DynamicUI/Models/ControlType.swift`

### 2. ScreenPattern
Mismo patron. Unknown patterns se renderizan como layout generico o se saltan.

**Archivo**: `Packages/DynamicUI/Sources/DynamicUI/Models/ScreenPattern.swift`

### 3. ActionTrigger y ActionType
Mismo patron. Unknown actions se ignoran.

**Archivo**: `Packages/DynamicUI/Sources/DynamicUI/Models/ActionDefinition.swift`

### 4. UI Rendering
En la capa de Presentation, slots con `controlType == .unknown(_)` se renderizan como `EmptyView()` o se ocultan.

### 5. Tests
- Test que decodifica un ControlType desconocido
- Test que decodifica una pantalla completa con 1 slot desconocido (los demas se renderizan)
- Test que verifica que un ScreenPattern desconocido no crashea

**Archivos a modificar**: 3 archivos modelo + tests

---

## Solucion B: decodeIfPresent con filtrado

**Descripcion**: En vez de agregar `.unknown`, usar `decodeIfPresent` para control types y filtrar slots con tipo nil.

**Riesgo**: Pierde informacion sobre que tipo era. Mas dificil de debuggear.

---

## Solucion Recomendada: A

Razon: `.unknown(String)` preserva el valor original para logging/debugging. Permite renderizar parcialmente pantallas con contenido nuevo del server.
