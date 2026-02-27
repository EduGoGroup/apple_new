import Foundation
import EduInfrastructure
import EduCore

/// API - Backend API integration module
///
/// Provides high-level API clients for EduGo backend services.
/// TIER-4 Features module.
///
/// ## Configuration
///
/// The API base URL is configured via environment variable `EDUGO_API_BASE_URL`.
/// Default: `https://api.edugo.com`
///
/// Set in Xcode scheme or launch arguments:
/// ```
/// EDUGO_API_BASE_URL=https://staging.edugo.com
/// ```
public actor APIClient: Sendable {
    public static let shared = APIClient()

    private let networkClient: NetworkClient
    private let baseURL: URL

    private init() {
        self.networkClient = .shared

        // Use environment variable or fallback to default
        let baseURLString = ProcessInfo.processInfo.environment["EDUGO_API_BASE_URL"] ?? "https://api.edugo.com"

        guard let url = URL(string: baseURLString) else {
            // Fallback to default if invalid URL in environment
            self.baseURL = URL(string: "https://api.edugo.com")!
            return
        }

        self.baseURL = url
    }

    /// Fetch user profile
    public func fetchUserProfile(userId: UUID) async throws -> User {
        let url = baseURL.appendingPathComponent("users/\(userId.uuidString)")
        return try await networkClient.request(url)
    }

    /// Update user profile
    public func updateUserProfile(_ user: User) async throws {
        let url = baseURL.appendingPathComponent("users/\(user.id.uuidString)")
        // Implementation would use POST/PUT request
    }
}
