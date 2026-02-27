import Foundation
import EduCore

// MARK: - UseCase Protocols for Dependency Injection

/// Protocolos que abstraen los UseCases concretos para permitir Dependency Injection
/// en los Handlers de CQRS, siguiendo los principios de Clean Architecture.
///
/// ## Propósito
/// Estos protocolos permiten:
/// - Inyectar mocks en tests
/// - Desacoplar Handlers de implementaciones concretas
/// - Facilitar testing de concurrencia
/// - Mantener Inversión de Dependencias (SOLID)
///
/// ## Patrón
/// Cada protocolo replica la firma de `execute()` del UseCase concreto,
/// pero como protocolo Actor-compatible para Swift 6.2 Concurrency.

// MARK: - Auth UseCases

/// Protocolo para LoginUseCase
public protocol LoginUseCaseProtocol: Actor, Sendable {
    func execute(input: LoginInput) async throws -> LoginOutput
}

// MARK: - Material UseCases

/// Protocolo para UploadMaterialUseCase
public protocol UploadMaterialUseCaseProtocol: Actor, Sendable {
    func execute(input: UploadMaterialInput) async throws -> Material
    func executeWithProgress(input: UploadMaterialInput) async throws -> (material: Material, progress: AsyncStream<UploadProgress>)
}

/// Protocolo para ListMaterialsUseCase
public protocol ListMaterialsUseCaseProtocol: Actor, Sendable {
    func execute(input: ListMaterialsInput) async throws -> MaterialsPage
}

/// Protocolo para AssignMaterialToUnitUseCase
/// NOTA: El nombre del protocolo usa "AssignMaterial" para ser más conciso
public protocol AssignMaterialUseCaseProtocol: Actor, Sendable {
    func execute(input: AssignMaterialInput) async throws -> MaterialAssignment
}

// MARK: - Assessment UseCases

/// Protocolo para TakeAssessmentUseCase
public protocol TakeAssessmentUseCaseProtocol: Actor, Sendable {
    var state: TakeAssessmentFlowState { get }
    var assessment: Assessment? { get }
    var inProgressAttempt: InProgressAttempt? { get }

    func loadAssessment(input: TakeAssessmentInput) async throws -> Assessment
    func startAttempt() async throws -> UUID
    func saveAnswer(questionId: UUID, selectedOptionId: UUID, timeSpentSeconds: Int) async throws
    func submitAttempt() async throws -> AttemptResult
}

/// Protocolo para LoadAssessmentUseCase
public protocol LoadAssessmentUseCaseProtocol: Actor, Sendable {
    func execute(input: LoadAssessmentInput) async throws -> AssessmentDetail
}

// MARK: - Student UseCases

/// Protocolo para LoadStudentDashboardUseCase
public protocol LoadStudentDashboardUseCaseProtocol: Actor, Sendable {
    func execute(input: LoadDashboardInput) async throws -> StudentDashboard
}

// MARK: - User UseCases

/// Protocolo para LoadUserContextUseCase
public protocol LoadUserContextUseCaseProtocol: Actor, Sendable {
    func execute() async throws -> UserContext
}

/// Protocolo para SwitchSchoolContextUseCase
public protocol SwitchSchoolContextUseCaseProtocol: Actor, Sendable {
    func execute(input: SwitchSchoolInput) async throws -> SwitchSchoolOutput
}

/// Protocolo para UpdateUserProfileUseCase
public protocol UpdateUserProfileUseCaseProtocol: Actor, Sendable {
    func execute(input: UpdateUserProfileInput) async throws -> User
}

// MARK: - Sync UseCases

/// Protocolo para SyncProgressUseCase
public protocol SyncProgressUseCaseProtocol: Actor, Sendable {
    func execute(input: SyncProgressInput) async throws -> SyncProgressOutput
}

// MARK: - Conformance Extensions

/// Extensiones que hacen que los UseCases reales conformen los protocolos.
/// Esto permite usar los UseCases concretos en producción sin cambios.

extension LoginUseCase: LoginUseCaseProtocol {}
extension UploadMaterialUseCase: UploadMaterialUseCaseProtocol {}
extension ListMaterialsUseCase: ListMaterialsUseCaseProtocol {}
extension AssignMaterialToUnitUseCase: AssignMaterialUseCaseProtocol {}
extension TakeAssessmentUseCase: TakeAssessmentUseCaseProtocol {}
extension LoadAssessmentUseCase: LoadAssessmentUseCaseProtocol {}
extension LoadStudentDashboardUseCase: LoadStudentDashboardUseCaseProtocol {}
extension LoadUserContextUseCase: LoadUserContextUseCaseProtocol {}
extension SwitchSchoolContextUseCase: SwitchSchoolContextUseCaseProtocol {}
extension UpdateUserProfileUseCase: UpdateUserProfileUseCaseProtocol {}
extension SyncProgressUseCase: SyncProgressUseCaseProtocol {}
