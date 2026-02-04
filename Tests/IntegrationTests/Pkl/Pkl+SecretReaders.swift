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

#if PklSupport && MockSupport
import PklSwift
import VaultCourier
import Testing
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.URL
import class Foundation.JSONDecoder
import class Foundation.JSONEncoder
import struct Foundation.Data
#endif
import OpenAPIRuntime
import HTTPTypes
import Utils

extension IntegrationTests.Pkl.SecretReaders {
    @Test
    func mount_path_in_vault_key_value_reader_cannot_be_empty() async throws {
        let vaultClient = VaultClient(configuration: .defaultHttp(),
                                      clientTransport: MockVaultClientTransport.successful)
        try await vaultClient.login(method: .token("test_token"))

        #expect(throws: VaultClientError.self) {
            try vaultClient.makeKeyValueSecretReader(mountPath: "")
        }
    }

    @Test
    func encode_mount_in_scheme_of_database_credential_reader() async throws {
        let scheme1 = try VaultDatabaseCredentialReader.buildSchemeFor(mountPath: "path/to/database", prefix: "test")
        #expect(scheme1 == "test.vault.path.to.database")

        let scheme2 = try VaultDatabaseCredentialReader.buildSchemeFor(mountPath: "path_to_database", prefix: "test")
        #expect(scheme2 == "test.vault.path-to-database")
    }

    @Test
    func vault_key_value_reader() async throws {
        let secret = "api_key"
        let value = "abcde12345"
        let secretPath = "key"
        let kvMountPath = "path/to/secrets"
        let clientToken = "test_token"
        let mockClient = MockVaultClientTransport.dev(
            clientToken: clientToken,
            keyValueMount: kvMountPath,
            secretKeyPath: secretPath,
            expectedSecrets: [secret: value]
        )

        let namespace = "ns/tenant1/stage"
        let vaultClient = VaultClient(configuration: .init(apiURL: VaultClient.Server.defaultHttpURL,
                                                           namespace: namespace),
                                      clientTransport: mockClient)
        try await vaultClient.login(method: .token(clientToken))

        let schemePrefix = "test"
        let scheme = try VaultKeyValueReader.buildSchemeFor(mountPath: kvMountPath, prefix: schemePrefix)
        let sut = try vaultClient.makeKeyValueSecretReader(
            mountPath: kvMountPath,
            prefix: schemePrefix
        )
        // MUT
        let output = try await withEvaluator(options: .preconfigured.withResourceReader(sut)) { evaluator in
            try await evaluator.evaluateOutputText(
                source: .text("""
                appKeys: String = read("\(scheme):/\(secretPath)?version=2").text
                """)
            )
        }

        // Note: Pkl adds `\#n"` at the end of the file
        let expected = #"appKeys = "{\"\#(secret)\":\"\#(value)\"}"\#n"#
        #expect(output == expected)
    }

    #if PostgresPluginSupport
    @Test
    func vault_database_credential_reader() async throws {
        struct DatabaseSecret: Codable, Sendable {
            var databaseCredentials: String
        }

        let username = "test_static_role_username"
        let password = "XS-bh8o95yFzdd3N9Gv-"

        let mockClient = MockVaultClientTransport { req, _, _, _ in
            switch req.normalizedPath {
                case "/auth/token/lookup-self":
                    return (.init(status: .ok), .init("""
                {
                  "request_id": "f1974b8f-266e-2dd6-3ed3-13d330d4589e",
                  "lease_id": "",
                  "renewable": false,
                  "lease_duration": 0,
                  "data": {
                    "accessor": "ufPPb3VC6rTBCIOqtZydD0bu",
                    "creation_time": 1769460540,
                    "creation_ttl": 0,
                    "display_name": "token",
                    "entity_id": "",
                    "expire_time": null,
                    "explicit_max_ttl": 0,
                    "id": "test_token",
                    "issue_time": "2026-01-26T20:49:00.428750095Z",
                    "meta": null,
                    "num_uses": 0,
                    "orphan": true,
                    "path": "auth/token/create",
                    "policies": [
                      "root"
                    ],
                    "renewable": false,
                    "ttl": 0,
                    "type": "service"
                  },
                  "wrap_info": null,
                  "warnings": null,
                  "auth": null
                }
                """))
                default:
                    return (.init(status: .ok), .init("""
                {
                  "request_id": "04c78e0d-141e-3a13-5d38-17821fbdb3c1",
                  "lease_id": "",
                  "renewable": false,
                  "lease_duration": 0,
                  "data": {
                    "last_vault_rotation": "2025-09-14T15:44:15.5738422Z",
                    "password": "\(password)",
                    "rotation_period": 3600,
                    "ttl": 3555,
                    "username": "\(username)"
                  },
                  "wrap_info": null,
                  "warnings": null,
                  "auth": null
                }
                """))
            }
        }

        let namespace = "ns/tenant1/stage"
        let databaseMount = "path/to/database/secrets"
        let vaultClient = VaultClient(configuration: .init(apiURL: VaultClient.Server.defaultHttpURL,
                                                           namespace: namespace),
                                      clientTransport: mockClient)
        try await vaultClient.login(method: .token("test_token"))

        let schemePrefix = "test"
        let scheme = try VaultDatabaseCredentialReader.buildSchemeFor(mountPath: databaseMount, prefix: schemePrefix)
        let sut = try vaultClient.makeDatabaseCredentialReader(mountPath: databaseMount, prefix: schemePrefix)

        // MUT
        let output = try await withEvaluator(options: .preconfigured.withResourceReader(sut)) { evaluator in
            try await evaluator.evaluateModule(
                source: .text("""
                databaseCredentials: String = read("\(scheme):/static-creds/qa_role").text
                """),
                as: DatabaseSecret.self
            )
        }

        let secrets = try JSONDecoder().decode(DatabaseCredentials.self, from: Data(output.databaseCredentials.utf8))
        #expect(secrets.username == username)
        #expect(secrets.password == password)
    }
    #endif
}
#endif
