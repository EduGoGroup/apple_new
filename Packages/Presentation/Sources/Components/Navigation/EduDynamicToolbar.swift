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

/// Action for the detail mode context menu.
public struct ToolbarContextAction: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let icon: String
    public let role: ButtonRole?
    public let action: @Sendable () -> Void

    public init(
        id: String,
        title: String,
        icon: String,
        role: ButtonRole? = nil,
        action: @escaping @Sendable () -> Void
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.role = role
        self.action = action
    }
}

/// Toolbar dinamico que cambia segun el modo de pantalla.
public struct EduDynamicToolbar: ViewModifier {
    private let mode: ToolbarMode
    private let title: String
    private let canCreate: Bool
    private let pendingMutationCount: Int
    private let contextActions: [ToolbarContextAction]
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
        pendingMutationCount: Int = 0,
        contextActions: [ToolbarContextAction] = [],
        onBack: (() -> Void)? = nil,
        onSave: (() -> Void)? = nil,
        onCreate: (() -> Void)? = nil,
        onSearch: ((String) -> Void)? = nil
    ) {
        self.mode = mode
        self.title = title
        self.canCreate = canCreate
        self.pendingMutationCount = pendingMutationCount
        self.contextActions = contextActions
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
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        isSearching.toggle()
                                    }
                                } label: {
                                    Image(systemName: "magnifyingglass")
                                }
                            }

                            if pendingMutationCount > 0 {
                                pendingBadge
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
                            HStack(spacing: DesignTokens.Spacing.small) {
                                if pendingMutationCount > 0 {
                                    pendingBadge
                                }
                                Button("Guardar") { onSave() }
                            }
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
                    if !contextActions.isEmpty {
                        ToolbarItem(placement: .primaryAction) {
                            Menu {
                                ForEach(contextActions) { action in
                                    Button(role: action.role) {
                                        action.action()
                                    } label: {
                                        Label(action.title, systemImage: action.icon)
                                    }
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                        }
                    }
                }

        case .titleOnly:
            content
                .navigationTitle(title)
                .toolbar {
                    if pendingMutationCount > 0 {
                        ToolbarItem(placement: .primaryAction) {
                            pendingBadge
                        }
                    }
                }
        }
    }

    // MARK: - Private

    private var pendingBadge: some View {
        Text("\(pendingMutationCount)")
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.orange, in: .capsule)
            .accessibilityLabel("\(pendingMutationCount) pending changes")
    }
}

// MARK: - View Extension

extension View {
    /// Aplica un toolbar dinamico basado en el modo de pantalla.
    public func eduDynamicToolbar(
        mode: ToolbarMode,
        title: String,
        canCreate: Bool = false,
        pendingMutationCount: Int = 0,
        contextActions: [ToolbarContextAction] = [],
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
                pendingMutationCount: pendingMutationCount,
                contextActions: contextActions,
                onBack: onBack,
                onSave: onSave,
                onCreate: onCreate,
                onSearch: onSearch
            )
        )
    }
}
