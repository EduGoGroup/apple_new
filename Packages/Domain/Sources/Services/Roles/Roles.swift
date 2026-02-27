import Foundation

// MARK: - Module Exports

/// Roles - Sistema de control de acceso basado en roles (RBAC)
///
/// Este módulo proporciona:
/// - `SystemRole`: Enum de roles del sistema sincronizado con el backend
/// - `Permission`: OptionSet de permisos granulares
/// - `RoleManager`: Actor para gestión de permisos en runtime
///
/// ## Arquitectura
/// ```
/// ┌─────────────────────────────────────────────┐
/// │                 RoleManager                  │
/// │  (actor - gestiona estado de autorización)  │
/// └─────────────────────────────────────────────┘
///                      │
///          ┌───────────┴───────────┐
///          ▼                       ▼
/// ┌─────────────────┐     ┌─────────────────┐
/// │   SystemRole    │     │   Permission    │
/// │   (enum)        │     │   (OptionSet)   │
/// └─────────────────┘     └─────────────────┘
/// ```
///
/// ## Ejemplo de uso
/// ```swift
/// // Configurar rol después del login
/// await RoleManager.shared.setRole(.teacher)
///
/// // Verificar permisos
/// if await RoleManager.shared.hasPermission(.createQuizzes) {
///     // Mostrar botón de crear quiz
/// }
///
/// // Verificar jerarquía de roles
/// if await RoleManager.shared.hasRole(.student) {
///     // El usuario tiene al menos nivel de estudiante
/// }
/// ```
///
/// ## Thread Safety
/// `RoleManager` es un actor, por lo que todas sus operaciones son thread-safe
/// y deben llamarse con `await` en contextos async.

// Los tipos públicos se exportan automáticamente desde sus respectivos archivos:
// - SystemRole.swift
// - Permission.swift
// - Permission+Defaults.swift
// - RoleManager.swift (pendiente de implementar en Task 3)

// MARK: - Deprecated Types (for migration)

/// UserRole está deprecado. Usar `SystemRole` en su lugar.
@available(*, deprecated, renamed: "SystemRole", message: "Use SystemRole instead for backend compatibility")
public typealias UserRole = SystemRole
