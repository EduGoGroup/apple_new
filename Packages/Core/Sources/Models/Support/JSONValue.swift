import Foundation

/// Codable representation for arbitrary JSON values.
///
/// This supports decoding/encoding JSON objects where values can be strings,
/// numbers, booleans, nulls, arrays, or nested objects.
public enum JSONValue: Codable, Sendable, Hashable {
    case string(String)
    case integer(Int)
    case double(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
            return
        }

        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
            return
        }

        if let value = try? container.decode(Int.self) {
            self = .integer(value)
            return
        }

        if let value = try? container.decode(Double.self) {
            self = .double(value)
            return
        }

        if let value = try? container.decode(String.self) {
            self = .string(value)
            return
        }

        if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
            return
        }

        if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
            return
        }

        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Unsupported JSON value"
        )
    }

    // MARK: - Typed accessors

    /// Returns the associated String value.
    public var stringValue: String? {
        if case .string(let v) = self { return v }
        return nil
    }

    /// Returns the associated Int value.
    public var intValue: Int? {
        if case .integer(let v) = self { return v }
        return nil
    }

    /// Returns the associated Double value, promoting `.integer` to Double.
    public var doubleValue: Double? {
        switch self {
        case .double(let v): return v
        case .integer(let v): return Double(v)
        default: return nil
        }
    }

    /// Returns the associated Bool value.
    public var boolValue: Bool? {
        if case .bool(let v) = self { return v }
        return nil
    }

    /// Returns the associated object dictionary.
    public var objectValue: [String: JSONValue]? {
        if case .object(let v) = self { return v }
        return nil
    }

    /// Returns the associated array.
    public var arrayValue: [JSONValue]? {
        if case .array(let v) = self { return v }
        return nil
    }

    /// Returns true when the value is `.null`.
    public var isNull: Bool {
        if case .null = self { return true }
        return false
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .string(let value):
            try container.encode(value)
        case .integer(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}
