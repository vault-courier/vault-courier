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
    name: "Pkl",
    description: "Enable Pkl Resource Reader. This trait provides PKLSwift.ResourceReader implementations that can read Vault secrets directly from pkl files."
)

let package = Package(
    name: "vault-courier",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "VaultCourier", targets: ["VaultCourier"]),
    ],
    traits: [
        PklTrait,
        .default(enabledTraits: .init([PklTrait.name]))
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-generator.git", from: "1.7.2"),
        .package(url: "https://github.com/apple/swift-openapi-runtime.git", from: "1.7.0"),
        .package(url: "https://github.com/swift-server/swift-openapi-async-http-client.git", from: "1.1.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.25.0"),
        .package(url: "https://github.com/apple/pkl-swift", from: "0.4.2"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.4")
    ],
    targets: [
        .target(
            name: "VaultCourier",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "PklSwift", package: "pkl-swift", condition: .when(traits: [PklTrait.name])),
                .product(name: "Logging", package: "swift-log"),
            ],
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")
            ]
        ),
        .testTarget(
            name: "VaultCourierTests",
            dependencies: [
                "VaultCourier",
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
