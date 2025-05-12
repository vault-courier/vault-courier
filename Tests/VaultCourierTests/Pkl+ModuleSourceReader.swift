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
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.URL
import class Foundation.JSONDecoder
import class Foundation.JSONEncoder
import struct Foundation.Data
#endif
import PklSwift

@testable import VaultCourier

extension IntegrationTests.Pkl {
    @Suite(
        .tags(.pkl, .integration),
        .enabled(if: isPklEnabled()),
        .bug(
            "https://github.com/swiftlang/swift-package-manager/issues/8394",
            "swift test is hanging on GitHub Actions, started in Swift 6.0+"
        )
    )
    struct ModuleSourceReader {
        let localApiURL = try! URL(validatingOpenAPIServerURL: "http://127.0.0.1:8200/v1")
        var configuration: VaultClient.Configuration { .init(apiURL: localApiURL) }

        @Test
        func vault_reader_regex_url_for_custom_kv_engine_path() async throws {
            let secret = "api_key"
            let value = "abcde12345"

            var client = MockClient()
            client.readKvSecretsAction = { input in
                return .ok(.init(body: .json(.init(data: .init(data: try .init(unvalidatedValue: [secret:value]))))))
            }

            let schema = "vault"
            let config = VaultClient.Configuration(
                    apiURL: localApiURL,
                    readerSchema: schema,
                    kvMountPath: "/path/to/secrets",
                    backgroundActivityLogger: .init(label: "vault-client")
            )
            let vaultClient = VaultClient(configuration: config,
                                          client: client,
                                          authentication: .token("vault_token"))
            try await vaultClient.authenticate()
            let output = try await vaultClient.readConfiguration(text:"""
            appKeys = read("\(schema):/path/to/secrets/key?query=api_key").text
            """)
            // Note: Pkl adds `\#n"` at the end of the file
            let expected = #"appKeys = "{\"\#(secret)\":\"\#(value)\"}"\#n"#
            #expect(output == expected)
        }

        @Test
        func vault_reader_regex_url_for_default_kv_engine_path() async throws {
            var client = MockClient()
            let secret = "api_key"
            let value = "abcde12345"
            client.readKvSecretsAction = { input in
                return .ok(.init(body: .json(.init(data: .init(data: try .init(unvalidatedValue: [secret:value]))))))
            }

            let vaultClient = VaultClient(configuration: configuration,
                                          client: client,
                                          authentication: .token("vault_token"))
            try await vaultClient.authenticate()
            let output = try await vaultClient.readConfiguration(text:"""
            appKeys = read("vault:/secret/key").text
            """)
            // Note: Pkl adds `\#n"` at the end of the file
            let expected = #"appKeys = "{\"\#(secret)\":\"\#(value)\"}"\#n"#
            #expect(output == expected)
        }

        @Test
        func vault_reader_regex_url_for_default_database_engine_path_and_static_role() async throws {
            struct DatabaseSecret: Codable, Sendable {
                var databaseCredentials: String
            }

            var client = MockClient()
            let username = "app_username"
            let password = "XS-bh8o95yFzdd3N9Gv-"
            client.databaseReadStaticRoleCredentialsAction = { input in
                return .ok(.init(body: .json(.init(
                    requestId: "f1a8fba3-d06d-9283-2f77-d14304701479",
                    renewable: false,
                    mountType: "database",
                    data: .init(lastVaultRotation: "2025-01-25T11:28:25.592030964Z",
                                ttl: 548836,
                                password: password,
                                username: username)))))
            }

            let vaultClient = VaultClient(configuration: configuration,
                                          client: client,
                                          authentication: .token("vault_token"))
            try await vaultClient.authenticate()
            let output = try await vaultClient.readConfiguration(
                source: .text("""
                databaseCredentials: String = read("vault:/database/static-creds/qa_role").text
                """),
                as: DatabaseSecret.self)

            let secrets = try JSONDecoder().decode(DatabaseCredentials.self, from: Data(output.databaseCredentials.utf8))
            #expect(secrets.username == username)
            #expect(secrets.password == password)
        }

