import SwiftUI
import EduDomain

/// Coordinador especializado para el flujo de materiales educativos.
///
/// Gestiona la navegación relacionada con visualización, subida y asignación
/// de materiales delegando al AppCoordinator para navegación global.
///
/// # Responsabilidades
/// - Mostrar lista de materiales
/// - Navegar a detalle de un material específico
/// - Presentar formulario de subida de materiales
/// - Presentar formulario de asignación de materiales
/// - Cerrar modales de subida/asignación
///
/// # Ejemplo de uso:
/// ```swift
/// let materialsCoordinator = MaterialsCoordinator(
///     appCoordinator: appCoordinator,
///     mediator: mediator
/// )
/// materialsCoordinator.start() // Navega a lista
/// materialsCoordinator.showUploadMaterial() // Abre modal
/// ```
@MainActor
public final class MaterialsCoordinator: FeatureCoordinator {

    // MARK: - Properties

    public let appCoordinator: AppCoordinator
    private let mediator: Mediator

    // MARK: - Initialization

    /// Crea una nueva instancia de MaterialsCoordinator.
    ///
    /// - Parameters:
    ///   - appCoordinator: Coordinador principal de la aplicación
    ///   - mediator: Mediator para ejecutar comandos
    public init(appCoordinator: AppCoordinator, mediator: Mediator) {
        self.appCoordinator = appCoordinator
        self.mediator = mediator
    }

    // MARK: - FeatureCoordinator

    /// Inicia el flujo de materiales navegando a la lista.
    public func start() {
        appCoordinator.navigate(to: .materialList)
    }

    // MARK: - Materials Flow Actions

    /// Muestra la lista de materiales.
    public func showMaterialList() {
        appCoordinator.navigate(to: .materialList)
    }

    /// Navega al detalle de un material específico.
    ///
    /// - Parameter materialId: ID del material a mostrar
    public func showMaterialDetail(materialId: UUID) {
        appCoordinator.navigate(to: .materialDetail(materialId: materialId))
    }

    /// Presenta el formulario para subir un nuevo material como sheet modal.
    public func showUploadMaterial() {
        appCoordinator.presentSheet(.materialUpload)
    }

    /// Presenta el formulario para asignar un material como sheet modal.
    ///
    /// - Parameter materialId: ID del material a asignar
    public func showAssignMaterial(materialId: UUID) {
        appCoordinator.presentSheet(.materialAssignment(materialId: materialId))
    }

    /// Cierra el modal de subida o asignación de materiales.
    public func dismissUpload() {
        appCoordinator.dismissModal()
    }
}
