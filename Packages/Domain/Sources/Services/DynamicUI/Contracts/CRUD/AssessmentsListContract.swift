import EduCore

/// Contrato para la lista de evaluaciones de un material.
public struct AssessmentsListContract: ScreenContract {
    public let screenKey = "assessments-list"
    public let resource = "assessments"

    public init() {}

    public func endpointFor(event: ScreenEvent, context: EventContext) -> String? {
        switch event {
        case .loadData, .refresh:
            guard let materialId = context.selectedItem?["material_id"]?.stringValue else {
                return "mobile:/api/v1/materials/assessment"
            }
            return "mobile:/api/v1/materials/\(materialId)/assessment"
        case .search:
            let query = context.searchQuery ?? ""
            return "mobile:/api/v1/materials/assessment?search=\(query)"
        default:
            return nil
        }
    }

    public func permissionFor(event: ScreenEvent) -> String? {
        switch event {
        case .loadData, .refresh, .search, .selectItem:
            return "assessments:read"
        default:
            return nil
        }
    }
}
