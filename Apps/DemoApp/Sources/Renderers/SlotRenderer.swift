import SwiftUI
import EduDynamicUI
import EduPresentation
import EduModels

struct SlotRenderer: View {
    let slot: Slot
    let data: [String: EduModels.JSONValue]?
    let slotData: [String: EduModels.JSONValue]?
    let actions: [ActionDefinition]
    var fieldValues: Binding<[String: String]>?
    let onAction: (ActionDefinition) -> Void
    var onEvent: ((String) -> Void)? = nil

    private let resolver = SlotBindingResolver()

    private var resolvedValue: EduModels.JSONValue? {
        resolver.resolve(slot: slot, data: data, slotData: slotData)
    }

    var body: some View {
        Group {
            switch slot.controlType {
            // MARK: - Input Controls
            case .textInput, .emailInput, .numberInput, .searchBar:
                if let fieldValues {
                    TextInputControl(
                        slot: slot,
                        fieldValues: fieldValues,
                        controlType: slot.controlType
                    )
                } else {
                    Text(resolvedValue?.stringRepresentation ?? "")
                }

            case .passwordInput:
                if let fieldValues {
                    PasswordInputControl(slot: slot, fieldValues: fieldValues)
                } else {
                    Text("••••••••")
                }

            // MARK: - Selection Controls
            case .select:
                if let fieldValues {
                    SelectControl(slot: slot, fieldValues: fieldValues)
                } else {
                    Text(resolvedValue?.stringRepresentation ?? "")
                }

            case .checkbox:
                if let fieldValues {
                    CheckboxControl(slot: slot, fieldValues: fieldValues)
                } else {
                    Label(
                        slot.label ?? "",
                        systemImage: resolvedValue?.boolValue == true ? "checkmark.square.fill" : "square"
                    )
                }

            case .switch:
                if let fieldValues {
                    SwitchToggleControl(slot: slot, fieldValues: fieldValues)
                } else {
                    Label(
                        slot.label ?? "",
                        systemImage: resolvedValue?.boolValue == true ? "checkmark.circle.fill" : "circle"
                    )
                }

            case .radioGroup:
                if let fieldValues {
                    RadioGroupControl(slot: slot, fieldValues: fieldValues)
                } else {
                    Text(resolvedValue?.stringRepresentation ?? "")
                }

            case .chip:
                if let fieldValues {
                    ChipControl(slot: slot, fieldValues: fieldValues)
                } else {
                    ChipDisplayControl(slot: slot, resolvedValue: resolvedValue)
                }

            case .rating:
                if let fieldValues {
                    RatingControl(slot: slot, fieldValues: fieldValues)
                } else {
                    RatingDisplayControl(slot: slot, resolvedValue: resolvedValue)
                }

            // MARK: - Buttons
            case .filledButton, .outlinedButton, .textButton, .iconButton:
                ButtonControl(
                    slot: slot,
                    actions: actions,
                    onAction: onAction,
                    onEvent: onEvent
                )

            // MARK: - Display Controls
            case .label:
                LabelControl(slot: slot, resolvedValue: resolvedValue)

            case .icon:
                IconControl(slot: slot, resolvedValue: resolvedValue)

            case .avatar:
                AvatarControl(slot: slot, resolvedValue: resolvedValue)

            case .image:
                ImageControl(slot: slot, resolvedValue: resolvedValue)

            case .divider:
                Divider()

            // MARK: - Compound Controls
            case .listItem:
                ListItemControl(slot: slot, resolvedValue: resolvedValue)

            case .listItemNavigation:
                ListItemNavigationControl(
                    slot: slot,
                    resolvedValue: resolvedValue,
                    actions: actions,
                    onAction: onAction
                )

            case .metricCard:
                MetricCardControl(
                    slot: slot,
                    resolvedValue: resolvedValue,
                    data: data,
                    actions: actions,
                    onAction: { onAction($0) }
                )
            }
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
        "logout": "rectangle.portrait.and.arrow.right",
        "language": "globe",
        "dark_mode": "moon.fill",
        "light_mode": "sun.max.fill",
        "phone": "phone.fill",
        "location": "location.fill",
        "link": "link",
        "attach_file": "paperclip",
        "more_vert": "ellipsis",
        "more_horiz": "ellipsis",
    ]

    static func sfSymbolName(for icon: String) -> String {
        iconMap[icon] ?? icon
    }
}
