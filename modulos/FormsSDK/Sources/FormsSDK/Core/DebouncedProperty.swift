import Foundation

/// A property wrapper that debounces value changes before triggering a callback.
///
/// Use `@DebouncedProperty` for properties that trigger expensive operations
/// like search queries or API calls. Changes are coalesced and the callback
/// is invoked only after the specified interval with no new changes.
///
/// ## Usage
/// ```swift
/// @MainActor
/// @Observable
/// final class SearchViewModel {
///     @DebouncedProperty(debounceInterval: 0.5) { query in
///         await self.performSearch(query: query)
///     }
///     var searchQuery: String = ""
/// }
/// ```
@MainActor
@propertyWrapper
public struct DebouncedProperty<Value: Sendable>: Sendable {

    private var value: Value
    private let debounceInterval: TimeInterval
    private let onDebouncedChange: (@Sendable (Value) async -> Void)?
    private var debounceTask: Task<Void, Never>?

    /// The wrapped value with automatic debouncing on set.
    public var wrappedValue: Value {
        get { value }
        set {
            value = newValue

            debounceTask?.cancel()

            if let onDebouncedChange {
                let newValueCopy = newValue
                let interval = debounceInterval

                debounceTask = Task {
                    try? await Task.sleep(for: .seconds(interval))

                    guard !Task.isCancelled else { return }
                    await onDebouncedChange(newValueCopy)
                }
            }
        }
    }

    /// The projected value providing access to the property wrapper itself.
    public var projectedValue: DebouncedProperty<Value> {
        self
    }

    /// Creates a debounced property with a callback.
    ///
    /// - Parameters:
    ///   - wrappedValue: The initial value.
    ///   - debounceInterval: The debounce interval in seconds. Default is 0.3.
    ///   - onDebouncedChange: Async callback invoked after the debounce interval
    ///     with no new changes.
    public init(
        wrappedValue: Value,
        debounceInterval: TimeInterval = 0.3,
        onDebouncedChange: (@Sendable (Value) async -> Void)? = nil
    ) {
        self.value = wrappedValue
        self.debounceInterval = debounceInterval
        self.onDebouncedChange = onDebouncedChange
    }

    /// Cancels any pending debounced callback.
    ///
    /// Call this when the view disappears or when you want to prevent
    /// the pending callback from executing.
    public mutating func cancel() {
        debounceTask?.cancel()
        debounceTask = nil
    }

    /// Forces immediate execution of the callback with the current value.
    ///
    /// This cancels any pending debounced callback and immediately
    /// invokes the callback with the current value.
    public mutating func flush() {
        debounceTask?.cancel()

        if let onDebouncedChange {
            let currentValue = value
            debounceTask = Task {
                await onDebouncedChange(currentValue)
            }
        }
    }
}
