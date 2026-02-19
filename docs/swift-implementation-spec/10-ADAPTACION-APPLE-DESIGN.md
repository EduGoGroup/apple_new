# 10 - Adaptacion a Apple Design

## 10.1 Principios HIG (Human Interface Guidelines)

La app Swift debe seguir los estandares de Apple, adaptando los conceptos de Dynamic UI a patrones nativos:

- **Usa controles nativos de SwiftUI** (no recrear material design)
- **Respeta las convenciones de plataforma** (back button, swipe gestures, pull-to-refresh)
- **Adapta layouts por size class** (compact/regular)
- **Soporta Dynamic Type** (tamaños de texto accesibles)
- **Soporta Dark Mode** nativo

## 10.2 Mapeo de Patterns a Patrones SwiftUI

### LOGIN → Full Screen con Form

```
NavigationStack {
  VStack {
    // Brand zone
    Image("edugo_logo")
    Text("EduGo").font(.largeTitle)
    Text("Learning made easy").font(.subheadline)

    // Form zone
    Form {
      TextField("Email", text: $email)
        .textContentType(.emailAddress)
        .keyboardType(.emailAddress)
      SecureField("Password", text: $password)
        .textContentType(.password)
      Toggle("Remember me", isOn: $remember)
      Button("Sign In") { ... }
        .buttonStyle(.borderedProminent)
    }
  }
}
```

**Diferencia con KMP**: En iOS, usar `Form` nativo en vez de Column con TextField custom. Aprovechar `.textContentType` para autofill.

### DASHBOARD → ScrollView con Sections

```
ScrollView {
  VStack(alignment: .leading, spacing: 16) {
    // Greeting
    Text("Good morning, \(user.firstName)")
      .font(.largeTitle)
    Text(formattedDate)
      .font(.subheadline)
      .foregroundStyle(.secondary)

    // KPIs → LazyVGrid 2x2
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
      MetricCard(label: "Students", value: stats.totalStudents, icon: "person.2")
      MetricCard(label: "Materials", value: stats.totalMaterials, icon: "folder")
      MetricCard(label: "Avg Score", value: stats.avgScore, icon: "chart.line.uptrend.xyaxis")
      MetricCard(label: "Completion", value: stats.completion, icon: "checkmark.circle")
    }

    // Recent Activity → List
    Section("Recent Activity") {
      ForEach(activities) { activity in
        HStack { ... }
      }
    }

    // Quick Actions → HStack
    HStack {
      Button("Upload Material") { ... }
      Button("View Progress") { ... }
    }
  }
  .padding()
}
.refreshable { await loadData() }
```

**iPad/Mac**: Usar layout de 2 o 3 columnas con `ViewThatFits` o `GeometryReader` para distribuir KPIs y actividad lado a lado.

### LIST → List nativo con Search

```
NavigationStack {
  List {
    ForEach(items) { item in
      NavigationLink(value: item) {
        HStack {
          Image(systemName: item.icon)
          VStack(alignment: .leading) {
            Text(item.title).font(.headline)
            Text(item.subtitle).font(.subheadline).foregroundStyle(.secondary)
          }
          Spacer()
          Text(item.status)
            .font(.caption)
            .padding(.horizontal, 8)
            .background(Capsule().fill(.secondary.opacity(0.2)))
        }
      }
    }
  }
  .searchable(text: $searchText, prompt: "Search materials...")
  .refreshable { await loadData() }
  .overlay {
    if items.isEmpty {
      ContentUnavailableView("No materials yet",
        systemImage: "folder",
        description: Text("Upload your first educational material"))
    }
  }
  .navigationTitle("Materials")
  .toolbar {
    Button(action: { /* navigate to create */ }) {
      Image(systemName: "plus")
    }
  }
}
```

**Diferencias clave con KMP**:
- Usar `.searchable()` nativo en vez de TextField custom
- Usar `ContentUnavailableView` para empty state (iOS 17+)
- Usar `NavigationLink(value:)` con `.navigationDestination`
- Pull-to-refresh via `.refreshable`
- FAB (floating action button) → toolbar button "+" (patron Apple)

