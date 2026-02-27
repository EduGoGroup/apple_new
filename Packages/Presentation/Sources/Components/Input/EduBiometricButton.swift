// EduBiometricButton.swift
// UI
//
// Biometric authentication button for iOS 26+ and macOS 26+

import SwiftUI
import LocalAuthentication

/// Biometric button (FaceID/TouchID/OpticID)
///
/// Automatically detects available biometric type and provides
/// authentication with appropriate icon and feedback.
@available(iOS 26.0, macOS 26.0, *)
@MainActor
public struct EduBiometricButton: View {
    public let action: () -> Void
    public let title: String?

    @State private var biometricType: BiometricType = .none
    @State private var errorMessage: String?

    public enum BiometricType: Sendable {
        case faceID
        case touchID
        case opticID
        case none

        public var iconName: String {
            switch self {
            case .faceID: return "faceid"
            case .touchID: return "touchid"
            case .opticID: return "opticid"
            case .none: return "person.badge.key"
            }
        }

        public var displayName: String {
            switch self {
            case .faceID: return "Face ID"
            case .touchID: return "Touch ID"
            case .opticID: return "Optic ID"
            case .none: return "Biometric"
            }
        }
    }

    /// Creates a Biometric Button
    ///
    /// - Parameters:
    ///   - title: Custom title (optional)
    ///   - action: Action on successful authentication
    public init(
        title: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: authenticateWithBiometric) {
            HStack(spacing: DesignTokens.Spacing.small) {
                Image(systemName: biometricType.iconName)
                    .font(.title3)

                Text(title ?? "Use \(biometricType.displayName)")
                    .font(.body)
            }
            .foregroundStyle(.primary)
        }
        .disabled(biometricType == .none)
        .opacity(biometricType == .none ? 0.5 : 1.0)
        .task {
            checkBiometricAvailability()
        }
    }

    // MARK: - Biometric Authentication

    private func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            biometricType = .none
            return
        }

        switch context.biometryType {
        case .faceID:
            biometricType = .faceID
        case .touchID:
            biometricType = .touchID
        case .opticID:
            biometricType = .opticID
        case .none:
            biometricType = .none
        @unknown default:
            biometricType = .none
        }
    }

    private func authenticateWithBiometric() {
        let context = LAContext()
        let reason = "Authenticate to continue"

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            Task { @MainActor in
                if success {
                    action()
                } else if let error = error as? LAError {
                    handleBiometricError(error)
                }
            }
        }
    }

    private func handleBiometricError(_ error: LAError) {
        switch error.code {
        case .authenticationFailed:
            errorMessage = "Authentication failed"
        case .userCancel:
            errorMessage = nil
        case .userFallback:
            errorMessage = "User chose password"
        case .biometryNotAvailable:
            errorMessage = "Biometric not available"
        case .biometryNotEnrolled:
            errorMessage = "Biometric not enrolled"
        case .biometryLockout:
            errorMessage = "Biometric locked"
        default:
            errorMessage = "Unknown error"
        }
    }
}

// MARK: - Compatibility Alias

@available(iOS 26.0, macOS 26.0, *)
@available(*, deprecated, renamed: "EduBiometricButton")
public typealias DSBiometricButton = EduBiometricButton
