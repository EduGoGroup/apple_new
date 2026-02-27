import Foundation

// MARK: - School Info DTO

/// Datos resumidos de una escuela en el contexto de autenticacion.
///
/// Diferente de `SchoolDTO` (que es la entidad completa).
/// Este DTO solo contiene lo necesario para seleccion de contexto.
public struct SchoolInfoDTO: Codable, Sendable, Equatable, Hashable, Identifiable {
    public let id: String
    public let name: String
    public let code: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case code
    }

    public init(id: String, name: String, code: String? = nil) {
        self.id = id
        self.name = name
        self.code = code
    }
}
