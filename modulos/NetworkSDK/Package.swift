// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NetworkSDK",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "NetworkSDK", targets: ["NetworkSDK"])
    ],
    dependencies: [
        .package(path: "../FoundationToolkit")
    ],
    targets: [
        .target(
            name: "NetworkSDK",
            dependencies: ["FoundationToolkit"],
            path: "Sources/NetworkSDK",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "NetworkSDKTests",
            dependencies: ["NetworkSDK"],
            path: "Tests/NetworkSDKTests",
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
