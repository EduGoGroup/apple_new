// DeltaSyncRequestDTO.swift
// Models
//
// Data Transfer Object for delta sync requests.

import Foundation

/// Data Transfer Object for requesting a delta sync from the backend.
///
/// Clients send their current hashes so the server can determine which
/// buckets have changed and need to be re-sent.
///
/// ## JSON Structure (sent to backend)
/// ```json
/// {
///     "hashes": {
///         "menu": "abc123",
///         "screens": "def456",
///         "permissions": "ghi789"
///     }
/// }
/// ```
public struct DeltaSyncRequestDTO: Codable, Sendable {
    /// Map of bucket names to their current hash values.
    public let hashes: [String: String]

    public init(hashes: [String: String]) {
        self.hashes = hashes
    }
}
