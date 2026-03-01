import Foundation

/// Configuration for TLS public key pinning.
///
/// Maps domain hostnames to a set of expected SHA-256 public key hashes
/// (base64-encoded). Supports multiple pins per domain for key rotation.
///
/// ## Usage
/// ```swift
/// let config = PinConfiguration.staging
/// let pins = config.pins(for: "edugo-api-iam-platform.wittyhill-f6d656fb.eastus.azurecontainerapps.io")
/// ```
public struct PinConfiguration: Sendable {

    /// Domain → Set of SHA-256 base64 public key hashes.
    public let domainPins: [String: Set<String>]

    /// Creates a pin configuration with explicit domain-to-hash mappings.
    public init(domainPins: [String: Set<String>]) {
        self.domainPins = domainPins
    }

    /// Returns the set of expected pin hashes for a given host, or `nil` if the domain is not pinned.
    public func pins(for host: String) -> Set<String>? {
        domainPins[host]
    }

    /// Whether the given host has pins configured.
    public func isPinned(_ host: String) -> Bool {
        domainPins[host] != nil
    }

    // MARK: - Factory Methods

    /// Development configuration — no pinning (localhost).
    public static let development = PinConfiguration(domainPins: [:])

    // PLACEHOLDER: Replace with actual SHA-256 public key hashes from Azure infrastructure team.
    // To obtain:
    //   openssl s_client -connect <host>:443 | openssl x509 -pubkey \
    //     | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary \
    //     | openssl enc -base64

    /// Staging configuration — Azure Container Apps domains.
    public static let staging = PinConfiguration(domainPins: [
        "edugo-api-iam-platform.wittyhill-f6d656fb.eastus.azurecontainerapps.io": [
            "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=",  // Primary
            "CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC="   // Backup for rotation
        ],
        "edugo-api-admin-new.wittyhill-f6d656fb.eastus.azurecontainerapps.io": [
            "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=",
            "CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC="
        ],
        "edugo-api-mobile-new.wittyhill-f6d656fb.eastus.azurecontainerapps.io": [
            "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=",
            "CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC="
        ]
    ])

    /// Production configuration — production domains.
    public static let production = PinConfiguration(domainPins: [
        "api-iam.edugo.com": [
            "DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD=",  // Primary
            "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE="     // Backup for rotation
        ],
        "api.edugo.com": [
            "DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD=",
            "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE="
        ],
        "api-mobile.edugo.com": [
            "DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD=",
            "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE="
        ]
    ])

    /// Returns the pin configuration for a given environment.
    public static func forEnvironment(_ environment: String) -> PinConfiguration {
        switch environment {
        case "development":
            return .development
        case "staging":
            return .staging
        case "production":
            return .production
        default:
            return .production
        }
    }
}
