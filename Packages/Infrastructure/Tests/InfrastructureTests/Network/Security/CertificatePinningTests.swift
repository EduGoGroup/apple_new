import Testing
import Foundation
@testable import EduNetwork

// MARK: - PinConfiguration Tests

@Suite("PinConfiguration Tests")
struct PinConfigurationTests {

    @Test("Development environment has no pins")
    func testDevelopmentHasNoPins() {
        let config = PinConfiguration.development
        #expect(config.domainPins.isEmpty)
    }

    @Test("Staging has correct IAM domain pinned")
    func testStagingIAMDomain() {
        let config = PinConfiguration.staging
        let host = "edugo-api-iam-platform.wittyhill-f6d656fb.eastus.azurecontainerapps.io"
        #expect(config.isPinned(host))
        #expect(config.pins(for: host)?.count == 2)
    }

    @Test("Staging has correct admin domain pinned")
    func testStagingAdminDomain() {
        let config = PinConfiguration.staging
        let host = "edugo-api-admin-new.wittyhill-f6d656fb.eastus.azurecontainerapps.io"
        #expect(config.isPinned(host))
        #expect(config.pins(for: host)?.count == 2)
    }

    @Test("Staging has correct mobile domain pinned")
    func testStagingMobileDomain() {
        let config = PinConfiguration.staging
        let host = "edugo-api-mobile-new.wittyhill-f6d656fb.eastus.azurecontainerapps.io"
        #expect(config.isPinned(host))
        #expect(config.pins(for: host)?.count == 2)
    }

    @Test("Production has correct domains pinned")
    func testProductionDomains() {
        let config = PinConfiguration.production
        #expect(config.isPinned("api-iam.edugo.com"))
        #expect(config.isPinned("api.edugo.com"))
        #expect(config.isPinned("api-mobile.edugo.com"))
        #expect(config.pins(for: "api-iam.edugo.com")?.count == 2)
    }

    @Test("Unknown domain returns nil pins")
    func testUnknownDomain() {
        let config = PinConfiguration.staging
        #expect(config.pins(for: "unknown.example.com") == nil)
        #expect(!config.isPinned("unknown.example.com"))
    }

    @Test("forEnvironment returns correct configuration")
    func testForEnvironment() {
        let dev = PinConfiguration.forEnvironment("development")
        #expect(dev.domainPins.isEmpty)

        let staging = PinConfiguration.forEnvironment("staging")
        #expect(staging.domainPins.count == 3)

        let prod = PinConfiguration.forEnvironment("production")
        #expect(prod.domainPins.count == 3)

        // Unknown environment defaults to production (fail-safe)
        let unknown = PinConfiguration.forEnvironment("unknown")
        #expect(unknown.domainPins.count == 3)
    }

    @Test("Each environment has backup pins for rotation")
    func testBackupPinsExist() {
        let staging = PinConfiguration.staging
        for (_, pins) in staging.domainPins {
            #expect(pins.count >= 2, "Each domain should have at least a primary and backup pin")
        }

        let production = PinConfiguration.production
        for (_, pins) in production.domainPins {
            #expect(pins.count >= 2, "Each domain should have at least a primary and backup pin")
        }
    }
}

// MARK: - CertificatePinningDelegate Tests

@Suite("CertificatePinningDelegate Tests")
struct CertificatePinningDelegateTests {

    @Test("SHA256 hash produces consistent output")
    func testSha256Consistency() {
        let data = Data("hello world".utf8)
        let hash1 = CertificatePinningDelegate.sha256Base64(data)
        let hash2 = CertificatePinningDelegate.sha256Base64(data)
        #expect(hash1 == hash2)
        #expect(!hash1.isEmpty)
    }

    @Test("SHA256 hash of known data produces correct base64")
    func testSha256KnownValue() {
        // SHA256("") = e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
        let emptyData = Data()
        let hash = CertificatePinningDelegate.sha256Base64(emptyData)
        #expect(hash == "47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=")
    }

    @Test("Different data produces different hashes")
    func testDifferentDataDifferentHashes() {
        let data1 = Data("hello".utf8)
        let data2 = Data("world".utf8)
        let hash1 = CertificatePinningDelegate.sha256Base64(data1)
        let hash2 = CertificatePinningDelegate.sha256Base64(data2)
        #expect(hash1 != hash2)
    }

    @Test("Delegate can be created with empty configuration")
    func testDelegateCreation() {
        let delegate = CertificatePinningDelegate(configuration: .development)
        #expect(delegate != nil)
    }

    @Test("Delegate can be created with staging configuration")
    func testDelegateWithStagingConfig() {
        let delegate = CertificatePinningDelegate(configuration: .staging)
        #expect(delegate != nil)
    }
}
