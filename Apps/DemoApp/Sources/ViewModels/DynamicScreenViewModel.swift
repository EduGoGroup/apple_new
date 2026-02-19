import EduDynamicUI
import EduModels
import EduNetwork
import Observation

@MainActor
@Observable
final class DynamicScreenViewModel {
    private let screenLoader: ScreenLoader
    private let dataLoader: DataLoader
    let screenKey: String

    private(set) var screenState: ScreenState = .loading
    private(set) var dataState: DataState = .idle
    var alertMessage: String?
    private var currentOffset: Int = 0

    init(screenKey: String, screenLoader: ScreenLoader, dataLoader: DataLoader) {
        self.screenKey = screenKey
        self.screenLoader = screenLoader
        self.dataLoader = dataLoader
    }

    func loadScreen() async {
        screenState = .loading
        do {
            let screen = try await screenLoader.loadScreen(key: screenKey)
            screenState = .ready(screen)
            if screen.dataEndpoint != nil {
                await loadData(screen: screen)
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

    func executeAction(_ action: ActionDefinition) {
        switch action.type {
        case .refresh:
            Task { await refresh() }
        case .logout:
            alertMessage = "Hola Mundo - Logout"
        default:
            alertMessage = "Hola Mundo - \(action.id)"
        }
    }

    func refresh() async {
        if case .ready(let screen) = screenState {
            await loadData(screen: screen)
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
}
