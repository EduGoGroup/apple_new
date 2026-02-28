# Solucion: Certificate Pinning

**Problema**: [SEC-03 HIGH](../problemas/seguridad.md) - Sin certificate pinning ni validacion TLS personalizada.

**Resumen**: `NetworkClient` usa `URLSession(configuration:)` sin delegate. No hay validacion de certificados mas alla del trust store del sistema. Vulnerable a MITM con CA comprometida.

---

## Solucion A: URLSessionDelegate con Public Key Pinning (RECOMENDADA)

**Descripcion**: Implementar `URLSessionDelegate` que valide los public keys del servidor contra pins embebidos en la app.

**Plan de trabajo**:
1. Crear `Packages/Infrastructure/Sources/Network/Security/CertificatePinningDelegate.swift`
   - Implementar `urlSession(_:didReceive:completionHandler:)`
   - Extraer public key del certificate chain
   - Comparar hash SHA256 contra pins embebidos
2. Crear `Packages/Infrastructure/Sources/Network/Security/PinConfiguration.swift`
   - Pins por dominio (staging vs production)
   - Soporte para pin rotation (backup pins)
3. Modificar `NetworkClient.init` para aceptar delegate
4. Configurar pins para:
   - `edugo-api-iam-platform.wittyhill-f6d656fb.eastus.azurecontainerapps.io`
   - `edugo-api-admin-new.wittyhill-f6d656fb.eastus.azurecontainerapps.io`
   - `edugo-api-mobile-new.wittyhill-f6d656fb.eastus.azurecontainerapps.io`
5. Excluir localhost/development de pinning
6. Tests con certificados mock

**Archivos a modificar**:
- NUEVO: `Packages/Infrastructure/Sources/Network/Security/CertificatePinningDelegate.swift`
- NUEVO: `Packages/Infrastructure/Sources/Network/Security/PinConfiguration.swift`
- MODIFICAR: `Packages/Infrastructure/Sources/Network/Network.swift` (agregar delegate parameter)
- NUEVO: Tests

**Riesgo**: Medio. Si los pins se desactualizan, la app dejara de funcionar. Requiere proceso de actualizacion de pins.

---

## Solucion B: TrustKit (dependencia externa)

**Descripcion**: Usar la libreria TrustKit de DataTheorem para certificate pinning automatico.

**Plan de trabajo**: Agregar TrustKit como dependencia SPM y configurar via Info.plist.

**Riesgo**: Alto. Agrega dependencia externa (el proyecto tiene zero dependencias externas por politica).

**No recomendada**: Viola la politica de zero dependencias externas.

---

## Solucion Recomendada: A (Public Key Pinning nativo)

Razon: Sin dependencias externas. Control total. Public key pinning sobrevive a rotacion de certificados (solo cambia si el server genera nueva key pair).

**Nota**: Este es un cambio que requiere coordinar con el equipo de infraestructura para obtener los public key hashes de los servidores de Azure.
