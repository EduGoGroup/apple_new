import EduDynamicUI
import EduDomain
import EduModels
import EduNetwork
import Observation

@MainActor
@Observable
final class DynamicScreenViewModel {
    private let screenLoader: ScreenLoader
    private let dataLoader: DataLoader
    private let orchestrator: EventOrchestrator?

    private(set) var screenState: ScreenState = .loading
    private(set) var dataState: DataState = .idle
    var alertMessage: String?
    var onLogout: (() -> Void)?
    var onNavigate: ((String, [String: String]) -> Void)?
    var onSubmit: ((String, String, [String: JSONValue]) async -> Void)?
    private var currentOffset: Int = 0

    // MARK: - Form State

    var fieldValues: [String: String] = [:]
    var fieldErrors: [String: String] = [:]
    var searchQuery: String?

    var isEditing: Bool {
        if case .success(let items, _, _) = dataState, !items.isEmpty {
            return true
        }
        return false
    }

    // MARK: - User Context

    var userContext: ScreenUserContext = .anonymous

    init(
        screenLoader: ScreenLoader,
        dataLoader: DataLoader,
        orchestrator: EventOrchestrator? = nil
    ) {
        self.screenLoader = screenLoader
        self.dataLoader = dataLoader
        self.orchestrator = orchestrator
    }

    func loadScreen(key: String) async {
        screenState = .loading
        dataState = .idle
        fieldValues = [:]
        fieldErrors = [:]
        do {
            let screen = try await screenLoader.loadScreen(key: key)
            screenState = .ready(screen)
            if screen.dataEndpoint != nil {
                await loadData(screen: screen)
            } else if orchestrator != nil {
                // Backend no envia dataEndpoint; usar contract via orchestrator
                await executeEvent(.loadData)
            }
        } catch {
            screenState = .error(error.localizedDescription)
        }
    }

    func loadData(screen: ScreenDefinition) async {
        guard let endpoint = screen.dataEndpoint else { return }
        dataState = .loading
        currentOffset = 0
        do {
            let raw = try await dataLoader.loadData(
                endpoint: endpoint,
                config: screen.dataConfig
            )
            let items = extractItems(from: raw)
            let pageSize = screen.dataConfig?.pagination?.pageSize ?? 20
            dataState = .success(
                items: items,
                hasMore: items.count >= pageSize,
                loadingMore: false
            )
        } catch {
            dataState = .error(error.localizedDescription)
        }
    }

    func loadNextPage() async {
        guard case .success(let items, let hasMore, let loadingMore) = dataState,
              hasMore, !loadingMore else { return }
        guard case .ready(let screen) = screenState,
              let endpoint = screen.dataEndpoint else { return }

        dataState = .success(items: items, hasMore: hasMore, loadingMore: true)
        let pageSize = screen.dataConfig?.pagination?.pageSize ?? 20
        currentOffset += pageSize

        do {
            let raw = try await dataLoader.loadNextPage(
                endpoint: endpoint,
                config: screen.dataConfig,
                currentOffset: currentOffset
            )
            let newItems = extractItems(from: raw)
            dataState = .success(
                items: items + newItems,
                hasMore: newItems.count >= pageSize,
                loadingMore: false
            )
        } catch {
            dataState = .success(items: items, hasMore: false, loadingMore: false)
        }
    }

    // MARK: - Event Execution

    func executeEvent(_ event: ScreenEvent, selectedItem: [String: JSONValue]? = nil) async {
        guard case .ready(let screen) = screenState else { return }

        let context = EventContext(
            screenKey: screen.screenKey,
            userContext: userContext,
            selectedItem: selectedItem,
            fieldValues: fieldValues,
            searchQuery: searchQuery,
            paginationOffset: currentOffset
        )

        guard let orchestrator else {
            // Fallback sin orchestrator
            await executeFallback(event: event, screen: screen)
            return
        }

        let result = await orchestrator.execute(event: event, context: context)
        handleResult(result)
    }

