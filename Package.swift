// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NetBIOSClient",
    platforms: [
      .macOS(.v13),
      .iOS(.v16)
    ],
    products: [
        .library(
            name: "NetBIOSClient",
            targets: ["NetBIOSClient"]),
    ],
    targets: [
        .target(
            name: "NetBIOSClient"),
        .testTarget(
            name: "NetBIOSClientTests",
            dependencies: ["NetBIOSClient"]
        ),
    ]
)
