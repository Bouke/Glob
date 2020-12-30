// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "Glob",
    products: [
        .library(
            name: "Glob",
            targets: ["Glob"]),
    ],
    targets: [
        .target(
            name: "Glob",
            dependencies: []),
        .testTarget(
            name: "GlobTests",
            dependencies: ["Glob"]),
    ]
)
