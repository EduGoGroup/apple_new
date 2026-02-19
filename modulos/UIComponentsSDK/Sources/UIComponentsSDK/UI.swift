/// Módulo UI de EduGo
///
/// Proporciona componentes reutilizables de UI para aplicaciones multi-plataforma
/// Apple (iOS, macOS).
///
/// ## Componentes Disponibles
///
/// ### Input
/// - ``EduTextField`` - Campo de texto con validación integrada
/// - ``EduSecureField`` - Campo de contraseña con toggle show/hide
/// - ``EduSearchField`` - Campo de búsqueda con debounce
/// - ``EduButton`` - Botón con variantes de estilo y estados
/// - ``ButtonStyle+Edu`` - Estilos de botón reutilizables
///
/// ## Características
/// - ✅ Swift 6.2 con Strict Concurrency
/// - ✅ Integración con módulo Binding
/// - ✅ Soporte multi-plataforma (iOS 26+, macOS 26+)
/// - ✅ Previews interactivos
/// - ✅ Accesibilidad integrada
///
/// ## Ejemplo de Uso
///
/// ```swift
/// import SwiftUI
/// import UI
/// import Binding
///
/// struct LoginView: View {
///     @State private var email = ""
///     @State private var password = ""
///     @State private var formState = FormState()
///
///     var body: some View {
///         VStack(spacing: 16) {
///             EduTextField(
///                 "Email",
///                 text: $email,
///                 validation: Validators.email(),
///                 formState: formState,
///                 fieldKey: "email"
///             )
///
///             EduSecureField(
///                 "Contraseña",
///                 text: $password,
///                 validation: Validators.password(),
///                 formState: formState,
///                 fieldKey: "password"
///             )
///
///             EduButton.primary("Iniciar Sesión") {
///                 Task {
///                     await formState.submit {
///                         try await login(email: email, password: password)
///                     }
///                 }
///             }
///         }
///         .padding()
///     }
/// }
/// ```

import Foundation

/// Versión del módulo UI
public let UIVersion = "1.0.0"
