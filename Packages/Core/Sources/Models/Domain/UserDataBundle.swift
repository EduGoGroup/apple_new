import Foundation

// MARK: - UserDataBundle

/// Bundle completo de datos del usuario post-login.
///
/// Contiene toda la informacion sincronizada desde el backend:
/// menu de navegacion, permisos, pantallas, contextos disponibles
/// y hashes para delta sync.
///
/// ## Uso
/// ```swift
/// let bundle = UserDataBundle(
///     menu: menuItems,
///     permissions: ["view_dashboard"],
///     screens: ["dashboard_main": screenBundle],
///     availableContexts: [contextDTO],
///     hashes: ["menu": "abc123"],
///     syncedAt: Date()
/// )
/// ```
public struct UserDataBundle: Sendable, Equatable, Codable {

    // MARK: - Properties

    /// Arbol de navegacion del usuario.
    public let menu: [MenuItemDTO]

    /// Lista plana de permisos otorgados.
    public let permissions: [String]

    /// Mapa de screen keys a sus definiciones completas.
    public let screens: [String: ScreenBundleDTO]

    /// Contextos disponibles para cambio de rol/escuela.
    public let availableContexts: [UserContextDTO]

    /// Hashes de cada bucket para delta sync.
    public let hashes: [String: String]

    /// Momento en que se sincronizaron los datos.
    public let syncedAt: Date

    // MARK: - Initialization

    public init(
        menu: [MenuItemDTO],
        permissions: [String],
        screens: [String: ScreenBundleDTO],
        availableContexts: [UserContextDTO],
        hashes: [String: String],
        syncedAt: Date = Date()
    ) {
        self.menu = menu
        self.permissions = permissions
        self.screens = screens
        self.availableContexts = availableContexts
        self.hashes = hashes
        self.syncedAt = syncedAt
    }
}

// MARK: - Factory Methods

extension UserDataBundle {
    /// Crea un `UserDataBundle` a partir de un `SyncBundleResponseDTO`.
    public static func from(response: SyncBundleResponseDTO) -> UserDataBundle {
        UserDataBundle(
            menu: response.menu,
            permissions: response.permissions,
            screens: response.screens,
            availableContexts: response.availableContexts,
            hashes: response.hashes,
            syncedAt: Date.now
        )
    }
}
