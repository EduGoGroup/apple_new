// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "EduCore",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(name: "EduCore", targets: ["EduCore"]),
        .library(name: "EduModels", targets: ["EduModels"]),
        .library(name: "EduLogger", targets: ["EduLogger"]),
        .library(name: "EduUtilities", targets: ["EduUtilities"])
    ],
    dependencies: [
        .package(path: "../Foundation")
    ],
    targets: [
        // Target principal que agrupa todo
        .target(
            name: "EduCore",
            dependencies: [
                "EduModels",
                "EduLogger",
                "EduUtilities"
            ],
            path: "Sources/EduCore"
        ),
        // Submodulos
        .target(
            name: "EduModels",
            dependencies: [
                .product(name: "EduFoundation", package: "Foundation")
            ],
            path: "Sources/Models",
            exclude: ["Validation/README.md"]
        ),
        .target(
            name: "EduLogger",
            dependencies: [
                .product(name: "EduFoundation", package: "Foundation")
            ],
            path: "Sources/Logger",
            exclude: ["Documentation", "Logger.docc"]
        ),
        .target(
            name: "EduUtilities",
            dependencies: [
                .product(name: "EduFoundation", package: "Foundation")
            ],
            path: "Sources/Utilities"
        ),
        // Tests
        .testTarget(
            name: "EduCoreTests",
            dependencies: [
                "EduCore",
                "EduModels",
                "EduLogger",
                "EduUtilities"
            ],
            path: "Tests/CoreTests",
            resources: [
                .copy("Resources/JSON")
            ]
        )
    ]
)
