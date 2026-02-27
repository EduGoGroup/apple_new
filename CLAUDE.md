# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Platform & Toolchain — Non-negotiable

- **Swift tools version**: 6.2 everywhere (`// swift-tools-version: 6.2`)
- **Deployment targets**: iOS 26, macOS 26, iPadOS 26 — nothing lower, ever
- **Xcode 26** required
- **UI paradigm**: Liquid Glass (iOS 26 / macOS 26 native design system)
- No deprecated APIs, no backwards-compatibility shims

## Commands

```bash
# Run DemoApp (macOS, staging by default)
make run
make run-dev          # development (localhost)
make run-prod         # production

# Build without running
make build

# Run all tests from root
make test             # equivalente a: swift test

# Run tests for a single package
cd Packages/Foundation && swift test
cd Packages/Infrastructure && swift test

# Run tests for modulos/ (standalone SDKs)
cd modulos/NetworkSDK && swift test

# Clean build artifacts
make clean
```

To run a single test suite or test: use `swift test --filter <TestSuiteName>` from within the relevant package directory.

## Architecture

The project has two zones:

### `Packages/` — Main 6-tier SPM hierarchy

Strict one-way dependency chain:

```
EduFoundation → EduCore → EduInfrastructure → EduDomain → EduPresentation → EduFeatures
                                          ↘ EduDynamicUI ↗
```

| Package | Product(s) | Responsibility |
|---|---|---|
| `Packages/Foundation` | `EduFoundation` | Base types, error protocols, entity base |
| `Packages/Core` | `EduCore`, `EduModels`, `EduLogger`, `EduUtilities` | DTOs, domain models, mappers, validation, logger, `APIConfiguration`, `AppEnvironment`. `EduCore` re-exports all submodules via `@_exported import` |
| `Packages/Infrastructure` | `EduNetwork`, `EduStorage`, `EduPersistence` | `NetworkClient` (actor), interceptor chain, `CircuitBreaker`, `RateLimiter`, SwiftData persistence |
| `Packages/Domain` | `EduDomain` | Use cases, CQRS, state machines, state management via `AsyncSequence`/`AsyncStream` |
| `Packages/Presentation` | `EduPresentation` | `@Observable` ViewModels, coordinator navigation, validators, design system |
| `Packages/Features` | `EduFeatures` | AI integration, analytics |
| `Packages/DynamicUI` | `EduDynamicUI` | Server-Driven UI: `ScreenLoader` (LRU cache + ETag), `DataLoader` (dual-API routing), resolvers |

Root `Package.swift` exposes an `EduGoModulesUmbrella` product that re-exports all packages.

### `modulos/` — Standalone SDK packages

Independent packages: `CQRSKit`, `DesignSystemSDK`, `FormsSDK`, `FoundationToolkit`, `LoggerSDK`, `NetworkSDK`, `UIComponentsSDK`. All use `swift-tools-version: 6.2`, iOS 26 / macOS 26.

### `Apps/DemoApp`

Executable app that imports from `Packages/`. Uses a `ServiceContainer` with two `NetworkClient` instances:
- Plain client (no interceptors) → `AuthService`
- Authenticated client (with `AuthenticationInterceptor`) → `ScreenLoader`, `DataLoader`

`AppEnvironment` is detected from `EDUGO_ENVIRONMENT` env var; defaults to `.development` in DEBUG builds.

## Swift 6.2 Concurrency Rules

**`@Observable`**: Always. Never `@Published`, `@ObservableObject`, or `@EnvironmentObject`.

**`actor`**: Use for thread-safe shared state. All concurrent abstractions (`NetworkClient`, `ScreenLoader`, `DataLoader`, `CircuitBreaker`, `RateLimiter`) are actors.

**`@MainActor`**: Apply to ViewModels, `ServiceContainer`, and any type that drives UI updates.

**`async/await` + `AsyncSequence`/`AsyncStream`**: Only concurrency primitives allowed. No Combine, no NotificationCenter.

**`nonisolated` is banned** — never use it as a workaround. Correct alternatives:
- Method that does not access actor state → make it `static func` (example: `isValidTransition` in state machines)
- Stored `let` on an actor that callers need synchronously → accept `await` at call site, or pass the value at construction so callers hold it directly

**`nonisolated(unsafe)`**: Also banned.

## Key Patterns

**Networking**: `HTTPRequest` builder pattern (fluent, immutable struct). `NetworkClientProtocol` is the abstraction; `NetworkClient` is the `actor` implementation. Interceptors conform to `RequestInterceptor`.

**DTOs**: All API response types have explicit `CodingKeys` with snake_case mapping. Use `CodableSerializer.dtoSerializer` for encoding/decoding.

**Tests**: Swift Testing framework exclusively — `@Suite`, `@Test`, `#expect`. No XCTest.

**DynamicUI resolvers**: `SlotBindingResolver` resolves data bindings (field > bind slot: > value). `PlaceholderResolver` handles `{user.*}`, `{context.*}`, `{item.*}`, date tokens.

## JSONValue — Single Source of Truth

`JSONValue` lives exclusively in `EduModels` (`Packages/Core/Sources/Models/Support/JSONValue.swift`). Conforms to `Codable + Sendable + Hashable`. Cases: `.string`, `.integer(Int)`, `.double`, `.bool`, `.object`, `.array`, `.null`. Note the integer case is `.integer`, not `.int`.

`EduCore` re-exports `EduModels` via `@_exported import`, so any module importing `EduCore` gets `JSONValue` automatically — no qualification needed.

Helper properties (`intValue`, `stringValue`, `boolValue`, `objectValue`, `arrayValue`, `stringRepresentation`) are in `EduDynamicUI/Utilities/JSONValue+Extensions.swift`. `doubleValue` and `isNull` are on the canonical definition in `EduModels`.

Do **not** redefine `JSONValue` in any other module.
