// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "WalletSDK",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "WalletSDK",
            targets: ["WalletSDK"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Boilertalk/Web3.swift", from: "0.8.0"),
    ],
    targets: [
        .target(
            name: "WalletSDK",
            dependencies: [
                .product(name: "Web3", package: "Web3.swift"),
            ]),
        .testTarget(
            name: "WalletSDKTests",
            dependencies: ["WalletSDK"]),
    ]
)
