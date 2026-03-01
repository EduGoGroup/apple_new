import EduCore
import EduDynamicUI
import EduDomain
import EduModels
import EduNetwork
import EduPresentation
import Observation

/// Tracks the info needed to execute or cancel a pending delete operation.
struct PendingDeleteInfo: Sendable {
    let screenKey: String
    let itemId: String
    let endpoint: String
    let method: String
}

@MainActor
@Observable
final class DynamicScreenViewModel {
    private let screenLoader: ScreenLoader
    private let dataLoader: DataLoader
    private let orchestrator: EventOrchestrator?
    private let networkClient: (any NetworkClientProtocol)?

    private(set) var screenState: ScreenState = .loading
    private(set) var dataState: DataState = .idle
    var alertMessage: String?
    var onLogout: (() -> Void)?
    var onNavigate: ((String, [String: String]) -> Void)?
    var onSubmit: ((String, String, [String: JSONValue]) async -> Void)?
    private var currentOffset: Int = 0
    private var prefetchCoordinator: PrefetchCoordinator?

    // MARK: - Optimistic UI

    var optimisticManager: OptimisticUpdateManager?
    private(set) var pendingOptimisticIds: Set<String> = []
    private var optimisticObserverTask: Task<Void, Never>?

    // MARK: - Form State

    var fieldValues: [String: String] = [:]
    var fieldErrors: [String: String] = [:]
    var searchQuery: String?

    // MARK: - Pending Delete State

    private(set) var pendingDeleteInfo: PendingDeleteInfo?
    private var pendingDeleteTask: Task<Void, Never>?

    // MARK: - Remote Select State

