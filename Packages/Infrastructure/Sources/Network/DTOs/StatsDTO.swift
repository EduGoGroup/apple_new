import Foundation
import EduCore

// MARK: - Global Stats Response DTO

/// Estadísticas globales del sistema.
///
/// Respuesta de `GET /v1/stats/global`.
/// Nota: El backend retorna un objeto genérico (additionalProperties: true),
/// por lo que usamos un enum tipado para los campos dinámicos.
public struct GlobalStatsDTO: Decodable, Sendable, Equatable {
    /// Campos de estadísticas conocidos.
    public let totalUsers: Int?
    public let totalMaterials: Int?
    public let totalSchools: Int?
    public let totalTeachers: Int?
    public let totalStudents: Int?
    public let totalAssessments: Int?
    public let averageProgress: Double?

    /// Campos adicionales dinámicos del backend.
    public let additionalFields: [String: JSONValue]

    /// Inicializa las estadísticas globales.
    public init(
        totalUsers: Int? = nil,
        totalMaterials: Int? = nil,
        totalSchools: Int? = nil,
        totalTeachers: Int? = nil,
        totalStudents: Int? = nil,
        totalAssessments: Int? = nil,
        averageProgress: Double? = nil,
        additionalFields: [String: JSONValue] = [:]
    ) {
        self.totalUsers = totalUsers
        self.totalMaterials = totalMaterials
        self.totalSchools = totalSchools
        self.totalTeachers = totalTeachers
        self.totalStudents = totalStudents
        self.totalAssessments = totalAssessments
        self.averageProgress = averageProgress
        self.additionalFields = additionalFields
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)

        // Decodificar campos conocidos
        totalUsers = try container.decodeIfPresent(Int.self, forKey: DynamicCodingKey(stringValue: "total_users")!)
        totalMaterials = try container.decodeIfPresent(Int.self, forKey: DynamicCodingKey(stringValue: "total_materials")!)
        totalSchools = try container.decodeIfPresent(Int.self, forKey: DynamicCodingKey(stringValue: "total_schools")!)
        totalTeachers = try container.decodeIfPresent(Int.self, forKey: DynamicCodingKey(stringValue: "total_teachers")!)
        totalStudents = try container.decodeIfPresent(Int.self, forKey: DynamicCodingKey(stringValue: "total_students")!)
        totalAssessments = try container.decodeIfPresent(Int.self, forKey: DynamicCodingKey(stringValue: "total_assessments")!)
        averageProgress = try container.decodeIfPresent(Double.self, forKey: DynamicCodingKey(stringValue: "average_progress")!)

        // Decodificar campos adicionales dinámicos
        let knownKeys: Set<String> = [
            "total_users", "total_materials", "total_schools",
            "total_teachers", "total_students", "total_assessments", "average_progress"
        ]

        var additional: [String: JSONValue] = [:]
        for key in container.allKeys where !knownKeys.contains(key.stringValue) {
            if let value = try? container.decode(JSONValue.self, forKey: key) {
                additional[key.stringValue] = value
            }
        }
        additionalFields = additional
    }
}

// MARK: - Dynamic Coding Key

/// Clave de codificación dinámica para decodificar campos desconocidos.
struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}