        @Test
        func vault_reader_regex_url_for_custom_database_engine_path_and_static_role() async throws {
            struct DatabaseSecret: Codable, Sendable {
                var databaseCredentials: String
            }

            var client = MockClient()
            let username = "app_username"
            let password = "XS-bh8o95yFzdd3N9Gv-"
            client.databaseReadStaticRoleCredentialsAction = { input in
                return .ok(.init(body: .json(.init(
                    requestId: "f1a8fba3-d06d-9283-2f77-d14304701479",
                    renewable: false,
                    mountType: "database",
                    data: .init(lastVaultRotation: "2025-01-25T11:28:25.592030964Z",
                                ttl: 548836,
                                password: password,
                                username: username)))))
            }

            let config = VaultClient.Configuration(
                    apiURL: localApiURL,
                    readerSchema: "vault",
                    databaseMountPath: "path/to/database/secrets",
                    backgroundActivityLogger: .init(label: "vault-client")
            )
            let vaultClient = VaultClient(configuration: config,
                                          client: client,
                                          authentication: .token("vault_token"))
            try await vaultClient.authenticate()
            let output = try await vaultClient.readConfiguration(
                source: .text("""
                databaseCredentials: String = read("vault:/path/to/database/secrets/static-creds/qa_role").text
                """),
                as: DatabaseSecret.self)

            let secrets = try JSONDecoder().decode(DatabaseCredentials.self, from: Data(output.databaseCredentials.utf8))
            #expect(secrets.username == username)
            #expect(secrets.password == password)
        }

        @Test
        func vault_reader_regex_url_for_custom_database_engine_path_and_dynamic_role() async throws {
            struct DatabaseSecret: Codable, Sendable {
                var databaseCredentials: String
            }

            var client = MockClient()
            let username = "app_username"
            let password = "XS-bh8o95yFzdd3N9Gv-"
            client.databaseReadRoleCredentialsAction = { input in
                return .ok(.init(body: .json(.init(
                    requestId: "f1a8fba3-d06d-9283-2f77-d14304701479",
                    renewable: false,
                    mountType: "database",
                    data: .init(lastVaultRotation: "2025-01-25T11:28:25.592030964Z",
                                ttl: 548836,
                                password: password,
                                username: username)))))
            }

            let config = VaultClient.Configuration(
                    apiURL: localApiURL,
                    readerSchema: "vault",
                    databaseMountPath: "path/to/database/secrets",
                    backgroundActivityLogger: .init(label: "vault-client")
            )
            let vaultClient = VaultClient(configuration: config,
                                          client: client,
                                          authentication: .token("vault_token"))
            try await vaultClient.authenticate()
            let output = try await vaultClient.readConfiguration(
                source: .text("""
                databaseCredentials: String = read("vault:/path/to/database/secrets/creds/qa_role").text
                """),
                as: DatabaseSecret.self)

            let secrets = try JSONDecoder().decode(DatabaseCredentials.self, from: Data(output.databaseCredentials.utf8))
            #expect(secrets.username == username)
            #expect(secrets.password == password)
        }

        @Test
        func vault_reader_regex_url_for_default_database_engine_path_and_dynamic_role() async throws {
            struct DatabaseSecret: Codable, Sendable {
                var databaseCredentials: String
            }

            var client = MockClient()
            let username = "app_username"
            let password = "XS-bh8o95yFzdd3N9Gv-"
            client.databaseReadRoleCredentialsAction = { input in
                return .ok(.init(body: .json(.init(
                    requestId: "f1a8fba3-d06d-9283-2f77-d14304701479",
                    renewable: false,
                    mountType: "database",
                    data: .init(lastVaultRotation: "2025-01-25T11:28:25.592030964Z",
                                ttl: 548836,
                                password: password,
                                username: username)))))
            }

            let vaultClient = VaultClient(configuration: configuration,
                                          client: client,
                                          authentication: .token("vault_token"))
            try await vaultClient.authenticate()
            let output = try await vaultClient.readConfiguration(
                source: .text("""
                databaseCredentials: String = read("vault:/database/creds/qa_role").text
                """),
                as: DatabaseSecret.self)

            let secrets = try JSONDecoder().decode(DatabaseCredentials.self, from: Data(output.databaseCredentials.utf8))
            #expect(secrets.username == username)
            #expect(secrets.password == password)
        }

    }
}

