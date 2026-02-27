import Foundation

/// Protocolo para handlers que procesan queries de solo lectura.
///
/// Un QueryHandler es responsable de ejecutar la lógica de negocio asociada
/// a una Query específica y retornar su resultado. Los handlers son concurrentes
/// y seguros (Sendable) por diseño.
///
/// # Ejemplo de uso:
/// ```swift
/// actor GetUserQueryHandler: QueryHandler {
///     typealias QueryType = GetUserQuery
///
///     private let userRepository: UserRepository
///
///     init(userRepository: UserRepository) {
///         self.userRepository = userRepository
///     }
///
///     func handle(_ query: GetUserQuery) async throws -> User {
///         return try await userRepository.findById(query.userId)
///     }
/// }
/// ```
public protocol QueryHandler: Sendable {
    /// Tipo de Query que este handler puede procesar
    associatedtype QueryType: Query

    /// Procesa la query de forma asíncrona y retorna el resultado.
    ///
    /// - Parameter query: La query a procesar
    /// - Returns: El resultado de tipo `QueryType.Result`
    /// - Throws: Errores durante la ejecución de la query
    func handle(_ query: QueryType) async throws -> QueryType.Result
}
