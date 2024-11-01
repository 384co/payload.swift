// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Payload",
    platforms: [
        .macOS(.v13),      // macOS Big Sur or later
        .iOS(.v16),        // iOS or later
        .tvOS(.v16)        // tvOS or later
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Payload",
            targets: ["Payload"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Payload"),
        .testTarget(
            name: "PayloadTests",
            dependencies: ["Payload"],
            resources: [
                .process("TestData")  // Include the TestData folder
            ]
        ),
    ]
)
