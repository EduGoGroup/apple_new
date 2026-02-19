# Guía de Uso del Makefile

Este proyecto incluye un **Makefile** para automatizar tareas comunes de compilación, testing y mantenimiento.

---

## 🚀 Comandos Principales

### Ver Ayuda

```bash
make help
```

Muestra todos los comandos disponibles con descripciones.

---

### Compilar Todo el Proyecto

```bash
make build
```

Compila todos los módulos en orden de dependencias (TIER-0 → TIER-1 → TIER-2 → TIER-3 → TIER-4).

**Salida esperada:**
```
✓ Compilación completa exitosa
```

---

### Ejecutar Todos los Tests

```bash
make test
```

Ejecuta los tests de los 8 módulos y muestra un resumen al final.

**Salida esperada:**
```
Módulos pasados: 10
✓ Todos los tests pasaron
```

**Ejemplo de salida por módulo:**
```
→ Testing TIER-0-Foundation/EduGoCommon
✔ Test run with 103 tests in 4 suites passed
  ✓ TIER-0-Foundation/EduGoCommon: PASSED
```

---

### Pipeline Completo (CI)

```bash
make ci
```

Ejecuta el pipeline completo:
1. Verifica la estructura del proyecto
2. Compila todos los módulos
3. Ejecuta todos los tests

**Uso recomendado:** Antes de hacer commit o push.

---

## 🧪 Tests por TIER

Puedes ejecutar tests solo de un tier específico:

### TIER-0 (Foundation)
```bash
make test-tier-0
```

Ejecuta tests de:
- EduGoCommon (103 tests)

### TIER-1 (Core)
```bash
make test-tier-1
```

Ejecuta tests de:
- Logger (1 test)
- Models (1 test)

### TIER-2 (Infrastructure)
```bash
make test-tier-2
```

Ejecuta tests de:
- Network (2 tests)
- Storage (2 tests)

### TIER-3 (Domain)
```bash
make test-tier-3
```

Ejecuta tests de:
- Auth (3 tests)
- Roles (3 tests)

### TIER-4 (Features)
```bash
make test-tier-4
```

Ejecuta tests de:
- AI (3 tests)
- API (1 test)
- Analytics (2 tests)

---

## 🧹 Limpieza

### Limpiar Archivos de Build

```bash
make clean
```

Elimina todos los archivos de build (.build directories) de todos los módulos.

### Limpiar y Recompilar

```bash
make clean-build
```

Equivalente a:
```bash
make clean && make build
```

---

## 📊 Información del Proyecto

### Ver Estadísticas

```bash
make stats
```

**Muestra:**
- Cantidad de archivos Swift por módulo
- Total de archivos Swift
- Total de líneas de código

**Salida ejemplo:**
```
Estadísticas del proyecto EduGo Apple:

Archivos Swift por módulo:
  TIER-0-Foundation/EduGoCommon: 6 archivos
  TIER-1-Core/Logger: 1 archivos
  ...

Total archivos Swift: 29
Total líneas de código: 1697
```

### Listar Módulos

```bash
make list-modules
```

Muestra todos los módulos organizados por tier.

### Verificar Estructura

```bash
make verify
```

Verifica que todos los módulos tengan su `Package.swift` correctamente.

**Salida esperada:**
```
✓ TIER-0-Foundation/EduGoCommon
✓ TIER-1-Core/Logger
...
✓ Estructura del proyecto correcta
```

---

## 🔧 Compilación Avanzada

### Compilación Release

```bash
make build-release
```

Compila todos los módulos en modo **release** (optimizado).

**Uso:** Para deployment o medición de performance.

### Tests Verbose

```bash
make test-verbose
```

Ejecuta tests con output completo (útil para debugging).

---

## 🛠️ Herramientas Opcionales

### Formatear Código

```bash
make format
```

**Requiere:** `swift-format`

**Instalar:**
```bash
brew install swift-format
```

Formatea todos los archivos `.swift` del proyecto según el estilo estándar.

---

### Linting

```bash
make lint
```

**Requiere:** `swiftlint`

**Instalar:**
```bash
brew install swiftlint
```

