//===----------------------------------------------------------------------===//
//  Copyright (c) 2025 Javier Cuesta
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//===----------------------------------------------------------------------===//

import Testing

import OpenAPIRuntime
import OpenAPIAsyncHTTPClient
import AsyncHTTPClient
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.URL
import class Foundation.JSONDecoder
import class Foundation.JSONEncoder
import struct Foundation.Data
#endif

import VaultCourier

extension Tag {
    @Tag static var integration: Self
}

@Suite(
    .tags(.integration),
    .enabled(if: enableIntegrationTests()),
    .setupVaultClient()
)
enum IntegrationTests {}

extension IntegrationTests {
    @Suite struct KeyValue {}
    @Suite(.serialized) struct Database {}
    @Suite struct Auth {}
}

extension IntegrationTests.Auth {
    @Suite struct Token {}
    @Suite(.serialized) struct AppRole {}
}

public func enableIntegrationTests() -> Bool {
    guard let rawValue = env("ENABLE_INTEGRATION_TESTS") else { return false }
    if let boolValue = Bool(rawValue) { return boolValue }
    if let intValue = Int(rawValue) { return intValue == 1 }
    return rawValue.lowercased() == "yes"
}

#if Pkl
extension IntegrationTests {
    @Suite(.enabled(if: isPklEnabled())) struct Pkl {}
}

extension IntegrationTests.Pkl {
    @Suite(
        .bug(
            "https://github.com/swiftlang/swift-package-manager/issues/8394",
            "swift test is hanging on GitHub Actions, started in Swift 6.0+"
        )
    ) struct ModuleSourceReader {
        let localApiURL = try! URL(validatingOpenAPIServerURL: "http://127.0.0.1:8200/v1")
        var configuration: VaultClient.Configuration { .init(apiURL: localApiURL) }
    }
}

public func isPklEnabled() -> Bool {
    guard let rawValue = env("PKL_EXEC") else { return false }
    return !rawValue.isEmpty
}
#endif
