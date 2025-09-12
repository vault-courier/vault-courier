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

let PklTrait: Trait = .trait(
    name: "PklSupport",
    description: "Enable Pkl Resource Reader. This trait provides PKLSwift.ResourceReader implementations that can read Vault secrets directly from pkl files."
)

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

let package = Package(
    name: "vault-courier",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "VaultCourier", targets: ["VaultCourier"]),
    ],
    traits: [
        PklTrait,
        AppRoleTrait,
        DatabaseEngineTrait,
        PostgresDatabasePluginTrait,
        ValkeyDatabasePluginTrait,
        .default(enabledTraits: [
            AppRoleTrait.name,
            DatabaseEngineTrait.name,
            PostgresDatabasePluginTrait.name,
            ValkeyDatabasePluginTrait.name,
            PklTrait.name,
        ])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-generator.git", from: "1.7.2"),
        .package(url: "https://github.com/apple/swift-openapi-runtime.git", from: "1.7.0"),
        .package(url: "https://github.com/swift-server/swift-openapi-async-http-client.git", from: "1.1.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.25.0"),
        .package(url: "https://github.com/apple/pkl-swift", from: "0.4.2"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.4"),
//        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "VaultCourier",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "PklSwift", package: "pkl-swift", condition: .when(traits: [PklTrait.name])),
                .product(name: "Logging", package: "swift-log"),
                .target(name: "VaultUtilities"),
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
                .target(name: "DatabaseEngine", condition: .when(traits: [DatabaseEngineTrait.name])),
            ],
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")
            ]
        ),
        .target(
            name: "VaultUtilities",
            dependencies: [],
            path: "Sources/VaultUtilities"
        ),
        // Auth Methods Targets
        .target(
            name: "AppRoleAuth",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "Logging", package: "swift-log"),
                .target(name: "VaultUtilities")
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
                .target(name: "VaultUtilities")
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
                .target(name: "VaultUtilities")
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
                .target(name: "VaultUtilities")
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
                .target(name: "VaultUtilities")
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
                .target(name: "VaultUtilities")
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
                .target(name: "VaultUtilities")
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
                .target(name: "VaultUtilities")
            ],
            path: "Sources/DatabaseEngine",
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")
            ]
        ),
        .testTarget(
            name: "VaultCourierTests",
            dependencies: [
                .target(name: "VaultCourier"),
                .product(name: "OpenAPIAsyncHTTPClient", package: "swift-openapi-async-http-client"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
            ],
            exclude: [
                "Fixtures"
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
