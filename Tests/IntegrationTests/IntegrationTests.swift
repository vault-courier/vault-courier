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

@Suite(
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

    #if AppRoleSupport
    @Suite struct AppRole {}
    #endif
}

extension IntegrationTests.SecretEngine {
    @Suite struct KeyValue {}
}

#if DatabaseEngineSupport
extension IntegrationTests.SecretEngine {
    @Suite(.serialized) struct Database {}
}

extension IntegrationTests.SecretEngine.Database {
    #if PostgresPluginSupport
    @Suite struct Postgres {}
    #endif

    #if ValkeyPluginSupport
    @Suite struct Valkey {}
    #endif
}
#endif

#if TransitEngineSupport
extension IntegrationTests.SecretEngine {
    @Suite(.setupSecretEngine(type: "transit", mountPath: "custom")) struct Transit {}
}
#endif

extension IntegrationTests.System {
    @Suite struct Wrapping {}
    @Suite struct Auth {}
    @Suite struct Policies {}
    @Suite struct Mounts {}
    @Suite struct Namespaces {}
}

#if PklSupport
extension IntegrationTests {
    static let localPklExecPath = "/opt/homebrew/bin/pkl"

    @Suite(
        .setupPkl(execPath: env("PKL_EXEC") ?? Self.localPklExecPath)
    ) struct Pkl {
        @Suite
        struct SecretReaders {}

        struct Payloads {}
    }
}
#endif

#if ConfigProviderSupport
extension IntegrationTests {
    @Suite struct VaultConfigProvider {}
}
#endif
