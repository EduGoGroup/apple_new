import Foundation

/// CodableSerializer - Thread-safe serialization actor
///
/// Provides a centralized, thread-safe API for JSON encoding and decoding
/// with pre-configured strategies for ISO8601 dates and snake_case keys.
///
/// ## Overview
/// `CodableSerializer` encapsulates `JSONEncoder` and `JSONDecoder` as private
/// properties within an actor, ensuring thread-safe access in Swift 6.2 concurrent
/// environments. This eliminates the need for ad-hoc encoder/decoder creation
/// throughout the codebase.
///
/// ## Usage
/// ```swift
/// let serializer = CodableSerializer.shared
///
/// // Encoding
/// let user = User(id: UUID(), name: "John", createdAt: Date())
/// let data = try await serializer.encode(user)
///
/// // Decoding
/// let decodedUser: User = try await serializer.decode(User.self, from: data)
///
/// // Pretty-printed output
/// let prettyData = try await serializer.encode(user, prettyPrinted: true)
/// ```
///
/// ## Thread Safety
/// As a Swift 6.2 actor, all operations are automatically thread-safe
/// without requiring locks or dispatch queues.
///
/// ## Configuration
/// Default strategies:
/// - Date encoding/decoding: ISO8601
/// - Key encoding/decoding: snake_case ↔ camelCase conversion
public actor CodableSerializer: Sendable {

    // MARK: - Singleton

    /// Shared instance with default configuration (snake_case key conversion).
    /// Use for types WITHOUT explicit CodingKeys.
    public static let shared = CodableSerializer()

    /// Shared instance for DTOs with explicit CodingKeys.
    /// Uses ISO8601 dates but NO key conversion (DTOs handle snake_case themselves).
    public static let dtoSerializer = CodableSerializer(configuration: .dtoCompatible)

    // MARK: - Private Properties

    /// JSON encoder with pre-configured strategies.
    private let encoder: JSONEncoder

    /// JSON decoder with pre-configured strategies.
    private let decoder: JSONDecoder

    // MARK: - Initialization

    /// Initializes the serializer with default configuration.
    ///
    /// Default configuration:
    /// - `.dateEncodingStrategy = .iso8601`
    /// - `.keyEncodingStrategy = .convertToSnakeCase`
    /// - `.dateDecodingStrategy = .iso8601`
    /// - `.keyDecodingStrategy = .convertFromSnakeCase`
    public init() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        self.encoder = encoder
        self.decoder = decoder
    }

    /// Initializes the serializer with a custom configuration.
    ///
    /// - Parameter configuration: Custom configuration for encoder/decoder strategies.
    public init(configuration: SerializerConfiguration) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = configuration.dateEncodingStrategy
        encoder.keyEncodingStrategy = configuration.keyEncodingStrategy
        if let outputFormatting = configuration.outputFormatting {
            encoder.outputFormatting = outputFormatting
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = configuration.dateDecodingStrategy
        decoder.keyDecodingStrategy = configuration.keyDecodingStrategy

        self.encoder = encoder
        self.decoder = decoder
    }

    // MARK: - Encoding

    /// Encodes an `Encodable` value to JSON data.
    ///
    /// - Parameters:
    ///   - value: The value to encode.
    ///   - prettyPrinted: If `true`, formats the output with indentation for readability.
    ///                    Defaults to `false`.
    /// - Returns: The encoded JSON data.
    /// - Throws: `SerializationError.encodingFailed` if encoding fails.
    ///
    /// ## Example
    /// ```swift
    /// struct User: Codable {
    ///     let userId: UUID
    ///     let userName: String
    ///     let createdAt: Date
    /// }
    ///
    /// let user = User(userId: UUID(), userName: "John", createdAt: Date())
    /// let data = try await serializer.encode(user)
    /// // JSON: {"user_id":"...","user_name":"John","created_at":"2024-01-15T10:30:00Z"}
    /// ```
    public func encode<T: Encodable>(_ value: T, prettyPrinted: Bool = false) async throws -> Data {
        do {
            if prettyPrinted {
                let prettyEncoder = JSONEncoder()
                prettyEncoder.dateEncodingStrategy = encoder.dateEncodingStrategy
                prettyEncoder.keyEncodingStrategy = encoder.keyEncodingStrategy
                prettyEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                return try prettyEncoder.encode(value)
            }
            return try encoder.encode(value)
        } catch let error as EncodingError {
            throw SerializationError.encodingFailed(
                type: String(describing: T.self),
                reason: describeEncodingError(error)
            )
        } catch {
            throw SerializationError.encodingFailed(
                type: String(describing: T.self),
                reason: error.localizedDescription
            )
        }
    }

    /// Encodes an `Encodable` value to a JSON string.
    ///
    /// - Parameters:
    ///   - value: The value to encode.
    ///   - prettyPrinted: If `true`, formats the output with indentation for readability.
    /// - Returns: The encoded JSON string.
    /// - Throws: `SerializationError.encodingFailed` if encoding fails.
    public func encodeToString<T: Encodable>(_ value: T, prettyPrinted: Bool = false) async throws -> String {
        let data = try await encode(value, prettyPrinted: prettyPrinted)
        guard let string = String(data: data, encoding: .utf8) else {
            throw SerializationError.encodingFailed(
                type: String(describing: T.self),
                reason: "Failed to convert data to UTF-8 string"
            )
        }
        return string
    }

    // MARK: - Decoding

    /// Decodes JSON data to a `Decodable` type.
    ///
    /// - Parameters:
    ///   - type: The type to decode to.
    ///   - data: The JSON data to decode.
    /// - Returns: The decoded value.
    /// - Throws: `SerializationError.decodingFailed` if decoding fails.
    ///
    /// ## Example
    /// ```swift
    /// let json = """
    /// {"user_id":"123","user_name":"John","created_at":"2024-01-15T10:30:00Z"}
    /// """.data(using: .utf8)!
    ///
    /// let user: User = try await serializer.decode(User.self, from: json)
    /// // user.userId, user.userName, user.createdAt are populated
    /// ```
    public func decode<T: Decodable>(_ type: T.Type, from data: Data) async throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch let error as DecodingError {
            throw SerializationError.decodingFailed(
                type: String(describing: T.self),
                reason: describeDecodingError(error)
            )
        } catch {
            throw SerializationError.decodingFailed(
                type: String(describing: T.self),
                reason: error.localizedDescription
            )
        }
    }

    /// Decodes a JSON string to a `Decodable` type.
    ///
    /// - Parameters:
    ///   - type: The type to decode to.
    ///   - string: The JSON string to decode.
    /// - Returns: The decoded value.
    /// - Throws: `SerializationError.decodingFailed` if decoding fails.
    public func decode<T: Decodable>(_ type: T.Type, from string: String) async throws -> T {
        guard let data = string.data(using: .utf8) else {
            throw SerializationError.decodingFailed(
                type: String(describing: T.self),
                reason: "Failed to convert string to UTF-8 data"
            )
        }
        return try await decode(type, from: data)
    }

    // MARK: - Private Helpers

    /// Describes an encoding error in a human-readable format.
    private func describeEncodingError(_ error: EncodingError) -> String {
        switch error {
        case .invalidValue(let value, let context):
            let path = context.codingPath.map(\.stringValue).joined(separator: ".")
            return "Invalid value '\(value)' at \(path.isEmpty ? "root" : path): \(context.debugDescription)"
        @unknown default:
            return error.localizedDescription
        }
    }

    /// Describes a decoding error in a human-readable format.
    private func describeDecodingError(_ error: DecodingError) -> String {
        switch error {
        case .typeMismatch(let type, let context):
            let path = context.codingPath.map(\.stringValue).joined(separator: ".")
            return "Type mismatch for \(type) at \(path.isEmpty ? "root" : path)"
        case .valueNotFound(let type, let context):
            let path = context.codingPath.map(\.stringValue).joined(separator: ".")
            return "Value not found for \(type) at \(path.isEmpty ? "root" : path)"
        case .keyNotFound(let key, let context):
            let path = context.codingPath.map(\.stringValue).joined(separator: ".")
            let fullPath = path.isEmpty ? key.stringValue : "\(path).\(key.stringValue)"
            return "Key '\(key.stringValue)' not found at \(fullPath)"
        case .dataCorrupted(let context):
            let path = context.codingPath.map(\.stringValue).joined(separator: ".")
            return "Data corrupted at \(path.isEmpty ? "root" : path): \(context.debugDescription)"
        @unknown default:
            return error.localizedDescription
        }
    }
}

