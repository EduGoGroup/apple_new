import EduInfrastructure

// MARK: - AssessmentManagementDataProvider Conformance

/// Extiende AssessmentManagementNetworkService para conformar con
/// el protocolo AssessmentManagementDataProvider definido en Domain.
///
/// Esta conformacion se declara en Domain porque es el primer modulo
/// que tiene acceso tanto a la implementacion concreta (Infrastructure)
/// como al protocolo (Domain).
extension AssessmentManagementNetworkService: AssessmentManagementDataProvider {}
