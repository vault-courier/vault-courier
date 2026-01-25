// swift-tools-version: 6.1
//  Copyright (c) 2025 Javier Cuesta
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  See LICENSE.txt for license information.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

import PackageDescription
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import class Foundation.ProcessInfo
#endif

// --- This util config is part of `swift-configuration` Package.swift ------------------------------------------------------
// Workaround to ensure that all traits are included in documentation. Swift Package Index adds
// SPI_GENERATE_DOCS (https://github.com/SwiftPackageIndex/SwiftPackageIndex-Server/issues/2336)
// when building documentation, so only tweak the default traits in this condition.
let spiGenerateDocs = ProcessInfo.processInfo.environment["SPI_GENERATE_DOCS"] != nil

// Conditionally add the swift-docc plugin only when previewing docs locally.
// Preview with:
// ```
// SWIFT_PREVIEW_DOCS=1 swift package --disable-sandbox preview-documentation --target VaultCourier
// ```
let previewDocs = ProcessInfo.processInfo.environment["SWIFT_PREVIEW_DOCS"] != nil

let addDoccPlugin = previewDocs || spiGenerateDocs
// Enable all traits for other CI actions.
let enableAllTraitsExplicit = ProcessInfo.processInfo.environment["ENABLE_ALL_TRAITS"] != nil

let enableAllTraits = spiGenerateDocs || previewDocs || enableAllTraitsExplicit
// --------------------------------------------------------------------------------------------

let AppRoleTrait: Trait = .trait(
    name: "AppRoleSupport",
    description: "Enable AppRole authentication"
)

let DatabaseEngineTrait: Trait = .trait(
    name: "DatabaseEngineSupport",
    description: "Enable support for database engine clients"
)

let PostgresDatabasePluginTrait: Trait = .trait(
    name: "PostgresPluginSupport",
    description: "Enable support for Vault's PostgreSQL database plugin HTTP API",
    enabledTraits: .init(arrayLiteral: DatabaseEngineTrait.name)
)

let ValkeyDatabasePluginTrait: Trait = .trait(
    name: "ValkeyPluginSupport",
    description: "Enable support for Vault's Valkey database plugin HTTP API",
    enabledTraits: .init(arrayLiteral: DatabaseEngineTrait.name)
)

let MockTrait: Trait = .trait(
    name: "MockSupport",
    description: "Provides a mock client transport for unit testing and development, and adds Encodable conformance to certain Vault response types."
)

let PklTrait: Trait = .trait(
    name: "PklSupport",
    description: "Enable Pkl Resource Reader. This trait provides PKLSwift.ResourceReader implementations that can read Vault secrets directly from pkl files."
)

let ConfigProviderTrait: Trait = .trait(
    name: "ConfigProviderSupport",
    description: "Enable a Vault configuration provider. This trait provides Configuration.ConfigProvider implementation that can fetch Vault secrets"
)

var traits: Set<Trait> = [
    MockTrait,
    AppRoleTrait,
    DatabaseEngineTrait,
    PostgresDatabasePluginTrait,
    ValkeyDatabasePluginTrait,
    PklTrait,
    ConfigProviderTrait
]

let defaultTraits: Set<String> = .init([
    MockTrait,
    AppRoleTrait,
    DatabaseEngineTrait,
    PostgresDatabasePluginTrait,
    ValkeyDatabasePluginTrait,
].map(\.name))

traits.insert(
    .default(
        enabledTraits: enableAllTraits ? Set(traits.map(\.name)) : defaultTraits
    ),
)

