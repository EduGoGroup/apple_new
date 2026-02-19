// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DesignSystemSDK",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "DesignSystemSDK", targets: ["DesignSystemSDK"])
    ],
    targets: [
        .target(
            name: "DesignSystemSDK",
            path: "Sources/DesignSystemSDK",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "DesignSystemSDKTests",
            dependencies: ["DesignSystemSDK"],
            path: "Tests/DesignSystemSDKTests",
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
