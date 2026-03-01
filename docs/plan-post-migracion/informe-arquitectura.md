# Informe Arquitectura — Mejoras Post-Migracion

## 1. Feature Flags desde Servidor

### Estado actual

No existe ningun mecanismo de feature flags en el codebase. No hay referencias a `FeatureFlag`, `toggle`, `experiment`, ni configuracion remota.

**Archivos relevantes:**
- `Packages/Core/Sources/Configuration/AppEnvironment.swift` — Solo maneja environment (dev/staging/prod), no features
- `Packages/Domain/Sources/Services/Sync/SyncService.swift` — Sync bundle no incluye feature flags

### Problema/oportunidad

- Imposible hacer rollout progresivo de features
- No hay mecanismo de kill-switch para features problematicas en produccion
- No hay A/B testing
- Cada cambio requiere nueva version de la app

### Solucion propuesta

**Diseno: `FeatureFlagService` (actor)**

```
Fuentes de flags (prioridad):
1. Override local (debug/development) — UserDefaults
2. Servidor (sync bundle) — se descarga con delta sync
3. Defaults compilados — fallback si no hay server ni override

Flujo:
App launch -> load defaults -> delta sync -> merge server flags -> notify observers
```

**Archivos a crear:**
- `Packages/Domain/Sources/Services/FeatureFlags/FeatureFlagService.swift` — Actor principal
- `Packages/Domain/Sources/Services/FeatureFlags/FeatureFlag.swift` — Enum con todos los flags
- `Packages/Domain/Sources/Services/FeatureFlags/FeatureFlagValue.swift` — Tipos de valor (bool, string, int, json)

**Archivos a modificar:**
- `Packages/Domain/Sources/Services/Sync/SyncService.swift` — Incluir flags en bundle
- `Packages/Core/Sources/Models/Sync/UserDataBundle.swift` — Agregar `featureFlags: [String: JSONValue]`
- `Apps/DemoApp/Sources/Services/ServiceContainer.swift` — Inyectar FeatureFlagService

### Plan de trabajo

1. Definir `FeatureFlag` enum con flags iniciales
2. Crear `FeatureFlagService` actor con cache local + remote sync
3. Agregar `featureFlags` a `UserDataBundle`
4. Integrar con `SyncService.deltaSync()` para recibir actualizaciones
5. Crear `FeatureFlagEnvironmentKey` para inyeccion en SwiftUI
6. Tests unitarios

**Complejidad:** ALTA — Nuevo subsistema transversal, afecta sync bundle

### Tests requeridos

- Flag booleano retorna valor default cuando no hay server
- Flag server sobreescribe default
- Override local sobreescribe server
- Flag desconocido retorna default seguro
- Sync actualiza flags sin reiniciar app

### Dependencias

- Backend debe soportar `feature_flags` en respuesta de sync bundle

---

## 2. Deduplicacion de Requests en Vuelo

### Estado actual

- `Packages/Infrastructure/Sources/Network/Interceptors/InterceptableNetworkClient.swift` (lineas 28-100)
  - `send()` construye URLRequest y ejecuta via URLSession
  - No hay tracking de requests en vuelo
  - No hay mapa de pending requests
  - Dos Views que pidan el mismo endpoint generan 2 HTTP requests

**Mecanismos existentes que NO deducan:**
- `CircuitBreaker` — Bloquea requests cuando hay muchos fallos, no deduplica
- `RateLimiter` — Limita tasa de requests, no deduplica
- URLSession HTTP/2 — Multiplexing a nivel TCP, pero cada request se procesa completo

### Problema/oportunidad

- Multiples ViewModels pueden pedir el mismo endpoint simultaneamente (ej: ScreenLoader + DataLoader)
- Refresh manual + auto-refresh pueden coincidir
- Desperdicio de ancho de banda y carga innecesaria al backend

### Solucion propuesta

**`RequestDeduplicator` (actor)**

```swift
actor RequestDeduplicator {
    // Clave: method + URL normalizada (sin timestamp params)
    private var inFlight: [String: Task<Data, Error>] = [:]

    func deduplicate(key: String, work: @Sendable () async throws -> Data) async throws -> Data {
        if let existing = inFlight[key] {
            return try await existing.value  // Reusar task existente
        }
        let task = Task { try await work() }
        inFlight[key] = task
        defer { inFlight[key] = nil }
        return try await task.value
    }
}
```

**Archivos a crear:**
- `Packages/Infrastructure/Sources/Network/Resilience/RequestDeduplicator.swift`

**Archivos a modificar:**
- `Packages/Infrastructure/Sources/Network/Interceptors/InterceptableNetworkClient.swift` — Integrar deduplicator antes de URLSession.send()

### Plan de trabajo

1. Crear `RequestDeduplicator` actor
2. Definir clave de deduplicacion (method + URL normalizada)
3. Integrar en `InterceptableNetworkClient.send()` para GET requests
4. Excluir POST/PUT/DELETE de deduplicacion (side effects)
5. Tests unitarios

**Complejidad:** MEDIA — Actor simple, integracion en 1 archivo

### Tests requeridos

- Dos GET simultaneos al mismo endpoint generan 1 HTTP request
- POST nunca se deduplica
- Request completado permite nuevo request al mismo endpoint
- Error en request se propaga a todos los waiters
- Requests con diferentes query params NO se deduplican

