// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "SpotSQLite",
    products: [
        .library(
            name: "SpotSQLite",
            targets: ["SpotSQLite"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "SpotSQLite",
            dependencies: []),
    ]
)
