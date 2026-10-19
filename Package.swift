// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "Logsmith",
    platforms: [
        .macOS(.v27)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.76.0")
    ],
    targets: [
        .target(
            name: "LogsmithCore",
            dependencies: [
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio")
            ]
        ),
        .executableTarget(
            name: "Logsmith",
            dependencies: ["LogsmithCore"]
        ),
        .testTarget(
            name: "LogsmithCoreTests",
            dependencies: ["LogsmithCore"]
        )
    ],
    swiftLanguageModes: [.v6]
)