### DETAIL → ScrollView con Sections

```
ScrollView {
  VStack(alignment: .leading, spacing: 16) {
    // Hero
    HStack {
      Image(systemName: "doc.fill")
        .font(.system(size: 48))
      Text(detail.status)
        .padding(.horizontal, 8)
        .background(Capsule().fill(.blue.opacity(0.2)))
    }

    // Header
    Text(detail.title).font(.largeTitle)
    Text(detail.subject).font(.body)

    Divider()

    // Details section
    LabeledContent("File Size", value: detail.fileSize)
    LabeledContent("Uploaded", value: detail.createdAt)
    LabeledContent("Status", value: detail.status)

    Divider()

    // Description
    Section("Description") {
      Text(detail.description)
    }

    // Actions
    HStack {
      Button("Download") { ... }
        .buttonStyle(.borderedProminent)
      Button("Take Quiz") { ... }
        .buttonStyle(.bordered)
    }
  }
  .padding()
}
.navigationTitle("Material Detail")
.navigationBarTitleDisplayMode(.inline)
```

### FORM → Form nativo

```
NavigationStack {
  Form {
    Section("Material Details") {
      TextField("Title", text: $title)
      TextField("Subject", text: $subject)
      TextField("Grade", text: $grade)
      TextField("Description", text: $description, axis: .vertical)
        .lineLimit(3...6)
    }
  }
  .navigationTitle("Create Material")
  .toolbar {
    ToolbarItem(placement: .cancellationAction) {
      Button("Cancel") { dismiss() }
    }
    ToolbarItem(placement: .confirmationAction) {
      Button("Create") { await submit() }
        .disabled(title.isEmpty)
    }
  }
}
```

**Diferencia con KMP**: En iOS, los forms usan `Form {}` nativo que da el look de Settings. Los botones van en toolbar, no inline. El cancel/submit estan en la navigation bar.

### SETTINGS → Form con Sections

```
Form {
  Section {
    HStack {
      Avatar(initials: user.initials)
      VStack(alignment: .leading) {
        Text(user.fullName).font(.headline)
        Text(user.email).font(.subheadline).foregroundStyle(.secondary)
      }
    }
  }

  Section("Appearance") {
    Toggle("Dark Mode", isOn: $isDarkMode)
    NavigationLink("Theme Color") { ThemePickerView() }
  }

  Section("Notifications") {
    Toggle("Push Notifications", isOn: $pushEnabled)
    Toggle("Email Notifications", isOn: $emailEnabled)
  }

  Section("Account") {
    NavigationLink("Change Password") { ... }
    NavigationLink("Language") { ... }
  }

  Section("About") {
    LabeledContent("Version", value: "1.0.0")
    NavigationLink("Privacy Policy") { ... }
    NavigationLink("Terms of Service") { ... }
  }

  Section {
    Button("Sign Out", role: .destructive) { ... }
  }
}
.navigationTitle("Settings")
```

## 10.3 Platform Overrides para Apple

### iPhone (ios override)
- Distribution: `stacked` (todo en columna)
- No maxWidth (full width)
- Sheets modales para crear/editar (en vez de push)

### iPad (ios o desktop override)
- Distribution: `side-by-side` para detail
- Master-detail con NavigationSplitView
- Popovers para acciones rapidas

### Mac (desktop override)
- Distribution: `side-by-side` o `three-panel`
- Sidebar permanente
- Inspector panel lateral para detalles
- Menu bar items

## 10.4 Componentes Apple Nativos Recomendados

| Concepto Dynamic UI | Componente Apple |
|---------------------|-----------------|
| metric-card | Custom card view |
| chip (filtro) | Picker con .segmented o Buttons con capsule |
| search-bar | .searchable() modifier |
| empty-state | ContentUnavailableView |
| pull-refresh | .refreshable {} |
| FAB | toolbar button |
| snackbar | .alert() o custom toast |
| confirm dialog | .confirmationDialog() |
| loading | ProgressView() |
| list item | Label, LabeledContent, NavigationLink |
| switch | Toggle |
| divider | Divider() |
| avatar | Circle clip con AsyncImage |

