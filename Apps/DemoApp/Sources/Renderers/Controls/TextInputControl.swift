import SwiftUI
import EduDynamicUI
import EduPresentation
import EduModels

struct TextInputControl: View {
    let slot: Slot
    let fieldValues: Binding<[String: String]>
    let controlType: ControlType

    private var fieldKey: String { slot.field ?? slot.id }

    private var textBinding: Binding<String> {
        Binding(
            get: { fieldValues.wrappedValue[fieldKey] ?? "" },
            set: { fieldValues.wrappedValue[fieldKey] = $0 }
        )
    }

    var body: some View {
        EduTextField(
            slot.label ?? "",
            text: textBinding,
            placeholder: slot.placeholder ?? "",
            isDisabled: slot.readOnly ?? false
        )
        .autocorrectionDisabled(controlType == .emailInput)
        #if os(iOS)
        .textInputAutocapitalization(controlType == .emailInput ? .never : .sentences)
        .keyboardType(keyboardType)
        #endif
    }

    #if os(iOS)
    private var keyboardType: UIKeyboardType {
        switch controlType {
        case .emailInput: .emailAddress
        case .numberInput: .numberPad
        case .searchBar: .default
        default: .default
        }
    }
    #endif
}
