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

#if AppRoleSupport
import Testing

import OpenAPIAsyncHTTPClient
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.URL
#endif

import VaultCourier

extension IntegrationTests.Auth.AppRole {
    var randomMountPath: String {
        let suffix = "abcdefghijklmnopqrstuvwxyz".randomSample(count: 10).map { String($0) }.joined()
        let path = "approle_\(suffix)"
        return path
    }

    @Test
    func enable_approle_at_custom_path() async throws {
        let vaultClient = VaultClient.current

        let path = randomMountPath
        try await vaultClient.enableAuthMethod(configuration: .init(path: path, type: "approle"))

        let config = try await vaultClient.readAuthMethodConfiguration(path)

        #expect(config.authMethod == "approle")

        try await vaultClient.disableAuthMethod(path)
    }

    @Test
    func crud_approle() async throws {
        let vaultClient = VaultClient.current

        let path = randomMountPath
        try await vaultClient.enableAuthMethod(configuration: .init(path: path, type: "approle"))

        let appRoleName = "batch_role_1"
        try await vaultClient.createAppRole(.init(name: appRoleName,
                                                  tokenPolicies: [],
                                                  tokenTimeToLive: .seconds(60*60),
                                                  tokenType: .batch),
                                            mountPath: path)

        let appRole = try await vaultClient.readAppRole(name: appRoleName, mountPath: path)

        #expect(appRole.tokenType == .batch)

        await #expect(throws: Never.self) {
            _ = try await vaultClient.appRoleID(name: appRoleName, mountPath: path)
        }

        let generateAppSecretIdResponse = try await vaultClient.generateAppSecretID(
            capabilities: .init(roleName: appRoleName),
            mountPath: path
        )

        switch generateAppSecretIdResponse {
            case .wrapped:
                Issue.record("Receive unexpected response: \(generateAppSecretIdResponse)")
            case .secretId(let secretIdResponse):
                #expect(secretIdResponse.secretIDNumberOfUses == 0)
        }

        try await vaultClient.deleteAppRole(name: appRoleName, mountPath: path)

        try await vaultClient.disableAuthMethod(path)
    }

    @Test
    func unwrapped_login() async throws {
        let vaultClient = VaultClient.current

        let path = randomMountPath
        try await vaultClient.enableAuthMethod(configuration: .init(path: path, type: "approle"))

        let appRoleName = "batch_role_2"
        try await vaultClient.createAppRole(.init(name: appRoleName,
                                                  tokenPolicies: [],
                                                  tokenTimeToLive: .seconds(60*60),
                                                  tokenType: .batch),
                                            mountPath: path)

        let appRoleID = try await vaultClient.appRoleID(name: appRoleName, mountPath: path).roleID
        let secretIDResponse = try await vaultClient.generateAppSecretID(
            capabilities: .init(roleName: appRoleName),
            mountPath: path
        )

        switch secretIDResponse {
            case .wrapped(let wrappedResponse):
                Issue.record("Receive unexpected response: \(wrappedResponse)")
            case .secretId(let response):
                // MUT
                await #expect(throws: Never.self) {
                    _ = try await vaultClient.loginToken(roleID: appRoleID, secretID: response.secretID, mountPath: path)
                }
        }

        try await vaultClient.deleteAppRole(name: appRoleName, mountPath: path)

        try await vaultClient.disableAuthMethod(path)
    }

    @Test
    func unwrapped_authentication() async throws {
        let vaultClient = VaultClient.current

        let path = randomMountPath
        try await vaultClient.enableAuthMethod(configuration: .init(path: path, type: "approle"))

        let appRoleName = "test_app_role"
        try await vaultClient.createAppRole(.init(name: appRoleName,
                                                  tokenPolicies: [],
                                                  tokenTimeToLive: .seconds(60*60),
                                                  tokenType: .batch),
                                            mountPath: path)

        let appRoleID = try await vaultClient.appRoleID(name: appRoleName, mountPath: path).roleID
        let secretIDResponse = try await vaultClient.generateAppSecretID(
            capabilities: .init(
                roleName: appRoleName
            ),
            mountPath: path
        )

        switch secretIDResponse {
            case .wrapped:
                Issue.record("Receive unexpected response: \(secretIDResponse)")

            case .secretId(let response):
                let sut = VaultClient(
                    configuration: .init(apiURL: try! URL(validatingOpenAPIServerURL: "http://127.0.0.1:8200/v1")),
                    clientTransport: AsyncHTTPClientTransport()
                )

                await #expect(throws: Never.self) {
                    // MUT
                    try await sut.login(method: .appRole(
                        path: path,
                        credentials: .init(roleID: appRoleID, secretID: response.secretID))
                    )
                }
        }

        try await vaultClient.deleteAppRole(name: appRoleName, mountPath: path)

        try await vaultClient.disableAuthMethod(path)
    }
}
#endif
