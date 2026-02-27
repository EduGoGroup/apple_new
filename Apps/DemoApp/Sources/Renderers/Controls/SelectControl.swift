import SwiftUI
import EduDynamicUI
import EduModels

// MARK: - Select (Picker)

struct SelectControl: View {
    let slot: Slot
    let fieldValues: Binding<[String: String]>

    private var fieldKey: String { slot.field ?? slot.id }

    private var selection: Binding<String> {
        Binding(
            get: { fieldValues.wrappedValue[fieldKey] ?? "" },
            set: { fieldValues.wrappedValue[fieldKey] = $0 }
        )
    }

    private var options: [(value: String, label: String)] {
        guard case .array(let array) = slot.value else { return [] }
        return array.compactMap { item in
            switch item {
            case .string(let s):
                return (value: s, label: s)
            case .object(let dict):
                let value = dict["value"]?.stringRepresentation ?? ""
                let label = dict["label"]?.stringRepresentation ?? value
                return (value: value, label: label)
            default:
                return nil
            }
        }
    }

    var body: some View {
        Picker(slot.label ?? "", selection: selection) {
            Text(slot.placeholder ?? "Seleccionar...").tag("")
            ForEach(options, id: \.value) { option in
                Text(option.label).tag(option.value)
            }
        }
    }
}

// MARK: - Checkbox (Toggle)

struct CheckboxControl: View {
    let slot: Slot
    let fieldValues: Binding<[String: String]>

    private var fieldKey: String { slot.field ?? slot.id }

    private var isOn: Binding<Bool> {
        Binding(
            get: { fieldValues.wrappedValue[fieldKey] == "true" },
            set: { fieldValues.wrappedValue[fieldKey] = $0 ? "true" : "false" }
        )
    }

    var body: some View {
        Toggle(slot.label ?? "", isOn: isOn)
            .toggleStyle(.checkbox)
            .disabled(slot.readOnly ?? false)
    }
}

// MARK: - Switch

struct SwitchToggleControl: View {
    let slot: Slot
    let fieldValues: Binding<[String: String]>

    private var fieldKey: String { slot.field ?? slot.id }

    private var isOn: Binding<Bool> {
        Binding(
            get: { fieldValues.wrappedValue[fieldKey] == "true" },
            set: { fieldValues.wrappedValue[fieldKey] = $0 ? "true" : "false" }
        )
    }

    var body: some View {
        Toggle(slot.label ?? "", isOn: isOn)
            .toggleStyle(.switch)
            .disabled(slot.readOnly ?? false)
    }
}

// MARK: - RadioGroup

struct RadioGroupControl: View {
    let slot: Slot
    let fieldValues: Binding<[String: String]>

    private var fieldKey: String { slot.field ?? slot.id }

    private var selection: Binding<String> {
        Binding(
            get: { fieldValues.wrappedValue[fieldKey] ?? "" },
            set: { fieldValues.wrappedValue[fieldKey] = $0 }
        )
    }

    private var options: [(value: String, label: String)] {
        guard case .array(let array) = slot.value else { return [] }
        return array.compactMap { item in
            switch item {
            case .string(let s):
                return (value: s, label: s)
            case .object(let dict):
                let value = dict["value"]?.stringRepresentation ?? ""
                let label = dict["label"]?.stringRepresentation ?? value
                return (value: value, label: label)
            default:
                return nil
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label = slot.label {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ForEach(options, id: \.value) { option in
                HStack {
                    Image(systemName: selection.wrappedValue == option.value
                        ? "circle.inset.filled"
                        : "circle")
                        .foregroundStyle(selection.wrappedValue == option.value ? Color.accentColor : .secondary)
                    Text(option.label)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selection.wrappedValue = option.value
                }
            }
        }
    }
}

// MARK: - Chip

struct ChipControl: View {
    let slot: Slot
    let fieldValues: Binding<[String: String]>

    private var fieldKey: String { slot.field ?? slot.id }

    private var isSelected: Bool {
        fieldValues.wrappedValue[fieldKey] == "true"
    }

    var body: some View {
        Button {
            fieldValues.wrappedValue[fieldKey] = isSelected ? "false" : "true"
        } label: {
            HStack(spacing: 4) {
                if let icon = slot.icon {
                    Image(systemName: SlotRenderer.sfSymbolName(for: icon))
                        .font(.caption)
                }
                Text(slot.label ?? "")
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1))
            .foregroundStyle(isSelected ? Color.accentColor : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