    func executeCustomEvent(_ eventId: String) async {
        guard case .ready(let screen) = screenState else { return }

        let context = EventContext(
            screenKey: screen.screenKey,
            userContext: userContext,
            fieldValues: fieldValues
        )

        guard let orchestrator else {
            alertMessage = "No orchestrator configured"
            return
        }

        let result = await orchestrator.executeCustom(eventId: eventId, context: context)
        handleResult(result)
    }

    func executeAction(_ action: ActionDefinition) {
        switch action.type {
        case .refresh:
            Task { await refresh() }
        case .logout:
            onLogout?()
        case .custom:
            Task { await executeCustomEvent(action.id) }
        case .submitForm:
            Task { await executeEvent(isEditing ? .saveExisting : .saveNew) }
        default:
            alertMessage = "Hola Mundo - \(action.id)"
        }
    }

    func refresh() async {
        if case .ready(let screen) = screenState {
            await loadData(screen: screen)
        }
    }

    // MARK: - Field Management

    func updateField(key: String, value: String) {
        fieldValues[key] = value
        fieldErrors[key] = nil
    }

    func validateField(key: String) {
        guard let value = fieldValues[key] else { return }
        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fieldErrors[key] = "Field is required"
        }
    }

    // MARK: - Private

    private func handleResult(_ result: EventResult) {
        switch result {
        case .success(let message, let data):
            if !message.isEmpty {
                alertMessage = message
            }
            if case .object(let dict) = data {
                var items = extractItems(from: dict)
                // Aplicar fieldMapping del contract si existe
                if let mapping = resolveFieldMapping() {
                    items = applyFieldMapping(items: items, mapping: mapping)
                }
                let pageSize = 20
                dataState = .success(
                    items: items,
                    hasMore: items.count >= pageSize,
                    loadingMore: false
                )
            }
        case .navigateTo(let screenKey, let params):
            onNavigate?(screenKey, params)
        case .error(let message, _):
            alertMessage = message
        case .permissionDenied:
            alertMessage = "Permission denied"
        case .logout:
            onLogout?()
        case .submitTo(let endpoint, let method, let body):
            if let onSubmit {
                Task { await onSubmit(endpoint, method, body) }
            } else {
                alertMessage = "Submit: \(method) \(endpoint)"
            }
        case .cancelled, .noOp:
            break
        }
    }

    private func executeFallback(event: ScreenEvent, screen: ScreenDefinition) async {
        switch event {
        case .loadData, .refresh:
            await loadData(screen: screen)
        case .loadMore:
            await loadNextPage()
        default:
            break
        }
    }

    private func extractItems(from raw: [String: EduModels.JSONValue]) -> [[String: EduModels.JSONValue]] {
        for key in ["items", "data", "results"] {
            if case .array(let array) = raw[key] {
                return array.compactMap { element in
                    if case .object(let dict) = element { return dict }
                    return nil
                }
            }
        }
        return [raw]
    }

    private func resolveFieldMapping() -> [String: String]? {
        guard case .ready(let screen) = screenState else { return nil }
        // Primero intentar desde el screen definition (backend)
        if let mapping = screen.dataConfig?.fieldMapping, !mapping.isEmpty {
            return mapping
        }
        // Fallback: obtener desde el contract registry via orchestrator
        return nil
    }

    private func applyFieldMapping(
        items: [[String: JSONValue]],
        mapping: [String: String]
    ) -> [[String: JSONValue]] {
        items.map { item in
            var mapped = item
            for (apiField, templateField) in mapping {
                if let value = item[apiField] {
                    if templateField == "status", case .bool(let b) = value {
                        mapped[templateField] = .string(b ? "Activo" : "Inactivo")
                    } else {
                        mapped[templateField] = value
                    }
                }
            }
            mapped.removeValue(forKey: "created_at")
            mapped.removeValue(forKey: "updated_at")
            return mapped
        }
    }
}
