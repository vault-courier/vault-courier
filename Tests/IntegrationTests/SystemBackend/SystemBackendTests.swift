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
import Algorithms

import VaultCourier

// MARK: Wrapping
extension IntegrationTests.System.Wrapping {
    @Test
    func wrap_rewrap_token_and_lookup_wrapped_token() async throws {
        let vaultClient = VaultClient.current

        let secrets = ["foo": "bar", "zip": "zap"]

        // MUT
        try await vaultClient.withSystemBackend { backend in
            let wrappedResponse = try await backend.wrap(secrets: secrets, wrapTimeToLive: .seconds(120))
            let rewrappedResponse = try await backend.rewrap(token: wrappedResponse.token)
            #expect(wrappedResponse.timeToLive == rewrappedResponse.timeToLive)
            #expect(wrappedResponse.token != rewrappedResponse.token)
            let info = try await backend.lookupWrapping(token: rewrappedResponse.token)
            #expect(wrappedResponse.timeToLive == info.timeToLive)
        }
    }
}

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
                                                  tokenTimeToLive: .seconds(120),
                                                  tokenType: .batch),
                                            mountPath: path)
        let secretIDResponse = try await vaultClient.generateAppSecretID(capabilities: .init(roleName: appRoleName, wrapTimeToLive: .seconds(120)),
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
                                                  tokenTimeToLive: .seconds(120),
                                                  tokenType: .batch),
                                            mountPath: path)

        // MUT
        let _ = try await vaultClient.wrapAppRoleID(
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

// MARK: Auth
extension IntegrationTests.System.Auth {
    @Test
    func enable_read_and_disable_auth_method() async throws {
        let vaultClient = VaultClient.current

        // MUT
        try await vaultClient.withSystemBackend { backend in
            let mountPath = "user"
            try await backend.enableAuthMethod(configuration: .init(path: mountPath, type: "approle"))
            let _ = try await backend.readAuthMethodConfiguration(mountPath)
            try await backend.disableAuthMethod(mountPath)
        }
    }
}

// MARK: Policies
extension IntegrationTests.System.Policies {
    @Test
    func create_read_delete_policy() async throws {
        let vaultClient = VaultClient.current

        // MUT
        try await vaultClient.withSystemBackend { backend in
            let policyName = "admin"
            try await backend.createPolicy(name: policyName, contentOf: fixtureUrl(for: "examplePolicy.hcl"))
            let _ = try await backend.readPolicy(name: policyName)
            try await backend.deletePolicy(name: policyName)
        }
    }
}

// MARK: Mounts
extension IntegrationTests.System.Mounts {
    @Test
    func enable_kv_secret_engine() async throws {
        let vaultClient = VaultClient.current

        // MUT
        try await vaultClient.withSystemBackend { backend in
            let mountPath = "my_kv_secrets_2"
            try await backend.enableSecretEngine(mountConfig: .init(mountType: "kv", path: mountPath))
            let _ = try await backend.readSecretEngineConfig(path: mountPath)
            try await backend.disableSecretEngine(path: mountPath)
        }
    }

    @Test
    func enable_database_secret_engine() async throws {
        let vaultClient = VaultClient.current

        // MUT
        try await vaultClient.withSystemBackend { backend in
            let mountPath = "my_database_secrets_2"
            try await backend.enableSecretEngine(mountConfig: .init(mountType: "database", path: mountPath))
            let _ = try await backend.readSecretEngineConfig(path: mountPath)
            try await backend.disableSecretEngine(path: mountPath)
        }
    }
}

// MARK: Namespaces
extension IntegrationTests.System.Namespaces {
    @Test
    func create_read_patch_and_delete_namespace() async throws {
        let vaultClient = VaultClient.current

        // MUT
        try await vaultClient.withSystemBackend { backend in
            let namespace = "my_app"
            let response = try await backend.createNamespace(namespace, metadata: ["region": "asia"])
            let info = try await backend.readNamespace(namespace)
            #expect(response.id == info.id)
            #expect(response.uuid == info.uuid)

            let patchedInfo = try await backend.patchNamespace(namespace, metadata: ["region": "europe"])
            #expect(patchedInfo.metadata["region"] == "europe")
            var status = try await backend.deleteNamespace(namespace)
            #expect(status == .inProgress)

            try await Task.sleep(nanoseconds: 1_000_000_000)

            status = try await backend.deleteNamespace(namespace)
            #expect(status == .deleted)
        }
    }
}
