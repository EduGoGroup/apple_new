// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "EduGoModules",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        // Umbrella para importar todo de una vez
        .library(name: "EduGoModules", targets: ["EduGoModulesUmbrella"])
    ],
    dependencies: [
        .package(path: "Packages/Foundation"),
        .package(path: "Packages/Core"),
        .package(path: "Packages/Infrastructure"),
        .package(path: "Packages/Domain"),
        .package(path: "Packages/Presentation"),
        .package(path: "Packages/Features")
    ],
    targets: [
        // Umbrella target que reexporta todos los modulos
        .target(
            name: "EduGoModulesUmbrella",
            dependencies: [
                .product(name: "EduFoundation", package: "Foundation"),
                .product(name: "EduCore", package: "Core"),
                .product(name: "EduInfrastructure", package: "Infrastructure"),
                .product(name: "EduDomain", package: "Domain"),
                .product(name: "EduPresentation", package: "Presentation"),
                .product(name: "EduFeatures", package: "Features")
            ]
        )
    ]
)
