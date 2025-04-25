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

@testable import VaultCourier

extension Tag {
    @Tag static var integration: Self
    @Tag static var vault: Self
    @Tag static var bao: Self
    @Tag static var postgres: Self
    @Tag static var pkl: Self
}

@Suite(
    .tags(.integration),
    .enabled(if: enableIntegrationTests())
)
enum IntegrationTests {}

extension IntegrationTests {
    @Suite
    struct AsyncHttpClientTransport {
        let localApiURL = try! URL(validatingOpenAPIServerURL: "http://127.0.0.1:8200/v1")
        var configuration: VaultClient.Configuration { .init(apiURL: localApiURL) }
        var authToken: VaultClient.Authentication { .token("integration_token") }

        @Test
        func write_and_read_kv_secret() async throws {
            struct Secret: Codable {
                var apiKey: String
            }
            let key = "dev-secret"
            let secret = Secret(apiKey: "abcde12345")

            let vaultClient = VaultClient(configuration: configuration,
                                          client: Client(
                                            serverURL: localApiURL,
                                            transport: AsyncHTTPClientTransport()
                                          ),
                                          authentication: authToken)
            try await vaultClient.authenticate()

            // MUT
            let response = try await vaultClient.writeKeyValue(secret: secret, key: key)
            #expect(response?.data.version == 1)

            guard let readResponse: Secret = try await vaultClient.readKeyValueSecret(key: key)
            else {
                Issue.record("Failed to read kv secret")
                return
            }

            #expect(readResponse.apiKey == secret.apiKey)
        }
    }
}

public func enableIntegrationTests() -> Bool {
    guard let rawValue = env("ENABLE_INTEGRATION_TESTS") else { return false }
    if let boolValue = Bool(rawValue) { return boolValue }
    if let intValue = Int(rawValue) { return intValue == 1 }
    return rawValue.lowercased() == "yes"
}

public func isPklEnabled() -> Bool {
    guard let rawValue = env("PKL_EXEC") else { return false }
    return !rawValue.isEmpty
}
