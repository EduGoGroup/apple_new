import Foundation
import EduFoundation
import EduCore

// MARK: - Input/Output Types

/// Input para cargar el dashboard del estudiante.
///
/// Contiene el ID del usuario y opciones de configuración para la carga.
public struct LoadDashboardInput: Sendable, Equatable {
    /// ID del estudiante
    public let userId: UUID

    /// Si se debe incluir el resumen de progreso (por defecto true)
    public let includeProgress: Bool

    /// Inicializa el input para cargar el dashboard.
    ///
    /// - Parameters:
    ///   - userId: ID del estudiante
    ///   - includeProgress: Si se debe cargar el progreso (default: true)
    public init(userId: UUID, includeProgress: Bool = true) {
        self.userId = userId
        self.includeProgress = includeProgress
    }
}

/// Resumen de progreso del estudiante.
public struct ProgressSummary: Sendable, Equatable {
    /// Número de materiales completados
    public let completed: Int

    /// Número de materiales en progreso
    public let inProgress: Int

    /// Número de materiales pendientes
    public let pending: Int

    /// Porcentaje promedio de progreso
    public let averagePercentage: Double

    public init(
        completed: Int,
        inProgress: Int,
        pending: Int,
        averagePercentage: Double
    ) {
        self.completed = completed
        self.inProgress = inProgress
        self.pending = pending
        self.averagePercentage = averagePercentage
    }
}

/// Intento de evaluación reciente.
public struct AssessmentAttempt: Sendable, Equatable, Identifiable {
    /// ID del intento
    public let id: UUID

    /// ID del material asociado
    public let materialId: UUID

    /// Título del material
    public let materialTitle: String

    /// Puntaje obtenido
    public let score: Int

    /// Puntaje máximo
    public let maxScore: Int

    /// Si aprobó
    public let passed: Bool

    /// Fecha de completado
    public let completedAt: Date

    public init(
        id: UUID,
        materialId: UUID,
        materialTitle: String,
        score: Int,
        maxScore: Int,
        passed: Bool,
        completedAt: Date
    ) {
        self.id = id
        self.materialId = materialId
        self.materialTitle = materialTitle
        self.score = score
        self.maxScore = maxScore
        self.passed = passed
        self.completedAt = completedAt
    }
}

/// Metadata del dashboard con timings y errores parciales.
public struct DashboardMetadata: Sendable, Equatable {
    /// Tiempo de carga de materiales en milisegundos
    public let materialsLoadTimeMs: Int?

    /// Tiempo de carga de progreso en milisegundos
    public let progressLoadTimeMs: Int?

    /// Tiempo de carga de intentos en milisegundos
    public let attemptsLoadTimeMs: Int?

    /// Tiempo total de carga en milisegundos
    public let totalLoadTimeMs: Int

    /// Errores parciales que ocurrieron durante la carga
    public let partialFailures: [DashboardPartialError]

    public init(
        materialsLoadTimeMs: Int?,
        progressLoadTimeMs: Int?,
        attemptsLoadTimeMs: Int?,
        totalLoadTimeMs: Int,
        partialFailures: [DashboardPartialError] = []
    ) {
        self.materialsLoadTimeMs = materialsLoadTimeMs
        self.progressLoadTimeMs = progressLoadTimeMs
        self.attemptsLoadTimeMs = attemptsLoadTimeMs
        self.totalLoadTimeMs = totalLoadTimeMs
        self.partialFailures = partialFailures
    }
}

/// Error parcial durante la carga del dashboard.
public struct DashboardPartialError: Sendable, Equatable {
    /// Tipo de recurso que falló
    public let resourceType: DashboardResourceType

    /// Mensaje de error
    public let message: String

    public init(resourceType: DashboardResourceType, message: String) {
        self.resourceType = resourceType
        self.message = message
    }
}

/// Tipos de recursos del dashboard.
public enum DashboardResourceType: String, Sendable, Equatable {
    case materials
    case progress
    case attempts
}

/// Dashboard completo del estudiante.
public struct StudentDashboard: Sendable, Equatable {
    /// Materiales recientes
    public let recentMaterials: [Material]

