import Foundation
import EduModels

/// Coordinates prefetching of next page data in paginated lists.
public actor PrefetchCoordinator {

    public struct PrefetchConfig: Sendable {
        public let prefetchThreshold: Int  // Items before end to trigger

        public static let `default` = PrefetchConfig(prefetchThreshold: 5)

        public init(prefetchThreshold: Int = 5) {
            self.prefetchThreshold = prefetchThreshold
        }
    }

    private let config: PrefetchConfig
    private var prefetchTask: Task<Void, Never>?
    private var isPrefetching: Bool = false
    private var prefetchedData: [[String: JSONValue]]?
    private var generation: Int = 0

    public init(config: PrefetchConfig = .default) {
        self.config = config
    }

    /// Evaluate if prefetch should trigger based on visible item position
    public func evaluatePrefetch(
        visibleIndex: Int,
        totalItems: Int,
        hasMore: Bool,
        loadAction: @Sendable @escaping () async throws -> [[String: JSONValue]]
    ) {
        let remainingItems = totalItems - visibleIndex - 1
        guard hasMore, !isPrefetching, prefetchedData == nil,
              remainingItems <= config.prefetchThreshold else { return }

        isPrefetching = true
        generation += 1
        let currentGeneration = generation
        prefetchTask = Task {
            do {
                let newItems = try await loadAction()
                // Only store if this generation is still current (not cancelled)
                guard !Task.isCancelled, self.generation == currentGeneration else { return }
                self.prefetchedData = newItems
            } catch {
                // Prefetch failed silently — will retry on next evaluation
            }
            if self.generation == currentGeneration {
                self.isPrefetching = false
            }
        }
    }

    /// Consume prefetched data (returns nil if none available)
    public func consumePrefetchedData() -> [[String: JSONValue]]? {
        let data = prefetchedData
        prefetchedData = nil
        return data
    }

    /// Cancel in-flight prefetch
    public func cancelPrefetch() {
        prefetchTask?.cancel()
        prefetchTask = nil
        isPrefetching = false
        prefetchedData = nil
    }

    /// Whether a prefetch is currently in progress
    public func isPrefetchInProgress() -> Bool { isPrefetching }
}
