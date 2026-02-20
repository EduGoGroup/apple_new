import SwiftUI
import EduDynamicUI
import EduPresentation
import EduModels

struct SlotRenderer: View {
    let slot: Slot
    let data: [String: EduModels.JSONValue]?
    let slotData: [String: EduModels.JSONValue]?
    let actions: [ActionDefinition]
    let onAction: (ActionDefinition) -> Void

    private let resolver = SlotBindingResolver()

    private var resolvedValue: EduModels.JSONValue? {
        resolver.resolve(slot: slot, data: data, slotData: slotData)
    }

    var body: some View {
        switch slot.controlType {
        case .label:
            labelView

        case .filledButton:
            EduButton(slot.label ?? "Button", icon: slot.icon.map { Self.sfSymbolName(for: $0) }, style: .primary) {
                triggerAction()
            }

        case .outlinedButton:
            EduButton(slot.label ?? "Button", icon: slot.icon.map { Self.sfSymbolName(for: $0) }, style: .secondary) {
                triggerAction()
            }

        case .textButton:
            EduButton.link(slot.label ?? "Button") {
                triggerAction()
            }

        case .iconButton:
            Button {
                triggerAction()
            } label: {
                Image(systemName: Self.sfSymbolName(for: slot.icon ?? "questionmark"))
            }

        case .metricCard:
            EduMetricCard(
                title: slot.label ?? "",
                value: resolvedValue?.stringRepresentation ?? "0",
                icon: Self.sfSymbolName(for: slot.icon ?? "chart.bar.fill")
            )

        case .icon:
            Image(systemName: slot.icon ?? "questionmark")

        case .divider:
            Divider()

        case .listItem:
            listItemView

        case .listItemNavigation:
            listItemNavigationView

        default:
            EmptyView()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var labelView: some View {
        let text = resolvedValue?.stringRepresentation ?? slot.label ?? ""
        switch slot.style {
        case "headline-large":
            Text(text).font(.largeTitle).fontWeight(.bold)
        case "title":
            Text(text).font(.title)
        case "title-medium":
            Text(text).font(.title2)
        case "title-small":
            Text(text).font(.title3)
        case "headline":
            Text(text).font(.headline)
        case "body":
            Text(text).font(.body)
        case "caption":
            Text(text).font(.caption).foregroundStyle(.secondary)
        case "subheadline":
            Text(text).font(.subheadline).foregroundStyle(.secondary)
        default:
            Text(text)
        }
    }

    private var listItemView: some View {
        HStack {
            if let icon = slot.icon {
                Image(systemName: Self.sfSymbolName(for: icon))
            }
            VStack(alignment: .leading) {
                Text(resolvedValue?.stringRepresentation ?? "")
                if let label = slot.label {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }

    private var listItemNavigationView: some View {
        HStack {
            if let icon = slot.icon {
                Image(systemName: Self.sfSymbolName(for: icon))
            }
            VStack(alignment: .leading) {
                Text(resolvedValue?.stringRepresentation ?? "")
                if let label = slot.label {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            triggerAction()
        }
    }

    // MARK: - Actions

    private func triggerAction() {
        if let action = actions.first(where: { $0.triggerSlotId == slot.id }) {
            onAction(action)
        }
    }

    // MARK: - Icon Mapping (Material Design → SF Symbols)

    private static let iconMap: [String: String] = [
        "people": "person.2.fill",
        "person": "person.fill",
        "folder": "folder.fill",
        "trending_up": "chart.line.uptrend.xyaxis",
        "check_circle": "checkmark.circle.fill",
        "upload": "arrow.up.doc.fill",
        "bar_chart": "chart.bar.fill",
        "search": "magnifyingglass",
        "add": "plus",
        "edit": "pencil",
        "delete": "trash",
        "settings": "gearshape.fill",
        "home": "house.fill",
        "star": "star.fill",
        "favorite": "heart.fill",
        "share": "square.and.arrow.up",
        "close": "xmark",
        "menu": "line.3.horizontal",
        "arrow_back": "chevron.left",
        "arrow_forward": "chevron.right",
        "notifications": "bell.fill",
        "google": "globe",
        "visibility": "eye.fill",
        "visibility_off": "eye.slash.fill",
        "email": "envelope.fill",
        "lock": "lock.fill",
        "school": "building.columns.fill",
        "calendar": "calendar",
        "description": "doc.text.fill",
        "assignment": "list.clipboard.fill",
        "quiz": "questionmark.circle.fill",
        "grade": "a.square.fill",
        "done": "checkmark",
        "error": "exclamationmark.triangle.fill",
        "info": "info.circle.fill",
        "warning": "exclamationmark.triangle.fill",
        "refresh": "arrow.clockwise",
        "download": "arrow.down.doc.fill",
        "filter_list": "line.3.horizontal.decrease",
        "sort": "arrow.up.arrow.down",
    ]

    static func sfSymbolName(for icon: String) -> String {
        iconMap[icon] ?? icon
    }
}