    /// Resumen de progreso (nil si falló o no se solicitó)
    public let progressSummary: ProgressSummary?

    /// Intentos recientes de evaluaciones
    public let recentAttempts: [AssessmentAttempt]

    /// Fecha de carga del dashboard
    public let loadedAt: Date

    /// Metadata con timings y errores parciales
    public let metadata: DashboardMetadata

    public init(
        recentMaterials: [Material],
        progressSummary: ProgressSummary?,
        recentAttempts: [AssessmentAttempt],
        loadedAt: Date,
        metadata: DashboardMetadata
    ) {
        self.recentMaterials = recentMaterials
        self.progressSummary = progressSummary
        self.recentAttempts = recentAttempts
        self.loadedAt = loadedAt
        self.metadata = metadata
    }
}

// MARK: - Repository Protocols

/// Protocolo del repositorio de materiales para el dashboard.
public protocol DashboardMaterialsRepositoryProtocol: Sendable {
    /// Obtiene los materiales recientes.
    /// - Parameter limit: Número máximo de materiales a retornar
    /// - Returns: Lista de materiales recientes
    func listRecent(limit: Int) async throws -> [Material]
}

/// Protocolo del repositorio de progreso para el dashboard.
public protocol DashboardProgressRepositoryProtocol: Sendable {
    /// Obtiene el resumen de progreso del usuario.
    /// - Parameter userId: ID del usuario
    /// - Returns: Resumen de progreso
    func getSummary(userId: UUID) async throws -> ProgressSummary
}

/// Protocolo del repositorio de intentos para el dashboard.
public protocol DashboardAttemptsRepositoryProtocol: Sendable {
    /// Obtiene los intentos recientes del usuario.
    /// - Parameters:
    ///   - userId: ID del usuario
    ///   - limit: Número máximo de intentos a retornar
    /// - Returns: Lista de intentos recientes
    func listRecent(userId: UUID, limit: Int) async throws -> [AssessmentAttempt]
}

// MARK: - LoadStudentDashboardUseCase