let package = Package(
    name: "vault-courier",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "VaultCourier", targets: ["VaultCourier"]),
    ],
    traits: traits,
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-generator.git", from: "1.10.4"),
        .package(url: "https://github.com/apple/swift-openapi-runtime.git", from: "1.9.0"),
        .package(url: "https://github.com/swift-server/swift-openapi-async-http-client.git", from: "1.3.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.30.3"),
        .package(url: "https://github.com/apple/pkl-swift", .upToNextMinor(from: "0.6.0")),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.9.0"),
        .package(url: "https://github.com/apple/swift-distributed-tracing.git", from: "1.3.1"),
        .package(url: "https://github.com/apple/swift-configuration.git", .upToNextMinor(from: "0.1.1")),
    ],
    targets: [
        .target(
            name: "VaultCourier",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "PklSwift", package: "pkl-swift", condition: .when(traits: [PklTrait.name])),
                .product(name: "Configuration", package: "swift-configuration", condition: .when(traits: [ConfigProviderTrait.name])),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Tracing", package: "swift-distributed-tracing"),
                .target(name: "Utils"),
                // Vault System backend
                .target(name: "SystemWrapping"),
                .target(name: "SystemAuth"),
                .target(name: "SystemPolicies"),
                .target(name: "SystemMounts"),
                // Authentication Methods
                .target(name: "TokenAuth"),
                .target(name: "AppRoleAuth", condition: .when(traits: [AppRoleTrait.name])),
                // Secrets
                .target(name: "KeyValue"),
                .target(name: "DatabaseEngine", condition: .when(traits: [DatabaseEngineTrait.name]))
            ]
        ),
        .target(
            name: "Utils",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime")
            ],
            path: "Sources/Utils"
        ),
        // Auth Methods Targets
        .target(
            name: "AppRoleAuth",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "Logging", package: "swift-log"),
                .target(name: "Utils")
            ],
            path: "Sources/AppRole",
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")
            ]
        ),
        .target(
            name: "TokenAuth",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "Logging", package: "swift-log"),
                .target(name: "Utils")
            ],
            path: "Sources/TokenAuth",
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")
            ]
        ),
        // Backend System Targets
        .target(
            name: "SystemWrapping",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "Logging", package: "swift-log"),
                .target(name: "Utils")
            ],
            path: "Sources/SystemWrapping",
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")
            ]
        ),
        .target(
            name: "SystemAuth",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "Logging", package: "swift-log"),
                .target(name: "Utils")
            ],
            path: "Sources/SystemAuth",
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")
            ]
        ),
        .target(
            name: "SystemPolicies",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "Logging", package: "swift-log"),
                .target(name: "Utils")
            ],
            path: "Sources/SystemPolicies",
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")
            ]
        ),
        .target(
            name: "SystemMounts",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "Logging", package: "swift-log"),
                .target(name: "Utils")
            ],
            path: "Sources/SystemMounts",
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")
            ]
        ),
        // Secret Engines
        .target(
            name: "KeyValue",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "Logging", package: "swift-log"),
                .target(name: "Utils")
            ],
            path: "Sources/KeyValue",
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")
            ]
        ),
        .target(
            name: "DatabaseEngine",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Tracing", package: "swift-distributed-tracing"),
                .target(name: "Utils")
            ],
            path: "Sources/DatabaseEngine",
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")
            ]
        ),
        .testTarget(
            name: "IntegrationTests",
            dependencies: [
                .target(name: "VaultCourier"),
                .product(name: "OpenAPIAsyncHTTPClient", package: "swift-openapi-async-http-client"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Configuration", package: "swift-configuration", condition: .when(traits: [ConfigProviderTrait.name])),
                .product(name: "ConfigurationTesting", package: "swift-configuration", condition: .when(traits: [ConfigProviderTrait.name]))
            ],
            exclude: [
                "Fixtures"
            ]
        ),
        .testTarget(
            name: "VaultCourierTests",
            dependencies: [
                .target(name: "VaultCourier"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Tracing", package: "swift-distributed-tracing"),
                .product(name: "InMemoryTracing", package: "swift-distributed-tracing"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets {
    var settings = target.swiftSettings ?? []

    // https://github.com/apple/swift-evolution/blob/main/proposals/0335-existential-any.md
    // Require `any` for existential types.
    settings.append(.enableUpcomingFeature("ExistentialAny"))

    // https://github.com/swiftlang/swift-evolution/blob/main/proposals/0444-member-import-visibility.md
    settings.append(.enableUpcomingFeature("MemberImportVisibility"))

    // ---- Not possible until swift-openapi supports it -----------------------------------------------
    // https://github.com/swiftlang/swift-evolution/blob/main/proposals/0409-access-level-on-imports.md
//    settings.append(.enableUpcomingFeature("InternalImportsByDefault"))
    // -------------------------------------------------------------------------------------------------

    target.swiftSettings = settings
}

if addDoccPlugin {
    package.dependencies.append(
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.0.0")
    )
}
