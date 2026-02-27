// MenuService.swift
// EduDomain
//
// Actor that manages the filtered menu state and exposes it via AsyncStream.

import Foundation
import EduCore

/// Actor que gestiona el menu filtrado por permisos.
///
/// Recibe un `UserDataBundle` y los permisos del usuario,
/// filtra el menu y lo expone via `menuStream`.
public actor MenuService {

    // MARK: - Properties

    /// Menu actual filtrado.
    public private(set) var currentMenu: [MenuItem] = []

    // MARK: - Menu Stream

    private var menuContinuation: AsyncStream<[MenuItem]>.Continuation?
    private var _menuStream: AsyncStream<[MenuItem]>?

    /// Stream para observar cambios en el menu filtrado.
    public var menuStream: AsyncStream<[MenuItem]> {
        if _menuStream == nil {
            let (stream, continuation) = AsyncStream<[MenuItem]>.makeStream(
                bufferingPolicy: .unbounded
            )
            self._menuStream = stream
            self.menuContinuation = continuation
        }
        return _menuStream!
    }

    // MARK: - Initialization

    public init() {}

    // MARK: - Update Menu

    /// Actualiza el menu filtrando items segun permisos.
    ///
    /// - Parameters:
    ///   - bundle: Bundle de datos del usuario con items de menu.
    ///   - permissions: Permisos del usuario actual.
    public func updateMenu(from bundle: UserDataBundle, permissions: [String]) {
        let filtered = MenuFilter.filter(items: bundle.menu, permissions: permissions)
        currentMenu = filtered
        menuContinuation?.yield(filtered)
    }
}
