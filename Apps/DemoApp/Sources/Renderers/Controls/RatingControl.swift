import SwiftUI
import EduDynamicUI
import EduModels

struct RatingControl: View {
    let slot: Slot
    let fieldValues: Binding<[String: String]>

    private var fieldKey: String { slot.field ?? slot.id }
    private let maxStars = 5

    private var currentRating: Int {
        Int(fieldValues.wrappedValue[fieldKey] ?? "0") ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let label = slot.label {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 4) {
                ForEach(1...maxStars, id: \.self) { star in
                    Image(systemName: star <= currentRating ? "star.fill" : "star")
                        .font(.title3)
                        .foregroundStyle(star <= currentRating ? .yellow : .secondary)
                        .onTapGesture {
                            fieldValues.wrappedValue[fieldKey] = String(star)
                        }
                }
            }
        }
    }
}

struct RatingDisplayControl: View {
    let slot: Slot
    let resolvedValue: JSONValue?

    private let maxStars = 5

    private var rating: Int {
        resolvedValue?.intValue ?? Int(resolvedValue?.stringRepresentation ?? "0") ?? 0
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxStars, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.caption)
                    .foregroundStyle(star <= rating ? .yellow : .secondary)
            }
        }
    }
}
