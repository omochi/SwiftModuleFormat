// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "SwiftModuleFormat",
    platforms: [.macOS(.v10_11)],
    products: [
        .library(name: "SwiftModuleFormat", targets: ["SwiftModuleFormat"]),
    ],
    dependencies: [
        .package(url: "https://github.com/omochi/BitcodeFormat.git", from: "1.1.0"),
    ],
    targets: [
        .target(name: "SwiftModuleFormat", dependencies: [
            "BitcodeFormat"]),
        .testTarget(name: "SwiftModuleFormatTests", dependencies: ["SwiftModuleFormat"]),
    ]
)
