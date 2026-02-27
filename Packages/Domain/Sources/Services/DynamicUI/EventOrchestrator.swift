import Foundation
import EduCore
import EduInfrastructure
import EduDynamicUI

/// Actor que ejecuta eventos de pantalla con verificacion de permisos,
/// resolucion de endpoints y delegacion a handlers personalizados.
///
/// Flujo de ejecucion:
/// 1. Buscar contrato para la pantalla
/// 2. Verificar permisos del usuario
/// 3. Resolver endpoint
/// 4. Si hay custom handler, ejecutarlo
/// 5. Si es lectura, fetch via DataLoader
/// 6. Si es escritura, enviar al API o encolar offline
public actor EventOrchestrator {
    private let registry: ContractRegistry
    private let networkClient: any NetworkClientProtocol
    private let dataLoader: DataLoader
    private let mutationQueue: MutationQueue?

    public init(
        registry: ContractRegistry,
        networkClient: any NetworkClientProtocol,
        dataLoader: DataLoader,
        mutationQueue: MutationQueue? = nil
    ) {
        self.registry = registry
        self.networkClient = networkClient
        self.dataLoader = dataLoader
        self.mutationQueue = mutationQueue
    }

    /// Ejecuta un evento de pantalla.
    public func execute(event: ScreenEvent, context: EventContext) async -> EventResult {
        // 1. Buscar contrato
        guard let contract = await MainActor.run(body: { registry.contract(for: context.screenKey) }) else {
            return .error(message: "No contract for screen: \(context.screenKey)")
        }

        // 2. Verificar permisos
        if let requiredPermission = contract.permissionFor(event: event) {
            guard context.userContext.hasPermission(requiredPermission) else {
                return .permissionDenied
            }
        }

        // 3. Resolver endpoint
        let endpoint = contract.endpointFor(event: event, context: context)

        // 4. Ejecutar segun tipo de evento
        switch event {
        case .loadData, .refresh, .search, .loadMore:
            return await executeRead(endpoint: endpoint, event: event, context: context)

        case .saveNew, .saveExisting, .delete:
            return await executeWrite(
                endpoint: endpoint,
                event: event,
                context: context
            )

        case .selectItem:
            return Self.resolveNavigation(contract: contract, context: context)

        case .create:
            let formKey = "\(contract.screenKey.replacingOccurrences(of: ":list", with: "")):crud"
            return .navigateTo(screenKey: formKey)
        }
    }

    /// Ejecuta un evento personalizado por su ID.
    public func executeCustom(eventId: String, context: EventContext) async -> EventResult {
        guard let contract = await MainActor.run(body: { registry.contract(for: context.screenKey) }) else {
            return .error(message: "No contract for screen: \(context.screenKey)")
        }

        guard let handler = contract.customEventHandler(for: eventId) else {
            return .noOp
        }

        return await handler(context)
    }

    // MARK: - Private

    private func executeRead(
        endpoint: String?,
        event: ScreenEvent,
        context: EventContext
    ) async -> EventResult {
        guard let endpoint else {
            return .error(message: "No endpoint for event: \(event.rawValue)")
        }

        do {
            let config = await MainActor.run(body: {
                registry.contract(for: context.screenKey)?.dataConfig()
            })

            let data: [String: JSONValue]
            if event == .loadMore {
                data = try await dataLoader.loadNextPage(
                    endpoint: endpoint,
                    config: config,
                    currentOffset: context.paginationOffset
                )
            } else {
                data = try await dataLoader.loadData(
                    endpoint: endpoint,
                    config: config
                )
            }
            return .success(data: .object(data))
        } catch {
            return .error(message: error.localizedDescription, canRetry: true)
        }
    }

    private func executeWrite(
        endpoint: String?,
        event: ScreenEvent,
        context: EventContext
    ) async -> EventResult {
        guard let endpoint else {
            return .error(message: "No endpoint for event: \(event.rawValue)")
        }

        let method: String
        switch event {
        case .saveNew: method = "POST"
        case .saveExisting: method = "PUT"
        case .delete: method = "DELETE"
        default: method = "POST"
        }

        // Preparar body como JSONValue
        var bodyDict: [String: JSONValue] = [:]
        for (key, value) in context.fieldValues {
            bodyDict[key] = .string(value)
        }
        let body = JSONValue.object(bodyDict)

        // Intentar enviar directamente al API
        do {
            let request: HTTPRequest
            switch event {
            case .delete:
                request = HTTPRequest.delete(endpoint)
            case .saveExisting:
                let bodyData = try JSONEncoder().encode(body)
                request = HTTPRequest.put(endpoint).jsonBody(bodyData)
            default:
                let bodyData = try JSONEncoder().encode(body)
                request = HTTPRequest.post(endpoint).jsonBody(bodyData)
            }

            let _: EmptyResponse = try await networkClient.request(request)
            let message: String
            switch event {
            case .saveNew: message = "Created successfully"
            case .saveExisting: message = "Updated successfully"
            case .delete: message = "Deleted successfully"
            default: message = "Operation completed"
            }
            return .success(message: message)
        } catch {
            // Si falla y hay mutation queue, encolar offline
            if let queue = mutationQueue {
                let mutation = PendingMutation(
                    endpoint: endpoint,
                    method: method,
                    body: body
                )
                do {
                    try await queue.enqueue(mutation)
                    return .success(message: "Saved offline. Will sync when connected.")
                } catch {
                    return .error(message: "Failed to save offline: \(error.localizedDescription)")
                }
            }
            return .error(message: error.localizedDescription, canRetry: true)
        }
    }

    /// Resuelve la navegacion para un selectItem (pure logic, no actor state needed).
    static func resolveNavigation(
        contract: any ScreenContract,
        context: EventContext
    ) -> EventResult {
        guard let item = context.selectedItem,
              let id = item["id"]?.stringValue else {
            return .noOp
        }

        let detailKey = "\(contract.screenKey.replacingOccurrences(of: ":list", with: "")):crud"
        return .navigateTo(screenKey: detailKey, params: ["id": id])
    }
}
