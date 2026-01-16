// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "swift-binary-parse-support",
    products: [
        .library(
            name: "BinaryParseSupport",
            targets: ["BinaryParseSupport"]
        ),
        .library(
            name: "BinaryParseSupportDynamic",
            type: .dynamic,
            targets: ["BinaryParseSupport"]
        ),
        .library(
            name: "BinaryParseSupportStatic",
            type: .static,
            targets: ["BinaryParseSupport"]
        ),
    ],
    targets: [
        .target(
            name: "BinaryParseSupport"
        ),
        .testTarget(
            name: "BinaryParseSupportTests",
            dependencies: ["BinaryParseSupport"]
        ),
    ]
)
