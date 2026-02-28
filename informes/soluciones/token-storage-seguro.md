# Solucion: Token Storage Seguro

**Problema**: [SEC-01 CRITICAL](../problemas/seguridad.md) - Tokens de autenticacion almacenados en UserDefaults sin cifrado.

**Resumen**: `AuthService` y `StorageManager` usan `UserDefaults` para persistir accessToken y refreshToken. UserDefaults almacena en un plist legible sin cifrar, exponiendo credenciales en dispositivos con jailbreak o backups no cifrados.

---

## Solucion A: KeychainManager dedicado (RECOMENDADA)

**Descripcion**: Crear un `KeychainManager` actor que encapsule las operaciones de Keychain Services (`SecItemAdd`, `SecItemCopyMatching`, `SecItemUpdate`, `SecItemDelete`).

**Plan de trabajo**:
1. Crear `Packages/Infrastructure/Sources/Storage/KeychainManager.swift` - Actor con CRUD generico para Keychain
2. Agregar enum `KeychainAccessibility` con opciones de proteccion (`.whenUnlockedThisDeviceOnly`, etc.)
3. Modificar `AuthService` para usar `KeychainManager` en vez de `UserDefaults` para tokens
4. Mantener `StorageManager` para datos no sensibles (preferencias, cache local)
5. Migrar datos existentes: al primer launch, leer tokens de UserDefaults, guardar en Keychain, eliminar de UserDefaults
6. Tests: verificar save/retrieve/delete en Keychain, verificar migracion

**Archivos a modificar**:
- NUEVO: `Packages/Infrastructure/Sources/Storage/KeychainManager.swift`
- MODIFICAR: `Packages/Domain/Sources/Services/Auth/AuthService.swift` (reemplazar UserDefaults por Keychain)
- NUEVO: `Packages/Infrastructure/Tests/InfrastructureTests/Storage/KeychainManagerTests.swift`

**Riesgo**: Bajo. Keychain es el estandar de la industria para credenciales en Apple platforms.

---

## Solucion B: Wrapper de Security framework con CryptoKit

**Descripcion**: Cifrar datos con CryptoKit antes de guardarlos en UserDefaults. Llave de cifrado en Keychain.

**Plan de trabajo**:
1. Crear `EncryptedStorageManager` que cifra con `AES.GCM.seal()` antes de guardar en UserDefaults
2. Llave simetrica almacenada en Keychain
3. Modificar `AuthService` para usar `EncryptedStorageManager`

**Riesgo**: Medio. Mas complejidad que la Solucion A. La llave en Keychain es un punto de falla adicional.

**No recomendada**: La Solucion A es mas simple y directa.

---

## Solucion Recomendada: A (KeychainManager)

Razon: Es el patron estandar de Apple. Menos complejidad. No requiere manejar cifrado manualmente. Compatible con iCloud Keychain si se necesita en el futuro.
