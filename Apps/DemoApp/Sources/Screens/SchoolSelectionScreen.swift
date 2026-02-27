import SwiftUI
import EduCore
import EduPresentation

// MARK: - School Selection Screen

/// Modal que muestra las escuelas/contextos disponibles para cambio.
///
/// Presenta una lista con nombre de escuela y rol del usuario.
/// Al seleccionar, ejecuta `authService.switchContext` → recarga sync → reconstruye menu.
struct SchoolSelectionScreen: View {
    let contexts: [UserContextDTO]
    let currentSchoolId: String?
    let onSelect: (UserContextDTO) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(contexts, id: \.roleId) { context in
                    Button {
                        onSelect(context)
                    } label: {
                        HStack(spacing: DesignTokens.Spacing.medium) {
                            Image(systemName: "building.columns.fill")
                                .font(.title3)
                                .foregroundStyle(isCurrentContext(context) ? Color.accentColor : .secondary)

                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                                Text(context.schoolName ?? "Sin escuela")
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
                    .accessibilityLabel("\(context.schoolName ?? "Sin escuela"), \(context.roleName)")
                    .accessibilityAddTraits(isCurrentContext(context) ? .isSelected : [])
                }
            }
            .navigationTitle("Seleccionar escuela")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }

    private func isCurrentContext(_ context: UserContextDTO) -> Bool {
        context.schoolId == currentSchoolId
    }
}
