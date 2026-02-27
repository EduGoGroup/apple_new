// AdaptiveNavigationContainer.swift
// EduPresentation
//
// Adaptive navigation container that switches between TabView and NavigationSplitView.

import SwiftUI
import EduDomain

/// Contenedor de navegacion adaptativo.
///
/// Cambia la estructura de navegacion segun el tamano de pantalla:
/// - **Compact**: `TabView` con max 5 items (primeros por sortOrder) + "More" si hay mas
/// - **Medium/Expanded**: `NavigationSplitView` con sidebar
///
/// Cada seleccion navega a la pantalla dinamica correspondiente.
public struct AdaptiveNavigationContainer<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let menuItems: [MenuItem]
    private let selectedItem: Binding<String?>
    private let sidebarHeader: AnyView?
    private let sidebarFooter: AnyView?
    private let content: (MenuItem) -> Content

    public init(
        menuItems: [MenuItem],
        selectedItem: Binding<String?>,
        @ViewBuilder sidebarHeader: () -> some View = { EmptyView() },
        @ViewBuilder sidebarFooter: () -> some View = { EmptyView() },
        @ViewBuilder content: @escaping (MenuItem) -> Content
    ) {
        self.menuItems = menuItems
        self.selectedItem = selectedItem
        self.sidebarHeader = AnyView(sidebarHeader())
        self.sidebarFooter = AnyView(sidebarFooter())
        self.content = content
    }

    private var layoutType: AdaptiveLayoutType {
        switch horizontalSizeClass {
        case .compact:
            return .compact
        default:
            return .expanded
        }
    }

    public var body: some View {
        switch layoutType {
        case .compact:
            compactLayout
        case .medium, .expanded:
            expandedLayout
        }
    }

    // MARK: - Compact Layout (TabView)

    private var tabItems: [MenuItem] {
        let sorted = menuItems.sorted { $0.sortOrder < $1.sortOrder }
        return Array(sorted.prefix(5))
    }

    @ViewBuilder
    private var compactLayout: some View {
        let binding = Binding<String>(
            get: { selectedItem.wrappedValue ?? tabItems.first?.key ?? "" },
            set: { selectedItem.wrappedValue = $0 }
        )

        TabView(selection: binding) {
            ForEach(tabItems) { item in
                content(item)
                    .tabItem {
                        Label(
                            item.displayName,
                            systemImage: IconMapper.sfSymbol(from: item.icon ?? "")
                        )
                    }
                    .tag(item.key)
            }
        }
    }

    // MARK: - Expanded Layout (NavigationSplitView)

    @ViewBuilder
    private var expandedLayout: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                if let header = sidebarHeader {
                    header
                }

                List(selection: selectedItem) {
                    ForEach(menuItems) { item in
                        if item.children.isEmpty {
                            EduMenuRow(item: item, isSelected: selectedItem.wrappedValue == item.key)
                                .tag(item.key)
                        } else {
                            DisclosureGroup {
                                ForEach(item.children) { child in
                                    EduMenuRow(item: child, isSelected: selectedItem.wrappedValue == child.key)
                                        .tag(child.key)
                                }
                            } label: {
                                EduMenuRow(item: item, isSelected: false)
                            }
                        }
                    }
                }
                .listStyle(.sidebar)

                if let footer = sidebarFooter {
                    footer
                }
            }
            .navigationTitle("Menu")
        } detail: {
            if let key = selectedItem.wrappedValue,
               let item = findItem(key: key) {
                content(item)
            } else if let first = menuItems.first {
                content(first)
            } else {
                ContentUnavailableView(
                    "Selecciona una opcion",
                    systemImage: "sidebar.left"
                )
            }
        }
    }

    // MARK: - Helpers

    private func findItem(key: String) -> MenuItem? {
        for item in menuItems {
            if item.key == key { return item }
            if let child = item.children.first(where: { $0.key == key }) {
                return child
            }
        }
        return nil
    }
}
