/// Registro centralizado de contratos de pantalla.
///
/// Almacena y busca contratos por `screenKey`.
/// Se inicializa con `registerDefaults()` que registra
/// todos los contratos predefinidos del sistema.
@MainActor
public final class ContractRegistry {
    private var contracts: [String: any ScreenContract] = [:]

    public init() {}

    /// Registra un contrato para su screenKey.
    public func register(_ contract: any ScreenContract) {
        contracts[contract.screenKey] = contract
    }

    /// Busca un contrato por screenKey.
    public func contract(for screenKey: String) -> (any ScreenContract)? {
        contracts[screenKey]
    }

    /// Numero de contratos registrados.
    public var count: Int { contracts.count }

    /// Registra todos los contratos por defecto del sistema.
    public func registerDefaults() {
        // Auth
        register(LoginContract())
        register(SettingsContract())

        // Dashboards
        register(DashboardSuperadminContract())
        register(DashboardSchoolAdminContract())
        register(DashboardTeacherContract())
        register(DashboardStudentContract())
        register(DashboardGuardianContract())

        // CRUD — Schools
        register(SchoolsListContract())
        register(SchoolCrudContract())

        // CRUD — Users
        register(UsersListContract())
        register(UserCrudContract())

        // CRUD — Units
        register(UnitsListContract())
        register(UnitCrudContract())

        // CRUD — Subjects
        register(SubjectsListContract())
        register(SubjectCrudContract())

        // CRUD — Memberships
        register(MembershipsListContract())
        register(MembershipCrudContract())

        // CRUD — Materials
        register(MaterialsListContract())
        register(MaterialCrudContract())

        // CRUD — Assessments
        register(AssessmentsListContract())

        // CRUD — Roles & Permissions
        register(RolesListContract())
        register(PermissionsListContract())

        // CRUD — Guardian
        register(GuardianContract())
    }
}
