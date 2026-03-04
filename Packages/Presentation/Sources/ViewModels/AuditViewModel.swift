import Foundation
import SwiftUI
import EduDomain
import EduCore

/// ViewModel para la vista de eventos de auditoría.
///
/// Gestiona la carga paginada de eventos de auditoría y el resumen
/// por severidad. Solo accesible para usuarios con permiso "audit:read".
///
/// ## Acceso
/// Solo visible si `authContext.hasPermission("audit:read") == true`
///
/// ## Ejemplo de uso
/// ```swift
/// let viewModel = AuditViewModel(
///     dataProvider: auditDataProvider,
///     authContext: currentAuthContext
/// )
///
/// // En la vista
/// if viewModel.hasAccess {
///     List(viewModel.events) { event in
///         AuditEventRow(event: event)
///     }
///     .task { await viewModel.loadEvents() }
/// }
/// ```
@MainActor
@Observable
public final class AuditViewModel {

    // MARK: - Published State

    /// Eventos de auditoría cargados.
    public private(set) var events: [AuditEventDTO] = []

    /// Resumen de auditoría por severidad.
    public private(set) var summary: AuditSummaryDTO?

    /// Indica si se está cargando datos.
    public var isLoading: Bool = false

    /// Error actual si lo hay.
    public var error: Error?

    /// Página actual para paginación.
    public private(set) var currentPage: Int = 1

    /// Indica si hay más páginas disponibles.
    public private(set) var hasNextPage: Bool = false

    /// Filtro de severidad activo.
    public var severityFilter: String?

    // MARK: - Dependencies

    private let dataProvider: any AuditDataProvider
    private let authContext: AuthContext?

    // MARK: - Constants

    private let pageSize = 20

    // MARK: - Initialization

    /// Crea un nuevo AuditViewModel.
    ///
    /// - Parameters:
    ///   - dataProvider: Proveedor de datos de auditoría.
    ///   - authContext: Contexto de autenticación del usuario actual.
    public init(
        dataProvider: any AuditDataProvider,
        authContext: AuthContext?
    ) {
        self.dataProvider = dataProvider
        self.authContext = authContext
    }

    // MARK: - Access Control

    /// Indica si el usuario tiene acceso a la vista de auditoría.
    public var hasAccess: Bool {
        authContext?.hasPermission("audit:read") == true
    }

    // MARK: - Public Methods

    /// Carga la primera página de eventos de auditoría.
    public func loadEvents() async {
        guard hasAccess else {
            error = AuditViewModelError.accessDenied
            return
        }

        isLoading = true
        error = nil
        currentPage = 1

        do {
            let result = try await dataProvider.listEvents(
                page: currentPage,
                pageSize: pageSize,
                severity: severityFilter
            )
            events = result.events
            hasNextPage = result.hasNextPage
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }

    /// Carga la siguiente página de eventos (paginación incremental).
    public func loadMore() async {
        guard hasAccess, hasNextPage, !isLoading else { return }

        isLoading = true
        let nextPage = currentPage + 1

        do {
            let result = try await dataProvider.listEvents(
                page: nextPage,
                pageSize: pageSize,
                severity: severityFilter
            )
            events.append(contentsOf: result.events)
            currentPage = nextPage
            hasNextPage = result.hasNextPage
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }

    /// Carga el resumen de auditoría.
    public func loadSummary() async {
        guard hasAccess else { return }

        do {
            summary = try await dataProvider.getSummary()
        } catch {
            self.error = error
        }
    }

    /// Limpia el error actual.
    public func clearError() {
        error = nil
    }

    // MARK: - Computed Properties

    /// Indica si hay un error.
    public var hasError: Bool {
        error != nil
    }

    /// Mensaje de error legible.
    public var errorMessage: String? {
        error?.localizedDescription
    }
}

// MARK: - AuditViewModel Errors

/// Errores del ViewModel de auditoría.
public enum AuditViewModelError: Error, LocalizedError, Sendable {
    case accessDenied

    public var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "No tiene permisos para ver registros de auditoría"
        }
    }
}
