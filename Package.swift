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

let package = Package(
    name: "vault-courier",
    platforms: [.macOS(.v15), .iOS(.v18), .visionOS(.v2), .tvOS(.v18), .watchOS(.v11)],
    products: [
        .library(name: "VaultCourier", targets: ["VaultCourier"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-generator.git", from: "1.7.2"),
        .package(url: "https://github.com/apple/swift-openapi-runtime.git", from: "1.7.0"),
        .package(url: "https://github.com/swift-server/swift-openapi-async-http-client.git", from: "1.1.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.25.0"),
        .package(url: "https://github.com/apple/pkl-swift", from: "0.4.1"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.4")
    ],
    targets: [
        .target(
            name: "VaultCourier",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIAsyncHTTPClient", package: "swift-openapi-async-http-client"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "PklSwift", package: "pkl-swift"),
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
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
