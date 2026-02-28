import Testing
@testable import EduPresentation

@Suite("ToastManager", .serialized)
struct ToastTests {

    @Test("ToastManager shared instance exists")
    @MainActor
    func sharedInstance() {
        let manager = ToastManager.shared
        #expect(manager != nil)
    }

    @Test("show() adds a toast to the list")
    @MainActor
    func showAddsToast() {
        let manager = ToastManager.shared
        let initialCount = manager.toasts.count
        manager.show("Test message", style: .info)
        #expect(manager.toasts.count == initialCount + 1)
    }

    @Test("dismiss() removes a toast from the list")
    @MainActor
    func dismissRemovesToast() {
        let manager = ToastManager.shared
        manager.show("To dismiss", style: .warning)
        let toast = manager.toasts.last!
        manager.dismiss(toast)
        #expect(!manager.toasts.contains { $0.id == toast.id })
    }

    @Test("showSuccess convenience method works")
    @MainActor
    func showSuccess() {
        let manager = ToastManager.shared
        let countBefore = manager.toasts.count
        manager.showSuccess("Success!")
        #expect(manager.toasts.count == countBefore + 1)
        let last = manager.toasts.last!
        #expect(last.style == .success)
        #expect(last.message == "Success!")
        manager.dismiss(last)
    }

    @Test("showError convenience method works")
    @MainActor
    func showError() {
        let manager = ToastManager.shared
        let countBefore = manager.toasts.count
        manager.showError("Error!")
        #expect(manager.toasts.count == countBefore + 1)
        let last = manager.toasts.last!
        #expect(last.style == .error)
        manager.dismiss(last)
    }

    @Test("showWarning convenience method works")
    @MainActor
    func showWarning() {
        let manager = ToastManager.shared
        let countBefore = manager.toasts.count
        manager.showWarning("Warning!")
        #expect(manager.toasts.count == countBefore + 1)
        let last = manager.toasts.last!
        #expect(last.style == .warning)
        manager.dismiss(last)
    }

    @Test("showInfo convenience method works")
    @MainActor
    func showInfoConvenience() {
        let manager = ToastManager.shared
        let countBefore = manager.toasts.count
        manager.showInfo("Info!")
        #expect(manager.toasts.count == countBefore + 1)
        let last = manager.toasts.last!
        #expect(last.style == .info)
        manager.dismiss(last)
    }

    @Test("ToastItem stores correct values")
    func toastItemValues() {
        let item = ToastItem(message: "Test", style: .success, duration: 5.0)
        #expect(item.message == "Test")
        #expect(item.style == .success)
        #expect(item.duration == 5.0)
    }

    @Test("ToastStyle has correct icons")
    func toastStyleIcons() {
        #expect(ToastStyle.success.icon == "checkmark.circle.fill")
        #expect(ToastStyle.error.icon == "xmark.circle.fill")
        #expect(ToastStyle.warning.icon == "exclamationmark.triangle.fill")
        #expect(ToastStyle.info.icon == "info.circle.fill")
    }

    @Test("ToastStyle has correct accessibility prefixes")
    func toastStyleAccessibility() {
        #expect(ToastStyle.success.accessibilityPrefix == "Success")
        #expect(ToastStyle.error.accessibilityPrefix == "Error")
        #expect(ToastStyle.warning.accessibilityPrefix == "Warning")
        #expect(ToastStyle.info.accessibilityPrefix == "Information")
    }

    @Test("EduToast view initializes correctly")
    @MainActor
    func toastViewInit() {
        let item = ToastItem(message: "Hello", style: .info, duration: 3)
        let toast = EduToast(item: item, onDismiss: {})
        #expect(toast != nil)
    }

    // MARK: - Undoable Toast

    @Test("showUndoable creates toast with action")
    @MainActor
    func showUndoableCreatesToast() {
        let manager = ToastManager.shared
        let countBefore = manager.toasts.count
        manager.showUndoable(message: "Item deleted", onUndo: {})
        #expect(manager.toasts.count == countBefore + 1)
        let last = manager.toasts.last!
        #expect(last.message == "Item deleted")
        #expect(last.style == .info)
        #expect(last.duration == 5.0)
        #expect(last.action != nil)
        #expect(last.action?.label == EduStrings.undo)
        manager.dismiss(last)
    }

    @Test("showUndoable with custom action label")
    @MainActor
    func showUndoableCustomLabel() {
        let manager = ToastManager.shared
        let countBefore = manager.toasts.count
        manager.showUndoable(
            message: "Removed",
            actionLabel: "Revert",
            onUndo: {},
            duration: 10.0
        )
        #expect(manager.toasts.count == countBefore + 1)
        let last = manager.toasts.last!
        #expect(last.action?.label == "Revert")
        #expect(last.duration == 10.0)
        manager.dismiss(last)
    }

    @Test("ToastAction stores label and handler")
    @MainActor
    func toastActionValues() {
        let action = ToastAction(label: "Undo") {}
        #expect(action.label == "Undo")
    }

    @Test("ToastItem without action has nil action")
    func toastItemWithoutAction() {
        let item = ToastItem(message: "Test", style: .info, duration: 3)
        #expect(item.action == nil)
    }

    @Test("ToastItem with action has non-nil action")
    func toastItemWithAction() {
        let action = ToastAction(label: "Undo") {}
        let item = ToastItem(message: "Test", style: .info, duration: 3, action: action)
        #expect(item.action != nil)
        #expect(item.action?.label == "Undo")
    }
}
