// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "Bugsnag",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .library(name: "Bugsnag", targets: ["Bugsnag"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0")
    ],
    targets: [
        .target(name: "Bugsnag", dependencies: [
            .product(name: "Vapor", package: "vapor"),
        ]),
    ]
)
