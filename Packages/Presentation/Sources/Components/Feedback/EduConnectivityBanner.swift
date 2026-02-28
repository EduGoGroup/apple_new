// EduConnectivityBanner.swift
// EduPresentation
//
// Banner de conectividad con soporte Liquid Glass.

import SwiftUI

/// Banner que indica el estado de conectividad de la app.
///
/// Muestra tres estados:
/// - **Offline**: fondo rojo, icono wifi.slash, "Sin conexión"
/// - **Syncing**: fondo azul, spinner, "Sincronizando..." + count
/// - **Synced**: fondo verde, checkmark, "Sincronizado" → auto-dismiss 3s
public struct EduConnectivityBanner: View {

    /// Indica si hay conexión de red disponible.
    public let isOnline: Bool

    /// Número de mutaciones pendientes.
    public let pendingCount: Int

    /// Indica si se está sincronizando activamente.
    public let isSyncing: Bool

    @State private var showSynced = false

    public init(isOnline: Bool, pendingCount: Int, isSyncing: Bool) {
        self.isOnline = isOnline
        self.pendingCount = pendingCount
        self.isSyncing = isSyncing
    }

    public var body: some View {
        Group {
            if !isOnline {
                bannerContent(
                    icon: "wifi.slash",
                    text: EduStrings.offline,
                    tint: .red
                )
            } else if isSyncing {
                syncingBanner
            } else if showSynced {
                bannerContent(
                    icon: "checkmark.circle.fill",
                    text: EduStrings.synced,
                    tint: .green
                )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isOnline)
        .animation(.easeInOut(duration: 0.3), value: isSyncing)
        .animation(.easeInOut(duration: 0.3), value: showSynced)
        .transition(.move(edge: .top).combined(with: .opacity))
        .onChange(of: isSyncing) { wasSyncing, nowSyncing in
            if wasSyncing && !nowSyncing && isOnline {
                showSynced = true
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    showSynced = false
                }
            }
        }
    }

    // MARK: - Subviews

    private var syncingBanner: some View {
        HStack(spacing: 8) {
            ProgressView()
                .tint(.white)

            Text(EduStrings.syncing)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)

            if pendingCount > 0 {
                Text("(\(pendingCount))")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(.blue.gradient, in: .capsule)
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal)
    }

    private func bannerContent(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(tint.gradient, in: .capsule)
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal)
    }
}