// MARK: - SerializerConfiguration

/// Configuration options for `CodableSerializer`.
public struct SerializerConfiguration: Sendable {

    /// Date encoding strategy for the encoder.
    public let dateEncodingStrategy: JSONEncoder.DateEncodingStrategy

    /// Key encoding strategy for the encoder.
    public let keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy

    /// Date decoding strategy for the decoder.
    public let dateDecodingStrategy: JSONDecoder.DateDecodingStrategy

    /// Key decoding strategy for the decoder.
    public let keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy

    /// Output formatting options for the encoder.
    public let outputFormatting: JSONEncoder.OutputFormatting?

    /// Default configuration with ISO8601 dates and snake_case keys.
    /// Use this for types WITHOUT explicit CodingKeys.
    public static let `default` = SerializerConfiguration(
        dateEncodingStrategy: .iso8601,
        keyEncodingStrategy: .convertToSnakeCase,
        dateDecodingStrategy: .iso8601,
        keyDecodingStrategy: .convertFromSnakeCase,
        outputFormatting: nil
    )

    /// Configuration with pretty-printed output.
    public static let prettyPrinted = SerializerConfiguration(
        dateEncodingStrategy: .iso8601,
        keyEncodingStrategy: .convertToSnakeCase,
        dateDecodingStrategy: .iso8601,
        keyDecodingStrategy: .convertFromSnakeCase,
        outputFormatting: [.prettyPrinted, .sortedKeys]
    )

