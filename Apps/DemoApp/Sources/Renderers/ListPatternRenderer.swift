import SwiftUI
import EduDynamicUI
import EduPresentation
import EduModels

struct ListPatternRenderer: View {
    let screen: ScreenDefinition
    let viewModel: DynamicScreenViewModel

    @State private var searchText = ""
    @State private var searchTask: Task<Void, Never>?

    private var itemLayout: ItemLayout? {
        screen.template.zones.first(where: { $0.itemLayout != nil })?.itemLayout
    }

    private var hasSearchBar: Bool {
        screen.template.zones.contains { zone in
            zone.slots?.contains(where: { $0.controlType == .searchBar }) == true
        }
    }

    private var title: String {
        if let titleData = screen.slotData?["page_title"] {
            return titleData.stringRepresentation
        }
        return screen.template.navigation?.topBar?.title ?? screen.screenName
    }

    var body: some View {
        contentView
            .navigationTitle(title)
            .refreshable {
                await viewModel.refresh()
            }
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.dataState {
        case .idle, .loading:
            EduLoadingStateView()

        case .error(let message):
            EduErrorStateView(message: message) {
                Task { await viewModel.refresh() }
            }

        case .success(let items, let hasMore, let loadingMore):
            if items.isEmpty && !loadingMore {
                EduEmptyStateView(
                    icon: "tray",
                    title: "Sin resultados",
                    description: "No hay elementos para mostrar",
                    actionTitle: "Recargar"
                ) {
                    Task { await viewModel.refresh() }
                }
            } else {
                listContent(items: items, hasMore: hasMore, loadingMore: loadingMore)
            }
        }
    }

    @ViewBuilder
    private func listContent(
        items: [[String: EduModels.JSONValue]],
        hasMore: Bool,
        loadingMore: Bool
    ) -> some View {
        let filteredItems = filterItems(items)

        List {
            if hasSearchBar {
                searchSection
            }

            ForEach(Array(filteredItems.enumerated()), id: \.offset) { _, item in
                itemRow(item: item)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        Task {
                            await viewModel.executeEvent(.selectItem, selectedItem: item)
                        }
                    }
            }

            if hasMore {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .onAppear {
                        Task { await viewModel.loadNextPage() }
                    }
            }
        }
        .listStyle(.plain)
    }

    @ViewBuilder
    private var searchSection: some View {
        TextField("Buscar...", text: $searchText)
            .textFieldStyle(.roundedBorder)
            .onChange(of: searchText) { _, newValue in
                searchTask?.cancel()
                searchTask = Task {
                    try? await Task.sleep(for: .milliseconds(300))
                    guard !Task.isCancelled else { return }
                    viewModel.searchQuery = newValue
                    await viewModel.executeEvent(.search)
                }
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }

    @ViewBuilder
    private func itemRow(item: [String: EduModels.JSONValue]) -> some View {
        if let layout = itemLayout {
            HStack(spacing: 8) {
                ForEach(layout.slots) { slot in
                    SlotRenderer(
                        slot: slot,
                        data: item,
                        slotData: screen.slotData,
                        actions: screen.actions,
                        onAction: { action in viewModel.executeAction(action) }
                    )
                }
            }
        } else {
            defaultItemRow(item: item)
        }
    }

    @ViewBuilder
    private func defaultItemRow(item: [String: EduModels.JSONValue]) -> some View {
        let titleValue = item["name"] ?? item["title"] ?? item["label"]
        let subtitleValue = item["description"] ?? item["subtitle"] ?? item["code"]

        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(titleValue?.stringRepresentation ?? "Item")
                    .font(.body)
                if let subtitle = subtitleValue?.stringRepresentation, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func filterItems(_ items: [[String: EduModels.JSONValue]]) -> [[String: EduModels.JSONValue]] {
        guard !searchText.isEmpty else { return items }
        let query = searchText.lowercased()
        return items.filter { item in
            item.values.contains { value in
                value.stringRepresentation.lowercased().contains(query)
            }
        }
    }
}
