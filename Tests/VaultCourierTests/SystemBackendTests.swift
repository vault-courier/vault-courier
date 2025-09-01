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

import OpenAPIAsyncHTTPClient
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.URL
#endif

import VaultCourier

// MARK: Wrapping

#if AppRoleSupport
extension IntegrationTests.System.Wrapping {
    struct AppRoleSecretID: Decodable, Sendable {
        let secretID: String
        let secretIDAccessor: String
        let secretIDTimeToLive: Int
        let secretIDNumberOfUses: Int

        enum CodingKeys: String, CodingKey {
            case secretID = "secret_id"
            case secretIDAccessor = "secret_id_accessor"
            case secretIDTimeToLive = "secret_id_ttl"
            case secretIDNumberOfUses = "secret_id_num_uses"
        }
    }

    var randomMount: String {
        let suffix = "abcdefghijklmnopqrstuvwxyz".randomSample(count: 10).map { String($0) }.joined()
        let path = "approle_\(suffix)"
        return path
    }

    @Test
    func unwrap_approle_response() async throws {
        let vaultClient = VaultClient.current

        let path = randomMount
        try await vaultClient.enableAuthMethod(configuration: .init(path: path, type: "approle"))

        let appRoleName = "test_app_role"
        try await vaultClient.createAppRole(.init(name: appRoleName,
                                                  tokenPolicies: [],
                                                  tokenTTL: .seconds(120),
                                                  tokenType: .batch),
                                            mountPath: path)
        let secretIDResponse = try await vaultClient.generateAppSecretId(capabilities: .init(roleName: appRoleName, wrapTTL: .seconds(120)),
                                                                         mountPath: path)

        switch secretIDResponse {
            case .wrapped(let wrappedResponse):
                // MUT
                try await vaultClient.withSystemBackend { systemBackend in
                    let _: VaultResponse<AppRoleSecretID, Never> = try await systemBackend.unwrapResponse(token: wrappedResponse.token)
                }
            case .secretId(let response):
                Issue.record("Receive unexpected response: \(response)")
        }

        // Clean up
        try await vaultClient.deleteAppRole(name: appRoleName, mountPath: path)

        try await vaultClient.disableAuthMethod(path)
    }

    @Test
    func wrap_approle_id_response() async throws {
        let vaultClient = VaultClient.current
        let path = randomMount
        try await vaultClient.enableAuthMethod(configuration: .init(path: path, type: "approle"))

        let appRoleName = "test_app_role"
        try await vaultClient.createAppRole(.init(name: appRoleName,
                                                  tokenPolicies: [],
                                                  tokenTTL: .seconds(120),
                                                  tokenType: .batch),
                                            mountPath: path)

        // MUT
        let wrappedResponse = try await vaultClient.wrapAppRoleID(
            name: appRoleName,
            mountPath: path,
            wrapTimeToLive: .seconds(120)
        )

        // Clean up
        try await vaultClient.deleteAppRole(name: appRoleName, mountPath: path)
        try await vaultClient.disableAuthMethod(path)
    }
}
#endif
