import Foundation
import EduFoundation

// MARK: - Input/Output Types

/// Input para cargar una evaluación con detalles de elegibilidad.
public struct LoadAssessmentInput: Sendable, Equatable {
    /// ID de la evaluación a cargar
    public let assessmentId: UUID
    /// ID del usuario para verificar elegibilidad
    public let userId: UUID
    /// Forzar recarga desde servidor ignorando cache
    public let forceRefresh: Bool

    public init(
        assessmentId: UUID,
        userId: UUID,
        forceRefresh: Bool = false
    ) {
        self.assessmentId = assessmentId
        self.userId = userId
        self.forceRefresh = forceRefresh
    }
}

/// Información de elegibilidad del usuario para tomar la evaluación.
public struct AssessmentEligibility: Sendable, Equatable, Codable {
    /// Si el usuario puede tomar la evaluación
    public let canTake: Bool
    /// Razón si no puede tomar (nil si canTake=true)
    public let reason: EligibilityReason?
    /// Intentos restantes
    public let attemptsLeft: Int
    /// Fecha de expiración de la elegibilidad (opcional)
    public let expiresAt: Date?

    public init(
        canTake: Bool,
        reason: EligibilityReason? = nil,
        attemptsLeft: Int,
        expiresAt: Date? = nil
    ) {
        self.canTake = canTake
        self.reason = reason
        self.attemptsLeft = attemptsLeft
        self.expiresAt = expiresAt
    }
}

/// Razones por las que un usuario no puede tomar una evaluación.
public enum EligibilityReason: String, Sendable, Equatable, Codable {
    case noAttemptsLeft = "no_attempts_left"
    case expired = "expired"
    case notEnrolled = "not_enrolled"
    case unknown = "unknown"
}

/// Detalle completo de una evaluación con información de elegibilidad y cache.
public struct AssessmentDetail: Sendable, Equatable {
    /// Evaluación con título, descripción, preguntas y configuración
    public let assessment: Assessment
    /// Información de elegibilidad del usuario
    public let eligibility: AssessmentEligibility
    /// Fecha en que se cachearon los datos (nil si viene directamente del servidor)
    public let cachedAt: Date?
    /// Si los datos están obsoletos (stale) pero aún usables
    public let isStale: Bool

    public init(
        assessment: Assessment,
        eligibility: AssessmentEligibility,
        cachedAt: Date? = nil,
        isStale: Bool = false
    ) {
        self.assessment = assessment
        self.eligibility = eligibility
        self.cachedAt = cachedAt
        self.isStale = isStale
    }
}

// MARK: - Cache Entry

/// Entrada de cache con timestamp para control de TTL.
public struct AssessmentCacheEntry: Sendable, Codable {
    /// Evaluación cacheada
    public let assessment: Assessment
    /// Elegibilidad cacheada
    public let eligibility: AssessmentEligibility
    /// Timestamp de cuando se cachearon los datos
    public let cachedAt: Date

    public init(assessment: Assessment, eligibility: AssessmentEligibility) {
        self.assessment = assessment
        self.eligibility = eligibility
        self.cachedAt = Date()
    }

    /// Inicializador para tests que permite especificar un timestamp custom.
    public init(assessment: Assessment, eligibility: AssessmentEligibility, cachedAt: Date) {
        self.assessment = assessment
        self.eligibility = eligibility
        self.cachedAt = cachedAt
    }
}

// MARK: - Eligibility Service Protocol

/// Protocolo del servicio de elegibilidad para evaluaciones.
public protocol EligibilityServiceProtocol: Sendable {
    /// Verifica la elegibilidad del usuario para tomar una evaluación.
    ///
    /// - Parameters:
    ///   - assessmentId: ID de la evaluación
    ///   - userId: ID del usuario
    /// - Returns: Información de elegibilidad
    func checkEligibility(
        assessmentId: UUID,
        userId: UUID
    ) async throws -> AssessmentEligibility
}

// MARK: - Assessment Cache Service Protocol

/// Protocolo del servicio de cache para evaluaciones con TTL.
public protocol AssessmentCacheServiceProtocol: Sendable {
    /// Obtiene una evaluación del cache con su metadata.
    ///
    /// - Parameter assessmentId: ID de la evaluación
    /// - Returns: Entrada de cache si existe, nil si no
    func get(assessmentId: UUID) async -> AssessmentCacheEntry?

    /// Guarda una evaluación en cache.
    ///
    /// - Parameters:
    ///   - entry: Entrada de cache a guardar
    ///   - assessmentId: ID de la evaluación
    func save(_ entry: AssessmentCacheEntry, for assessmentId: UUID) async

