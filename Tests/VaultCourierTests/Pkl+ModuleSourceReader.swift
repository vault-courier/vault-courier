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

#if Pkl
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

import VaultCourier

extension IntegrationTests.Pkl.ModuleSourceReader {
    @Test
    func vault_reader_regex_url_for_custom_kv_engine_path() async throws {
        let secret = "api_key"
        let value = "abcde12345"

        var client = MockClient()
        client.readKvSecretsAction = { input in
            return .ok(.init(body: .json(.init(
                requestId: "f1a8fba3-d06d-9283-2f77-d14304701479",
                data: .init(data: try .init(unvalidatedValue: [secret:value])))))
            )
        }

        let config = VaultClient.Configuration(
                apiURL: localApiURL,
                kvMountPath: "/path/to/secrets"
        )
        let vaultClient = VaultClient(configuration: config,
                                      client: client,
                                      authentication: .token("vault_token"))
        try await vaultClient.authenticate()

        let schema = "vault"
        let sut = await vaultClient.makeResourceReader(scheme: schema)
        let output = try await sut.readConfiguration(text:"""
        appKeys = read("\(schema):/path/to/secrets/key?version=2").text
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
            return .ok(.init(body: .json(.init(
                requestId: "f1a8fba3-d06d-9283-2f77-d14304701479",
                data: .init(data: try .init(unvalidatedValue: [secret:value])))))
            )
        }

        let vaultClient = VaultClient(configuration: configuration,
                                      client: client,
                                      authentication: .token("vault_token"))
        try await vaultClient.authenticate()

        let sut = await vaultClient.makeResourceReader()
        // MUT
        let output = try await sut.readConfiguration(text:"""
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

        let sut = await vaultClient.makeResourceReader()
        // MUT
        let output = try await sut.readConfiguration(
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
                databaseMountPath: "path/to/database/secrets"
        )
        let vaultClient = VaultClient(configuration: config,
                                      client: client,
                                      authentication: .token("vault_token"))
        try await vaultClient.authenticate()

        let scheme = "vault"
        let sut = await vaultClient.makeResourceReader(scheme: scheme)
        // MUT
        let output = try await sut.readConfiguration(
            source: .text("""
            databaseCredentials: String = read("\(scheme):/path/to/database/secrets/static-creds/qa_role").text
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
                databaseMountPath: "path/to/database/secrets",
                backgroundActivityLogger: .init(label: "vault-client")
        )
        let vaultClient = VaultClient(configuration: config,
                                      client: client,
                                      authentication: .token("vault_token"))
        try await vaultClient.authenticate()

        let sut = await vaultClient.makeResourceReader()
        // MUT
        let output = try await sut.readConfiguration(
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

        let sut = await vaultClient.makeResourceReader()
        // MUT
        let output = try await sut.readConfiguration(
            source: .text("""
            databaseCredentials: String = read("vault:/database/creds/qa_role").text
            """),
            as: DatabaseSecret.self)

        let secrets = try JSONDecoder().decode(DatabaseCredentials.self, from: Data(output.databaseCredentials.utf8))
        #expect(secrets.username == username)
        #expect(secrets.password == password)
    }

    @Test(.setupVaultClient(kvMountPath: "secret"))
    func default_vault_resource_reader() async throws {
        struct Secret: Codable {
            var apiKey: String
        }
        let key = "app_key"
        let secret = Secret(apiKey: "abcde12345")

        let vaultClient = VaultClient.current
        _ = try await vaultClient.writeKeyValue(secret: secret, key: key)

        let url = pklFixtureUrl(for: "Sample1/appConfig1.pkl")

        let sut = await vaultClient.makeResourceReader()
        
        // MUT
        let output = try await sut.readConfiguration(source: .url(url), as: AppConfig.Module.self)
        let appkeys = try #require(output.appKeys)
        let outputSecret = try JSONDecoder().decode(Secret.self, from: Data(appkeys.utf8))

        #expect(outputSecret.apiKey == secret.apiKey)
    }

    struct ResourceReaderStrategy {
        @Test
        func kv_parse_strategy() async throws {
            let keyValueMount = "/path/to/secrets"
            let expectedKey = "key"
            let expectedVersion = 2
            let url =   URL(string: "vault:\(keyValueMount)/\(expectedKey)?version=\(expectedVersion)")!
            let sut = KeyValueReaderParser(mount: keyValueMount)

            // MUT
            let (mount, key, version) = try #require(try sut.parse(url))

            #expect(mount == keyValueMount.dropFirst())
            #expect(key == expectedKey)
            #expect(version == expectedVersion)
        }

        @Test
        func kv_parse_strategy_by_data_path() async throws {
            let keyValueMount = "/path/to/secrets"
            let expectedKey = "key"
            let expectedVersion = 2
            let url =   URL(string: "vault:\(keyValueMount)/data/\(expectedKey)?version=\(expectedVersion)")!
            let sut = KeyValueDataPathParser()

            // MUT
            let (mount, key, version) = try #require(try sut.parse(url))

            #expect(mount == keyValueMount.dropFirst())
            #expect(key == expectedKey)
            #expect(version == expectedVersion)

            guard try sut.parse(.init(string: "vault:secrets/key")!) == nil
            else {
                Issue.record("KeyValueDataPathParser should fail when path data is missing")
                return
            }
        }

        @Test
        func database_parse_strategy_static_creds() async throws {
            let databaseMount = "/path/to/database/mount"
            let expectedRoleName = "test_static_role"
            let url =   URL(string: "vault:\(databaseMount)/static-creds/\(expectedRoleName)")!
            let sut = DatabaseReaderParser(mount: databaseMount)

            // MUT
            let (mount, role) = try #require(try sut.parse(url))

            guard case .static(let roleName) = role
            else {
                Issue.record("Unexpected role type")
                return
            }

            #expect(mount == databaseMount.dropFirst())
            #expect(roleName == expectedRoleName)
        }

        @Test
        func database_parse_strategy_dynamic_creds() async throws {
            let databaseMount = "/path/to/database/mount"
            let expectedRoleName = "test_dynamic_role"
            let url =   URL(string: "vault:\(databaseMount)/creds/\(expectedRoleName)")!
            let sut = DatabaseReaderParser(mount: databaseMount)

            // MUT
            let (mount, role) = try #require(try sut.parse(url))

            guard case .dynamic(let roleName) = role
            else {
                Issue.record("Unexpected role type: \(role)")
                return
            }

            #expect(mount == databaseMount.dropFirst())
            #expect(roleName == expectedRoleName)
        }
    }
}

#endif
