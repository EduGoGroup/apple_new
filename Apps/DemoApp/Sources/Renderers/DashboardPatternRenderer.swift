import SwiftUI
import EduDynamicUI
import EduPresentation
import EduModels

struct DashboardPatternRenderer: View {
    let screen: ScreenDefinition
    let viewModel: DynamicScreenViewModel

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    private var metricColumns: [GridItem] {
        #if os(iOS)
        let count = horizontalSizeClass == .compact ? 2 : 3
        #else
        let count = 3
        #endif
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
    }

    private var quickActionColumns: [GridItem] {
        #if os(iOS)
        let count = horizontalSizeClass == .compact ? 4 : 6
        #else
        let count = 6
        #endif
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
    }

    var body: some View {
        ScrollView {
            content
                .padding()
        }
        .refreshable {
            await viewModel.executeEvent(.refresh)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.dataState {
        case .loading:
            dashboardSkeleton
        case .idle:
            welcomeFallback
        default:
            dashboardContent
        }
    }

    // MARK: - Dashboard Content

    @ViewBuilder
    private var dashboardContent: some View {
        let hasMetrics = screen.template.zones.contains { $0.type == .metricGrid }
        if !hasMetrics, case .success(let items, _, _) = viewModel.dataState, items.isEmpty {
            welcomeFallback
        } else {
            VStack(spacing: 16) {
                ForEach(screen.template.zones) { zone in
                    zoneSection(zone)
                }
            }
        }
    }

    @ViewBuilder
    private func zoneSection(_ zone: Zone) -> some View {
        switch zone.type {
        case .metricGrid:
            metricGridSection(zone: zone)
        case .actionGroup:
            quickActionSection(zone: zone)
        default:
            ZoneRenderer(
                zone: zone,
                data: slotData,
                slotData: screen.slotData,
                actions: screen.actions,
                onAction: { action in viewModel.executeAction(action) }
            )
        }
    }

    // MARK: - Metric Grid

    @ViewBuilder
    private func metricGridSection(zone: Zone) -> some View {
        LazyVGrid(columns: metricColumns, spacing: 12) {
            if let slots = zone.slots {
                ForEach(slots) { slot in
                    MetricCardControl(
                        slot: slot,
                        resolvedValue: resolveValue(for: slot),
                        data: slotData,
                        actions: screen.actions,
                        onAction: { action in viewModel.executeAction(action) }
                    )
                }
            }
            if let childZones = zone.zones {
                ForEach(childZones) { child in
                    if let childSlots = child.slots {
                        ForEach(childSlots) { slot in
                            MetricCardControl(
                                slot: slot,
                                resolvedValue: resolveValue(for: slot),
                                data: slotData,
                                actions: screen.actions,
                                onAction: { action in viewModel.executeAction(action) }
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Quick Actions

    @ViewBuilder
    private func quickActionSection(zone: Zone) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            if let titleSlot = zone.slots?.first(where: { $0.controlType == .label }) {
                Text(titleSlot.label ?? "")
                    .font(.headline)
            }

            let actionSlots = (zone.slots ?? []).filter { slot in
                slot.controlType != .label
            }

            if !actionSlots.isEmpty {
                LazyVGrid(columns: quickActionColumns, spacing: 12) {
                    ForEach(actionSlots) { slot in
                        QuickActionControl(
                            slot: slot,
                            actions: screen.actions,
                            onAction: { action in viewModel.executeAction(action) }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Welcome Fallback

    @ViewBuilder
    private var welcomeFallback: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()
                .frame(height: 40)

            Image(systemName: "graduationcap.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)

            VStack(spacing: DesignTokens.Spacing.small) {
                Text(welcomeTitle)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text("Tu panel se cargará con las métricas de tu rol.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    private var welcomeTitle: String {
        let role = viewModel.userContext.roleName
        if role.isEmpty || role == "anonymous" {
            return "Bienvenido a EduGo"
        }
        return "Bienvenido"
    }

    // MARK: - Skeleton

    @ViewBuilder
    private var dashboardSkeleton: some View {
        let metricSlotCount = screen.template.zones
            .filter { $0.type == .metricGrid }
            .reduce(0) { total, zone in
                let direct = zone.slots?.count ?? 0
                let nested = zone.zones?.reduce(0) { $0 + ($1.slots?.count ?? 0) } ?? 0
                return total + direct + nested
            }
        let actionSlotCount = screen.template.zones
            .filter { $0.type == .actionGroup }
            .reduce(0) { $0 + (($1.slots?.count ?? 0)) }

        VStack(spacing: 16) {
            LazyVGrid(columns: metricColumns, spacing: 12) {
                ForEach(0..<max(metricSlotCount, 4), id: \.self) { _ in
                    skeletonMetricCard
                }
            }
            .shimmer()

            if actionSlotCount > 0 {
                LazyVGrid(columns: quickActionColumns, spacing: 12) {
                    ForEach(0..<actionSlotCount, id: \.self) { _ in
                        skeletonQuickAction
                    }
                }
                .shimmer()
            }
        }
    }

    @ViewBuilder
    private var skeletonMetricCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            HStack {
                EduSkeletonLoader(shape: .circle)
                    .frame(width: 28, height: 28)
                Spacer()
                EduSkeletonLoader(shape: .capsule)
                    .frame(width: 60, height: 20)
            }
            EduSkeletonLoader(shape: .capsule)
                .frame(height: 28)
                .frame(maxWidth: 100)
            EduSkeletonLoader(shape: .capsule)
                .frame(height: 12)
                .frame(maxWidth: 80)
        }
        .padding()
        .background(Color(white: 0.98))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.glass))
    }

    @ViewBuilder
    private var skeletonQuickAction: some View {
        VStack(spacing: DesignTokens.Spacing.small) {
            EduSkeletonLoader(shape: .circle)
                .frame(width: 40, height: 40)
            EduSkeletonLoader(shape: .capsule)
                .frame(height: 10)
                .frame(maxWidth: 50)
        }
        .padding(.vertical, DesignTokens.Spacing.medium)
        .background(Color(white: 0.98))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.glass))
    }

    // MARK: - Data Resolution

    private var slotData: [String: EduModels.JSONValue]? {
        if case .success(let items, _, _) = viewModel.dataState,
           let first = items.first {
            return first
        }
        return screen.slotData
    }

    private let resolver = SlotBindingResolver()

    private func resolveValue(for slot: Slot) -> JSONValue? {
        resolver.resolve(slot: slot, data: slotData, slotData: screen.slotData)
    }
}