    /// Elimina una evaluación del cache.
    ///
    /// - Parameter assessmentId: ID de la evaluación
    func remove(assessmentId: UUID) async
}

// MARK: - LoadAssessmentUseCase

/// Actor que carga una evaluación con estrategia offline-first y cache inteligente.
///
/// Implementa el patrón stale-while-revalidate:
/// - **Fresh** (< 10 min): Retorna cache sin revalidar
/// - **Stale** (10-60 min): Retorna cache marcado como stale, revalida en background
/// - **Expired** (> 60 min): Fetch bloqueante del servidor
///
/// ## Flujo Offline-First
/// 1. Si `forceRefresh=false`, verifica cache local
/// 2. Según TTL del cache, decide si retornar cached o fetch
/// 3. Fetch assessment y eligibility en PARALELO
/// 4. Merge y guarda en cache
/// 5. Retorna `AssessmentDetail` con metadata de cache
///
/// ## Error Handling
/// - Network error + cache existe: retorna cache stale con warning
/// - Network error + no cache: propaga error
/// - Eligibility check falla: asume `canTake=false` con `reason=unknown`
///
/// ## Validaciones de Elegibilidad
/// - Si `canTake=false`: incluye reason en output
/// - Si `attemptsLeft=0`: NO carga preguntas completas (solo metadata)
/// - Si `expired`: marca en eligibility pero permite ver assessment (read-only)
///
/// ## Ejemplo de Uso
/// ```swift
/// let useCase = LoadAssessmentUseCase(
///     assessmentsRepository: assessmentsRepo,
///     eligibilityService: eligibilityService,
///     cacheService: cacheService
/// )
///
/// let input = LoadAssessmentInput(
///     assessmentId: assessmentId,
///     userId: userId,
///     forceRefresh: false
/// )
///
/// let detail = try await useCase.execute(input: input)
/// if detail.isStale {
///     print("Datos del cache, actualizándose en background")
/// }
/// if detail.eligibility.canTake {
///     // Mostrar botón para iniciar evaluación
/// } else {
///     print("No puede tomar: \(detail.eligibility.reason?.rawValue ?? "unknown")")
/// }
/// ```
public actor LoadAssessmentUseCase: UseCase {

    public typealias Input = LoadAssessmentInput
    public typealias Output = AssessmentDetail

    // MARK: - Dependencies

    private let assessmentsRepository: AssessmentsRepositoryProtocol
    private let eligibilityService: EligibilityServiceProtocol
    private let cacheService: AssessmentCacheServiceProtocol

    // MARK: - Configuration

    /// TTL para considerar cache como fresh (10 minutos)
    private let freshTTL: TimeInterval = 600

    /// TTL para considerar cache como usable pero stale (60 minutos)
    private let staleTTL: TimeInterval = 3600

    // MARK: - Initialization

    /// Crea una nueva instancia del caso de uso.
    ///
    /// - Parameters:
    ///   - assessmentsRepository: Repositorio de assessments
    ///   - eligibilityService: Servicio de verificación de elegibilidad
    ///   - cacheService: Servicio de cache con TTL
    public init(
        assessmentsRepository: AssessmentsRepositoryProtocol,
        eligibilityService: EligibilityServiceProtocol,
        cacheService: AssessmentCacheServiceProtocol
    ) {
        self.assessmentsRepository = assessmentsRepository
        self.eligibilityService = eligibilityService
        self.cacheService = cacheService
    }

    // MARK: - UseCase Implementation

    /// Ejecuta la carga de la evaluación con estrategia offline-first.
    ///
    /// - Parameter input: Input con assessmentId, userId y forceRefresh
    /// - Returns: AssessmentDetail con assessment, eligibility y metadata de cache
    /// - Throws: Error si no se puede obtener la evaluación ni del servidor ni del cache
    public func execute(input: LoadAssessmentInput) async throws -> AssessmentDetail {
        // PASO 1: Si no es forceRefresh, verificar cache
        if !input.forceRefresh {
            if let cacheResult = await checkCache(for: input.assessmentId) {
                switch cacheResult {
                case .fresh(let entry):
                    // Cache fresh: retornar inmediatamente
                    return AssessmentDetail(
                        assessment: entry.assessment,
                        eligibility: entry.eligibility,
                        cachedAt: entry.cachedAt,
                        isStale: false
                    )

                case .stale(let entry):
                    // Cache stale: retornar cached y revalidar en background
                    Task {
                        await revalidateInBackground(input: input)
                    }
                    return AssessmentDetail(
                        assessment: entry.assessment,
                        eligibility: entry.eligibility,
                        cachedAt: entry.cachedAt,
                        isStale: true
                    )

                case .expired, .miss:
                    // Continuar con fetch bloqueante
                    break
                }
            }
        }

        // PASO 2: Fetch bloqueante desde servidor
        return try await fetchAndCache(input: input)
    }

    // MARK: - Private Methods

    /// Verifica el estado del cache para una evaluación.
    private func checkCache(for assessmentId: UUID) async -> CacheState? {
        guard let entry = await cacheService.get(assessmentId: assessmentId) else {
            return .miss
        }

        let age = Date().timeIntervalSince(entry.cachedAt)

        if age < freshTTL {
            return .fresh(entry)
        } else if age < staleTTL {
            return .stale(entry)
        } else {
            return .expired(entry)
        }
    }

    /// Revalida el cache en background sin bloquear.
    private func revalidateInBackground(input: LoadAssessmentInput) async {
        do {
            _ = try await fetchAndCache(input: input)
        } catch {
            // Silently fail - el usuario ya tiene datos del cache
        }
    }

    /// Fetch desde servidor y actualiza cache.
    private func fetchAndCache(input: LoadAssessmentInput) async throws -> AssessmentDetail {
        // Fetch assessment y eligibility en PARALELO
        async let assessmentTask = fetchAssessment(id: input.assessmentId)
        async let eligibilityTask = fetchEligibility(
            assessmentId: input.assessmentId,
            userId: input.userId
        )

        let assessment: Assessment
        let eligibility: AssessmentEligibility

        do {
            // Esperar ambos resultados
            assessment = try await assessmentTask
            eligibility = await eligibilityTask
        } catch {
            // Network error: intentar usar cache si existe
            if let cached = await cacheService.get(assessmentId: input.assessmentId) {
                return AssessmentDetail(
                    assessment: cached.assessment,
                    eligibility: cached.eligibility,
                    cachedAt: cached.cachedAt,
                    isStale: true
                )
            }
            // No hay cache, propagar error
            throw error
        }

        // Determinar si mostrar preguntas completas
        let finalAssessment = applyEligibilityRestrictions(
            assessment: assessment,
            eligibility: eligibility
        )

        // Guardar en cache
        let cacheEntry = AssessmentCacheEntry(
            assessment: finalAssessment,
            eligibility: eligibility
        )
        await cacheService.save(cacheEntry, for: input.assessmentId)

        return AssessmentDetail(
            assessment: finalAssessment,
            eligibility: eligibility,
            cachedAt: nil,
            isStale: false
        )
    }

    /// Fetch assessment desde el repositorio.
    private func fetchAssessment(id: UUID) async throws -> Assessment {
        try await assessmentsRepository.get(id: id)
    }

    /// Fetch eligibility con fallback a canTake=false si falla.
    private func fetchEligibility(
        assessmentId: UUID,
        userId: UUID
    ) async -> AssessmentEligibility {
        do {
            return try await eligibilityService.checkEligibility(
                assessmentId: assessmentId,
                userId: userId
            )
        } catch {
            // Eligibility check fails: asumir canTake=false con reason=unknown
            return AssessmentEligibility(
                canTake: false,
                reason: .unknown,
                attemptsLeft: 0,
                expiresAt: nil
            )
        }
    }

    /// Aplica restricciones según elegibilidad.
    ///
    /// Si `attemptsLeft=0`, retorna assessment sin preguntas completas (solo metadata).
    private func applyEligibilityRestrictions(
        assessment: Assessment,
        eligibility: AssessmentEligibility
    ) -> Assessment {
        // Si no tiene intentos restantes, ocultar preguntas (solo metadata)
        if eligibility.attemptsLeft == 0 {
            return Assessment(
                id: assessment.id,
                materialId: assessment.materialId,
                title: assessment.title,
                description: assessment.description,
                questions: [], // Sin preguntas
                timeLimitSeconds: assessment.timeLimitSeconds,
                maxAttempts: assessment.maxAttempts,
                passThreshold: assessment.passThreshold,
                attemptsUsed: assessment.attemptsUsed,
                expiresAt: assessment.expiresAt
            )
        }
        return assessment
    }
}

// MARK: - Cache State

/// Estado del cache para una evaluación.
private enum CacheState {
    /// Cache válido y fresh (< freshTTL)
    case fresh(AssessmentCacheEntry)
    /// Cache válido pero stale (freshTTL < age < staleTTL)
    case stale(AssessmentCacheEntry)
    /// Cache expirado (> staleTTL)
    case expired(AssessmentCacheEntry)
    /// No hay cache
    case miss
}