### Dependencias

Ninguna.

---

## 3. Compresion de Payloads (gzip)

### Estado actual

- `Packages/Infrastructure/Sources/Network/Interceptors/InterceptableNetworkClient.swift` (lineas 81-89)
  - URLSessionConfiguration no configura compresion explicita
  - URLSession decomprime automaticamente respuestas gzip del servidor
  - Request bodies no se comprimen

### Problema/oportunidad

- Bodies de POST/PUT pueden ser grandes (formularios con muchos campos, batch updates)
- Sin compresion, payloads se envian raw
- Ancho de banda desperdiciado en conexiones moviles

### Solucion propuesta

**`CompressionInterceptor` (RequestInterceptor)**

```swift
struct CompressionInterceptor: RequestInterceptor {
    let minSizeForCompression: Int = 1024  // 1KB threshold

    func intercept(request: URLRequest) async throws -> URLRequest {
        guard let body = request.httpBody, body.count > minSizeForCompression else { return request }
        var compressed = request
        compressed.httpBody = try (body as NSData).compressed(using: .zlib) as Data
        compressed.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
        return compressed
    }
}
```

**Archivos a crear:**
- `Packages/Infrastructure/Sources/Network/Interceptors/CompressionInterceptor.swift`

**Archivos a modificar:**
- `Apps/DemoApp/Sources/Services/ServiceContainer.swift` — Agregar interceptor a la cadena

### Plan de trabajo

1. Crear `CompressionInterceptor` como `RequestInterceptor`
2. Configurar threshold (1KB default)
3. Agregar a cadena de interceptors del authenticated client
4. Verificar que backend acepta Content-Encoding: gzip
5. Tests unitarios

**Complejidad:** BAJA — 1 archivo nuevo, 1 linea de integracion

### Tests requeridos

- Body > 1KB se comprime
- Body < 1KB no se comprime
- Header Content-Encoding: gzip se agrega
- Body vacio no se comprime
- GET request (sin body) no se modifica

### Dependencias

- Backend debe aceptar Content-Encoding: gzip en requests

---

## 4. Cifrado de Cache Local

### Estado actual

- `Packages/Domain/Sources/Services/Sync/LocalSyncStore.swift` (lineas 39-61)
  - Persiste `UserDataBundle` en UserDefaults como JSON plano
  - `encoder.encode(bundle)` -> `defaults.set(data, forKey:)` — SIN CIFRADO
  - Bundle contiene: menu, permisos, roles, contextos, screens, glossary, hashes

- `Packages/Domain/Sources/Services/Offline/MutationQueue.swift` (lineas 160-163)
  - Persiste mutations en UserDefaults como JSON plano
  - Contiene endpoints, bodies con datos de usuario

- `Packages/Infrastructure/Sources/Storage/KeychainManager.swift`
  - Tokens JWT ya se almacenan en Keychain (seguro)
  - Pero los datos de aplicacion estan en UserDefaults (inseguro)

### Problema/oportunidad

- Datos sensibles (permisos, roles, estructura de menus) en texto plano
- Accesibles en backup de dispositivo o dispositivos con jailbreak
- MutationQueue puede contener datos de formularios del usuario
- Riesgo MEDIO de exposicion de datos

### Solucion propuesta

**`EncryptedStorage` (actor)**

```swift
import CryptoKit

actor EncryptedStorage {
    private let keychain: KeychainManager
    private let keyTag = "com.edugo.storage.encryption.key"

    func save(data: Data, forKey key: String) throws {
        let encryptionKey = try getOrCreateKey()
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey)
        guard let combined = sealedBox.combined else { throw EncryptionError.sealFailed }
        UserDefaults.standard.set(combined, forKey: key)
    }

    func load(forKey key: String) throws -> Data {
        guard let combined = UserDefaults.standard.data(forKey: key) else { throw EncryptionError.notFound }
        let encryptionKey = try getOrCreateKey()
        let sealedBox = try AES.GCM.SealedBox(combined: combined)
        return try AES.GCM.open(sealedBox, using: encryptionKey)
    }
}
```

**Archivos a crear:**
- `Packages/Infrastructure/Sources/Storage/EncryptedStorage.swift`

**Archivos a modificar:**
- `Packages/Domain/Sources/Services/Sync/LocalSyncStore.swift` — Usar EncryptedStorage
- `Packages/Domain/Sources/Services/Offline/MutationQueue.swift` — Usar EncryptedStorage

### Plan de trabajo

1. Crear `EncryptedStorage` actor con CryptoKit AES-256-GCM
2. Almacenar clave de cifrado en Keychain (via KeychainManager)
3. Migrar `LocalSyncStore` de UserDefaults plano a EncryptedStorage
4. Migrar `MutationQueue` persistence a EncryptedStorage
5. Manejar migracion: si hay datos sin cifrar, leerlos, cifrarlos, reescribir
6. Tests unitarios

**Complejidad:** MEDIA — CryptoKit es directo, migracion requiere cuidado

### Tests requeridos

- Datos se cifran correctamente (round-trip save/load)
- Clave se almacena en Keychain
- Datos corruptos lanzan error apropiado
- Migracion de datos sin cifrar funciona
- Performance: cifrado/descifrado < 10ms para bundles tipicos

### Dependencias

Ninguna — CryptoKit es framework nativo de Apple.
