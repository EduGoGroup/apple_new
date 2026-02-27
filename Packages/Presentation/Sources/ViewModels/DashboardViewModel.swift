import Foundation
import SwiftUI
import EduDomain
import EduCore
import EduFoundation
import EduDomain

/// ViewModel para el Dashboard del estudiante usando CQRS Mediator.
///
/// Este ViewModel se refactorizó para usar el patrón CQRS en lugar de
/// llamar use cases directamente. Todas las operaciones de lectura
/// pasan por queries que aprovechan cache automático.
///
/// ## Responsabilidades
/// - Cargar dashboard del estudiante via GetStudentDashboardQuery
/// - Suscribirse a eventos relevantes (LoginSuccessEvent, MaterialUploadedEvent)
/// - Gestionar estado de carga y errores
/// - Refrescar datos cuando sea necesario
///
/// ## Integración con CQRS
/// - **Queries**: GetStudentDashboardQuery (con cache automático)
/// - **Events**: LoginSuccessEvent, MaterialUploadedEvent (auto-refresh)
///
/// ## Ejemplo de uso
/// ```swift
/// @StateObject private var viewModel = DashboardViewModel(
///     mediator: mediator,
///     eventBus: eventBus,
///     userId: currentUserId
/// )
/// ```
@MainActor
@Observable
public final class DashboardViewModel {

    // MARK: - Published State

    /// Dashboard del estudiante
    public var dashboard: StudentDashboard?

    /// Indica si está cargando
    public var isLoading: Bool = false

    /// Error actual si lo hay
    public var error: Error?

    /// Indica si se debe incluir progreso detallado
    public var includeProgress: Bool = true

    // MARK: - Dependencies

    /// Mediator CQRS para dispatch de queries
    private let mediator: Mediator

    /// EventBus para suscripción a eventos
    private let eventBus: EventBus

    /// ID del usuario actual
    private let userId: UUID

    /// IDs de suscripciones a eventos (para cleanup)
    private var subscriptionIds: [UUID] = []

    // MARK: - Initialization

    /// Crea un nuevo DashboardViewModel.
    ///
    /// - Parameters:
    ///   - mediator: Mediator CQRS para ejecutar queries
    ///   - eventBus: EventBus para suscribirse a eventos de dominio
    ///   - userId: ID del usuario actual
    public init(
        mediator: Mediator,
        eventBus: EventBus,
        userId: UUID
    ) {
        self.mediator = mediator
        self.eventBus = eventBus
        self.userId = userId

        // Suscribirse a eventos relevantes
        Task {
            await subscribeToEvents()
        }
    }

    // MARK: - Public Methods

    /// Carga el dashboard del estudiante.
    ///
    /// Utiliza GetStudentDashboardQuery que tiene cache automático con TTL de 5 minutos.
    /// Si el cache está fresco, retorna inmediatamente sin hacer fetch.
    ///
    /// - Parameter forceRefresh: Forzar recarga ignorando cache
    public func loadDashboard(forceRefresh: Bool = false) async {
        isLoading = true
        error = nil

        do {
            // Crear query con opciones
            let query = GetStudentDashboardQuery(
                userId: userId,
                includeProgress: includeProgress,
                forceRefresh: forceRefresh,
                metadata: [
                    "source": "DashboardViewModel",
                    "timestamp": ISO8601DateFormatter().string(from: Date())
                ]
            )

            // Ejecutar query via Mediator
            let loadedDashboard = try await mediator.send(query)

            // Actualizar estado en MainActor
            self.dashboard = loadedDashboard
            self.isLoading = false

        } catch {
            // Manejar errores específicos de CQRS
            self.error = error
            self.isLoading = false

            // Log del error (en producción usar logger inyectado)
            print("❌ Error loading dashboard: \(error.localizedDescription)")
        }
    }

    /// Refresca el dashboard forzando recarga.
    public func refresh() async {
        await loadDashboard(forceRefresh: true)
    }

    /// Limpia el error actual.
    public func clearError() {
        error = nil
    }

    // MARK: - Event Subscriptions

    /// Suscribe el ViewModel a eventos relevantes.
    private func subscribeToEvents() async {
        // Suscribirse a LoginSuccessEvent para refrescar después de login
        let loginSubscriptionId = await eventBus.subscribe(to: LoginSuccessEvent.self) { [weak self] event in
            guard let self = self else { return }

            // Verificar que el evento sea para este usuario
            if event.userId == self.userId {
                await MainActor.run {
                    Task {
                        await self.refresh()
                    }
                }
            }
        }
        subscriptionIds.append(loginSubscriptionId)

        // Suscribirse a MaterialUploadedEvent para actualizar lista de materiales
        let materialSubscriptionId = await eventBus.subscribe(to: MaterialUploadedEvent.self) { [weak self] _ in
            guard let self = self else { return }

            // Refrescar dashboard cuando se sube un material nuevo
            await MainActor.run {
                Task {
                    await self.refresh()
                }
            }
        }
        subscriptionIds.append(materialSubscriptionId)

        // Suscribirse a AssessmentSubmittedEvent para actualizar intentos recientes
        let assessmentSubscriptionId = await eventBus.subscribe(to: AssessmentSubmittedEvent.self) { [weak self] event in
            guard let self = self else { return }

            // Verificar que el evento sea para este usuario
            if event.userId == self.userId {
                await MainActor.run {
                    Task {
                        await self.refresh()
                    }
                }
            }
        }
        subscriptionIds.append(assessmentSubscriptionId)
    }
}

// MARK: - Convenience Computed Properties

extension DashboardViewModel {
    /// Indica si hay datos cargados
    public var hasDashboard: Bool {
        dashboard != nil
    }

    /// Indica si hay un error
    public var hasError: Bool {
        error != nil
    }

    /// Mensaje de error legible
    public var errorMessage: String? {
        guard let error = error else { return nil }

        // Personalizar mensajes según tipo de error
        if let mediatorError = error as? MediatorError {
            switch mediatorError {
            case .handlerNotFound:
                return "Configuración incorrecta del sistema. Contacte soporte."
            case .validationError(let message, _):
                return "Error de validación: \(message)"
            case .executionError(let message, _):
                return "Error al cargar: \(message)"
            case .registrationError:
                return "Error de configuración del sistema."
            }
        }

        return error.localizedDescription
    }
}
