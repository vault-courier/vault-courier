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

@testable import VaultCourier

extension IntegrationTests.Auth.AppRole {
    @Test
    func enable_approle_at_custom_path() async throws {
        let vaultClient = VaultClient.current

        let path = "test_approle"
        try await vaultClient.enableAuthMethod(configuration: .init(path: path, type: "approle"))

        let config = try await vaultClient.readAuthMethodConfiguration(path)

        #expect(config.authMethod == "approle")

        try await vaultClient.disableAuthMethod(path)
    }

    @Test
    func crud_approle() async throws {
        let vaultClient = VaultClient.current

        let path = "approle"
        try await vaultClient.enableAuthMethod(configuration: .init(path: path, type: "approle"))

        let appRoleName = "batch_role"
        try await vaultClient.createAppRole(.init(name: appRoleName,
                                                  tokenPolicies: [],
                                                  tokenTTL: .seconds(60*60),
                                                  tokenType: .batch))

        let appRole = try await vaultClient.readAppRole(name: appRoleName)

        #expect(appRole.tokenType == .batch)

        await #expect(throws: Never.self) {
            _ = try await vaultClient.appRoleID(name: appRoleName)
        }

        let generateAppSecretIdResponse = try await vaultClient.generateAppSecretId(
            capabilities: .init(roleName: appRoleName)
        )

        switch generateAppSecretIdResponse {
            case .wrapped(let wrappedResponse):
                Issue.record("Receive unexpected response: \(generateAppSecretIdResponse)")
            case .secretId(let secretIdResponse):
                #expect(secretIdResponse.secretIDNumberOfUses == 0)
        }

        try await vaultClient.deleteAppRole(name: appRoleName)

        try await vaultClient.disableAuthMethod(path)
    }

    @Test
    func unwrapped_login() async throws {
        let vaultClient = VaultClient.current

        let path = "approle"
        try await vaultClient.enableAuthMethod(configuration: .init(path: path, type: "approle"))

        let appRoleName = "batch_role"
        try await vaultClient.createAppRole(.init(name: appRoleName,
                                                  tokenPolicies: [],
                                                  tokenTTL: .seconds(60*60),
                                                  tokenType: .batch))

        let appRoleID = try await vaultClient.appRoleID(name: appRoleName).roleId
        let secretIDResponse = try await vaultClient.generateAppSecretId(capabilities: .init(roleName: appRoleName))

        switch secretIDResponse {
            case .wrapped(let wrappedResponse):
                Issue.record("Receive unexpected response: \(wrappedResponse)")
            case .secretId(let response):
                // MUT
                await #expect(throws: Never.self) {
                    _ = try await vaultClient.loginToken(roleID: appRoleID, secretID: response.secretID)
                }
        }

    }
}
