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

#if PklSupport
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

extension IntegrationTests.Pkl {
    @Suite(
        .bug(
            "https://github.com/swiftlang/swift-package-manager/issues/8394",
            "swift test is hanging on GitHub Actions, started in Swift 6.0+"
        ),
        .setupPkl(execPath: env("PKL_EXEC") ?? "/opt/homebrew/bin/pkl")
    ) struct ModuleSourceReader {
        @Test
        func vault_reader_regex_url_for_custom_kv_engine_path() async throws {
            let secret = "api_key"
            let value = "abcde12345"

            let mockClient = MockVaultClientTransport { _, _, _, _ in
                (.init(status: .ok), .init("""
                    {
                      "request_id": "ef3951c9-8c61-11c8-2260-f304a4e8073a",
                      "lease_id": "",
                      "renewable": false,
                      "lease_duration": 0,
                      "data": {
                        "data": {
                          "\(secret)": "\(value)"
                        },
                        "metadata": {
                          "created_time": "2025-09-14T15:03:50Z",
                          "custom_metadata": null,
                          "deletion_time": "",
                          "destroyed": false,
                          "version": 2
                        }
                      },
                      "wrap_info": null,
                      "warnings": null,
                      "auth": null
                    }
                    """))
            }

            let vaultClient = VaultClient(configuration: .defaultHttp(),
                                          clientTransport: mockClient)
            try await vaultClient.login(method: .token("test_token"))

            let schema = "vault"
            let kvMountPath = "path/to/secrets"
            let sut = try await vaultClient.makeResourceReader(
                scheme: "vault",
                keyValueReaderParsers: [KeyValueReaderParser(mount: kvMountPath)]
            )
            let output = try await sut.readConfiguration(text:"""
            appKeys = read("\(schema):/\(kvMountPath)/key?version=2").text
            """)
            // Note: Pkl adds `\#n"` at the end of the file
            let expected = #"appKeys = "{\"\#(secret)\":\"\#(value)\"}"\#n"#
            #expect(output == expected)
        }

        @Test
        func vault_reader_regex_url_for_custom_database_engine_path_and_static_role() async throws {
            struct DatabaseSecret: Codable, Sendable {
                var databaseCredentials: String
            }

            let username = "test_static_role_username"
            let password = "XS-bh8o95yFzdd3N9Gv-"

            let mockClient = MockVaultClientTransport { _, _, _, _ in
                (.init(status: .ok), .init("""
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

            let databaseMount = "path/to/database/secrets"
            let vaultClient = VaultClient(configuration: .defaultHttp(),
                                          clientTransport: mockClient)
            try await vaultClient.login(method: .token("test_token"))

            let scheme = "vault"
            let sut = try await vaultClient.makeResourceReader(
                scheme: "vault",
                databaseReaderParsers: [DatabaseReaderParser(mount: databaseMount)]
            )

            // MUT
            let output = try await sut.readConfiguration(
                source: .text("""
                databaseCredentials: String = read("\(scheme):/\(databaseMount)/static-creds/qa_role").text
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

            let username = "v-token-test_dyn-g5RGxYCabRmtspJ1gL2J-1757865237"
            let password = "FQ6-DIT6SCMchBYfCphm"
            let databaseMount = "path/to/database/secrets"
            let dynamicRole = "test_dynamic_role"

            let mockClient = MockVaultClientTransport { _, _, _, _ in
                (.init(status: .ok), .init("""
                    {
                      "request_id": "152f611f-9b99-a89e-4341-e796b9cba6b8",
                      "lease_id": "\(databaseMount)/creds/\(dynamicRole)/UylQDf6H5MD8bgTrzElBRs8g",
                      "renewable": true,
                      "lease_duration": 3600,
                      "data": {
                        "password": "FQ6-DIT6SCMchBYfCphm",
                        "username": "v-token-test_dyn-g5RGxYCabRmtspJ1gL2J-1757865237"
                      },
                      "wrap_info": null,
                      "warnings": null,
                      "auth": null
                    }
                    """))
            }

            let vaultClient = VaultClient(configuration: .defaultHttp(),
                                          clientTransport: mockClient)
            try await vaultClient.login(method: .token("test_token"))

            let scheme = "vault"
            let sut = try await vaultClient.makeResourceReader(
                scheme: scheme,
                databaseReaderParsers: [DatabaseReaderParser(mount: databaseMount)]
            )
            // MUT
            let output = try await sut.readConfiguration(
                source: .text("""
                databaseCredentials: String = read("vault:/\(databaseMount)/creds/\(dynamicRole)").text
                """),
                as: DatabaseSecret.self)
    
            let secrets = try JSONDecoder().decode(DatabaseCredentials.self, from: Data(output.databaseCredentials.utf8))
            #expect(secrets.username == username)
            #expect(secrets.password == password)
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

        @Test
        func read_credentials_for_two_database_secret_mounts() async throws {
            struct DatabaseSecrets: Codable, Sendable {
                var postgresRoleCredentials: String
                var valkeyRoleCredentials: String
            }

            let vaultRole1 = "test_static_role_1"
            let vaultRole2 = "test_static_role_2"
            let username = "test_static_role_username"
            let passwordDatabase1 = "secret_password_1"
            let passwordDatabase2 = "secret_password_2"
            let databaseMount1 = "path/to/database1"
            let databaseMount2 = "path/to/database2"

            let mockClient = MockVaultClientTransport { req, _, _, _ in
                switch req.normalizedPath {
                    case "/\(databaseMount1)/static-creds/\(vaultRole1)":
                        return (.init(status: .ok), .init("""
                                {
                                  "request_id": "04c78e0d-141e-3a13-5d38-17821fbdb3c1",
                                  "lease_id": "",
                                  "renewable": false,
                                  "lease_duration": 0,
                                  "data": {
                                    "last_vault_rotation": "2025-09-14T15:44:15.5738422Z",
                                    "password": "\(passwordDatabase1)",
                                    "rotation_period": 3600,
                                    "ttl": 3555,
                                    "username": "\(username)"
                                  },
                                  "wrap_info": null,
                                  "warnings": null,
                                  "auth": null
                                }
                                """))
                    case "/\(databaseMount2)/static-creds/\(vaultRole2)":
                        return (.init(status: .ok), .init("""
                            {
                              "request_id": "04c78e0d-141e-3a13-5d38-17821fbdb3c1",
                              "lease_id": "",
                              "renewable": false,
                              "lease_duration": 0,
                              "data": {
                                "last_vault_rotation": "2025-09-14T15:44:15.5738422Z",
                                "password": "\(passwordDatabase2)",
                                "rotation_period": 3600,
                                "ttl": 3555,
                                "username": "\(username)"
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

            let scheme = "vault"
            let sut = try await vaultClient.makeResourceReader(
                scheme: scheme,
                databaseReaderParsers: [.mount(databaseMount1), .mount(databaseMount2)]
            )

            // MUT
            let output = try await sut.readConfiguration(
                source: .text("""
                postgresRoleCredentials: String = read("\(scheme):/\(databaseMount1)/static-creds/\(vaultRole1)").text
                valkeyRoleCredentials: String = read("\(scheme):/\(databaseMount2)/static-creds/\(vaultRole2)").text
                """),
                as: DatabaseSecrets.self)

            let databaseSecrets1 = try JSONDecoder().decode(DatabaseCredentials.self, from: Data(output.postgresRoleCredentials.utf8))
            let databaseSecrets2 = try JSONDecoder().decode(DatabaseCredentials.self, from: Data(output.valkeyRoleCredentials.utf8))
            #expect(databaseSecrets1.username == username)
            #expect(databaseSecrets1.password == passwordDatabase1)
            #expect(databaseSecrets2.username == username)
            #expect(databaseSecrets2.password == passwordDatabase2)
        }

        @Test
        func custom_parse_strategy() async throws {
            struct AppConfig: Codable, Sendable {
                var secrets: String
            }

            let fooValue = "bar"
            let zipValue = "zap"

            let customPath = "/sys/wrapping/unwrap"
            let mockClient = MockVaultClientTransport { req, _, _, _ in
                switch req.normalizedPath {
                    case customPath:
                        return (.init(status: .ok), .init("""
                            {
                              "request_id": "d4eb86fe-1a60-7cef-5a97-623bb789891c",
                              "lease_id": "",
                              "renewable": false,
                              "lease_duration": 0,
                              "data": {
                                "foo": "\(fooValue)",
                                "zip": "\(zipValue)"
                              },
                              "wrap_info": null,
                              "warnings": null,
                              "auth": null
                            }
                            """))
                    default:
                        Issue.record("Unexpected request made to \(String(reflecting: req.path))")
                        throw TestError()
                }
            }

            let vaultClient = VaultClient(configuration: .defaultHttp(),
                                          clientTransport: mockClient)
            try await vaultClient.login(method: .token("test_token"))

            let scheme = "vault"
            let sut = try await vaultClient.makeResourceReader(
                scheme: scheme,
                customResourceReaderParsers: [vaultClient.unwrapReader(customPath: customPath)]
            )

            // MUT
            let output = try await sut.readConfiguration(
                source: .text("""
                secrets: String = read("\(scheme):\(customPath)?token=wrapping_token").text
                """),
                as: AppConfig.self)

            let secrets = try JSONDecoder().decode(WrappingTestSecret.self, from: Data(output.secrets.utf8))
            #expect(secrets.foo == fooValue)
            #expect(secrets.zip == zipValue)
        }
    }
}

fileprivate struct WrappingTestSecret: Codable {
    let foo: String
    let zip: String
}

fileprivate extension VaultClient {
    struct CustomReader: CustomResourceReaderStrategy {
        let client: VaultClient
        let customPath: String

        func parse(_ url: URL) async throws -> [UInt8]? {
            let relativePath = url.relativePath.removeSlash()

            if !customPath.isEmpty,
               relativePath.starts(with: customPath.removeSlash()) {
                let query = url.query()
                let token: String? = if let query {
                    String(query.dropFirst("token=".count))
                } else {
                    nil
                }
                let response: VaultResponse<WrappingTestSecret, Never> = try await client.withSystemBackend { systemBackend in
                    try await systemBackend.unwrapResponse(token: token)
                }

                let data = try response.data.map(JSONEncoder().encode) ?? Data()
                return Array(data)
            } else {
                return nil
            }
        }
    }
}

fileprivate extension CustomResourceReaderStrategy where Self == VaultClient.CustomReader {
    /// Strategy to parse KeyValue resource which expects a URL prefixed with the given `mount`
    static func unwrapSecret(customPath: String, client: VaultClient) -> VaultClient.CustomReader {
        .init(client: client, customPath: customPath)
    }
}

fileprivate extension VaultClient {
    func unwrapReader(customPath: String) -> VaultClient.CustomReader {
        .unwrapSecret(customPath: customPath, client: self)
    }
}

#endif
