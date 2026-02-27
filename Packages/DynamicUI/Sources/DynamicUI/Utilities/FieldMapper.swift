import EduModels

/// Maps API field names to template field names for slot binding.
///
/// Example: Given mapping `{"full_name": "title", "code": "subtitle"}`,
/// converts `data["full_name"]` to `data["title"]` so that a slot with
/// `bind: "title"` finds the correct value.
public struct FieldMapper: Sendable {
    public init() {}

    /// Transforms data keys from API field names to template field names.
    ///
    /// - Parameters:
    ///   - data: Raw API data dictionary.
    ///   - fieldMapping: Dictionary mapping API field names (keys) to template names (values).
    /// - Returns: Data dictionary with both original and mapped keys.
    public func map(
        data: [String: JSONValue],
        fieldMapping: [String: String]?
    ) -> [String: JSONValue] {
        guard let mapping = fieldMapping else { return data }
        var result = data
        for (apiField, templateField) in mapping {
            if let value = data[apiField] {
                result[templateField] = value
            }
        }
        return result
    }

    /// Transforms an array of items using the given field mapping.
    public func mapItems(
        items: [[String: JSONValue]],
        fieldMapping: [String: String]?
    ) -> [[String: JSONValue]] {
        guard fieldMapping != nil else { return items }
        return items.map { map(data: $0, fieldMapping: fieldMapping) }
    }

    /// Creates a reverse mapping (template → API) for submitting form data.
    public static func reverseMapping(
        _ fieldMapping: [String: String]
    ) -> [String: String] {
        var reversed: [String: String] = [:]
        for (apiField, templateField) in fieldMapping {
            reversed[templateField] = apiField
        }
        return reversed
    }
}
