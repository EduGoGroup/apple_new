import Foundation
import Security
import CommonCrypto

/// URLSession delegate that performs TLS public key pinning.
///
/// Extracts the server's public key from the certificate chain, computes its
/// SHA-256 hash, and compares against the expected pins from `PinConfiguration`.
///
/// Domains without configured pins are allowed through (e.g., development/localhost).
///
/// ## Usage
/// ```swift
/// let delegate = CertificatePinningDelegate(configuration: .staging)
/// let session = URLSession(
///     configuration: .default,
///     delegate: delegate,
///     delegateQueue: nil
/// )
/// ```
public final class CertificatePinningDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {

    private let configuration: PinConfiguration

    /// Creates a pinning delegate with the given pin configuration.
    ///
    /// - Parameter configuration: Domain-to-hash mapping for pin validation.
    public init(configuration: PinConfiguration) {
        self.configuration = configuration
        super.init()
    }

    // MARK: - URLSessionDelegate

    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let host = challenge.protectionSpace.host

        // If no pins configured for this domain, allow it (development / unpinned domains)
        guard let expectedPins = configuration.pins(for: host) else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // Evaluate the server trust first
        if !evaluateServerTrust(serverTrust) {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Check the certificate chain for a matching public key hash
        if validatePins(serverTrust: serverTrust, expectedPins: expectedPins) {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    // MARK: - Pin Validation

    /// Validates that at least one certificate in the chain has a public key
    /// whose SHA-256 hash matches one of the expected pins.
    static func validatePins(
        serverTrust: SecTrust,
        expectedPins: Set<String>
    ) -> Bool {
        guard let chain = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate] else {
            return false
        }

        for secCert in chain {
            guard let publicKeyHash = Self.sha256HashOfPublicKey(for: secCert) else {
                continue
            }

            if expectedPins.contains(publicKeyHash) {
                return true
            }
        }

        return false
    }

    /// Computes the base64-encoded SHA-256 hash of a certificate's public key.
    static func sha256HashOfPublicKey(for certificate: SecCertificate) -> String? {
        guard let publicKey = SecCertificateCopyKey(certificate) else {
            return nil
        }

        var error: Unmanaged<CFError>?
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
            return nil
        }

        return sha256Base64(publicKeyData)
    }

    /// Computes the base64-encoded SHA-256 digest of raw data.
    static func sha256Base64(_ data: Data) -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash).base64EncodedString()
    }

    // MARK: - Trust Evaluation

    private func evaluateServerTrust(_ serverTrust: SecTrust) -> Bool {
        var error: CFError?
        return SecTrustEvaluateWithError(serverTrust, &error)
    }

    // Instance wrapper for testability
    private func validatePins(serverTrust: SecTrust, expectedPins: Set<String>) -> Bool {
        Self.validatePins(serverTrust: serverTrust, expectedPins: expectedPins)
    }
}
