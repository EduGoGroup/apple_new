// EduDynamicToolbar.swift
// EduPresentation
//
// Dynamic toolbar that adapts based on screen mode.

import SwiftUI

/// Modo del toolbar basado en el tipo de pantalla.
///
/// Independiente de `ScreenPattern` (DynamicUI) para mantener la separacion de capas.
/// El consumidor (e.g. DemoApp) mapea `ScreenPattern` a `ToolbarMode`.
public enum ToolbarMode: Sendable {
    /// Sin toolbar (login, onboarding)
    case hidden

    /// Lista: titulo + boton crear (si permitido) + busqueda
    case list

    /// Formulario: cancelar + titulo + guardar
    case form

    /// Detalle: back + titulo
    case detail

    /// Solo titulo (dashboard, settings, profile)
    case titleOnly
}

/// Toolbar dinamico que cambia segun el modo de pantalla.
public struct EduDynamicToolbar: ViewModifier {
    private let mode: ToolbarMode
    private let title: String
    private let canCreate: Bool
    private let onBack: (() -> Void)?
    private let onSave: (() -> Void)?
    private let onCreate: (() -> Void)?
    private let onSearch: ((String) -> Void)?

    @State private var searchText = ""
    @State private var isSearching = false

    public init(
        mode: ToolbarMode,
        title: String,
        canCreate: Bool = false,
        onBack: (() -> Void)? = nil,
        onSave: (() -> Void)? = nil,
        onCreate: (() -> Void)? = nil,
        onSearch: ((String) -> Void)? = nil
    ) {
        self.mode = mode
        self.title = title
        self.canCreate = canCreate
        self.onBack = onBack
        self.onSave = onSave
        self.onCreate = onCreate
        self.onSearch = onSearch
    }

    public func body(content: Content) -> some View {
        switch mode {
        case .hidden:
            content

        case .list:
            content
                .navigationTitle(title)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        HStack(spacing: DesignTokens.Spacing.small) {
                            if onSearch != nil {
                                Button {
                                    isSearching.toggle()
                                } label: {
                                    Image(systemName: "magnifyingglass")
                                }
                            }

                            if canCreate, let onCreate {
                                Button {
                                    onCreate()
                                } label: {
                                    Image(systemName: "plus")
                                }
                            }
                        }
                    }
                }
                .searchable(
                    text: $searchText,
                    isPresented: $isSearching,
                    prompt: "Buscar..."
                )
                .onChange(of: searchText) { _, newValue in
                    onSearch?(newValue)
                }

        case .form:
            content
                .navigationTitle(title)
                .toolbar {
                    if let onBack {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancelar") { onBack() }
                        }
                    }
                    if let onSave {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Guardar") { onSave() }
                        }
                    }
                }

        case .detail:
            content
                .navigationTitle(title)
                .toolbar {
                    if let onBack {
                        ToolbarItem(placement: .cancellationAction) {
                            Button {
                                onBack()
                            } label: {
                                Image(systemName: "chevron.left")
                            }
                        }
                    }
                }

        case .titleOnly:
            content
                .navigationTitle(title)
        }
    }
}

// MARK: - View Extension

extension View {
    /// Aplica un toolbar dinamico basado en el modo de pantalla.
    public func eduDynamicToolbar(
        mode: ToolbarMode,
        title: String,
        canCreate: Bool = false,
        onBack: (() -> Void)? = nil,
        onSave: (() -> Void)? = nil,
        onCreate: (() -> Void)? = nil,
        onSearch: ((String) -> Void)? = nil
    ) -> some View {
        modifier(
            EduDynamicToolbar(
                mode: mode,
                title: title,
                canCreate: canCreate,
                onBack: onBack,
                onSave: onSave,
                onCreate: onCreate,
                onSearch: onSearch
            )
        )
    }
}
