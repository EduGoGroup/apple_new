// EduDomain - Unified Domain Layer
// Consolidates CQRS, StateManagement, UseCases, Auth, and Roles

import EduFoundation
import EduCore
import EduInfrastructure

/// EduDomain module metadata
public enum EduDomain {
    public static let version = "2.0.0"

    /// Domain submodules
    public enum Submodules {
        public static let cqrs = "CQRS"
        public static let stateManagement = "StateManagement"
        public static let useCases = "UseCases"
        public static let auth = "Auth"
        public static let roles = "Roles"
    }
}
