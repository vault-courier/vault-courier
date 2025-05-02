// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "VaultDynamicRole",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/vault-courier/vault-courier", branch: "main"),
        .package(url: "https://github.com/swift-server/swift-openapi-async-http-client.git", from: "1.1.0")
    ],
    targets: [
        .executableTarget(
            name: "VaultDynamicRole",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "VaultCourier", package: "vault-courier"),
                .product(name: "OpenAPIAsyncHTTPClient", package: "swift-openapi-async-http-client")
            ]
        ),
    ]
)
