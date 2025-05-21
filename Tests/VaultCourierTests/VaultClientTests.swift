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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.URL
#endif

@testable import VaultCourier

@Suite
struct VaultClientTests {
    let localApiURL = try! URL(validatingOpenAPIServerURL: "http://127.0.0.1:8200/v1")

    var configuration: VaultClient.Configuration {
        .init(
            apiURL: localApiURL,
            readerSchema: "vault",
            appRolePath: "approle",
        )
    }

    @Test
    func authenticate_with_token_always_succeds() async throws {
        let vaultClient = VaultClient(configuration: configuration,
                                      client: MockClient(),
                                      authentication: .token("vault_token"))
        let output = try await vaultClient.authenticate()
        #expect(output == true)
    }

    @Test
    func authenticate_with_unwrapped_app_role_secret() async throws {
        let roleId = "59d6d1ca-47bb-4e7e-a40b-8be3bc5a0ba8"
        let secretId = "84896a0c-1347-aa90-a4f6-aca8b7558780"
        var client = MockClient()
        client.authApproleLoginAction = { input in
            #expect(input.headers.xVaultToken == nil)

            return .ok(.init(body: .json(.init(
                requestId: "8e33c808-f86c-cff8-f30a-fbb3ac22c431",
                auth: .init(clientToken: "5b1a0318-679c-9c45-e5c6-d1b9a9035d49",
                            accessor: "fd6c9a00-d2dc-3b11-0be5-af7ae0e1d374",
                            tokenPolicies: ["default"],
                            leaseDuration: 1200,
                            renewable: true,
                            tokenType: .batch,
                            orphan: true,
                            numUses: 0)))))
        }

        let vaultClient = VaultClient(configuration: configuration,
                                      client: client,
                                      authentication: .appRole(credentials: .init(roleID: roleId,
                                                                                  secretID: secretId),
                                                               isWrapped: false))
        let output = try await vaultClient.authenticate()
        #expect(output == true)
    }

    @Test
    func authenticate_with_unwrapped_app_role_secret_and_custom_approle_path() async throws {
        let roleId = "59d6d1ca-47bb-4e7e-a40b-8be3bc5a0ba8"
        let secretId = "84896a0c-1347-aa90-a4f6-aca8b7558780"
        var client = MockClient()
        client.authApproleLoginAction = { input in
            #expect(input.headers.xVaultToken == nil)

            return .ok(.init(body: .json(.init(
                requestId: "8e33c808-f86c-cff8-f30a-fbb3ac22c431",
                auth: .init(clientToken: "5b1a0318-679c-9c45-e5c6-d1b9a9035d49",
                            accessor: "fd6c9a00-d2dc-3b11-0be5-af7ae0e1d374",
                            tokenPolicies: ["default"],
                            leaseDuration: 1200,
                            renewable: true,
                            tokenType: .batch,
                            orphan: true,
                            numUses: 0)))))
        }

        let config = VaultClient.Configuration(
                apiURL: localApiURL,
                readerSchema: "vault",
                appRolePath: "/path/to/approle",
                backgroundActivityLogger: .init(label: "vault-courier-test")
        )
        let vaultClient = VaultClient(configuration: config,
                                      client: client,
                                      authentication: .appRole(credentials: .init(roleID: roleId,
                                                                                  secretID: secretId),
                                                               isWrapped: false))
        let output = try await vaultClient.authenticate()
        #expect(output == true)
    }

    @Test
    func authenticate_with_wrapped_app_role_secret() async throws {
        let roleId = "59d6d1ca-47bb-4e7e-a40b-8be3bc5a0ba8"
        let secretId = "84896a0c-1347-aa90-a4f6-aca8b7558780"
        var client = MockClient()
        client.authApproleLoginAction = { input in
            #expect(input.headers.xVaultToken == nil)

            return .ok(.init(body: .json(.init(
                requestId: "8e33c808-f86c-cff8-f30a-fbb3ac22c431",
                auth: .init(clientToken: "5b1a0318-679c-9c45-e5c6-d1b9a9035d49",
                            accessor: "fd6c9a00-d2dc-3b11-0be5-af7ae0e1d374",
                            tokenPolicies: ["default"],
                            leaseDuration: 1200,
                            renewable: true,
                            tokenType: .batch,
                            orphan: true,
                            numUses: 0)))))
        }
        client.unwrapAction = { input in
            return .ok(.init(body: .json(.init(requestId: "8e33c808-f86c-cff8-f30a-fbb3ac22c4a8",
                                               data: .init(secretIdAccessor: "3a2e9483-a7d2-dc19-7480-b1a025daeccc",
                                                           secretId: "c4086c73-4569-90c9-fd73-72c879e3b7b4",
                                                           secretIdTtl: 3600,
                                                           secretIdNumUses: 40),
                                               wrapInfo: nil))))
        }

        let vaultClient = VaultClient(configuration: configuration,
                                      client: client,
                                      authentication: .appRole(credentials: .init(roleID: roleId,
                                                                                  secretID: secretId),
                                                               isWrapped: true))
        let output = try await vaultClient.authenticate()
        #expect(output == true)
    }

    @Test
    func write_kv_secret_in_default_engine_path() async throws {
        struct Secret: Codable {
            var apiKey: String
        }
        let secret = Secret(apiKey: "abcde12345")
        var client = MockClient()
        client.writeKvSecretsAction = { input in
            return .ok(.init(body: .json(.init(requestId: "8e33c808-f86c-cff8-f30a-fbb3ac22c4a8",
                                               data: .init(createdTime: "2025-01-25T11:28:25.592030964Z",
                                                           deletionTime: nil,
                                                           destroyed: false,
                                                           version: 1)))))
        }

        let vaultClient = VaultClient(configuration: configuration,
                                      client: client,
                                      authentication: .token("vault_token"))
        try await vaultClient.authenticate()
        try await vaultClient.writeKeyValue(secret: secret, key: "dev-secret")
    }
}

