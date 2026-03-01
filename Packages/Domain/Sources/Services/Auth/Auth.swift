import Foundation
import EduCore
import EduFoundation

/// Auth - Authentication and authorization module
///
/// Handles user authentication, token management, and authorization.
/// TIER-3 Domain module.
///
/// ## UserContextProtocol Implementation
///
/// AuthManager implementa `UserContextProtocol` para exponer información básica
/// del usuario a otros módulos sin crear dependencias circulares.
public actor AuthManager: Sendable, UserContextProtocol {
    public static let shared = AuthManager()

    private var currentUser: User?
    private var accessToken: String?

    private init() {}

    /// Check if user is authenticated
    public var isAuthenticated: Bool {
        accessToken != nil
    }

    /// Get current authenticated user
    public func getCurrentUser() -> User? {
        currentUser
    }

    /// Sign in with credentials
    ///
    /// - Parameters:
    ///   - email: User email address
    ///   - password: User password
    ///
    /// - Throws: `DomainError.validationFailed` if email is invalid
    ///
    /// - Important: This is a **development stub**. Replace with a Keychain-backed
    ///   implementation that calls the IAM API before shipping to staging or production.
    ///   See `informes/soluciones/token-storage-seguro.md` for the migration plan.
    #warning("STUB: AuthManager.signIn must be replaced with Keychain-backed IAM auth before release.")
    public func signIn(email: String, password: String) async throws {
        #if DEBUG
        let user = try User(id: UUID(), firstName: "Dev", lastName: "User", email: email)
        currentUser = user
        accessToken = "dev_token_\(UUID().uuidString)"
        #else
        throw DomainError.invalidOperation(operation: "Authentication not configured for production")
        #endif
    }

    /// Sign out
    public func signOut() {
        currentUser = nil
        accessToken = nil
    }

    // MARK: - UserContextProtocol Implementation

    /// ID del usuario actualmente autenticado
    public var currentUserId: UUID? {
        get async {
            currentUser?.id
        }
    }

    /// Email del usuario actualmente autenticado
    public var currentUserEmail: String? {
        get async {
            currentUser?.email
        }
    }
}
