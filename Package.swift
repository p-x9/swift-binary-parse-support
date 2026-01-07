// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "swift-binary-parse-support",
    products: [
        .library(
            name: "BinaryParseSupport",
            targets: ["BinaryParseSupport"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/p-x9/swift-fileio.git", from: "0.13.0")
    ],
    targets: [
        .target(
            name: "BinaryParseSupport",
            dependencies: [
                .product(name: "FileIO", package: "swift-fileio")
            ]
        ),
        .testTarget(
            name: "BinaryParseSupportTests",
            dependencies: ["BinaryParseSupport"]
        ),
    ]
)