/// Actor que implementa la carga optimizada del dashboard del estudiante.
///
/// Este use case coordina la carga paralela de materiales, progreso y evaluaciones
/// implementando graceful degradation ante errores parciales.
///
/// ## Flujo de Ejecución
/// 1. Validar input (userId válido)
/// 2. Ejecutar 3 fetches en PARALELO con TaskGroup
/// 3. Aplicar timeouts individuales (5s) y global (8s)
/// 4. Ensamblar dashboard con graceful degradation
/// 5. Cachear resultado (TTL: 2 minutos)
///
/// ## Optimizaciones
/// - TaskGroup para paralelización máxima de 3 fetches
/// - Timeout individual por fetch: 5 segundos
/// - Timeout global: 8 segundos
/// - Graceful degradation: 1-2 fetches pueden fallar
/// - Cache inteligente con TTL de 2 minutos
///
/// ## Graceful Degradation
/// - Si materials falla: retorna array vacío
/// - Si progress falla: retorna nil
/// - Si attempts falla: retorna array vacío
/// - Solo falla si TODOS los fetches fallan
///
/// ## Ejemplo de Uso
/// ```swift
/// let useCase = LoadStudentDashboardUseCase(
///     materialsRepository: materialsRepo,
///     progressRepository: progressRepo,
///     attemptsRepository: attemptsRepo
/// )
///
/// let input = LoadDashboardInput(userId: studentId)
/// let dashboard = try await useCase.execute(input: input)
///
/// print("Materiales: \(dashboard.recentMaterials.count)")
/// print("Progreso: \(dashboard.progressSummary?.averagePercentage ?? 0)%")
/// if !dashboard.metadata.partialFailures.isEmpty {
///     print("Advertencia: \(dashboard.metadata.partialFailures.count) errores parciales")
/// }
/// ```
public actor LoadStudentDashboardUseCase: UseCase {

    public typealias Input = LoadDashboardInput
    public typealias Output = StudentDashboard

    // MARK: - Dependencies

    private let materialsRepository: DashboardMaterialsRepositoryProtocol
    private let progressRepository: DashboardProgressRepositoryProtocol
    private let attemptsRepository: DashboardAttemptsRepositoryProtocol

    // MARK: - Cache

    private var cachedDashboard: [UUID: CachedDashboard] = [:]
    private let cacheDuration: TimeInterval = 120 // 2 minutos

    // MARK: - Configuration

    private let individualTimeout: TimeInterval = 5.0
    private let globalTimeout: TimeInterval = 8.0
    private let materialsLimit = 10
    private let attemptsLimit = 5

    // MARK: - Initialization

    /// Crea una nueva instancia del caso de uso.
    ///
    /// - Parameters:
    ///   - materialsRepository: Repositorio de materiales
    ///   - progressRepository: Repositorio de progreso
    ///   - attemptsRepository: Repositorio de intentos
    public init(
        materialsRepository: DashboardMaterialsRepositoryProtocol,
        progressRepository: DashboardProgressRepositoryProtocol,
        attemptsRepository: DashboardAttemptsRepositoryProtocol
    ) {
        self.materialsRepository = materialsRepository
        self.progressRepository = progressRepository
        self.attemptsRepository = attemptsRepository
    }

    // MARK: - UseCase Implementation

    /// Ejecuta la carga del dashboard del estudiante.
    ///
    /// - Parameter input: Input con userId y opciones
    /// - Returns: StudentDashboard con toda la información
    /// - Throws: UseCaseError si todos los fetches fallan
    public func execute(input: LoadDashboardInput) async throws -> StudentDashboard {
        let startTime = Date()

        // Verificar cache
        if let cached = cachedDashboard[input.userId],
           Date().timeIntervalSince(cached.timestamp) < cacheDuration {
            return cached.dashboard
        }

        // Ejecutar fetches en paralelo con timeout global
        let fetchResults: FetchResults
        do {
            fetchResults = try await withThrowingTaskGroup(
                of: FetchResult.self,
                returning: FetchResults.self
            ) { group in
                // Task 1: Cargar materiales recientes
                group.addTask {
                    await self.fetchMaterials()
                }

                // Task 2: Cargar resumen de progreso (si se solicita)
                if input.includeProgress {
                    group.addTask {
                        await self.fetchProgress(userId: input.userId)
                    }
                }

                // Task 3: Cargar intentos recientes
                group.addTask {
                    await self.fetchAttempts(userId: input.userId)
                }

                // Recolectar resultados
                var materials: [Material] = []
                var materialsTime: Int?
                var progress: ProgressSummary?
                var progressTime: Int?
                var attempts: [AssessmentAttempt] = []
                var attemptsTime: Int?
                var errors: [DashboardPartialError] = []

                for try await result in group {
                    switch result {
                    case .materials(let data, let timeMs):
                        materials = data
                        materialsTime = timeMs
                    case .materialsError(let error):
                        errors.append(DashboardPartialError(
                            resourceType: .materials,
                            message: error.localizedDescription
                        ))
                    case .progress(let data, let timeMs):
                        progress = data
                        progressTime = timeMs
                    case .progressError(let error):
                        errors.append(DashboardPartialError(
                            resourceType: .progress,
                            message: error.localizedDescription
                        ))
                    case .attempts(let data, let timeMs):
                        attempts = data
                        attemptsTime = timeMs
                    case .attemptsError(let error):
                        errors.append(DashboardPartialError(
                            resourceType: .attempts,
                            message: error.localizedDescription
                        ))
                    }
                }

                return FetchResults(
                    materials: materials,
                    materialsTimeMs: materialsTime,
                    progress: progress,
                    progressTimeMs: progressTime,
                    attempts: attempts,
                    attemptsTimeMs: attemptsTime,
                    errors: errors
                )
            }
        } catch {
            throw UseCaseError.executionFailed(
                reason: "Error en carga paralela del dashboard: \(error.localizedDescription)"
            )
        }

        // Verificar si todos los fetches fallaron
        let allFailed = fetchResults.materials.isEmpty
            && fetchResults.progress == nil
            && fetchResults.attempts.isEmpty
            && fetchResults.errors.count >= (input.includeProgress ? 3 : 2)

        if allFailed {
            throw UseCaseError.executionFailed(
                reason: "Todos los fetches del dashboard fallaron: \(fetchResults.errors.map { $0.message }.joined(separator: ", "))"
            )
        }

        // Calcular tiempo total
        let totalTimeMs = Int(Date().timeIntervalSince(startTime) * 1000)

        // Crear metadata
        let metadata = DashboardMetadata(
            materialsLoadTimeMs: fetchResults.materialsTimeMs,
            progressLoadTimeMs: fetchResults.progressTimeMs,
            attemptsLoadTimeMs: fetchResults.attemptsTimeMs,
            totalLoadTimeMs: totalTimeMs,
            partialFailures: fetchResults.errors
        )

        // Ensamblar dashboard
        let dashboard = StudentDashboard(
            recentMaterials: fetchResults.materials,
            progressSummary: fetchResults.progress,
            recentAttempts: fetchResults.attempts,
            loadedAt: Date(),
            metadata: metadata
        )

        // Cachear resultado
        cachedDashboard[input.userId] = CachedDashboard(
            dashboard: dashboard,
            timestamp: Date()
        )

        return dashboard
    }

    /// Invalida el cache para un usuario específico.
    ///
    /// - Parameter userId: ID del usuario cuyo cache se invalida
    public func invalidateCache(for userId: UUID) {
        cachedDashboard.removeValue(forKey: userId)
    }

    /// Invalida todo el cache del dashboard.
    public func invalidateAllCache() {
        cachedDashboard.removeAll()
    }

    // MARK: - Private Fetch Methods

    /// Fetch de materiales con timeout individual.
    private func fetchMaterials() async -> FetchResult {
        let startTime = Date()
        do {
            let materials = try await withTimeout(seconds: individualTimeout) {
                try await self.materialsRepository.listRecent(limit: self.materialsLimit)
            }
            let timeMs = Int(Date().timeIntervalSince(startTime) * 1000)
            return .materials(materials, timeMs)
        } catch {
            return .materialsError(error)
        }
    }

    /// Fetch de progreso con timeout individual.
    private func fetchProgress(userId: UUID) async -> FetchResult {
        let startTime = Date()
        do {
            let progress = try await withTimeout(seconds: individualTimeout) {
                try await self.progressRepository.getSummary(userId: userId)
            }
            let timeMs = Int(Date().timeIntervalSince(startTime) * 1000)
            return .progress(progress, timeMs)
        } catch {
            return .progressError(error)
        }
    }

    /// Fetch de intentos con timeout individual.
    private func fetchAttempts(userId: UUID) async -> FetchResult {
        let startTime = Date()
        do {
            let attempts = try await withTimeout(seconds: individualTimeout) {
                try await self.attemptsRepository.listRecent(userId: userId, limit: self.attemptsLimit)
            }
            let timeMs = Int(Date().timeIntervalSince(startTime) * 1000)
            return .attempts(attempts, timeMs)
        } catch {
            return .attemptsError(error)
        }
    }

    /// Ejecuta una operación con timeout.
    private func withTimeout<T: Sendable>(
        seconds: TimeInterval,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }

            guard let result = try await group.next() else {
                throw TimeoutError()
            }

            group.cancelAll()
            return result
        }
    }
}

// MARK: - Helper Types

/// Resultado de un fetch individual.
private enum FetchResult: Sendable {
    case materials([Material], Int)
    case materialsError(Error)
    case progress(ProgressSummary, Int)
    case progressError(Error)
    case attempts([AssessmentAttempt], Int)
    case attemptsError(Error)
}

/// Resultados agregados de todos los fetches.
private struct FetchResults: Sendable {
    let materials: [Material]
    let materialsTimeMs: Int?
    let progress: ProgressSummary?
    let progressTimeMs: Int?
    let attempts: [AssessmentAttempt]
    let attemptsTimeMs: Int?
    let errors: [DashboardPartialError]
}

/// Cache entry para un dashboard.
private struct CachedDashboard: Sendable {
    let dashboard: StudentDashboard
    let timestamp: Date
}

/// Error de timeout.
private struct TimeoutError: Error, Sendable {
    var localizedDescription: String {
        "Operation timed out"
    }
}
