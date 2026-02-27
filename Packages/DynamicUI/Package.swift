// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "EduDynamicUI",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(name: "EduDynamicUI", targets: ["EduDynamicUI"])
    ],
    dependencies: [
        .package(path: "../Foundation"),
        .package(path: "../Core"),
        .package(path: "../Infrastructure")
    ],
    targets: [
        .target(
            name: "EduDynamicUI",
            dependencies: [
                .product(name: "EduFoundation", package: "Foundation"),
                .product(name: "EduModels", package: "Core"),
                .product(name: "EduNetwork", package: "Infrastructure")
            ],
            path: "Sources/DynamicUI"
        ),
        .testTarget(
            name: "EduDynamicUITests",
            dependencies: [
                "EduDynamicUI",
                .product(name: "EduModels", package: "Core"),
                .product(name: "EduNetwork", package: "Infrastructure")
            ],
            path: "Tests/DynamicUITests"
        )
    ]
)
