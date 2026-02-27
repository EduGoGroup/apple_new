// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "FoundationToolkit",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
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
            path: "Sources/FoundationToolkit"
        ),
        .testTarget(
            name: "FoundationToolkitTests",
            dependencies: ["FoundationToolkit"],
            path: "Tests/FoundationToolkitTests"
        )
    ]
)
