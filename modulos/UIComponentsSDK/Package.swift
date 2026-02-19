// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "UIComponentsSDK",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "UIComponentsSDK", targets: ["UIComponentsSDK"])
    ],
    dependencies: [
        .package(path: "../DesignSystemSDK"),
        .package(path: "../FormsSDK")
    ],
    targets: [
        .target(
            name: "UIComponentsSDK",
            dependencies: ["DesignSystemSDK", "FormsSDK"],
            path: "Sources/UIComponentsSDK",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "UIComponentsSDKTests",
            dependencies: ["UIComponentsSDK"],
            path: "Tests/UIComponentsSDKTests",
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
