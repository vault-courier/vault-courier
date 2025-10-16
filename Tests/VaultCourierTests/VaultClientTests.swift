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

#if MockSupport
import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.URL
import class Foundation.JSONDecoder
import struct Foundation.Data
#endif

import VaultCourier

@Suite
struct VaultClientTests {
    @Test
    func wrapping_parameter_token_and_client_token_cannot_be_the_same() async throws {
        let clientToken = "test_token"
        let vaultClient = VaultClient(configuration: .defaultHttp(),
                                      clientTransport: MockVaultClientTransport.successful)
        try await vaultClient.login(method: .token(clientToken))

        await #expect(throws: VaultClientError.self) {
            struct Secrets: Codable, Equatable {
                let apiKey: String
            }

            let _: VaultResponse<Secrets,Never> = try await vaultClient.unwrapResponse(token: clientToken)
        }

        #if AppRoleSupport
        await #expect(throws: VaultClientError.self) {
            try await vaultClient.unwrapAppRoleSecretID(token: clientToken)
        }
        #endif
    }

    #if AppRoleSupport
    @Test
    func login_with_unwrapped_app_role_secret() async throws {
        let roleID = "59d6d1ca-47bb-4e7e-a40b-8be3bc5a0ba8"
        let secretID = "84896a0c-1347-aa90-a4f6-aca8b7558780"

        let clientToken = "b.AAAAAQJZ4d_EQOicFoz3O5of1b_Bg8kivgrxeQ_zzx62UzoqygeNxwopmuJChpFK9j"

        let approleMount = "path/to/approle"

        let mockClient = MockVaultClientTransport { req, _, _, _ in
            #expect(req.normalizedPath == "/auth/\(approleMount)/login", "custom approle path was not taken into account")

            return (.init(status: .ok), .init("""
                {
                  "request_id": "bb10149f-39dd-8261-a427-d52e64922355",
                  "lease_id": "",
                  "renewable": false,
                  "lease_duration": 0,
                  "data": null,
                  "wrap_info": null,
                  "warnings": null,
                  "auth": {
                    "client_token": "\(clientToken)",
                    "accessor": "",
                    "policies": [
                      "default"
                    ],
                    "token_policies": [
                      "default"
                    ],
                    "metadata": {
                      "role_name": "my_role",
                      "tag1": "production"
                    },
                    "lease_duration": 600,
                    "renewable": false,
                    "entity_id": "913160eb-837f-ee8c-e6aa-9ded162b5b75",
                    "token_type": "batch",
                    "orphan": true,
                    "mfa_requirement": null,
                    "num_uses": 0
                  }
                }
                """))
        }

        let vaultClient = VaultClient(configuration: .defaultHttp(),
                                      clientTransport: mockClient)
        try await vaultClient.login(method: .appRole(path: approleMount,
                                                     credentials: .init(roleID: roleID,
                                                                        secretID: secretID)))
        #expect(try vaultClient.sessionToken() == clientToken)
    }
    #endif

    #if AppRoleSupport
    @Test
    func wrap_and_unwrap_approle_secret_id() async throws {
        let mountPath = "path/to/approle"
        let appRoleName = "batch_app"
        let expectedSecretID = "ed8313c8-852a-0098-0d3f-67c5771cca6e"
        let mockClient = MockVaultClientTransport { req, _, _, _ in
            switch req.normalizedPath {
                    case "/auth/\(mountPath)/role/\(appRoleName)/secret-id":
                    return (.init(status: .ok), .init("""
                        {
                          "request_id": "",
                          "lease_id": "",
                          "renewable": false,
                          "lease_duration": 0,
                          "data": null,
                          "wrap_info": {
                            "token": "s.miFj0zRahqINOyYOyJK1GlpR",
                            "accessor": "S13eSfZEllbVNMMJNQ1cN7XV",
                            "ttl": 120,
                            "creation_time": "2025-09-14T18:44:15.318941505Z",
                            "creation_path": "auth/\(mountPath)/role/\(appRoleName)/secret-id",
                            "wrapped_accessor": "54d4834d-aa0e-8f19-3286-7a172370ae7b"
                          },
                          "warnings": null,
                          "auth": null
                        }
                        """))
                case "/sys/wrapping/unwrap":
                    return (.init(status: .ok), .init("""
                        {
                          "request_id": "81ac0ea6-610d-61df-4039-9aab7cc5bf05",
                          "lease_id": "",
                          "renewable": false,
                          "lease_duration": 0,
                          "data": {
                            "secret_id": "\(expectedSecretID)",
                            "secret_id_accessor": "e69a33c6-af8e-0ca1-fbc7-63a35ca50d33",
                            "secret_id_num_uses": 50,
                            "secret_id_ttl": 600
                          },
                          "wrap_info": null,
                          "warnings": null,
                          "auth": null
                        }
                        """))
                default:
                    Issue.record("Unexpected request made to \(String(reflecting: req.path)): \(req)")
                    throw TestError()
            }
        }

        let vaultClient = VaultClient(configuration: .defaultHttp(),
                                      clientTransport: mockClient)
        try await vaultClient.login(method: .token("test_token"))
        let generateAppSecretIdResponse = try await vaultClient.generateAppSecretID(
            capabilities: .init(roleName: appRoleName, wrapTimeToLive: .seconds(120)),
            mountPath: mountPath
        )

        let wrappedToken: String
        switch generateAppSecretIdResponse {
            case .wrapped(let wrapped):
                wrappedToken = wrapped.token

            case .secretId:
                Issue.record("Receive unexpected response: \(generateAppSecretIdResponse)")
                throw TestError()
        }

        let secretID = try await vaultClient.unwrapAppRoleSecretID(token: wrappedToken)
        #expect(secretID.secretID == expectedSecretID)
    }
    #endif
}

