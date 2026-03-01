import Testing
import Foundation
import Synchronization
import EduModels
@testable import EduDynamicUI

/// Thread-safe counter for use in @Sendable closures.
private final class CallTracker: Sendable {
    let counter = Mutex<Int>(0)

    func increment() {
        counter.withLock { $0 += 1 }
    }

    var value: Int {
        counter.withLock { $0 }
    }
}

/// Thread-safe boolean flag for use in @Sendable closures.
private final class Flag: Sendable {
    let storage = Mutex<Bool>(false)

    func set() {
        storage.withLock { $0 = true }
    }

    var value: Bool {
        storage.withLock { $0 }
    }
}

@Suite("PrefetchCoordinator Tests")
struct PrefetchCoordinatorTests {

    @Test("Prefetch triggers at threshold")
    func prefetchTriggersAtThreshold() async {
        let coordinator = PrefetchCoordinator(config: .init(prefetchThreshold: 5))
        let loadCalled = Flag()

        await coordinator.evaluatePrefetch(
            visibleIndex: 15,
            totalItems: 20,
            hasMore: true,
            loadAction: {
                loadCalled.set()
                return [["id": .string("new1")]]
            }
        )

        // Wait briefly for task to execute
        try? await Task.sleep(for: .milliseconds(100))
        #expect(loadCalled.value == true)
    }

    @Test("Prefetch does not trigger when far from end")
    func prefetchDoesNotTriggerFarFromEnd() async {
        let coordinator = PrefetchCoordinator(config: .init(prefetchThreshold: 5))
        let loadCalled = Flag()

        await coordinator.evaluatePrefetch(
            visibleIndex: 5,
            totalItems: 20,
            hasMore: true,
            loadAction: {
                loadCalled.set()
                return []
            }
        )

        try? await Task.sleep(for: .milliseconds(100))
        #expect(loadCalled.value == false)
    }

    @Test("Prefetch does not duplicate when already in progress")
    func prefetchDoesNotDuplicate() async {
        let coordinator = PrefetchCoordinator(config: .init(prefetchThreshold: 5))
        let tracker = CallTracker()

        // First call starts a slow prefetch
        await coordinator.evaluatePrefetch(
            visibleIndex: 16,
            totalItems: 20,
            hasMore: true,
            loadAction: {
                tracker.increment()
                try? await Task.sleep(for: .milliseconds(200))
                return [["id": .string("item1")]]
            }
        )

        // Brief delay to let the first prefetch start
        try? await Task.sleep(for: .milliseconds(20))

        // Second call should be ignored because a prefetch is in progress
        await coordinator.evaluatePrefetch(
            visibleIndex: 17,
            totalItems: 20,
            hasMore: true,
            loadAction: {
                tracker.increment()
                return [["id": .string("item2")]]
            }
        )

        try? await Task.sleep(for: .milliseconds(300))
        #expect(tracker.value == 1)
    }

    @Test("Consumed prefetch clears buffer")
    func consumedPrefetchClearsBuffer() async {
        let coordinator = PrefetchCoordinator(config: .init(prefetchThreshold: 5))

        await coordinator.evaluatePrefetch(
            visibleIndex: 16,
            totalItems: 20,
            hasMore: true,
            loadAction: {
                return [["id": .string("prefetched1")]]
            }
        )

        try? await Task.sleep(for: .milliseconds(100))

        // First consume should return data
        let first = await coordinator.consumePrefetchedData()
        #expect(first != nil)
        #expect(first?.count == 1)

        // Second consume should return nil
        let second = await coordinator.consumePrefetchedData()
        #expect(second == nil)
    }

    @Test("Cancel stops prefetch")
    func cancelStopsPrefetch() async {
        let coordinator = PrefetchCoordinator(config: .init(prefetchThreshold: 5))

        await coordinator.evaluatePrefetch(
            visibleIndex: 16,
            totalItems: 20,
            hasMore: true,
            loadAction: {
                try? await Task.sleep(for: .milliseconds(500))
                return [["id": .string("slow")]]
            }
        )

        // Cancel immediately
        await coordinator.cancelPrefetch()

        let inProgress = await coordinator.isPrefetchInProgress()
        #expect(inProgress == false)

        let data = await coordinator.consumePrefetchedData()
        #expect(data == nil)
    }

    @Test("No prefetch when hasMore is false")
    func noPrefetchWhenNoMore() async {
        let coordinator = PrefetchCoordinator(config: .init(prefetchThreshold: 5))
        let loadCalled = Flag()

        await coordinator.evaluatePrefetch(
            visibleIndex: 18,
            totalItems: 20,
            hasMore: false,
            loadAction: {
                loadCalled.set()
                return []
            }
        )

        try? await Task.sleep(for: .milliseconds(100))
        #expect(loadCalled.value == false)
    }

    @Test("Default config has expected values")
    func defaultConfig() {
        let config = PrefetchCoordinator.PrefetchConfig.default
        #expect(config.prefetchThreshold == 5)
        #expect(config.maxConcurrentPrefetches == 1)
    }
}
