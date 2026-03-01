import Foundation
import EduCore
import EduDynamicUI

/// Status of an optimistic update.
public enum OptimisticUpdateStatus: Sendable {
    case pending
    case confirmed
    case rolledBack
    case timedOut
}

/// A snapshot of a pending optimistic update, including previous state for rollback.
public struct PendingUpdate: Sendable {
    public let id: String
    public let screenKey: String
    public let event: ScreenEvent
    public let previousItems: [[String: JSONValue]]
    public let optimisticItems: [[String: JSONValue]]
    public let fieldValues: [String: String]
    public let createdAt: Date
    public let timeoutSeconds: TimeInterval
    public private(set) var status: OptimisticUpdateStatus

    public init(
        id: String = UUID().uuidString,
        screenKey: String,
        event: ScreenEvent,
        previousItems: [[String: JSONValue]],
        optimisticItems: [[String: JSONValue]],
        fieldValues: [String: String],
        createdAt: Date = Date(),
        timeoutSeconds: TimeInterval = 30,
        status: OptimisticUpdateStatus = .pending
    ) {
        self.id = id
        self.screenKey = screenKey
        self.event = event
        self.previousItems = previousItems
        self.optimisticItems = optimisticItems
        self.fieldValues = fieldValues
        self.createdAt = createdAt
        self.timeoutSeconds = timeoutSeconds
        self.status = status
    }

    mutating func updateStatus(_ newStatus: OptimisticUpdateStatus) {
        status = newStatus
    }
}

/// Event emitted through the status stream when an optimistic update resolves.
public struct OptimisticStatusEvent: Sendable {
    public let updateId: String
    public let status: OptimisticUpdateStatus
    public let previousItems: [[String: JSONValue]]?

    public init(
        updateId: String,
        status: OptimisticUpdateStatus,
        previousItems: [[String: JSONValue]]? = nil
    ) {
        self.updateId = updateId
        self.status = status
        self.previousItems = previousItems
    }
}

/// Actor that tracks pending optimistic updates with snapshots for rollback.
/// Provides an AsyncStream to notify the UI of status changes.
public actor OptimisticUpdateManager {
    private var pendingUpdates: [String: PendingUpdate] = [:]
    private var continuation: AsyncStream<OptimisticStatusEvent>.Continuation?
    private let _statusStream: AsyncStream<OptimisticStatusEvent>

    /// Stream that emits events when optimistic updates are confirmed, rolled back, or timed out.
    public var statusStream: AsyncStream<OptimisticStatusEvent> {
        _statusStream
    }

    public init() {
        var capturedContinuation: AsyncStream<OptimisticStatusEvent>.Continuation?
        _statusStream = AsyncStream { continuation in
            capturedContinuation = continuation
        }
        self.continuation = capturedContinuation
    }

    /// Registers a new optimistic update and starts a timeout timer.
    /// - Returns: The ID of the registered update.
    @discardableResult
    public func registerOptimisticUpdate(
        id: String = UUID().uuidString,
        screenKey: String,
        event: ScreenEvent,
        previousItems: [[String: JSONValue]],
        optimisticItems: [[String: JSONValue]],
        fieldValues: [String: String],
        timeoutSeconds: TimeInterval = 30
    ) -> String {
        let update = PendingUpdate(
            id: id,
            screenKey: screenKey,
            event: event,
            previousItems: previousItems,
            optimisticItems: optimisticItems,
            fieldValues: fieldValues,
            timeoutSeconds: timeoutSeconds
        )
        pendingUpdates[id] = update

        // Start timeout timer
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(timeoutSeconds))
            await self?.handleTimeout(id: id)
        }

        return id
    }

    /// Confirms an optimistic update (server accepted). Removes from pending and emits confirmed event.
    public func confirmUpdate(id: String) {
        guard var update = pendingUpdates[id] else { return }
        update.updateStatus(.confirmed)
        pendingUpdates.removeValue(forKey: id)
        continuation?.yield(OptimisticStatusEvent(
            updateId: id,
            status: .confirmed
        ))
    }

    /// Rolls back an optimistic update (server rejected). Returns previous items for restoration.
    @discardableResult
    public func rollbackUpdate(id: String) -> [[String: JSONValue]]? {
        guard var update = pendingUpdates[id] else { return nil }
        let previousItems = update.previousItems
        update.updateStatus(.rolledBack)
        pendingUpdates.removeValue(forKey: id)
        continuation?.yield(OptimisticStatusEvent(
            updateId: id,
            status: .rolledBack,
            previousItems: previousItems
        ))
        return previousItems
    }

    /// Checks whether there are any pending optimistic updates for a given screen.
    public func hasPendingUpdates(forScreen screenKey: String) -> Bool {
        pendingUpdates.values.contains { $0.screenKey == screenKey && $0.status == .pending }
    }

    /// Checks whether a specific update ID is still pending.
    public func isPending(id: String) -> Bool {
        pendingUpdates[id]?.status == .pending
    }

    /// Returns the current status of an update, if it still exists.
    public func status(for id: String) -> OptimisticUpdateStatus? {
        pendingUpdates[id]?.status
    }

    /// Cleans up expired updates that have timed out.
    public func cleanupExpired() {
        let now = Date()
        let expiredIds = pendingUpdates.filter { _, update in
            now.timeIntervalSince(update.createdAt) >= update.timeoutSeconds
        }.map(\.key)

        for id in expiredIds {
            handleTimeout(id: id)
        }
    }

    /// Returns the count of pending updates (useful for testing).
    public func pendingCount() -> Int {
        pendingUpdates.count
    }

    // MARK: - Private

    private func handleTimeout(id: String) {
        guard let update = pendingUpdates[id], update.status == .pending else { return }
        var mutableUpdate = update
        mutableUpdate.updateStatus(.timedOut)
        pendingUpdates.removeValue(forKey: id)
        continuation?.yield(OptimisticStatusEvent(
            updateId: id,
            status: .timedOut,
            previousItems: update.previousItems
        ))
    }
}
