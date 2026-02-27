// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "CQRSKit",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "CQRSKit",
            targets: ["CQRSKit"]
        )
    ],
    targets: [
        .target(
            name: "CQRSKit",
            path: "Sources/CQRSKit"
        ),
        .testTarget(
            name: "CQRSKitTests",
            dependencies: ["CQRSKit"],
            path: "Tests/CQRSKitTests"
        )
    ]
)
