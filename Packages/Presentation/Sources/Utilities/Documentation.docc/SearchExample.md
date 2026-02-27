# Search Example

Implementación de búsqueda con debouncing y optimización.

## Overview

Este ejemplo muestra cómo implementar una búsqueda optimizada con:
- Debouncing para evitar llamadas excesivas
- Estados de carga
- Manejo de resultados vacíos
- Cancelación de búsquedas anteriores

## ViewModel

```swift
import Foundation
import Observation
import Binding

@MainActor
@Observable
public final class SearchViewModel {
    
    // MARK: - Search State
    
    public enum SearchState: Equatable {
        case idle
        case searching
        case results([SearchResult])
        case empty
        case error(String)
    }
    
    // MARK: - Properties
    
    @DebouncedProperty(
        debounceInterval: 0.5,
        onDebouncedChange: { [weak self] query in
            await self?.performSearch(query)
        }
    )
    public var searchQuery: String = ""
    
    public var state: SearchState = .idle
    
    public var recentSearches: [String] = []
    
    // MARK: - Computed
    
    public var isSearching: Bool {
        state == .searching
    }
    
    public var results: [SearchResult] {
        if case .results(let items) = state {
            return items
        }
        return []
    }
    
    public var showEmptyState: Bool {
        state == .empty
    }
    
    public var errorMessage: String? {
        if case .error(let message) = state {
            return message
        }
        return nil
    }
    
    // MARK: - Dependencies
    
    private let searchService: SearchServiceProtocol
    private var currentSearchTask: Task<Void, Never>?
    
    // MARK: - Init
    
    public init(searchService: SearchServiceProtocol) {
        self.searchService = searchService
        loadRecentSearches()
    }
    
    // MARK: - Actions
    
    private func performSearch(_ query: String) async {
        // Cancelar búsqueda anterior
        currentSearchTask?.cancel()
        
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedQuery.isEmpty else {
            state = .idle
            return
        }
        
        guard trimmedQuery.count >= 2 else {
            // Esperar más caracteres
            return
        }
        
        state = .searching
        
        currentSearchTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(100)) // Pequeño delay para UI
                
                guard !Task.isCancelled else { return }
                
                let results = try await searchService.search(query: trimmedQuery)
                
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    if results.isEmpty {
                        state = .empty
                    } else {
                        state = .results(results)
                        saveToRecentSearches(trimmedQuery)
                    }
                }
            } catch {
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    state = .error(error.localizedDescription)
                }
            }
        }
    }
    
    public func search(query: String) {
        searchQuery = query
    }
    
    public func selectRecentSearch(_ query: String) {
        searchQuery = query
    }
    
    public func clearSearch() {
        $searchQuery.cancel()
        searchQuery = ""
        state = .idle
    }
    
    public func clearRecentSearches() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: "recentSearches")
    }
    
    public func retry() {
        let query = searchQuery
        searchQuery = ""
        searchQuery = query
    }
    
    // MARK: - Persistence
    
    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: "recentSearches") ?? []
    }
    
    private func saveToRecentSearches(_ query: String) {
        var searches = recentSearches.filter { $0 != query }
        searches.insert(query, at: 0)
        searches = Array(searches.prefix(10))
        recentSearches = searches
        UserDefaults.standard.set(searches, forKey: "recentSearches")
    }
}

// MARK: - Models

public struct SearchResult: Identifiable, Equatable {
    public let id: UUID
    public let title: String
    public let subtitle: String
    public let imageURL: URL?
}
```

## View

