import SwiftUI
import EduDynamicUI
import EduPresentation
import EduModels

struct ListPatternRenderer: View {
    let screen: ScreenDefinition
    let items: [[String: EduModels.JSONValue]]
    let onAction: (ActionDefinition) -> Void
    var onLoadMore: (() -> Void)?
    var hasMore: Bool = false

    private var itemLayout: ItemLayout? {
        screen.template.zones.first(where: { $0.itemLayout != nil })?.itemLayout
    }

    var body: some View {
        List {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                if let layout = itemLayout {
                    HStack {
                        ForEach(layout.slots) { slot in
                            SlotRenderer(
                                slot: slot,
                                data: item,
                                slotData: screen.slotData,
                                actions: screen.actions,
                                onAction: onAction
                            )
                        }
                    }
                } else {
                    Text(item.description)
                }
            }

            if hasMore {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .onAppear {
                        onLoadMore?()
                    }
            }
        }
    }
}
