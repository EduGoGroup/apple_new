import Foundation
import EduFoundation
import EduInfrastructure

// MARK: - Eligibility Service

/// Implementacion del servicio de elegibilidad que conforma `EligibilityServiceProtocol`.
///
/// Utiliza `EligibilityNetworkService` del modulo de Infrastructure para obtener
/// datos de elegibilidad del servidor y los mapea a `AssessmentEligibility` del dominio.
///
/// ## Thread Safety
/// Como actor de Swift 6.2, todas las operaciones son thread-safe.
///
/// ## Ejemplo de uso
/// ```swift
/// let networkService = EligibilityNetworkService(
///     client: authenticatedClient,
///     baseURL: config.mobileBaseURL
/// )
/// let service = EligibilityService(networkService: networkService)
///
/// let eligibility = try await service.checkEligibility(
///     assessmentId: assessmentId,
///     userId: userId
/// )
/// ```
public actor EligibilityService: EligibilityServiceProtocol {

    // MARK: - Dependencies

    private let networkService: EligibilityNetworkService

    // MARK: - Initialization

    /// Crea un nuevo servicio de elegibilidad.
    ///
    /// - Parameter networkService: Servicio de red de elegibilidad (de Infrastructure)
    public init(networkService: EligibilityNetworkService) {
        self.networkService = networkService
    }

    // MARK: - EligibilityServiceProtocol

    public func checkEligibility(
        assessmentId: UUID,
        userId: UUID
    ) async throws -> AssessmentEligibility {
        let dto = try await networkService.checkEligibility(
            assessmentId: assessmentId.uuidString,
            userId: userId.uuidString
        )
        return Self.mapToDomain(dto)
    }

    // MARK: - DTO to Domain Mapping

    /// Mapea un EligibilityDTO a un AssessmentEligibility del dominio.
    static func mapToDomain(_ dto: EligibilityDTO) -> AssessmentEligibility {
        let reason: EligibilityReason? = dto.reason.flatMap { EligibilityReason(rawValue: $0) }

        return AssessmentEligibility(
            canTake: dto.canTake,
            reason: reason,
            attemptsLeft: dto.attemptsLeft,
            expiresAt: dto.expiresAt
        )
    }
}
