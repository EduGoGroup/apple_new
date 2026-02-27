import SwiftUI
import EduDomain

// MARK: - Mock Data

/// Datos de ejemplo reutilizables para Xcode Previews.
@MainActor
public enum PreviewMocks {

    // MARK: - Strings

    public static let shortText = "Hola"
    public static let mediumText = "Este es un texto de longitud media para testing"
    public static let longText = """
        Este es un texto muy largo que se utiliza para probar cómo se comportan \
        los componentes cuando tienen contenido extenso. Puede incluir múltiples \
        líneas y varios párrafos para simular contenido real de una aplicación.
        """

    public static let loremIpsum = """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod \
        tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, \
        quis nostrud exercitation ullamco laboris.
        """

    // MARK: - User Data

    public static let userName = "Juan Pérez"
    public static let userEmail = "juan.perez@example.com"
    public static let userInvalidEmail = "invalid-email"

    // MARK: - Lists

    public static let shortList = ["Elemento 1", "Elemento 2", "Elemento 3"]
    public static let mediumList = Array(1...10).map { "Elemento \($0)" }
    public static let longList = Array(1...50).map { "Elemento \($0)" }
    public static let emptyList: [String] = []

    // MARK: - Numbers

    public static let smallNumber = 5
    public static let mediumNumber = 42
    public static let largeNumber = 1_234_567

    public static let percentage = 0.75
    public static let smallPercentage = 0.15
    public static let fullPercentage = 1.0

    // MARK: - Dates

    public static let today = Date()
    public static let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    public static let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
    public static let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    public static let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: Date())!

    // MARK: - URLs

    public static let exampleURL = URL(string: "https://example.com")!
    public static let imageURL = URL(string: "https://picsum.photos/200/300")!

    // MARK: - Colors

    public static let sampleColors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink
    ]

    // MARK: - Errors

    public static let genericError = "Ha ocurrido un error"
    public static let networkError = "Error de conexión. Verifica tu internet."
    public static let validationError = "Los datos ingresados no son válidos"
    public static let notFoundError = "El recurso no fue encontrado"
}

// MARK: - Mock ViewModels

/// Mock ViewModel para simular estado de carga.
@MainActor
@Observable
public final class MockLoadingViewModel {
    public var isLoading: Bool
    public var error: String?
    public var data: [String]

    public init(
        isLoading: Bool = false,
        error: String? = nil,
        data: [String] = []
    ) {
        self.isLoading = isLoading
        self.error = error
        self.data = data
    }

    public func simulateLoading() async {
        isLoading = true
        error = nil
        try? await Task.sleep(for: .seconds(2))
        isLoading = false
        data = PreviewMocks.mediumList
    }

    public func simulateError() {
        isLoading = false
        error = PreviewMocks.networkError
        data = []
    }

    public func simulateSuccess() {
        isLoading = false
        error = nil
        data = PreviewMocks.mediumList
    }
}

/// Mock FormState para simular validación de formularios.
@MainActor
@Observable
public final class MockFormViewModel {
    public var email: String = ""
    public var password: String = ""
    public var isSubmitting: Bool = false
    public var isValid: Bool {
        !email.isEmpty && email.contains("@") && password.count >= 6
    }

    public init() {}

    public func submit() async {
        guard isValid else { return }
        isSubmitting = true
        try? await Task.sleep(for: .seconds(2))
        isSubmitting = false
    }
}

/// Mock ViewModel para simulación de lista con estados.
@MainActor
@Observable
public final class MockListViewModel {
    public enum State {
        case idle
        case loading
        case loaded([String])
        case empty
        case error(String)
    }

    public var state: State = .idle

    public init(state: State = .idle) {
        self.state = state
    }

    public func loadData() async {
        state = .loading
        try? await Task.sleep(for: .seconds(1))

        // Simula resultado aleatorio
        let random = Int.random(in: 0...10)
        if random < 2 {
            state = .error(PreviewMocks.networkError)
        } else if random < 4 {
            state = .empty
        } else {
            state = .loaded(PreviewMocks.mediumList)
        }
    }

    public static var loading: MockListViewModel {
        MockListViewModel(state: .loading)
    }

    public static var loaded: MockListViewModel {
        MockListViewModel(state: .loaded(PreviewMocks.mediumList))
    }

    public static var empty: MockListViewModel {
        MockListViewModel(state: .empty)
    }

    public static var error: MockListViewModel {
        MockListViewModel(state: .error(PreviewMocks.networkError))
    }
}

// MARK: - Mock Bindings

extension Binding where Value == String {
    /// Crea un Binding mock para previews con un valor inicial.
    public static func mock(_ initialValue: String = "") -> Binding<String> {
        return Binding(
            get: { initialValue },
            set: { _ in }
        )
    }
}

extension Binding where Value == Bool {
    /// Crea un Binding mock para previews con un valor inicial.
    public static func mock(_ initialValue: Bool = false) -> Binding<Bool> {
        return Binding(
            get: { initialValue },
            set: { _ in }
        )
    }
}

extension Binding where Value == Int {
    /// Crea un Binding mock para previews con un valor inicial.
    public static func mock(_ initialValue: Int = 0) -> Binding<Int> {
        return Binding(
            get: { initialValue },
            set: { _ in }
        )
    }
}

extension Binding where Value == Double {
    /// Crea un Binding mock para previews con un valor inicial.
    public static func mock(_ initialValue: Double = 0.0) -> Binding<Double> {
        return Binding(
            get: { initialValue },
            set: { _ in }
        )
    }
}

// MARK: - Mock Actions

/// Closure vacía para simular acciones en previews.
@MainActor
public let mockAction: @Sendable () -> Void = { print("Mock action triggered") }

/// Closure async vacía para simular acciones asíncronas.
@MainActor
public let mockAsyncAction: @Sendable () async -> Void = {
    print("Mock async action triggered")
    try? await Task.sleep(for: .seconds(1))
}

// MARK: - Mock FormState

extension FormState {
    /// Crea un FormState mock con validación pre-configurada.
    @MainActor
    public static func mock(isValid: Bool = true) -> FormState {
        let formState = FormState()

        // Registrar campos mock
        formState.registerField("email") {
            ValidationResult(isValid: isValid, errorMessage: isValid ? nil : "Email inválido")
        }

        formState.registerField("password") {
            ValidationResult(isValid: isValid, errorMessage: isValid ? nil : "Contraseña muy corta")
        }

        return formState
    }
}

// MARK: - Example Usage in Comments

/*
 EJEMPLOS DE USO:

 1. Usar texto mock:
 ```swift
 #Preview {
     Text(PreviewMocks.mediumText)
 }
 ```

 2. Usar ViewModel mock:
 ```swift
 #Preview("Loading") {
     MyListView(viewModel: .loading)
 }
 ```

 3. Usar Binding mock:
 ```swift
 #Preview {
     @Previewable @State var text = PreviewMocks.userEmail
     EduTextField("Email", text: $text)
 }
 ```

 4. Usar action mock:
 ```swift
 #Preview {
     EduButton("Presionar", action: mockAction)
 }
 ```

 5. Simular estados de carga:
 ```swift
 #Preview("Estados") {
     VStack {
         MyView(viewModel: MockListViewModel.loading)
         MyView(viewModel: MockListViewModel.loaded)
         MyView(viewModel: MockListViewModel.empty)
         MyView(viewModel: MockListViewModel.error)
     }
 }
 ```
 */
