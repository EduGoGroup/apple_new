// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "EduInfrastructure",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(name: "EduInfrastructure", targets: ["EduInfrastructure"]),
        // Exponer submodulos individualmente
        .library(name: "EduNetwork", targets: ["EduNetwork"]),
        .library(name: "EduStorage", targets: ["EduStorage"]),
        .library(name: "EduPersistence", targets: ["EduPersistence"])
    ],
    dependencies: [
        .package(path: "../Foundation"),
        .package(path: "../Core")
    ],
    targets: [
        // Target principal que agrupa todo
        .target(
            name: "EduInfrastructure",
            dependencies: [
                "EduNetwork",
                "EduStorage",
                "EduPersistence"
            ],
            path: "Sources/EduInfrastructure"
        ),
        // Submodulos
        .target(
            name: "EduNetwork",
            dependencies: [
                .product(name: "EduFoundation", package: "Foundation"),
                .product(name: "EduCore", package: "Core")
            ],
            path: "Sources/Network"
        ),
        .target(
            name: "EduStorage",
            dependencies: [
                .product(name: "EduFoundation", package: "Foundation"),
                .product(name: "EduCore", package: "Core")
            ],
            path: "Sources/Storage"
        ),
        .target(
            name: "EduPersistence",
            dependencies: [
                .product(name: "EduFoundation", package: "Foundation"),
                .product(name: "EduCore", package: "Core")
            ],
            path: "Sources/Persistence"
        ),
        // Tests
        .testTarget(
            name: "EduInfrastructureTests",
            dependencies: ["EduInfrastructure"],
            path: "Tests/InfrastructureTests"
        )
    ]
)
