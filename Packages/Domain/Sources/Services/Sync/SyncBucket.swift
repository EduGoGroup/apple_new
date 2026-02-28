/// Buckets disponibles para sincronizacion selectiva.
///
/// Permite solicitar solo los buckets necesarios al backend
/// via `?buckets=menu,permissions,...` en el endpoint de sync.
public enum SyncBucket: String, Sendable, CaseIterable {
    case menu
    case permissions
    case availableContexts = "available_contexts"
    case screens
    case glossary
    case strings
}
