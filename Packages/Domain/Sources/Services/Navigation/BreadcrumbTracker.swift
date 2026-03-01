// BreadcrumbTracker.swift
// EduDomain

import Foundation

/// Tracks the SDUI navigation breadcrumb trail.
///
/// Thread-safe actor that maintains an ordered list of breadcrumb entries
/// as the user navigates through server-driven screens. Emits trail changes
/// via an `AsyncStream` so that UI layers can observe updates.
///
/// - Maximum depth: 7 entries (oldest entries are pruned when exceeded).
/// - Duplicate detection: pushing an already-present `screenKey` prunes the
///   trail back to that entry instead of creating a duplicate.
public actor BreadcrumbTracker {

    // MARK: - Types

    /// A single entry in the breadcrumb trail.
    public struct BreadcrumbEntry: Sendable, Identifiable, Hashable {
        /// Unique identifier for this entry (UUID string).
        public let id: String
        /// The SDUI screen key (e.g. "schools-list", "user-detail").
        public let screenKey: String
        /// Human-readable title shown in the breadcrumb chip.
        public let title: String
        /// Optional SF Symbol name for the breadcrumb icon.
        public let icon: String?
        /// The `ScreenPattern.rawValue` of the screen (e.g. "list", "detail").
        public let pattern: String

        public init(
            id: String = UUID().uuidString,
            screenKey: String,
            title: String,
            icon: String? = nil,
            pattern: String
        ) {
            self.id = id
            self.screenKey = screenKey
            self.title = title
            self.icon = icon
            self.pattern = pattern
        }
    }

    // MARK: - Properties

    private var trail: [BreadcrumbEntry] = []
    private let maxDepth: Int = 7

    private let trailContinuation: AsyncStream<[BreadcrumbEntry]>.Continuation

    /// An `AsyncStream` that emits the current trail whenever it changes.
    /// UI layers should iterate over this stream to stay in sync.
    public let trailStream: AsyncStream<[BreadcrumbEntry]>

    // MARK: - Initialization

    public init() {
        let (stream, continuation) = AsyncStream<[BreadcrumbEntry]>.makeStream()
        self.trailStream = stream
        self.trailContinuation = continuation
    }

    // MARK: - Public API

    /// Push a screen onto the breadcrumb trail.
    ///
    /// If a screen with the same `screenKey` already exists in the trail,
    /// the trail is pruned back to that entry (avoiding duplicates).
    /// Otherwise the new entry is appended. When the trail exceeds
    /// `maxDepth`, the oldest entries are removed.
    public func push(
        screenKey: String,
        title: String,
        icon: String? = nil,
        pattern: String
    ) {
        if let existingIndex = trail.firstIndex(where: { $0.screenKey == screenKey }) {
            trail = Array(trail.prefix(existingIndex + 1))
        } else {
            let entry = BreadcrumbEntry(
                screenKey: screenKey,
                title: title,
                icon: icon,
                pattern: pattern
            )
            trail.append(entry)
            if trail.count > maxDepth {
                trail = Array(trail.suffix(maxDepth))
            }
        }
        trailContinuation.yield(trail)
    }

    /// Navigate to a specific breadcrumb entry by its `id`.
    ///
    /// Prunes all entries after the target, making it the current (last) entry.
    /// Returns the target entry if found, `nil` otherwise.
    @discardableResult
    public func navigateTo(entryId: String) -> BreadcrumbEntry? {
        guard let index = trail.firstIndex(where: { $0.id == entryId }) else { return nil }
        trail = Array(trail.prefix(index + 1))
        trailContinuation.yield(trail)
        return trail.last
    }

    /// Pop the last entry from the trail (back navigation).
    public func pop() {
        guard !trail.isEmpty else { return }
        trail.removeLast()
        trailContinuation.yield(trail)
    }

    /// Clear the entire trail (e.g. on section change or logout).
    public func clear() {
        trail.removeAll()
        trailContinuation.yield(trail)
    }

    /// Returns a snapshot of the current trail.
    public func currentTrail() -> [BreadcrumbEntry] {
        trail
    }
}
