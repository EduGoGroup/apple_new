# Configuración de Ambientes - DemoApp

Este documento explica cómo ejecutar DemoApp con diferentes configuraciones de API (localhost vs Azure).

## 🌐 Ambientes Disponibles

### 1. **Staging (Azure)** - Por Defecto ✨
Las APIs están desplegadas en Azure Container Apps:

- **IAM Platform**: `https://edugo-api-iam-platform.wittyhill-f6d656fb.eastus.azurecontainerapps.io`
- **Admin API**: `https://edugo-api-admin-new.wittyhill-f6d656fb.eastus.azurecontainerapps.io`
- **Mobile API**: `https://edugo-api-mobile-new.wittyhill-f6d656fb.eastus.azurecontainerapps.io`

### 2. **Development (Localhost)**
APIs corriendo localmente en tu máquina:

- **IAM Platform**: `http://localhost:8070`
- **Admin API**: `http://localhost:8060`
- **Mobile API**: `http://localhost:8065`

### 3. **Production**
URLs de producción (aún no desplegadas):

- **IAM Platform**: `https://api-iam.edugo.com`
- **Admin API**: `https://api.edugo.com`
- **Mobile API**: `https://api-mobile.edugo.com`

---

## 🚀 Método 1: Desde Terminal (Recomendado)

### Ejecutar con Azure (Staging) - Por Defecto

```bash
cd /Users/jhoanmedina/source/EduGo/EduUI/apple_new/Apps/DemoApp
make run
# o explícitamente:
make run-staging
```

### Ejecutar con Localhost (Development)

```bash
cd /Users/jhoanmedina/source/EduGo/EduUI/apple_new/Apps/DemoApp
make run-dev
```

### Ejecutar con Production

```bash
cd /Users/jhoanmedina/source/EduGo/EduUI/apple_new/Apps/DemoApp
make run-prod
```

---

## 🔧 Método 2: Desde Xcode

### Opción A: Configurar el Scheme una vez (Recomendado para Azure)

1. En Xcode, selecciona el scheme **DemoApp** en la barra superior
2. Click en el nombre del scheme → **Edit Scheme...**
3. En el panel izquierdo, selecciona **Run**
4. Ve a la pestaña **Arguments**
5. En **Environment Variables**, agrega:
   - **Name**: `EDUGO_ENVIRONMENT`
   - **Value**: `staging` (para Azure) o `development` (para localhost)
6. Click **Close**
7. Ahora simplemente presiona **⌘R** para ejecutar

### Opción B: Crear Schemes separados (Más cómodo)

#### Scheme para Azure:
1. En Xcode: **Product** → **Scheme** → **Manage Schemes...**
2. Selecciona **DemoApp** y click en el icono de engranaje ⚙️ → **Duplicate**
3. Renombra a: **DemoApp (Azure)**
4. Click en **Edit...**
5. Ve a **Run** → **Arguments** → **Environment Variables**
6. Agrega:
   - **Name**: `EDUGO_ENVIRONMENT`
   - **Value**: `staging`
7. Click **Close**

#### Scheme para Localhost:
1. Repite los pasos anteriores
2. Renombra a: **DemoApp (Localhost)**
3. En Environment Variables:
   - **Name**: `EDUGO_ENVIRONMENT`
   - **Value**: `development`

Ahora puedes cambiar entre schemes desde el selector en la barra superior de Xcode.

---

## 🔍 Verificar el Ambiente Actual

El ambiente se detecta automáticamente en este orden de prioridad:

1. Variable de entorno `EDUGO_ENVIRONMENT` (staging, development, production)
2. Build configuration (`DEBUG` → development, `RELEASE` → production)

Para ver qué ambiente está usando la app, revisa los logs al iniciar:

```swift
// En ServiceContainer.swift, se inicializa con:
init(environment: AppEnvironment = .detect())

// Para debug, puedes agregar:
print("🌐 Running in \(environment) environment")
print("📡 API Config: \(apiConfiguration)")
```

---

## ⚠️ Importante: APIs en Azure

Las APIs en Azure están en tier **free** y tienen tiempo de inactividad. Si las APIs no responden:

1. Ejecuta el script de warm-up:
   ```bash
   /Users/jhoanmedina/source/EduGo/EduUI/kmp_new/warm-up-apis.sh
   ```

2. O espera ~30-60 segundos en el primer request (cold start)

---

## 🛠️ Variables de Entorno Avanzadas

Puedes sobrescribir URLs individuales:

```bash
# En Xcode: Edit Scheme → Arguments → Environment Variables
EDUGO_IAM_API_URL=https://custom-iam.example.com
EDUGO_ADMIN_API_URL=https://custom-admin.example.com
EDUGO_MOBILE_API_URL=https://custom-mobile.example.com
EDUGO_API_TIMEOUT=45
```

O desde terminal:

```bash
EDUGO_ENVIRONMENT=staging EDUGO_API_TIMEOUT=90 make run
```

---

## 📝 Notas

- **Por defecto, la app apunta a Azure** (staging) en modo DEBUG
- Si necesitas localhost, usa `make run-dev` o configura la variable `EDUGO_ENVIRONMENT=development`
- El código en `APIConfiguration.swift` ya soporta todos los ambientes
- No se usan parches ni código legacy - todo es Swift 6.2 estricto
