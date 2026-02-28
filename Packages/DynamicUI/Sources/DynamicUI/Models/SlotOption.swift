/// Opcion individual para selects remotos.
public struct SlotOption: Sendable, Hashable, Codable {
    public let label: String
    public let value: String

    public init(label: String, value: String) {
        self.label = label
        self.value = value
    }
}
