// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LocalNews",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.7.0"),
    ],
    targets: [
        .executableTarget(
            name: "LocalNews",
            dependencies: [
                .product(name: "SwiftSoup", package: "SwiftSoup"),
            ],
            path: "Sources/LocalNews",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
