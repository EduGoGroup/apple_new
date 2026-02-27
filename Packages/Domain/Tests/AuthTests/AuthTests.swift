import Testing
import Foundation
@testable import EduDomain

@Suite("Auth Tests")
struct AuthTests {
    @Test("AuthManager shared instance is accessible")
    func testSharedInstance() {
        let auth = AuthManager.shared
        // Auth should be accessible - if this compiles and runs, the test passes
        _ = auth
    }

    @Test("Initial authentication state is false")
    func testInitialAuthState() async {
        let auth = AuthManager.shared
        await auth.signOut() // Ensure clean state

        let isAuth = await auth.isAuthenticated
        #expect(isAuth == false)
    }

    @Test("Sign in updates authentication state")
    func testSignIn() async throws {
        let auth = AuthManager.shared

        try await auth.signIn(email: "test@edugo.com", password: "password")

        let isAuth = await auth.isAuthenticated
        #expect(isAuth == true)

        await auth.signOut()
    }
}
