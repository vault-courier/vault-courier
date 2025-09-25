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
    @Suite struct Auth {}
    @Suite struct SecretEngine {}
    @Suite struct System {}
}

extension IntegrationTests.Auth {
    @Suite struct Token {}
    @Suite(.serialized) struct AppRole {}
}

extension IntegrationTests.SecretEngine {
    @Suite struct KeyValue {}
}

#if DatabaseEngineSupport
extension IntegrationTests.SecretEngine {
    @Suite(.serialized) struct Database {}
}

extension IntegrationTests.SecretEngine.Database {
    @Suite struct Postgres {}
    @Suite struct Valkey {}
}
#endif

extension IntegrationTests.System {
    @Suite struct Wrapping {}
    @Suite struct Auth {}
    @Suite struct Policies {}
    @Suite struct Mounts {}
}

public func enableIntegrationTests() -> Bool {
    guard let rawValue = env("ENABLE_INTEGRATION_TESTS") else { return false }
    if let boolValue = Bool(rawValue) { return boolValue }
    if let intValue = Int(rawValue) { return intValue == 1 }
    return rawValue.lowercased() == "yes"
}

#if PklSupport
extension IntegrationTests {
    @Suite struct Pkl {}
}

public func isPklEnabled() -> Bool {
    guard let rawValue = env("PKL_EXEC") else { return false }
    return !rawValue.isEmpty
}
#endif