## 10.5 Gestos y Interacciones Apple

| Interaction | Implementacion |
|-------------|---------------|
| Pull to refresh | `.refreshable { }` |
| Swipe actions | `.swipeActions { }` en List rows |
| Long press | `.contextMenu { }` |
| Search | `.searchable(text:)` |
| Back navigation | Automatico con NavigationStack |
| Sheet/Modal | `.sheet(isPresented:)` |
| Confirmation | `.confirmationDialog()` |
| Alert | `.alert()` |

## 10.6 Accesibilidad

- **Dynamic Type**: Todos los textos deben usar Font.TextStyle (no tamaños fijos)
- **VoiceOver**: Labels descriptivos en todos los controles
- **Reduce Motion**: Respetar `.accessibilityReduceMotion`
- **Color Contrast**: Suficiente contraste en light y dark mode

## 10.7 State Management Recomendado

| Concepto KMP | Equivalente Swift |
|-------------|-------------------|
| StateFlow | @Published / @Observable |
| collectAsState | @StateObject / @EnvironmentObject |
| ViewModel | @Observable class |
| Koin DI | SwiftUI Environment / Swinject / manual DI |
| Coroutine scope | Task / async-await |
| Mutex | actor |
| SharedFlow (events) | AsyncSequence / NotificationCenter / Combine |

## 10.8 Estructura de Proyecto Sugerida

```
EduGo-Apple/
├── App/
│   ├── EduGoApp.swift
│   └── AppDelegate.swift (si necesario)
├── Core/
│   ├── Auth/
│   │   ├── AuthService.swift
│   │   ├── TokenRefreshManager.swift
│   │   ├── Models/ (AuthToken, AuthUserInfo, UserContext, etc.)
│   │   └── Resilience/ (CircuitBreaker, RateLimiter, RetryPolicy)
│   ├── Network/
│   │   ├── APIClient.swift
│   │   ├── DualAPIRouter.swift
│   │   ├── AuthInterceptor.swift
│   │   └── Models/ (request/response types)
│   └── Storage/
│       ├── KeychainService.swift
│       └── CacheManager.swift
├── DynamicUI/
│   ├── Models/ (ScreenDefinition, Zone, Slot, Action, etc.)
│   ├── Loader/
│   │   ├── ScreenLoader.swift
│   │   ├── DataLoader.swift
│   │   └── CachedScreenLoader.swift
│   ├── Renderers/
│   │   ├── PatternRouter.swift
│   │   ├── LoginRenderer.swift
│   │   ├── DashboardRenderer.swift
│   │   ├── ListRenderer.swift
│   │   ├── DetailRenderer.swift
│   │   ├── FormRenderer.swift
│   │   ├── SettingsRenderer.swift
│   │   ├── ZoneRenderer.swift
│   │   └── SlotRenderer.swift
│   ├── Actions/
│   │   ├── ActionRegistry.swift
│   │   ├── ScreenHandlerRegistry.swift
│   │   └── Handlers/ (LoginHandler, CrudHandlers, etc.)
│   ├── Resolvers/
│   │   ├── SlotBindingResolver.swift
│   │   └── PlaceholderResolver.swift
│   └── ViewModels/
│       └── DynamicScreenViewModel.swift
├── Screens/
│   ├── MainScreen.swift (app shell)
│   ├── DynamicScreen.swift (generic renderer)
│   ├── DynamicDashboardScreen.swift
│   └── Navigation/
│       └── AdaptiveNavigationLayout.swift
├── DesignSystem/
│   ├── Components/ (buttons, cards, inputs, etc.)
│   ├── Theme.swift
│   └── IconMapper.swift
└── Resources/
    └── Assets.xcassets
```

## 10.9 Soporte Minimo de OS

Recomendado:
- **iOS 17+** (para ContentUnavailableView, @Observable, etc.)
- **iPadOS 17+**
- **macOS 14+ (Sonoma)** (si Mac Catalyst) o **macOS 15+ (Sequoia)** (si SwiftUI nativo)

Esto permite usar las APIs mas modernas de SwiftUI sin workarounds.
