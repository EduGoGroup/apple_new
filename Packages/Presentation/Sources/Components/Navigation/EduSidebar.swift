// EduSidebar.swift
// EduPresentation
//
// Sidebar component with header (avatar, name, role, school), menu sections, and footer.

import SwiftUI
import EduCore

/// Header del sidebar con informacion del usuario.
///
/// Muestra avatar, nombre, rol y escuela del contexto activo.
public struct EduSidebarHeader: View {
    private let userName: String
    private let roleName: String
    private let schoolName: String?
    private let showSchoolSwitch: Bool
    private let onSchoolSwitch: (() -> Void)?

    public init(
        userName: String,
        roleName: String,
        schoolName: String? = nil,
        showSchoolSwitch: Bool = false,
        onSchoolSwitch: (() -> Void)? = nil
    ) {
        self.userName = userName
        self.roleName = roleName
        self.schoolName = schoolName
        self.showSchoolSwitch = showSchoolSwitch
        self.onSchoolSwitch = onSchoolSwitch
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            HStack(spacing: DesignTokens.Spacing.medium) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(userName)
                        .font(.headline)

                    Text(roleName.capitalized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let schoolName {
                        Text(schoolName)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                if showSchoolSwitch {
                    Button {
                        onSchoolSwitch?()
                    } label: {
                        Image(systemName: "arrow.triangle.swap")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Cambiar escuela")
                }
            }
            .padding(DesignTokens.Spacing.large)
        }
    }
}

/// Footer del sidebar con opciones de ajustes y logout.
public struct EduSidebarFooter: View {
    private let onSettings: (() -> Void)?
    private let onLogout: (() -> Void)?

    public init(
        onSettings: (() -> Void)? = nil,
        onLogout: (() -> Void)? = nil
    ) {
        self.onSettings = onSettings
        self.onLogout = onLogout
    }

    public var body: some View {
        VStack(spacing: DesignTokens.Spacing.small) {
            Divider()

            if let onSettings {
                Button {
                    onSettings()
                } label: {
                    Label("Ajustes", systemImage: "gearshape.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, DesignTokens.Spacing.large)
            }

            if let onLogout {
                Button(role: .destructive) {
                    onLogout()
                } label: {
                    Label("Cerrar sesion", systemImage: "rectangle.portrait.and.arrow.right")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, DesignTokens.Spacing.large)
            }
        }
        .padding(.bottom, DesignTokens.Spacing.medium)
    }
}
