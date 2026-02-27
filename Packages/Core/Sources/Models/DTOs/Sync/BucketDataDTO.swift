// BucketDataDTO.swift
// Models
//
// Data Transfer Object for bucket data in delta sync responses.

import Foundation

/// Data Transfer Object representing a single bucket of changed data
/// in a delta sync response.
///
/// ## JSON Structure (from backend)
/// ```json
/// {
///     "data": { ... },
///     "hash": "abc123def456"
/// }
/// ```
public struct BucketDataDTO: Codable, Sendable {
    /// The bucket payload as arbitrary JSON.
    public let data: JSONValue

    /// Hash of the bucket data for future delta comparisons.
    public let hash: String

    public init(data: JSONValue, hash: String) {
        self.data = data
        self.hash = hash
    }
}
