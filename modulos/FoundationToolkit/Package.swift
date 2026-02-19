// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift Package Manager required to build this package.

import PackageDescription

let package = Package(
    name: "FoundationToolkit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "FoundationToolkit",
            targets: ["FoundationToolkit"]
        )
    ],
    targets: [
        .target(
            name: "FoundationToolkit",
            path: "Sources/FoundationToolkit",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "FoundationToolkitTests",
            dependencies: ["FoundationToolkit"],
            path: "Tests/FoundationToolkitTests",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
