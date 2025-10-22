// swift-tools-version:6.1
import PackageDescription

let package = Package(
    name: "ApproleVaporExample",
    platforms: [
       .macOS(.v15)
    ],
    products: [
        .executable(name: "App", targets: ["App"]),
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
        // 🗄 An ORM for SQL and NoSQL databases.
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        // 🐘 Fluent driver for Postgres.
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.8.0"),
        // 🔵 Non-blocking, event-driven networking for Swift. Used for custom executors
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        // 🔐 Client for interacting with Hashicorp Vault and OpenBao
        .package(url: "https://github.com/vault-courier/vault-courier", .upToNextMinor(from: "0.3.0"), traits: ["PklSupport"]),
        // 🚀 Transport type for VaultCourier
        .package(url: "https://github.com/swift-server/swift-openapi-async-http-client.git", from: "1.1.0"),
        // Straightforward, type-safe argument parsing
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.4.0"),
        // Postgres client
        .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.21.0"),
        // 🥒 Swift bindings for Pkl
        .package(url: "https://github.com/apple/pkl-swift", .upToNextMinor(from: "0.6.0"))
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "VaultCourier", package: "vault-courier"),
                .product(name: "OpenAPIAsyncHTTPClient", package: "swift-openapi-async-http-client"),
                .product(name: "PklSwift", package: "pkl-swift")
            ],
            path: "Sources/App",
            swiftSettings: swiftSettings
        ),
        .executableTarget(
            name: "Operations",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "VaultCourier", package: "vault-courier"),
                .product(name: "OpenAPIAsyncHTTPClient", package: "swift-openapi-async-http-client"),
            ],
            path: "Sources/Operations",
        ),
        .executableTarget(
            name: "Migrator",
            dependencies: [
                .product(name: "PostgresNIO", package: "postgres-nio"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "VaultCourier", package: "vault-courier"),
                .product(name: "OpenAPIAsyncHTTPClient", package: "swift-openapi-async-http-client")
            ],
            path: "Sources/Migrator"
        ),
        .testTarget(
            name: "ApproleVaporExampleTests",
            dependencies: [
                .target(name: "App"),
                .product(name: "VaporTesting", package: "vapor"),
            ],
            swiftSettings: swiftSettings
        )
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
] }