#if AppRoleSupport
extension VaultClientTests {
    struct Mock {
        @Test func approle_login() async throws {
            let apppRoleMountPath = "path/to/approle"
            let roleID = "role_id"
            let secretID = "secret_id"
            let clientToken = "approle_client_token"

            let transportClient = MockVaultClientTransport { req, _, _, _ in
                switch req.normalizedPath {
                    case "/auth/\(apppRoleMountPath)/login":

                        return (.init(status: .ok),
                                try await MockVaultClientTransport.encode(response:
                                    VaultAuthResponse(
                                        requestID: "bb10149f-39dd-8261-a427-d52e64922355",
                                        clientToken: clientToken,
                                        accessor: "accessor_token",
                                        tokenPolicies: ["default"],
                                        metadata: ["tag1": "development"],
                                        leaseDuration: .seconds(3600*24),
                                        isRenewable: true,
                                        entityID: "913160eb-837f-ee8c-e6aa-9ded162b5b75",
                                        tokenType: .batch,
                                        isOrphan: true,
                                        numberOfUses: 0
                                    )
                            )
                        )
                    default:
                        Issue.record("Unexpected request made to \(String(reflecting: req.path)): \(req)")
                        throw TestError()
                }
            }

            let vaultClient = VaultClient(configuration: .defaultHttp(),
                                          clientTransport: transportClient)
            try await vaultClient.login(method: .appRole(path: apppRoleMountPath,
                                                         credentials: .init(roleID: roleID, secretID: secretID)))
            #expect(try vaultClient.sessionToken() == clientToken)
        }

        @Test func unwrap_approle_login_and_secrets_read() async throws {
            let apppRoleMountPath = "path/to/approle"
            let appRoleName = "test_role_name"
            let roleID = "role_id"
            let wrappedToken = "secret_wrap_id"
            let expectedSecretID = "secret_id"
            let clientToken = "approle_client_token"
            let databaseMount = "database_mount_path"
            let staticRole = "test_static_role"
            let staticRoleDatabaseUsername = "test_database_username"
            let staticRoleDatabasePassword = "test_database_password"
            let dynamicRole = "test_dynamic_role"
            let dynamicRoleDatabaseUsername = "test_database_username"
            let dynamicRoleDatabasePassword = "test_dynamic_database_password"
            let keyValueMount = "key_value_mount_path"
            let secretKeyPath = "secret_key_path"
            struct Secrets: Codable, Equatable {
                let apiKey1: String
                let apiKey2: String
            }
            let expectedSecrets = Secrets(
                apiKey1: "api_key_1",
                apiKey2: "api_key_2"
            )

            let transportClient = MockVaultClientTransport.dev(
                clientToken: clientToken,
                apppRoleMountPath: apppRoleMountPath,
                appRoleName: appRoleName,
                wrappedToken: wrappedToken,
                expectedSecretID: expectedSecretID,
                databaseMount: databaseMount,
                staticRole: staticRole,
                staticRoleDatabaseUsername: staticRoleDatabaseUsername,
                staticRoleDatabasePassword: staticRoleDatabasePassword,
                dynamicRole: dynamicRole,
                dynamicRoleDatabaseUsername: dynamicRoleDatabaseUsername,
                dynamicRoleDatabasePassword: dynamicRoleDatabasePassword,
                keyValueMount: keyValueMount,
                secretKeyPath: secretKeyPath,
                expectedSecrets: expectedSecrets
            )

            let vaultClient = VaultClient(configuration: .defaultHttp(),
                                          clientTransport: transportClient)
            let response = try await vaultClient.unwrapAppRoleSecretID(token: wrappedToken)
            try await vaultClient.login(method: .appRole(
                    path: apppRoleMountPath,
                    credentials: .init(roleID: roleID,secretID: response.secretID)
                )
            )
            let secrets: Secrets = try await vaultClient.readKeyValueSecret(mountPath: keyValueMount,
                                                                            key: secretKeyPath)
            #expect(secrets == expectedSecrets)

            #if DatabaseEngineSupport
            let credentials = try await vaultClient.databaseCredentials(staticRole: staticRole,
                                                                        enginePath: databaseMount)
            #expect(credentials.username == staticRoleDatabaseUsername)
            #expect(credentials.password == staticRoleDatabasePassword)

            let dynamicCredentials = try await vaultClient.databaseCredentials(dynamicRole: dynamicRole,
                                                                               enginePath: databaseMount)
            #expect(dynamicCredentials.username == dynamicRoleDatabaseUsername)
            #expect(dynamicCredentials.password == dynamicRoleDatabasePassword)
            #endif
        }
    }
}
#endif
#endif
