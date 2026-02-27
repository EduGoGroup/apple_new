import SwiftUI
import DesignSystemSDK

// MARK: - Modal Size

/// Tamaños predefinidos para modales
public enum EduModalSize: Sendable {
    case small
    case medium
    case large
    case fullScreen
    case custom(CGFloat)

    @MainActor
    var height: CGFloat? {
        switch self {
        case .small: return 300
        case .medium: return 500
        case .large: return 700
        case .fullScreen: return nil
        case .custom(let height): return height
        }
    }
}

// MARK: - Modal Content

/// Contenido configurado para un modal
public struct EduModalContent<Content: View>: View {
    public let title: String
    public let size: EduModalSize
    public let showCloseButton: Bool
    public let onDismiss: (@Sendable () -> Void)?
    @ViewBuilder public let content: () -> Content

    public init(
        title: String,
        size: EduModalSize = .medium,
        showCloseButton: Bool = true,
        onDismiss: (@Sendable () -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.size = size
        self.showCloseButton = showCloseButton
        self.onDismiss = onDismiss
        self.content = content
    }

    public var body: some View {
        #if os(iOS) || os(visionOS)
        NavigationView {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.large) {
                    content()
                }
                .padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showCloseButton {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            onDismiss?()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        #elseif os(macOS)
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                if showCloseButton {
                    Button {
                        onDismiss?()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(Color(white: 0.95))

            Divider()

            // Content
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.large) {
                    content()
                }
                .padding()
            }
        }
        .frame(minWidth: 400, minHeight: size.height)
        #endif
    }
}

// MARK: - Modal Presentation Style

public enum EduModalPresentationStyle: Sendable {
    case sheet

    #if os(iOS) || os(visionOS)
    case fullScreenCover
    case pageSheet
    case formSheet
    #endif
}

// MARK: - View Extension

extension View {
    /// Presenta un modal educativo
    public func eduModal<Content: View>(
        isPresented: Binding<Bool>,
        style: EduModalPresentationStyle = .sheet,
        isDismissible: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        Group {
            switch style {
            case .sheet:
                self.sheet(isPresented: isPresented) {
                    content()
                        // MARK: - Keyboard Navigation
                        .dismissOnEscape(isPresented: isPresented, isDismissible: isDismissible)
                }
            #if os(iOS) || os(visionOS)
            case .fullScreenCover:
                self.fullScreenCover(isPresented: isPresented) {
                    content()
                        // MARK: - Keyboard Navigation
                        .dismissOnEscape(isPresented: isPresented, isDismissible: isDismissible)
                }
            case .pageSheet:
                self.sheet(isPresented: isPresented) {
                    content()
                        .presentationDetents([.medium, .large])
                        // MARK: - Keyboard Navigation
                        .dismissOnEscape(isPresented: isPresented, isDismissible: isDismissible)
                }
            case .formSheet:
                self.sheet(isPresented: isPresented) {
                    content()
                        .presentationDetents([.height(600)])
                        // MARK: - Keyboard Navigation
                        .dismissOnEscape(isPresented: isPresented, isDismissible: isDismissible)
                }
            #endif
            }
        }
    }
}

// MARK: - Modal Manager

/// Manager centralizado para mostrar modales en toda la aplicación
@MainActor
@Observable
public final class EduModalManager: Sendable {
    public static let shared = EduModalManager()

    private(set) var isPresented: Bool = false
    private(set) var modalView: AnyView?

    private init() {}

    /// Muestra un modal
    public func show<Content: View>(title: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        modalView = AnyView(content())
        isPresented = true

        // VoiceOver announcement
        let announcement = title != nil ? "Modal opened: \(title!)" : "Modal opened"
        AccessibilityAnnouncements.announce(announcement, priority: .medium)
    }

    /// Oculta el modal actual
    public func dismiss() {
        isPresented = false
        // Delay para permitir la animación de cierre
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            await MainActor.run {
                modalView = nil
            }
        }
    }
}

// MARK: - Modal Overlay Modifier

public struct EduModalOverlayModifier: ViewModifier {
    @State private var modalManager = EduModalManager.shared

    public func body(content: Content) -> some View {
        content
            .sheet(isPresented: Binding(
                get: { modalManager.isPresented },
                set: { if !$0 { modalManager.dismiss() } }
            )) {
                if let modalView = modalManager.modalView {
                    modalView
                }
            }
    }
}

extension View {
    /// Agrega el overlay de modales globales a la vista
    public func eduModalOverlay() -> some View {
        modifier(EduModalOverlayModifier())
    }
}

// MARK: - Bottom Sheet (iOS/visionOS only)

#if os(iOS) || os(visionOS)
/// Bottom sheet con detents personalizables
public struct EduBottomSheet<Content: View>: View {
    @Binding private var isPresented: Bool
    private let detents: Set<PresentationDetent>
    private let content: () -> Content

    public init(
        isPresented: Binding<Bool>,
        detents: Set<PresentationDetent> = [.medium, .large],
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._isPresented = isPresented
        self.detents = detents
        self.content = content
    }

    public var body: some View {
        EmptyView()
            .sheet(isPresented: $isPresented) {
                content()
                    .presentationDetents(detents)
                    .presentationDragIndicator(.visible)
            }
    }
}

extension View {
    /// Presenta un bottom sheet
    public func eduBottomSheet<Content: View>(
        isPresented: Binding<Bool>,
        detents: Set<PresentationDetent> = [.medium, .large],
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            content()
                .presentationDetents(detents)
                .presentationDragIndicator(.visible)
        }
    }
}
#endif

// MARK: - Previews

#Preview("Modal Content") {
    EduModalContent(
        title: "Configuración",
        size: .medium,
        onDismiss: { print("Cerrado") }
    ) {
        VStack(spacing: 16) {
            Text("Contenido del modal")
            Text("Puedes agregar cualquier vista aquí")
            Spacer()
        }
    }
}

#Preview("Modal pequeño") {
    EduModalContent(
        title: "Alerta",
        size: .small,
        onDismiss: { print("Cerrado") }
    ) {
        Text("Este es un modal pequeño")
    }
}

#Preview("Modal grande") {
    EduModalContent(
        title: "Detalles",
        size: .large,
        onDismiss: { print("Cerrado") }
    ) {
        VStack(spacing: 12) {
            ForEach(1..<10) { i in
                Text("Elemento \(i)")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(white: 0.95))
                    .cornerRadius(8)
            }
        }
    }
}

#Preview("Modal sin botón cerrar") {
    EduModalContent(
        title: "Proceso en curso",
        size: .small,
        showCloseButton: false
    ) {
        VStack(spacing: 16) {
            ProgressView()
            Text("Procesando...")
        }
    }
}

#Preview("Dark Mode") {
    EduModalContent(
        title: "Modal oscuro",
        size: .medium,
        onDismiss: {}
    ) {
        Text("Contenido en modo oscuro")
    }
    .preferredColorScheme(.dark)
}