    /// Configuration for DTOs that have explicit CodingKeys for snake_case mapping.
    /// Uses ISO8601 dates but NO key conversion (DTOs handle it themselves).
    public static let dtoCompatible = SerializerConfiguration(
        dateEncodingStrategy: .iso8601,
        keyEncodingStrategy: .useDefaultKeys,
        dateDecodingStrategy: .iso8601,
        keyDecodingStrategy: .useDefaultKeys,
        outputFormatting: nil
    )

    /// Creates a custom configuration.
    ///
    /// - Parameters:
    ///   - dateEncodingStrategy: Strategy for encoding dates.
    ///   - keyEncodingStrategy: Strategy for encoding keys.
    ///   - dateDecodingStrategy: Strategy for decoding dates.
    ///   - keyDecodingStrategy: Strategy for decoding keys.
    ///   - outputFormatting: Output formatting options.
    public init(
        dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .iso8601,
        keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .convertToSnakeCase,
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601,
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase,
        outputFormatting: JSONEncoder.OutputFormatting? = nil
    ) {
        self.dateEncodingStrategy = dateEncodingStrategy
        self.keyEncodingStrategy = keyEncodingStrategy
        self.dateDecodingStrategy = dateDecodingStrategy
        self.keyDecodingStrategy = keyDecodingStrategy
        self.outputFormatting = outputFormatting
    }
}

// MARK: - SerializationError

/// Errors that can occur during serialization operations.
public enum SerializationError: Error, Sendable, Equatable {
    /// Encoding failed for the specified type.
    case encodingFailed(type: String, reason: String)

    /// Decoding failed for the specified type.
    case decodingFailed(type: String, reason: String)
}

extension SerializationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .encodingFailed(let type, let reason):
            return "Failed to encode \(type): \(reason)"
        case .decodingFailed(let type, let reason):
            return "Failed to decode \(type): \(reason)"
        }
    }
}
