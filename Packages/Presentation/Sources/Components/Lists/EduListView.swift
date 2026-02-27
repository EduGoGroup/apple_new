import SwiftUI
import EduDomain

public enum ViewState<T>: Sendable where T: Sendable {
    case loading
    case success(T)
    case error(String)
    case empty
}

@MainActor
public struct EduListView<Item, Content: View>: View where Item: Sendable {
    private let state: ViewState<[Item]>
    private let emptyTitle: String
    private let emptyDescription: String
    private let onRetry: (() -> Void)?
    private let content: (Item) -> Content

    public init(
        state: ViewState<[Item]>,
        emptyTitle: String = "Sin resultados",
        emptyDescription: String = "No hay elementos para mostrar",
        onRetry: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.state = state
        self.emptyTitle = emptyTitle
        self.emptyDescription = emptyDescription
        self.onRetry = onRetry
        self.content = content
    }

    public var body: some View {
        Group {
            switch state {
            case .loading:
                EduLoadingStateView()
            case .success(let items):
                if items.isEmpty {
                    EduEmptyStateView(
                        title: emptyTitle,
                        description: emptyDescription
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                                content(item)
                                    .accessibilityLabel("Item \(index + 1) of \(items.count)")
                            }
                        }
                    }
                    // MARK: - Accessibility
                    .onAppear {
                        AccessibilityAnnouncements.announce("\(items.count) item\(items.count == 1 ? "" : "s") loaded", priority: .low)
                    }
                }
            case .error(let message):
                EduErrorStateView(
                    message: message,
                    onRetry: onRetry ?? {}
                )
            case .empty:
                EduEmptyStateView(
                    title: emptyTitle,
                    description: emptyDescription
                )
            }
        }
    }
}

// MARK: - Previews

#Preview("Estado: Loading") {
    EduListView(
        state: ViewState<[String]>.loading
    ) { item in
        Text(item)
            .padding()
    }
}

#Preview("Estado: Success") {
    EduListView(
        state: ViewState.success(["Elemento 1", "Elemento 2", "Elemento 3", "Elemento 4", "Elemento 5"])
    ) { item in
        HStack {
            Image(systemName: "doc")
            Text(item)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview("Estado: Empty") {
    EduListView(
        state: ViewState<[String]>.empty,
        emptyTitle: "Sin elementos",
        emptyDescription: "Agrega tu primer elemento para comenzar"
    ) { item in
        Text(item)
    }
}

#Preview("Estado: Error") {
    EduListView(
        state: ViewState<[String]>.error("No se pudo conectar al servidor"),
        onRetry: { print("Reintentando...") }
    ) { item in
        Text(item)
    }
}

#Preview("Dark Mode - Success") {
    EduListView(
        state: ViewState.success(["Item A", "Item B", "Item C"])
    ) { item in
        Text(item)
            .padding()
    }
    .preferredColorScheme(.dark)
}
