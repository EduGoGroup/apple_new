// EduStrings.swift
// EduPresentation
//
// Static localized strings for the EduGo app UI.

import Foundation

public enum EduStrings {
    // MARK: - Actions

    public static let save = String(localized: "action.save", defaultValue: "Guardar")
    public static let cancel = String(localized: "action.cancel", defaultValue: "Cancelar")
    public static let delete = String(localized: "action.delete", defaultValue: "Eliminar")
    public static let edit = String(localized: "action.edit", defaultValue: "Editar")
    public static let create = String(localized: "action.create", defaultValue: "Crear")
    public static let search = String(localized: "action.search", defaultValue: "Buscar")
    public static let retry = String(localized: "action.retry", defaultValue: "Reintentar")
    public static let back = String(localized: "action.back", defaultValue: "Volver")
    public static let close = String(localized: "action.close", defaultValue: "Cerrar")
    public static let confirm = String(localized: "action.confirm", defaultValue: "Confirmar")
    public static let logout = String(localized: "action.logout", defaultValue: "Cerrar sesión")
    public static let undo = String(localized: "action.undo", defaultValue: "Deshacer")

    // MARK: - Messages

    public static let itemDeleted = String(localized: "message.itemDeleted", defaultValue: "Elemento eliminado")

    // MARK: - Connectivity

    public static let offline = String(localized: "connectivity.offline", defaultValue: "Sin conexión")
    public static let syncing = String(localized: "connectivity.syncing", defaultValue: "Sincronizando...")
    public static let synced = String(localized: "connectivity.synced", defaultValue: "Sincronizado")

    // MARK: - Forms

    public static let invalidEmail = String(localized: "form.invalidEmail", defaultValue: "Email inválido")
    public static let saveSuccess = String(localized: "form.saveSuccess", defaultValue: "Guardado exitosamente")
    public static let deleteConfirmTitle = String(localized: "form.deleteConfirmTitle", defaultValue: "¿Eliminar?")
    public static let deleteConfirmMessage = String(localized: "form.deleteConfirmMessage", defaultValue: "Esta acción no se puede deshacer")

    // MARK: - States

    public static let loading = String(localized: "state.loading", defaultValue: "Cargando...")
    public static let emptyList = String(localized: "state.emptyList", defaultValue: "No hay elementos")
    public static let errorOccurred = String(localized: "state.error", defaultValue: "Ocurrió un error")
    public static let noPermission = String(localized: "state.noPermission", defaultValue: "Sin permiso para esta acción")

    // MARK: - Auth

    public static let loginTitle = String(localized: "auth.loginTitle", defaultValue: "Iniciar sesión")
    public static let email = String(localized: "auth.email", defaultValue: "Correo electrónico")
    public static let password = String(localized: "auth.password", defaultValue: "Contraseña")
    public static let loginButton = String(localized: "auth.loginButton", defaultValue: "Ingresar")
    public static let loginError = String(localized: "auth.loginError", defaultValue: "Credenciales inválidas")

    // MARK: - Navigation

    public static let settings = String(localized: "nav.settings", defaultValue: "Configuración")
    public static let dashboard = String(localized: "nav.dashboard", defaultValue: "Inicio")
    public static let selectSchool = String(localized: "nav.selectSchool", defaultValue: "Seleccionar escuela")
    public static let noSchool = String(localized: "nav.noSchool", defaultValue: "Sin escuela")

    // MARK: - Form Validation

    public static let fieldRequired = String(localized: "form.fieldRequired", defaultValue: "Este campo es obligatorio")
    public static let fixErrors = String(localized: "form.fixErrors", defaultValue: "Corrige los campos marcados")

    // MARK: - Select

    public static let selectLoading = String(localized: "select.loading", defaultValue: "Cargando...")
    public static let selectLoadError = String(localized: "select.loadError", defaultValue: "Error al cargar opciones")
    public static let selectPlaceholder = String(localized: "select.placeholder", defaultValue: "Seleccionar...")
}
