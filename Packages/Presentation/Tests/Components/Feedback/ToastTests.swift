import Testing
@testable import EduPresentation

@Suite("ToastManager")
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
}
