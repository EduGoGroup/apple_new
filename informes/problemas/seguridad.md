# Problemas de Seguridad

## SEC-01: CRITICAL - Tokens de autenticacion en UserDefaults sin cifrado

**Archivos**:
- `Packages/Domain/Sources/Services/Auth/AuthService.swift:157-269`
- `Packages/Infrastructure/Sources/Storage/Storage.swift:7-34`

**Descripcion**: `AuthService` persiste `AuthToken` (accessToken + refreshToken) en `UserDefaults.standard` via `StorageManager`. UserDefaults se almacena en un plist legible sin cifrar. En dispositivos con jailbreak, cualquier app puede leer estos datos.

**Impacto**: Un atacante con acceso fisico o un dispositivo comprometido puede extraer tokens de sesion y suplantar al usuario.

**Ver solucion**: [Token Storage Seguro](../soluciones/token-storage-seguro.md)

---

## SEC-02: HIGH - Fake token en AuthManager (protegido por #if DEBUG)

**Archivo**: `Packages/Domain/Sources/Services/Auth/Auth.swift:52`

**Descripcion**: `AuthManager` genera `accessToken = "dev_token_\(UUID().uuidString)"` en builds DEBUG. Tiene un `throw` en `#else`, lo cual es correcto. Sin embargo, si el flag DEBUG se deja activado por error en un release, se generarian tokens falsos.

**Impacto**: Riesgo de token falso en release si la configuracion de build es incorrecta.

---

## SEC-03: HIGH - Sin Certificate Pinning (TLS)

**Archivos**:
- `Packages/Infrastructure/Sources/Network/Network.swift`
- `modulos/NetworkSDK/Sources/NetworkSDK/Network.swift`

**Descripcion**: `NetworkClient` usa `URLSession(configuration:)` sin delegate. No hay certificate pinning ni validacion TLS personalizada. Busqueda de `certificatePinn`, `ServerTrust`, `pinnedCertificates`: 0 resultados.

**Impacto**: Vulnerable a ataques Man-in-the-Middle donde un proxy o WiFi malicioso intercepta trafico incluyendo tokens.

**Ver solucion**: [Certificate Pinning](../soluciones/certificate-pinning.md)

---

## SEC-04: MEDIUM - HTTP sin TLS para entorno de desarrollo

**Archivo**: `Packages/Core/Sources/EduCore/Configuration/APIConfiguration.swift:123-125`

**Descripcion**: URLs de desarrollo usan `http://localhost:80XX`. Solo aplica a `.development`. Staging y production usan HTTPS.

**Impacto**: Bajo. Aceptable para desarrollo local.

---

## SEC-05: MEDIUM - DynamicUI sin sanitizacion de datos del servidor

**Archivos**:
- `Packages/DynamicUI/Sources/DynamicUI/Resolvers/PlaceholderResolver.swift`
- `Packages/DynamicUI/Sources/DynamicUI/Resolvers/SlotBindingResolver.swift`

**Descripcion**: PlaceholderResolver hace reemplazo directo sin sanitizacion. Si `userInfo.firstName` contiene HTML/JS, se insertaria tal cual. SwiftUI nativo mitiga XSS, pero si se usa WKWebView seria vulnerable.

**Impacto**: Medio. Mitigado por SwiftUI pero falta defensa en profundidad.

---

## SEC-06: MEDIUM - Datos de sync y mutation queue en UserDefaults

**Archivos**:
- `Packages/Domain/Sources/Services/Offline/MutationQueue.swift:162`
- `Packages/Domain/Sources/Services/Sync/LocalSyncStore.swift:52`

**Descripcion**: Mutation queue y sync bundle persisten en UserDefaults. Si contienen PII o datos academicos, estan sin cifrar.

---

## SEC-07: MEDIUM - SwiftData models sin cifrado de datos en reposo

**Archivos**: 6 modelos @Model en `Packages/Infrastructure/Sources/Persistence/Models/`

**Descripcion**: Modelos SwiftData almacenan email, nombre, informacion academica sin `ModelConfiguration` con file protection.

---

## SEC-08: LOW - Logging incluye URLs en modo DEBUG

**Archivo**: `Packages/Infrastructure/Sources/Network/Network.swift:513-543`

Protegido por `#if DEBUG`. Aceptable.

---

## SEC-09: LOW - try! en previews/examples de domain models

**Archivos**: Multiples archivos en `Packages/Core/Sources/Models/Domain/`

Solo afecta previews de desarrollo, no produccion.

---

## SEC-10: LOW - print() en previews de Presentation

**Archivos**: ~50+ print() en `Packages/Presentation/Sources/Components/`

Solo en contextos de preview con datos estaticos.
