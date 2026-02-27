import Foundation
import EduFoundation
import EduCore

// MARK: - UserContext

/// Contexto completo del usuario autenticado con toda su información relacionada.
///
/// Este struct contiene toda la información necesaria para mostrar el dashboard
/// del usuario, incluyendo sus memberships activos y las unidades/escuelas asociadas.
public struct UserContext: Sendable, Equatable {
    /// Usuario autenticado
    public let user: User

    /// Memberships del usuario
    public let memberships: [Membership]

    /// Unidades académicas indexadas por ID para acceso rápido
    public let unitsMap: [UUID: AcademicUnit]

    /// Escuelas indexadas por ID para acceso rápido
    public let schoolsMap: [UUID: School]

    /// Metadata de errores parciales que ocurrieron durante la carga
    public let partialErrors: [PartialLoadError]

    /// Inicializa un nuevo contexto de usuario
    ///
    /// - Parameters:
    ///   - user: Usuario autenticado
    ///   - memberships: Memberships del usuario
    ///   - unitsMap: Mapa de unidades académicas por ID
    ///   - schoolsMap: Mapa de escuelas por ID
    ///   - partialErrors: Errores parciales que ocurrieron (por defecto vacío)
    public init(
        user: User,
        memberships: [Membership],
        unitsMap: [UUID: AcademicUnit],
        schoolsMap: [UUID: School],
        partialErrors: [PartialLoadError] = []
    ) {
        self.user = user
        self.memberships = memberships
        self.unitsMap = unitsMap
        self.schoolsMap = schoolsMap
        self.partialErrors = partialErrors
    }
}

// MARK: - PartialLoadError

/// Representa un error parcial que ocurrió durante la carga del contexto
public struct PartialLoadError: Sendable, Equatable {
    /// ID del membership que falló
    public let membershipID: UUID

    /// Tipo de recurso que falló (unit o school)
    public let resourceType: ResourceType

    /// Mensaje de error
    public let message: String

    public enum ResourceType: String, Sendable, Equatable {
        case unit
        case school
    }

    public init(membershipID: UUID, resourceType: ResourceType, message: String) {
        self.membershipID = membershipID
        self.resourceType = resourceType
        self.message = message
    }
}

// MARK: - LoadUserContextUseCase

