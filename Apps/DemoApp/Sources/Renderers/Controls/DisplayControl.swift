import SwiftUI
import EduDynamicUI
import EduModels

// MARK: - Label

struct LabelControl: View {
    let slot: Slot
    let resolvedValue: JSONValue?

    var body: some View {
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
}

// MARK: - Icon

struct IconControl: View {
    let slot: Slot

    var body: some View {
        Image(systemName: SlotRenderer.sfSymbolName(for: slot.icon ?? "questionmark"))
            .font(iconFont)
            .foregroundStyle(iconColor)
    }

    private var iconFont: Font {
        switch slot.style {
        case "large": .largeTitle
        case "medium": .title2
        case "small": .caption
        default: .body
        }
    }

    private var iconColor: Color {
        switch slot.style {
        case "primary": .accentColor
        case "secondary": .secondary
        case "destructive": .red
        default: .primary
        }
    }
}

// MARK: - Avatar

struct AvatarControl: View {
    let slot: Slot
    let resolvedValue: JSONValue?

    var body: some View {
        let name = resolvedValue?.stringRepresentation ?? slot.label ?? ""
        let initials = name.split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
            .uppercased()

        Circle()
            .fill(Color.accentColor.opacity(0.15))
            .frame(width: 40, height: 40)
            .overlay {
                Text(initials.isEmpty ? "?" : initials)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentColor)
            }
    }
}

// MARK: - Image

struct ImageControl: View {
    let slot: Slot
    let resolvedValue: JSONValue?

    var body: some View {
        if let urlString = resolvedValue?.stringRepresentation,
           let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure:
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                case .empty:
                    ProgressView()
                @unknown default:
                    EmptyView()
                }
            }
        } else if let icon = slot.icon {
            Image(systemName: SlotRenderer.sfSymbolName(for: icon))
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Chip (Display-only)

struct ChipDisplayControl: View {
    let slot: Slot
    let resolvedValue: JSONValue?

    var body: some View {
        HStack(spacing: 4) {
            if let icon = slot.icon {
                Image(systemName: SlotRenderer.sfSymbolName(for: icon))
                    .font(.caption)
            }
            Text(resolvedValue?.stringRepresentation ?? slot.label ?? "")
                .font(.subheadline)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.1))
        .clipShape(Capsule())
    }
}