    var selectOptions: [String: SelectOptionsState] = [:]

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
        orchestrator: EventOrchestrator? = nil,
        networkClient: (any NetworkClientProtocol)? = nil
    ) {
        self.screenLoader = screenLoader
        self.dataLoader = dataLoader
        self.orchestrator = orchestrator
        self.networkClient = networkClient
    }

    func loadScreen(key: String) async {
        screenState = .loading
        dataState = .idle
        fieldValues = [:]
        fieldErrors = [:]
        do {
            let screen = try await screenLoader.loadScreen(key: key)
            screenState = .ready(screen)
            self.prefetchCoordinator = PrefetchCoordinator()
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
            // Try to consume prefetched data first
            if let prefetched = await prefetchCoordinator?.consumePrefetchedData() {
                let newHasMore = prefetched.count >= pageSize
                dataState = .success(items: items + prefetched, hasMore: newHasMore, loadingMore: false)
                return
            }

            // No prefetch available — load normally with metadata
            let result = try await dataLoader.loadNextPageWithMetadata(
                endpoint: endpoint,
                config: screen.dataConfig,
                currentOffset: currentOffset
            )
            dataState = .success(
                items: items + result.items,
                hasMore: result.hasNextPage,
                loadingMore: false
            )
        } catch {
            dataState = .success(items: items, hasMore: false, loadingMore: false)
        }
    }

    // MARK: - Prefetch

    func evaluatePrefetch(visibleIndex: Int, totalItems: Int) {
        guard case .success(_, let hasMore, let loadingMore) = dataState,
              hasMore, !loadingMore else { return }

        Task {
            await prefetchCoordinator?.evaluatePrefetch(
                visibleIndex: visibleIndex,
                totalItems: totalItems,
                hasMore: hasMore,
                loadAction: { [weak self] in
                    guard let self else { return [] }
                    return try await self.performPrefetch()
                }
            )
        }
    }

    @MainActor
    private func performPrefetch() async throws -> [[String: EduModels.JSONValue]] {
        guard case .ready(let screen) = screenState,
              let endpoint = screen.dataEndpoint else { return [] }

        let pageSize = screen.dataConfig?.pagination?.pageSize ?? 20
        let nextOffset = currentOffset + pageSize

        let result = try await dataLoader.loadNextPageWithMetadata(
            endpoint: endpoint,
            config: screen.dataConfig,
            currentOffset: nextOffset
        )
        return result.items
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
        case .navigate:
            if let config = action.config,
               case .string(let screenKey) = config["screen_key"] ?? config["screenKey"] {
                var params: [String: String] = [:]
                if case .object(let paramsDict) = config["params"] {
                    for (key, val) in paramsDict {
                        if let str = val.stringValue {
                            params[key] = str
                        }
                    }
                }
                onNavigate?(screenKey, params)
            }
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

    // MARK: - Remote Select

    func loadSelectOptions(
        fieldKey: String,
        endpoint: String,
        labelField: String,
        valueField: String
    ) async {
        if let current = selectOptions[fieldKey] {
            switch current {
            case .loading, .success:
                return
            case .error:
                break // Allow retry
            }
        }

        selectOptions[fieldKey] = .loading

        do {
            let raw = try await dataLoader.loadData(
                endpoint: endpoint,
                config: nil
            )
            let items = extractItems(from: raw)
            let options: [SlotOption] = items.compactMap { item in
                guard let label = item[labelField]?.stringValue,
                      let value = item[valueField]?.stringValue else { return nil }
                return SlotOption(label: label, value: value)
            }
            selectOptions[fieldKey] = .success(options: options)
        } catch {
            selectOptions[fieldKey] = .error(message: error.localizedDescription)
        }
    }

    // MARK: - Pending Delete

    /// Schedules a pending delete that executes after a 5-second delay.
    /// During that time the user can cancel via `cancelPendingDelete()`.
    func schedulePendingDelete(info: PendingDeleteInfo) {
        // Cancel any existing pending delete
        pendingDeleteTask?.cancel()
        pendingDeleteInfo = info

        // Remove the item from the current list immediately for visual feedback
        if case .success(var items, let hasMore, let loadingMore) = dataState {
            items.removeAll { item in
                item["id"]?.stringValue == info.itemId
            }
            dataState = .success(items: items, hasMore: hasMore, loadingMore: loadingMore)
        }

        // Show undoable toast
        ToastManager.shared.showUndoable(
            message: EduStrings.itemDeleted,
            onUndo: { [weak self] in
                self?.cancelPendingDelete()
            }
        )

        // Schedule the actual DELETE after 5 seconds
        pendingDeleteTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            await self?.executePendingDelete()
        }
    }

    /// Cancels the pending delete and restores the item by refreshing data.
    func cancelPendingDelete() {
        pendingDeleteTask?.cancel()
        pendingDeleteTask = nil
        pendingDeleteInfo = nil
        // Refresh data to restore the item
        Task { await refresh() }
    }

    /// Executes the real HTTP DELETE for the pending delete.
    private func executePendingDelete() async {
        guard let info = pendingDeleteInfo else { return }
        pendingDeleteInfo = nil
        pendingDeleteTask = nil

        guard let networkClient else {
            alertMessage = "No network client configured for delete"
            return
        }

        do {
            let request = HTTPRequest.delete(info.endpoint)
            let _: EmptyResponse = try await networkClient.request(request)
            // Refresh to ensure list is up-to-date after server confirms deletion
            await refresh()
        } catch {
            alertMessage = error.localizedDescription
            // Refresh to restore the item since delete failed
            await refresh()
        }
    }

    // MARK: - Optimistic Queries

    /// Returns true if the given item ID has a pending optimistic update.
    func isPendingOptimistic(itemId: String) -> Bool {
        pendingOptimisticIds.contains(itemId)
    }

    /// Starts observing the optimistic manager status stream for resolved updates.
    func startOptimisticObserver() {
        guard let manager = optimisticManager else { return }
        optimisticObserverTask?.cancel()
        optimisticObserverTask = Task { [weak self] in
            for await event in await manager.statusStream {
                guard let self, !Task.isCancelled else { break }
                self.handleOptimisticEvent(event)
            }
        }
    }

    /// Stops observing the optimistic manager status stream.
    func stopOptimisticObserver() {
        optimisticObserverTask?.cancel()
        optimisticObserverTask = nil
    }

    private func handleOptimisticEvent(_ event: OptimisticStatusEvent) {
        switch event.status {
        case .confirmed:
            pendingOptimisticIds.remove(event.updateId)

        case .rolledBack:
            pendingOptimisticIds.remove(event.updateId)
            // Restore previous items
            if let previousItems = event.previousItems {
                let pageSize = 20
                dataState = .success(
                    items: previousItems,
                    hasMore: previousItems.count >= pageSize,
                    loadingMore: false
                )
            }
            ToastManager.shared.showError("Save failed. Changes reverted.")

        case .timedOut:
            pendingOptimisticIds.remove(event.updateId)
            ToastManager.shared.showWarning("Save is taking longer than expected.")

        case .pending:
            break
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
        case .pendingDelete(let screenKey, let itemId, let endpoint, let method):
            schedulePendingDelete(info: PendingDeleteInfo(
                screenKey: screenKey,
                itemId: itemId,
                endpoint: endpoint,
                method: method
            ))
        case .optimisticSuccess(let updateId, let message, let optimisticData):
            if !message.isEmpty {
                ToastManager.shared.showSuccess(message)
            }

            // Snapshot current items for rollback
            var currentItems: [[String: JSONValue]] = []
            if case .success(let items, _, _) = dataState {
                currentItems = items
            }

            // Apply optimistic change to dataState
            if case .object(let bodyDict) = optimisticData {
                // Determine if this is a new item or an update to existing
                let existingId = bodyDict["id"]?.stringValue
                if let existingId, currentItems.contains(where: { $0["id"]?.stringValue == existingId }) {
                    // Update existing item
                    let updatedItems = currentItems.map { item -> [String: JSONValue] in
                        if item["id"]?.stringValue == existingId {
                            var merged = item
                            for (key, value) in bodyDict {
                                merged[key] = value
                            }
                            return merged
                        }
                        return item
                    }
                    let pageSize = 20
                    dataState = .success(
                        items: updatedItems,
                        hasMore: updatedItems.count >= pageSize,
                        loadingMore: false
                    )
                } else {
                    // Prepend new item
                    var newItem = bodyDict
                    if newItem["id"] == nil {
                        newItem["id"] = .string(updateId)
                    }
                    let updatedItems = [newItem] + currentItems
                    let pageSize = 20
                    dataState = .success(
                        items: updatedItems,
                        hasMore: updatedItems.count >= pageSize,
                        loadingMore: false
                    )
                }
            }

            // Track pending state and register snapshot with manager
            pendingOptimisticIds.insert(updateId)
            if let manager = optimisticManager {
                Task {
                    var optimisticItems: [[String: JSONValue]] = []
                    if case .success(let items, _, _) = dataState {
                        optimisticItems = items
                    }
                    // The orchestrator already registered the update; we don't re-register.
                    // The observer will handle confirmed/rolledBack/timedOut events.
                    _ = optimisticItems // suppress unused warning
                    _ = currentItems
                    _ = manager
                }
            }

            // Start observing if not already
            startOptimisticObserver()

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
