// DeltaSyncResponseDTO.swift
// Models
//
// Data Transfer Object for delta sync responses.

import Foundation

/// Data Transfer Object representing the server's response to a delta sync request.
///
/// Contains changed buckets with their new data and hashes, plus a list of
/// unchanged bucket names.
///
/// ## JSON Structure (from backend)
/// ```json
/// {
///     "changed": {
///         "menu": { "data": { ... }, "hash": "new_hash" }
///     },
///     "unchanged": ["screens", "permissions"]
/// }
/// ```
public struct DeltaSyncResponseDTO: Codable, Sendable {
    /// Buckets that have changed, keyed by bucket name.
    public let changed: [String: BucketDataDTO]

    /// Names of buckets that remain unchanged.
    public let unchanged: [String]

    public init(changed: [String: BucketDataDTO], unchanged: [String]) {
        self.changed = changed
        self.unchanged = unchanged
    }
}
