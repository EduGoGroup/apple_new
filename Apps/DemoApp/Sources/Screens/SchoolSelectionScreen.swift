import SwiftUI
import EduCore
import EduPresentation
import EduModels

// MARK: - School Selection Screen

/// Modal que muestra las escuelas/contextos disponibles para cambio.
///
/// Soporta dos modos:
/// 1. Modo contextos: lista de `UserContextDTO` (cambio de contexto normal)
/// 2. Modo escuelas API: lista de escuelas del backend (super_admin sin escuela)
struct SchoolSelectionScreen: View {
    let contexts: [UserContextDTO]
    let currentSchoolId: String?
    let schools: [[String: JSONValue]]
    let onSelect: (UserContextDTO) -> Void

    @Environment(\.dismiss) private var dismiss

    init(
        contexts: [UserContextDTO],
        currentSchoolId: String?,
        schools: [[String: JSONValue]] = [],
        onSelect: @escaping (UserContextDTO) -> Void
    ) {
        self.contexts = contexts
        self.currentSchoolId = currentSchoolId
        self.schools = schools
        self.onSelect = onSelect
    }

    private var useSuperAdminMode: Bool {
        !schools.isEmpty
    }

    var body: some View {
        NavigationStack {
            List {
                if useSuperAdminMode {
                    schoolsFromAPISection
                } else {
                    contextsSection
                }
            }
            .navigationTitle(EduStrings.selectSchool)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(EduStrings.close) { dismiss() }
                }
            }
        }
    }

    // MARK: - Contexts Mode

    @ViewBuilder
    private var contextsSection: some View {
        ForEach(contexts, id: \.roleId) { context in
            Button {
                onSelect(context)
            } label: {
                HStack(spacing: DesignTokens.Spacing.medium) {
                    Image(systemName: "building.columns.fill")
                        .font(.title3)
                        .foregroundStyle(isCurrentContext(context) ? Color.accentColor : .secondary)

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text(context.schoolName ?? EduStrings.noSchool)
                            .font(.body)
                            .foregroundStyle(.primary)

                        Text(context.roleName.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if isCurrentContext(context) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .padding(.vertical, DesignTokens.Spacing.small)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(context.schoolName ?? EduStrings.noSchool), \(context.roleName)")
            .accessibilityAddTraits(isCurrentContext(context) ? .isSelected : [])
        }
    }

    // MARK: - Schools API Mode (super_admin)

    @ViewBuilder
    private var schoolsFromAPISection: some View {
        ForEach(Array(schools.enumerated()), id: \.offset) { _, school in
            let schoolId = school["id"]?.stringValue ?? ""
            let schoolName = school["name"]?.stringValue ?? "Escuela"
            let city = school["city"]?.stringValue

            Button {
                let roleId = contexts.first?.roleId ?? ""
                let permissions = contexts.first?.permissions ?? []
                let syntheticContext = UserContextDTO(
                    roleId: roleId,
                    roleName: "super_admin",
                    schoolId: schoolId,
                    schoolName: schoolName,
                    permissions: permissions
                )
                onSelect(syntheticContext)
            } label: {
                HStack(spacing: DesignTokens.Spacing.medium) {
                    Image(systemName: "building.columns.fill")
                        .font(.title3)
                        .foregroundStyle(currentSchoolId == schoolId ? Color.accentColor : .secondary)

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text(schoolName)
                            .font(.body)
                            .foregroundStyle(.primary)

                        if let city {
                            Text(city)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if currentSchoolId == schoolId {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .padding(.vertical, DesignTokens.Spacing.small)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(schoolName)
            .accessibilityAddTraits(currentSchoolId == schoolId ? .isSelected : [])
        }
    }

    private func isCurrentContext(_ context: UserContextDTO) -> Bool {
        context.schoolId == currentSchoolId
    }
}
