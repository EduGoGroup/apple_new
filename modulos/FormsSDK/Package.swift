// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FormsSDK",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "FormsSDK", targets: ["FormsSDK"])
    ],
    targets: [
        .target(
            name: "FormsSDK",
            path: "Sources/FormsSDK",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "FormsSDKTests",
            dependencies: ["FormsSDK"],
            path: "Tests/FormsSDKTests",
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
