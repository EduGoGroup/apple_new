/// Estado de carga de opciones para un campo remote_select.
public enum SelectOptionsState: Sendable {
    case loading
    case success(options: [SlotOption])
    case error(message: String)
}
