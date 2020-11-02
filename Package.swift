// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "leaf-x",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .library(name: "LeafX", targets: ["LeafX"]),
    ],
    targets: [
        .target(name: "LeafX"),
        .testTarget(name: "LeafXTests", dependencies: [
            .target(name: "LeafX"),
        ]),
    ]
)