```swift
import SwiftUI
import Binding

public struct SearchView: View {
    
    @State private var viewModel: SearchViewModel
    @FocusState private var isSearchFocused: Bool
    
    public init(viewModel: SearchViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                contentView
            }
            .navigationTitle("Buscar")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Buscar...", text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)
                    .focused($isSearchFocused)
                    .autocorrectionDisabled()
                
                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.clearSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
                
                if viewModel.isSearching {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            if isSearchFocused {
                Button("Cancelar") {
                    viewModel.clearSearch()
                    isSearchFocused = false
                }
            }
        }
        .padding()
        .animation(.easeInOut(duration: 0.2), value: isSearchFocused)
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .idle:
            if !viewModel.recentSearches.isEmpty {
                recentSearchesView
            } else {
                emptyIdleView
            }
            
        case .searching:
            searchingView
            
        case .results(let results):
            resultsList(results)
            
        case .empty:
            emptyResultsView
            
        case .error(let message):
            errorView(message)
        }
    }
    
    private var recentSearchesView: some View {
        List {
            Section {
                ForEach(viewModel.recentSearches, id: \.self) { query in
                    Button {
                        viewModel.selectRecentSearch(query)
                    } label: {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.secondary)
                            Text(query)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Búsquedas Recientes")
                    Spacer()
                    Button("Limpiar") {
                        viewModel.clearRecentSearches()
                    }
                    .font(.caption)
                }
            }
        }
    }
    
    private var emptyIdleView: some View {
        ContentUnavailableView(
            "Buscar",
            systemImage: "magnifyingglass",
            description: Text("Escribe para buscar contenido")
        )
    }
    
    private var searchingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Buscando...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func resultsList(_ results: [SearchResult]) -> some View {
        List(results) { result in
            NavigationLink {
                Text("Detalle de \(result.title)")
            } label: {
                HStack(spacing: 12) {
                    AsyncImage(url: result.imageURL) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.title)
                            .font(.headline)
                        Text(result.subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private var emptyResultsView: some View {
        ContentUnavailableView(
            "Sin Resultados",
            systemImage: "doc.text.magnifyingglass",
            description: Text("No se encontraron resultados para \"\(viewModel.searchQuery)\"")
        )
    }
    
    private func errorView(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Error", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Reintentar") {
                viewModel.retry()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
```

## Testing

```swift
import Testing
@testable import Binding

@Suite("SearchViewModel Tests")
@MainActor
struct SearchViewModelTests {
    
    @Test("Initial state is idle")
    func initialState() {
        let viewModel = SearchViewModel(searchService: MockSearchService())
        
        #expect(viewModel.state == .idle)
        #expect(!viewModel.isSearching)
    }
    
    @Test("Empty query returns to idle")
    func emptyQuery() async {
        let viewModel = SearchViewModel(searchService: MockSearchService())
        
        viewModel.searchQuery = "test"
        try? await Task.sleep(for: .milliseconds(600))
        
        viewModel.clearSearch()
        
        #expect(viewModel.state == .idle)
        #expect(viewModel.searchQuery.isEmpty)
    }
    
    @Test("Search with results updates state")
    func searchWithResults() async {
        let service = MockSearchService(results: [
            SearchResult(id: UUID(), title: "Result 1", subtitle: "Subtitle", imageURL: nil)
        ])
        let viewModel = SearchViewModel(searchService: service)
        
        viewModel.searchQuery = "test"
        try? await Task.sleep(for: .milliseconds(700))
        
        #expect(!viewModel.results.isEmpty)
    }
    
    @Test("Empty results shows empty state")
    func emptyResults() async {
        let service = MockSearchService(results: [])
        let viewModel = SearchViewModel(searchService: service)
        
        viewModel.searchQuery = "nonexistent"
        try? await Task.sleep(for: .milliseconds(700))
        
        #expect(viewModel.showEmptyState)
    }
    
    @Test("Recent searches are saved")
    func recentSearchesSaved() async {
        let service = MockSearchService(results: [
            SearchResult(id: UUID(), title: "Test", subtitle: "", imageURL: nil)
        ])
        let viewModel = SearchViewModel(searchService: service)
        
        viewModel.searchQuery = "test query"
        try? await Task.sleep(for: .milliseconds(700))
        
        #expect(viewModel.recentSearches.contains("test query"))
    }
}

// Mock
class MockSearchService: SearchServiceProtocol {
    let results: [SearchResult]
    
    init(results: [SearchResult] = []) {
        self.results = results
    }
    
    func search(query: String) async throws -> [SearchResult] {
        try await Task.sleep(for: .milliseconds(100))
        return results
    }
}
```

## Ver También

- <doc:LoginExample>
- <doc:RegistrationExample>
- <doc:PerformanceOptimization>
- ``DebouncedProperty``
