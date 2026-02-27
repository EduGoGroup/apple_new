import Testing
import Foundation
@testable import EduModels

@Suite("AuthToken Tests")
struct AuthTokenTests {

    // MARK: - isExpired

    @Test("isExpired returns true when expiresAt is in the past")
    func testIsExpiredTrue() {
        let token = AuthToken(
            accessToken: "access",
            refreshToken: "refresh",
            expiresAt: Date.now.addingTimeInterval(-60)
        )

        #expect(token.isExpired == true)
    }

    @Test("isExpired returns false when expiresAt is in the future")
    func testIsExpiredFalse() {
        let token = AuthToken(
            accessToken: "access",
            refreshToken: "refresh",
            expiresAt: Date.now.addingTimeInterval(3600)
        )

        #expect(token.isExpired == false)
    }

    // MARK: - shouldRefresh

    @Test("shouldRefresh returns true when less than 5 minutes remain")
    func testShouldRefreshTrue() {
        let token = AuthToken(
            accessToken: "access",
            refreshToken: "refresh",
            expiresAt: Date.now.addingTimeInterval(180) // 3 minutes
        )

        #expect(token.shouldRefresh() == true)
    }

    @Test("shouldRefresh returns false when more than 5 minutes remain")
    func testShouldRefreshFalse() {
        let token = AuthToken(
            accessToken: "access",
            refreshToken: "refresh",
            expiresAt: Date.now.addingTimeInterval(600) // 10 minutes
        )

        #expect(token.shouldRefresh() == false)
    }

    @Test("shouldRefresh returns true for already expired token")
    func testShouldRefreshExpired() {
        let token = AuthToken(
            accessToken: "access",
            refreshToken: "refresh",
            expiresAt: Date.now.addingTimeInterval(-300)
        )

        #expect(token.shouldRefresh() == true)
    }

    @Test("shouldRefresh uses custom threshold")
    func testShouldRefreshCustomThreshold() {
        let token = AuthToken(
            accessToken: "access",
            refreshToken: "refresh",
            expiresAt: Date.now.addingTimeInterval(480) // 8 minutes
        )

        // 5 min threshold → false (8 > 5)
        #expect(token.shouldRefresh(thresholdMinutes: 5) == false)
        // 10 min threshold → true (8 < 10)
        #expect(token.shouldRefresh(thresholdMinutes: 10) == true)
    }

    // MARK: - Factory: from LoginResponseDTO

    @Test("AuthToken.from(response: LoginResponseDTO) calculates expiresAt")
    func testFactoryFromLoginResponse() {
        let response = LoginResponseDTO(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            expiresIn: 3600,
            tokenType: "Bearer",
            user: AuthUserInfoDTO(
                id: "u1",
                email: "test@test.com",
                firstName: "Test",
                lastName: "User",
                fullName: "Test User"
            ),
            schools: [],
            activeContext: UserContextDTO(roleId: "r1", roleName: "admin")
        )

        let before = Date.now
        let token = AuthToken.from(response: response)
        let after = Date.now

        #expect(token.accessToken == "access-token")
        #expect(token.refreshToken == "refresh-token")
        #expect(token.tokenType == "Bearer")

        // expiresAt should be ~3600 seconds from now
        let expectedLow = before.addingTimeInterval(3600)
        let expectedHigh = after.addingTimeInterval(3600)
        #expect(token.expiresAt >= expectedLow)
        #expect(token.expiresAt <= expectedHigh)
    }

    // MARK: - Factory: from RefreshTokenResponseDTO

    @Test("AuthToken.from(response: RefreshTokenResponseDTO) calculates expiresAt")
    func testFactoryFromRefreshResponse() {
        let response = RefreshTokenResponseDTO(
            accessToken: "new-access",
            refreshToken: "new-refresh",
            expiresIn: 7200,
            tokenType: "Bearer"
        )

        let before = Date.now
        let token = AuthToken.from(response: response)
        let after = Date.now

        #expect(token.accessToken == "new-access")
        #expect(token.refreshToken == "new-refresh")

        let expectedLow = before.addingTimeInterval(7200)
        let expectedHigh = after.addingTimeInterval(7200)
        #expect(token.expiresAt >= expectedLow)
        #expect(token.expiresAt <= expectedHigh)
    }

    // MARK: - Codable Round-trip

    @Test("AuthToken round-trips through JSON encoding/decoding")
    func testCodableRoundTrip() throws {
        let original = AuthToken(
            accessToken: "access",
            refreshToken: "refresh",
            expiresAt: Date(timeIntervalSince1970: 1700000000),
            tokenType: "Bearer"
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AuthToken.self, from: data)

        #expect(decoded == original)
    }

    // MARK: - Default tokenType

    @Test("Default tokenType is Bearer")
    func testDefaultTokenType() {
        let token = AuthToken(
            accessToken: "a",
            refreshToken: "r",
            expiresAt: Date.now
        )

        #expect(token.tokenType == "Bearer")
    }
}
