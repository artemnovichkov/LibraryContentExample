// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Components",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "Components", targets: ["Components"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", exact: "600.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    ],
    targets: [
        .target(name: "Components"),
        .plugin(
            name: "GenerateLibraryContent",
            capability: .command(
                intent: .custom(
                    verb: "generate-library-content",
                    description: "Generate LibraryContent"),
                permissions: [.writeToPackageDirectory(reason: "Generate LibraryContent")]),
            dependencies: [
                .target(name: "generate-library-content")
            ]),
        .executableTarget(
            name: "generate-library-content",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax")
            ]
        ),
    ]
)
