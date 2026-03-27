import SwiftUI

/// Selectable card for a multiple-choice option with a radio-style indicator.
///
/// Displays the option text alongside a circle indicator that fills when
/// selected. The card border highlights the active selection.
///
/// ## Example
/// ```swift
/// OptionCard(
///     text: "Paris",
///     isSelected: selectedId == optionId,
///     onTap: { selectedId = optionId }
/// )
/// ```
@available(iOS 26.0, macOS 26.0, *)
@MainActor
public struct OptionCard: View {

    // MARK: - Properties

    private let text: String
    private let isSelected: Bool
    private let isCorrect: Bool?
    private let isDisabled: Bool
    private let onTap: () -> Void

    // MARK: - Initialization

    /// Creates an option card for an answer choice.
    ///
    /// - Parameters:
    ///   - text: The option text to display.
    ///   - isSelected: Whether this option is currently selected.
    ///   - isCorrect: If non-nil, shows correct/incorrect state (for review mode).
    ///   - isDisabled: Disables interaction (used in review mode).
    ///   - onTap: Action triggered when the card is tapped.
    public init(
        text: String,
        isSelected: Bool,
        isCorrect: Bool? = nil,
        isDisabled: Bool = false,
        onTap: @escaping () -> Void
    ) {
        self.text = text
        self.isSelected = isSelected
        self.isCorrect = isCorrect
        self.isDisabled = isDisabled
        self.onTap = onTap
    }

    // MARK: - Body

    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignTokens.Spacing.medium) {
                radioIndicator

                Text(text)
                    .font(.body)
                    .foregroundStyle(isDisabled ? .secondary : .primary)
                    .multilineTextAlignment(.leading)

                Spacer()

                if let isCorrect {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(isCorrect ? .green : .red)
                        .font(.title3)
                }
            }
            .padding(DesignTokens.Insets.cardList)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl)
                    .stroke(borderColor, lineWidth: isSelected ? DesignTokens.BorderWidth.medium : DesignTokens.BorderWidth.thin)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityLabel(text)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint(isDisabled ? "" : "Toca para seleccionar esta opcion")
    }

    // MARK: - Subviews

    private var radioIndicator: some View {
        ZStack {
            Circle()
                .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.4), lineWidth: 2)
                .frame(width: 22, height: 22)

            if isSelected {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 12, height: 12)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    // MARK: - Styling

    private var cardBackground: Color {
        if let isCorrect {
            return isCorrect ? Color.green.opacity(0.08) : (isSelected ? Color.red.opacity(0.08) : Color.cardBackground)
        }
        return isSelected ? Color.accentColor.opacity(0.08) : Color.cardBackground
    }

    private var borderColor: Color {
        if let isCorrect {
            return isCorrect ? .green : (isSelected ? .red : Color.secondary.opacity(0.2))
        }
        return isSelected ? .accentColor : Color.secondary.opacity(0.2)
    }
}

// MARK: - Previews

#Preview("Option Cards") {
    VStack(spacing: DesignTokens.Spacing.small) {
        OptionCard(text: "Paris", isSelected: true) { }
        OptionCard(text: "London", isSelected: false) { }
        OptionCard(text: "Berlin", isSelected: false) { }
        OptionCard(text: "Madrid", isSelected: false) { }
    }
    .padding()
}

#Preview("Review Mode") {
    VStack(spacing: DesignTokens.Spacing.small) {
        OptionCard(text: "Paris", isSelected: true, isCorrect: true, isDisabled: true) { }
        OptionCard(text: "London", isSelected: false, isCorrect: false, isDisabled: true) { }
        OptionCard(text: "Berlin", isSelected: false, isCorrect: false, isDisabled: true) { }
    }
    .padding()
}
