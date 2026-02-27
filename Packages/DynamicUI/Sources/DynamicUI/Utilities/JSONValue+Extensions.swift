import EduModels

extension JSONValue {
    /// Representacion como string del valor JSON.
    public var stringRepresentation: String {
        switch self {
        case .string(let s): return s
        case .integer(let i): return String(i)
        case .double(let d): return String(d)
        case .bool(let b): return b ? "true" : "false"
        case .null: return ""
        case .object, .array: return ""
        }
    }
}
