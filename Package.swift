// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "zero-kit",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .library(name: "ZeroKit", targets: ["ZeroKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.2.0"),
    ],
    targets: [
        .target(name: "ZeroKit", dependencies: [
            .product(name: "NIO", package: "swift-nio"),
        ]),
        .testTarget(name: "ZeroKitTests", dependencies: [
            .target(name: "ZeroKit"),
        ]),
    ]
)
