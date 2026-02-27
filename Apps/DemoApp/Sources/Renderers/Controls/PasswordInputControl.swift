import SwiftUI
import EduDynamicUI
import EduPresentation
import EduModels

struct PasswordInputControl: View {
    let slot: Slot
    let fieldValues: Binding<[String: String]>

    private var fieldKey: String { slot.field ?? slot.id }

    private var textBinding: Binding<String> {
        Binding(
            get: { fieldValues.wrappedValue[fieldKey] ?? "" },
            set: { fieldValues.wrappedValue[fieldKey] = $0 }
        )
    }

    var body: some View {
        EduSecureField(
            slot.label ?? "",
            text: textBinding,
            placeholder: slot.placeholder ?? "",
            showPasswordToggle: true,
            isDisabled: slot.readOnly ?? false
        )
    }
}
