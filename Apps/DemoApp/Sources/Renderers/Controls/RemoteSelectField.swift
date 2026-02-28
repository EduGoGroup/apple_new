import SwiftUI
import EduDynamicUI
import EduPresentation

struct RemoteSelectField: View {
    let slot: Slot
    let state: SelectOptionsState?
    let selectedValue: String?
    let onValueChanged: (String) -> Void
    let onLoadOptions: () async -> Void

    private var selection: Binding<String> {
        Binding(
            get: { selectedValue ?? "" },
            set: { onValueChanged($0) }
        )
    }

    var body: some View {
        Group {
            switch state {
            case .loading, .none:
                HStack {
                    Text(slot.label ?? "")
                        .foregroundStyle(.secondary)
                    Spacer()
                    ProgressView()
                        .controlSize(.small)
                    Text(EduStrings.selectLoading)
                        .foregroundStyle(.tertiary)
                        .font(.subheadline)
                }

            case .success(let options):
                Picker(slot.label ?? "", selection: selection) {
                    Text(slot.placeholder ?? EduStrings.selectLoading)
                        .tag("")
                    ForEach(options, id: \.value) { option in
                        Text(option.label).tag(option.value)
                    }
                }

            case .error(let message):
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(slot.label ?? "")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(EduStrings.selectLoadError)
                            .foregroundStyle(.red)
                            .font(.subheadline)
                    }
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .task { await onLoadOptions() }
    }
}
