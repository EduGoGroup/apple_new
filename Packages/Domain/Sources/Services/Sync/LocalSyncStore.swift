// LocalSyncStore.swift
// EduDomain
//
// Actor that persists the sync bundle to local storage.

import Foundation
import EduCore

/// Actor que persiste el bundle de sincronización en almacenamiento local.
///
/// Responsable de guardar, restaurar y actualizar parcialmente el
/// `UserDataBundle` en el dispositivo para arranque offline y delta sync.
///
/// ## Flujo
/// 1. `restore()` → carga bundle desde disco al iniciar
/// 2. `save(bundle:)` → persiste bundle completo post full-sync
/// 3. `updateBucket(...)` → actualización parcial post delta-sync
///
/// ## Almacenamiento
/// Usa `UserDefaults` via serialización JSON. Para producción futura
/// se puede migrar a archivo en disco sin cambiar la interfaz.
public actor LocalSyncStore {

    // MARK: - Constants

    private static let storageKey = "com.edugo.sync.bundle"

    // MARK: - State

    private var cachedBundle: UserDataBundle?
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    // MARK: - Initialization

    public init() {
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Public API

    /// Persiste el bundle completo en almacenamiento local.
    ///
    /// - Parameter bundle: Bundle a guardar.
    /// - Throws: `SyncError.storageFailed` si la serialización falla.
    public func save(bundle: UserDataBundle) throws {
        do {
            let data = try encoder.encode(bundle)
            UserDefaults.standard.set(data, forKey: Self.storageKey)
            cachedBundle = bundle
        } catch {
            throw SyncError.storageFailed("No se pudo serializar bundle: \(error.localizedDescription)")
        }
    }

    /// Restaura el bundle desde almacenamiento local.
    ///
    /// - Returns: El bundle guardado, o `nil` si no existe.
    public func restore() -> UserDataBundle? {
        if let cached = cachedBundle {
            return cached
        }

        guard let data = UserDefaults.standard.data(forKey: Self.storageKey) else {
            return nil
        }

        do {
            let bundle = try decoder.decode(UserDataBundle.self, from: data)
            cachedBundle = bundle
            return bundle
        } catch {
            return nil
        }
    }

    /// Actualiza un bucket específico en el bundle local (delta sync).
    ///
    /// Deserializa el bucket, actualiza los datos y el hash correspondiente,
    /// y persiste el bundle actualizado.
    ///
    /// - Parameters:
    ///   - name: Nombre del bucket (e.g. "menu", "screens", "permissions").
    ///   - data: Nuevos datos del bucket como JSONValue.
    ///   - hash: Nuevo hash del bucket.
    /// - Throws: `SyncError.storageFailed` si no hay bundle activo o falla la persistencia.
    public func updateBucket(name: String, data: JSONValue, hash: String) throws {
        guard var bundle = cachedBundle else {
            throw SyncError.storageFailed("No hay bundle activo para actualizar")
        }

        var updatedHashes = bundle.hashes
        updatedHashes[name] = hash

        let updatedBundle: UserDataBundle

        switch name {
        case "menu":
            let menu = Self.decodeMenuFromJSON(data)
            updatedBundle = UserDataBundle(
                menu: menu ?? bundle.menu,
                permissions: bundle.permissions,
                screens: bundle.screens,
                availableContexts: bundle.availableContexts,
                hashes: updatedHashes,
                syncedAt: Date()
            )

        case "permissions":
            let permissions = Self.decodePermissionsFromJSON(data)
            updatedBundle = UserDataBundle(
                menu: bundle.menu,
                permissions: permissions ?? bundle.permissions,
                screens: bundle.screens,
                availableContexts: bundle.availableContexts,
                hashes: updatedHashes,
                syncedAt: Date()
            )

        case "screens":
            let screens = Self.decodeScreensFromJSON(data)
            updatedBundle = UserDataBundle(
                menu: bundle.menu,
                permissions: bundle.permissions,
                screens: screens ?? bundle.screens,
                availableContexts: bundle.availableContexts,
                hashes: updatedHashes,
                syncedAt: Date()
            )

        case "available_contexts":
            let contexts = Self.decodeContextsFromJSON(data)
            updatedBundle = UserDataBundle(
                menu: bundle.menu,
                permissions: bundle.permissions,
                screens: bundle.screens,
                availableContexts: contexts ?? bundle.availableContexts,
                hashes: updatedHashes,
                syncedAt: Date()
            )

        default:
            // Bucket desconocido: solo actualizar el hash
            updatedBundle = UserDataBundle(
                menu: bundle.menu,
                permissions: bundle.permissions,
                screens: bundle.screens,
                availableContexts: bundle.availableContexts,
                hashes: updatedHashes,
                syncedAt: Date()
            )
        }

        try save(bundle: updatedBundle)
    }

    /// Elimina el bundle persistido.
    public func clear() {
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
        cachedBundle = nil
    }

    // MARK: - JSON Decoding Helpers

    private static func decodeMenuFromJSON(_ json: JSONValue) -> [MenuItemDTO]? {
        guard let arrayData = encodeJSONValue(json) else { return nil }
        return try? JSONDecoder().decode([MenuItemDTO].self, from: arrayData)
    }

    private static func decodePermissionsFromJSON(_ json: JSONValue) -> [String]? {
        guard case .array(let items) = json else { return nil }
        return items.compactMap(\.stringValue)
    }

    private static func decodeScreensFromJSON(_ json: JSONValue) -> [String: ScreenBundleDTO]? {
        guard let objData = encodeJSONValue(json) else { return nil }
        return try? JSONDecoder().decode([String: ScreenBundleDTO].self, from: objData)
    }

    private static func decodeContextsFromJSON(_ json: JSONValue) -> [UserContextDTO]? {
        guard let arrayData = encodeJSONValue(json) else { return nil }
        return try? JSONDecoder().decode([UserContextDTO].self, from: arrayData)
    }

    private static func encodeJSONValue(_ value: JSONValue) -> Data? {
        try? JSONEncoder().encode(value)
    }
}
