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
    targets: [
        .target(name: "ZeroKit"),
        .testTarget(name: "ZeroKitTests", dependencies: [
            .target(name: "ZeroKit"),
        ]),
    ]
)