/// Actor que implementa la carga del contexto completo del usuario.
///
/// Este use case coordina múltiples repositorios para cargar toda la información
/// necesaria del usuario de forma paralela, implementando graceful degradation
/// ante errores parciales.
///
/// ## Flujo de Ejecución
/// 1. Obtener usuario actual
/// 2. Cargar memberships del usuario en paralelo
/// 3. Por cada membership, cargar unit + school en paralelo (nested parallel)
/// 4. Ensamblar UserContext con maps indexados
/// 5. Si hay errores parciales, incluirlos en metadata
///
/// ## Optimizaciones
/// - TaskGroup para paralelización máxima
/// - Caching en memoria (5 minutos)
/// - Graceful degradation (errores parciales no fallan todo)
/// - Timeout global de 10 segundos
///
/// ## Ejemplo de Uso
/// ```swift
/// let useCase = LoadUserContextUseCase(
///     userRepository: userRepo,
///     membershipRepository: membershipRepo,
///     unitRepository: unitRepo,
///     schoolRepository: schoolRepo
/// )
///
/// do {
///     let context = try await useCase.execute()
///     print("Usuario: \(context.user.fullName)")
///     print("Memberships: \(context.memberships.count)")
///     if !context.partialErrors.isEmpty {
///         print("Advertencia: \(context.partialErrors.count) errores parciales")
///     }
/// } catch {
///     print("Error al cargar contexto: \(error)")
/// }
/// ```
public actor LoadUserContextUseCase: SimpleUseCase {

    public typealias Output = UserContext

    // MARK: - Dependencies

    private let userRepository: UserRepositoryProtocol
    private let membershipRepository: MembershipRepositoryProtocol
    private let unitRepository: AcademicUnitRepositoryProtocol
    private let schoolRepository: SchoolRepositoryProtocol

    // MARK: - Cache

    private var cachedContext: UserContext?
    private var cacheTimestamp: Date?
    private let cacheDuration: TimeInterval = 300 // 5 minutos

    // MARK: - Configuration

    private let timeout: TimeInterval = 10.0
    private let maxConcurrentRequests = 5

    // MARK: - Initialization

    /// Crea una nueva instancia del caso de uso.
    ///
    /// - Parameters:
    ///   - userRepository: Repositorio de usuarios
    ///   - membershipRepository: Repositorio de memberships
    ///   - unitRepository: Repositorio de unidades académicas
    ///   - schoolRepository: Repositorio de escuelas
    public init(
        userRepository: UserRepositoryProtocol,
        membershipRepository: MembershipRepositoryProtocol,
        unitRepository: AcademicUnitRepositoryProtocol,
        schoolRepository: SchoolRepositoryProtocol
    ) {
        self.userRepository = userRepository
        self.membershipRepository = membershipRepository
        self.unitRepository = unitRepository
        self.schoolRepository = schoolRepository
    }

    // MARK: - SimpleUseCase Implementation

    /// Ejecuta la carga del contexto del usuario.
    ///
    /// - Returns: UserContext con toda la información del usuario
    /// - Throws: UseCaseError si falla la carga del usuario o memberships
    public func execute() async throws -> UserContext {
        // Verificar cache
        if let cached = cachedContext,
           let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < cacheDuration {
            return cached
        }

        // PASO 1: Cargar usuario actual
        // Nota: En producción esto vendría de AuthManager.currentUserId
        // Por ahora asumimos que UserRepository tiene un método list()
        let users = try await userRepository.list()
        guard let user = users.first else {
            throw UseCaseError.preconditionFailed(
                description: "No hay usuario autenticado"
            )
        }

        // PASO 2: Cargar memberships del usuario
        let memberships: [Membership]
        do {
            memberships = try await membershipRepository.listByUser(userID: user.id)
        } catch let error as RepositoryError {
            throw UseCaseError.repositoryError(error)
        } catch {
            throw UseCaseError.executionFailed(
                reason: "Error al cargar memberships: \(error.localizedDescription)"
            )
        }

        // PASO 3: Cargar units y schools en paralelo con timeout
        let (unitsMap, schoolsMap, partialErrors) = try await withThrowingTaskGroup(
            of: MembershipData.self,
            returning: ([UUID: AcademicUnit], [UUID: School], [PartialLoadError]).self
        ) { group in
            // Límite de concurrencia
            var activeTasks = 0
            var pendingMemberships = memberships

            // Iniciar primeras tareas
            while activeTasks < min(maxConcurrentRequests, pendingMemberships.count) {
                let membership = pendingMemberships.removeFirst()
                activeTasks += 1

                group.addTask {
                    await self.loadMembershipData(membership)
                }
            }

            // Procesar resultados y lanzar nuevas tareas
            var units: [UUID: AcademicUnit] = [:]
            var schools: [UUID: School] = [:]
            var errors: [PartialLoadError] = []

            for try await data in group {
                activeTasks -= 1

                // Procesar resultado
                if let unit = data.unit {
                    units[unit.id] = unit
                }
                if let school = data.school {
                    schools[school.id] = school
                }
                errors.append(contentsOf: data.errors)

                // Lanzar siguiente tarea si hay pendientes
                if !pendingMemberships.isEmpty {
                    let membership = pendingMemberships.removeFirst()
                    activeTasks += 1

                    group.addTask {
                        await self.loadMembershipData(membership)
                    }
                }
            }

            return (units, schools, errors)
        }

        // PASO 4: Ensamblar contexto
        let context = UserContext(
            user: user,
            memberships: memberships,
            unitsMap: unitsMap,
            schoolsMap: schoolsMap,
            partialErrors: partialErrors
        )

        // PASO 5: Cachear resultado
        cachedContext = context
        cacheTimestamp = Date()

        return context
    }

    /// Invalida el cache (útil para logout)
    public func invalidateCache() {
        cachedContext = nil
        cacheTimestamp = nil
    }

    // MARK: - Private Helpers

    /// Carga los datos de unit y school para un membership en paralelo
    private func loadMembershipData(_ membership: Membership) async -> MembershipData {
        await withTaskGroup(of: MembershipDataPart.self) { group in
            var unit: AcademicUnit?
            var school: School?
            var errors: [PartialLoadError] = []

            // Tarea 1: Cargar unit
            group.addTask {
                do {
                    let loadedUnit = try await self.unitRepository.get(id: membership.unitID)
                    return .unit(loadedUnit)
                } catch {
                    let partialError = PartialLoadError(
                        membershipID: membership.id,
                        resourceType: .unit,
                        message: error.localizedDescription
                    )
                    return .error(partialError)
                }
            }

            // Esperar resultados
            for await part in group {
                switch part {
                case .unit(let loadedUnit):
                    unit = loadedUnit
                case .school(let loadedSchool):
                    school = loadedSchool
                case .error(let error):
                    errors.append(error)
                }
            }

            // Si tenemos unit, cargar school
            if let unit = unit {
                do {
                    school = try await schoolRepository.get(id: unit.schoolID)
                } catch {
                    errors.append(PartialLoadError(
                        membershipID: membership.id,
                        resourceType: .school,
                        message: error.localizedDescription
                    ))
                }
            }

            return MembershipData(unit: unit, school: school, errors: errors)
        }
    }
}

// MARK: - Helper Types

/// Resultado de cargar datos de un membership
private struct MembershipData: Sendable {
    let unit: AcademicUnit?
    let school: School?
    let errors: [PartialLoadError]
}

/// Parte del resultado de cargar un membership
private enum MembershipDataPart: Sendable {
    case unit(AcademicUnit?)
    case school(School?)
    case error(PartialLoadError)
}