Ejecuta análisis estático de código para detectar problemas de estilo y calidad.

---

## 📱 Integración con Xcode

### Abrir en Xcode

Para abrir un módulo en Xcode:

```bash
open TIER-0-Foundation/EduGoCommon/Package.swift
```

O directamente:

```bash
xed TIER-0-Foundation/EduGoCommon
```

**Nota:** Este proyecto usa SPM multi-módulo, no hay un workspace único.

---

## 🎯 Flujos de Trabajo Recomendados

### Antes de Hacer Commit

```bash
make ci
```

Esto verifica que todo compila y los tests pasan.

---

### Desarrollo Diario

```bash
# Al comenzar el día
make verify

# Después de hacer cambios
make test-tier-X   # Donde X es el tier donde trabajaste

# Antes de terminar
make test
```

---

### Debug de Tests Fallidos

```bash
# 1. Ver qué módulo falla
make test

# 2. Ver output completo del módulo específico
cd TIER-X/ModuleName
swift test

# 3. Ejecutar solo ese tier
make test-tier-X
```

---

### Actualización de Dependencias

```bash
# Limpiar todo
make clean

# Recompilar desde cero
make build

# Verificar que todo funciona
make test
```

---

## 📋 Resumen de Comandos Más Usados

| Comando | Descripción | Frecuencia de Uso |
|---------|-------------|-------------------|
| `make test` | Ejecutar todos los tests | ⭐⭐⭐⭐⭐ |
| `make build` | Compilar todo | ⭐⭐⭐⭐ |
| `make ci` | Pipeline completo | ⭐⭐⭐⭐ |
| `make clean` | Limpiar build | ⭐⭐⭐ |
| `make stats` | Ver estadísticas | ⭐⭐ |
| `make verify` | Verificar estructura | ⭐⭐ |
| `make test-tier-X` | Tests por tier | ⭐⭐ |

---

## 🚨 Solución de Problemas

### Error: "make: command not found"

**macOS:**
```bash
xcode-select --install
```

**Verificar:**
```bash
which make
# Debe mostrar: /usr/bin/make
```

---

### Error: Tests Fallan en Paralelo

Algunos tests (especialmente Roles) pueden fallar con `swift test --parallel`.

**Solución:** El Makefile ya ejecuta tests sin paralelismo por defecto.

---

### Error: "Package.swift not found"

Ejecuta:
```bash
make verify
```

Si algún módulo está corrupto, se mostrará en rojo.

---

### Error de Compilación en un Módulo

```bash
# Limpiar y recompilar ese módulo específicamente
cd TIER-X/ModuleName
swift package clean
swift build
```

---

## 💡 Tips Avanzados

### Ejecutar Tests en Background

```bash
make test > test-results.log 2>&1 &
```

### Medir Tiempo de Compilación

```bash
time make build
```

### Compilar Solo un Módulo

```bash
cd TIER-0-Foundation/EduGoCommon
swift build
```

### Ver Dependencias de un Módulo

```bash
cd TIER-3-Domain/Auth
swift package show-dependencies
```

**Ejemplo de salida:**
```
Auth
├── EduGoCommon
├── Logger
├── Models
├── Network
└── Storage
```

---

## 📚 Referencias

- **Swift Package Manager:** https://swift.org/package-manager/
- **Swift Testing:** https://developer.apple.com/documentation/testing
- **Makefile Tutorial:** https://makefiletutorial.com/

---

## 🎉 Ejemplo de Sesión Completa

```bash
# 1. Verificar estructura
make verify
# ✓ Estructura del proyecto correcta

# 2. Ver estadísticas
make stats
# Total archivos Swift: 29
# Total líneas de código: 1697

# 3. Compilar todo
make build
# ✓ Compilación completa exitosa

# 4. Ejecutar todos los tests
make test
# Módulos pasados: 10
# ✓ Todos los tests pasaron

# 5. Limpiar
make clean
# ✓ Limpieza completa
```

---

**Última actualización:** 2026-01-27  
**Versión:** 1.0  
**Proyecto:** EduGo Apple Modules
