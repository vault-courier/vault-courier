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

#if ConfigProviderSupport && MockSupport
import Testing
import VaultCourier
import Configuration
import ConfigurationTesting
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.URL
import class Foundation.JSONDecoder
import class Foundation.JSONEncoder
import struct Foundation.Data
#endif

extension VaultClientTests {
    @Suite
    struct VaultConfigProvider {
        struct ServiceSecret: Decodable, ExpressibleByConfigString {
            var apiKey: String

            enum CodingKeys: String, CodingKey {
                case apiKey = "api_key"
            }

            public init?(configString: String) {
                guard let data = configString.data(using: .utf8),
                      let apiKey = try? JSONDecoder().decode(ServiceSecret.self, from: data)
                else { return nil }
                self = apiKey
            }

            public var description: String {
                "apiKey=<REDACTED>"
            }
        }

        @Test
        func printingDescription() async throws {
            let expectedDescription = #"""
                VaultProvider[http://127.0.0.1:8200/v1]
                """#
            let vaultClient = VaultClient(configuration: .defaultHttp(),
                                          clientTransport: MockVaultClientTransport.successful)
            try await vaultClient.login(method: .token("client_token"))

            let sut = VaultProvider(vaultClient: vaultClient)
            #expect(sut.description == expectedDescription)
        }

        @Test
        func printingDebugDescription() async throws {
            let expectedDescription = #"""
                VaultProvider[http://127.0.0.1:8200/v1, 0 watchers, 1 values: string=[string: Hello]]
                """#
            let vaultClient = VaultClient(configuration: .defaultHttp(),
                                          clientTransport: MockVaultClientTransport.successful)
            try await vaultClient.login(method: .token("client_token"))

            let sut = VaultProvider(vaultClient: vaultClient,
                                    initialValues: [.init(["string"]): .init("Hello", isSecret: false)])
            #expect(sut.debugDescription == expectedDescription)
        }

        @Test
        func fetch_kv_secrets() async throws {
            let kvMount = "secret"
            let secretKeyPath = "local_test"
            let expectedSecrets = ["api_key": "secret_api_key"]
            let transport = MockVaultClientTransport.dev(
                keyValueMount: kvMount,
                secretKeyPath: secretKeyPath,
                expectedSecrets: expectedSecrets
            )
            let vaultClient = VaultClient(configuration: .defaultHttp(),
                                          clientTransport: transport)
            try await vaultClient.login(method: .token("client_token"))

            let sut = VaultProvider(vaultClient: vaultClient)

            let relativeURL = "\(kvMount)/\(secretKeyPath)?version=2"
            let context = VaultProvider.makeContext(
                .keyValue,
                mount: kvMount,
                url: URL(configString: relativeURL)!
            )

            let value = try #require(
                try await sut.fetchValue(
                    forKey: .init(["third_party", "service", "api_key"], context: context),
                    type: .string
                ).value
            )

            if case let .string(jsonString) = value.content {
                let secrets = try JSONDecoder().decode([String: String].self, from: jsonString.data(using: .utf8)!)
                #expect(secrets == expectedSecrets)
            } else {
                Issue.record("Decoding failed for value '\(value.description)' in \(#function)")
            }
        }

        @Test
        func config_reader() async throws {
            let kvMount = "secret"
            let secretKeyPath = "local_test"
            let expectedSecrets = ["api_key": "secret_api_key"]
            let transport = MockVaultClientTransport.dev(
                keyValueMount: kvMount,
                secretKeyPath: secretKeyPath,
                expectedSecrets: expectedSecrets
            )
            let vaultClient = VaultClient(configuration: .defaultHttp(),
                                          clientTransport: transport)
            try await vaultClient.login(method: .token("client_token"))

            let provider = VaultProvider(vaultClient: vaultClient)

            let relativeURL = "\(kvMount)/\(secretKeyPath)?version=2"
            let context = VaultProvider.makeContext(
                .keyValue,
                mount: kvMount,
                url: URL(configString: relativeURL)!
            )

            let sut = ConfigReader(provider: provider)

            let readerValue = try await sut.fetchRequiredString(forKey: "third_party.service.api_key", context: context)
            #expect(readerValue == #"{"api_key":"secret_api_key"}"#)
        }

        @Test
        func absolute_url_in_context() async throws {
            let kvMount = "secret"
            let secretKeyPath = "local_test"
            let expectedSecrets = ["api_key": "secret_api_key"]
            let transport = MockVaultClientTransport.dev(
                keyValueMount: kvMount,
                secretKeyPath: secretKeyPath,
                expectedSecrets: expectedSecrets
            )
            let vaultClient = VaultClient(configuration: .defaultHttp(),
                                          clientTransport: transport)
            try await vaultClient.login(method: .token("client_token"))

            let sut = VaultProvider(vaultClient: vaultClient)

            let absoluteURL = "\(VaultClient.Server.defaultHttpURL)/\(kvMount)/\(secretKeyPath)?version=2"
            let context = VaultProvider.makeContext(
                .keyValue,
                mount: kvMount,
                url: URL(configString: absoluteURL)!
            )

            _ = try #require(
                try await sut.fetchValue(
                    forKey: .init(["third_party", "service", "api_key"], context: context),
                    type: .string
                ).value
            )
        }

        @Test
        func relative_url_in_context() async throws {
            let kvMount = "secret"
            let secretKeyPath = "local_test"
            let expectedSecrets = ["api_key": "secret_api_key"]
            let transport = MockVaultClientTransport.dev(
                keyValueMount: kvMount,
                secretKeyPath: secretKeyPath,
                expectedSecrets: expectedSecrets
            )
            let vaultClient = VaultClient(configuration: .defaultHttp(),
                                          clientTransport: transport)
            try await vaultClient.login(method: .token("client_token"))

            let sut = VaultProvider(vaultClient: vaultClient)

            let relative = "/\(kvMount)/\(secretKeyPath)?version=2"
            let context = VaultProvider.makeContext(
                .keyValue,
                mount: kvMount,
                url: URL(configString: relative)!
            )

            _ = try #require(
                try await sut.fetchValue(
                    forKey: .init(["third_party", "service", "api_key"], context: context),
                    type: .string
                ).value
            )
        }

        @Test
        func update_cache_on_fetch() async throws {
            let kvMount = "secret"
            let secretKeyPath = "local_test"
            let expectedSecrets = ["api_key": "secret_api_key"]
            let transport = MockVaultClientTransport.dev(
                keyValueMount: kvMount,
                secretKeyPath: secretKeyPath,
                expectedSecrets: expectedSecrets
            )
            let vaultClient = VaultClient(configuration: .defaultHttp(),
                                          clientTransport: transport)
            try await vaultClient.login(method: .token("client_token"))

            let sut = VaultProvider(vaultClient: vaultClient)

            let relativeURL = "\(kvMount)/\(secretKeyPath)?version=2"
            let context = VaultProvider.makeContext(
                .keyValue,
                mount: kvMount,
                url: URL(configString: relativeURL)!
            )

            let absoluteKey = AbsoluteConfigKey(["third_party", "service", "api_key"], context: context)
            let value = try #require(
                try await sut.fetchValue(forKey: absoluteKey,type: .string).value
            )

            let expected = try #require(
                try await sut.value(forKey: absoluteKey, type: .string).value
            )

            #expect(expected == value)
        }

        @Test
        func unsupported_url() async throws {
            let vaultClient = VaultClient(configuration: .defaultHttp(),
                                          clientTransport: MockVaultClientTransport.successful)
            try await vaultClient.login(method: .token("client_token"))

            let sut = VaultProvider(vaultClient: vaultClient)

            let context = try VaultProvider.makeContext(
                .database,
                mount: "database",
                url: "/database/unsupported_url/role"
            )

            await #expect(throws: VaultClientError.self) {
                try await sut.fetchValue(
                    forKey: .init(["database", "postgres", "credentials"], context: context),
                    type: .string
                )
            }
        }

        @Test
        func malformed_url() async throws {
            let vaultClient = VaultClient(configuration: .defaultHttp(),
                                          clientTransport: MockVaultClientTransport.successful)
            try await vaultClient.login(method: .token("client_token"))

            let sut = VaultProvider(vaultClient: vaultClient)

            await #expect(throws: VaultProviderError.self) {
                try await sut.fetchValue(
                    forKey: .init(
                        ["database", "postgres", "credentials"],
                        context: [
                            "engine": .string("database"),
                            "mount": .string("database"),
                            "url": .string("invalid_url")
                        ]),
                    type: .string
                )
            }
        }

        @Test
        func unsupported_secret_engine() async throws {
            let vaultClient = VaultClient(configuration: .defaultHttp(),
                                          clientTransport: MockVaultClientTransport.successful)
            try await vaultClient.login(method: .token("client_token"))

            let sut = VaultProvider(vaultClient: vaultClient)

            await #expect(throws: VaultProviderError.self) {
                try await sut.fetchValue(
                    forKey: .init(
                        ["database", "postgres", "credentials"],
                        context: [
                            "engine": .string("unsupported_engine"),
                            "mount": .string("database"),
                            "url": .string("/database/creds/role")
                        ]),
                    type: .string
                )
            }
        }

        @Test
        func unsupported_return_types() async throws {
            let kvMount = "secret"
            let secretKeyPath = "local_test"
            let expectedSecrets = ["api_key": "secret_api_key"]
            let transport = MockVaultClientTransport.dev(
                keyValueMount: kvMount,
                secretKeyPath: secretKeyPath,
                expectedSecrets: expectedSecrets
            )
            let vaultClient = VaultClient(configuration: .defaultHttp(),
                                          clientTransport: transport)
            try await vaultClient.login(method: .token("client_token"))

            let sut = VaultProvider(vaultClient: vaultClient)

            let context = try VaultProvider.makeContext(
                .keyValue,
                mount: kvMount,
                url: "/\(kvMount)/data/\(secretKeyPath)"
            )

            let absoluteKey = AbsoluteConfigKey(["third_party", "service", "api_key"], context: context)
            await #expect(throws: VaultProviderError.self) {
                try await sut.fetchValue(
                    forKey: absoluteKey,
                    type: .int
                )
            }

            await #expect(throws: VaultProviderError.self) {
                try await sut.fetchValue(
                    forKey: absoluteKey,
                    type: .double
                )
            }

            await #expect(throws: VaultProviderError.self) {
                try await sut.fetchValue(
                    forKey: absoluteKey,
                    type: .bool
                )
            }

            await #expect(throws: VaultProviderError.self) {
                try await sut.fetchValue(
                    forKey: absoluteKey,
                    type: .stringArray
                )
            }

            await #expect(throws: VaultProviderError.self) {
                try await sut.fetchValue(
                    forKey: absoluteKey,
                    type: .intArray
                )
            }

            await #expect(throws: VaultProviderError.self) {
                try await sut.fetchValue(
                    forKey: absoluteKey,
                    type: .byteChunkArray
                )
            }

            await #expect(throws: VaultProviderError.self) {
                try await sut.fetchValue(
                    forKey: absoluteKey,
                    type: .doubleArray
                )
            }

            await #expect(throws: VaultProviderError.self) {
                try await sut.fetchValue(
                    forKey: absoluteKey,
                    type: .boolArray
                )
            }
        }

        @Test
        func engine_mount_is_not_contained_in_url() async throws {
            let vaultClient = VaultClient(configuration: .defaultHttp(),
                                          clientTransport: MockVaultClientTransport.successful)
            try await vaultClient.login(method: .token("client_token"))

            let sut = VaultProvider(vaultClient: vaultClient)

            let context = try VaultProvider.makeContext(
                .database,
                mount: "other/database",
                url: "/database/unsupported_url/role"
            )

            await #expect(throws: VaultProviderError.self) {
                try await sut.fetchValue(
                    forKey: .init(["database", "postgres", "credentials"], context: context),
                    type: .string
                )
            }
        }

        @Test
        func receive_unauthorized_response() async throws {
            // We should throw
            let vaultClient = VaultClient(configuration: .defaultHttp(),
                                          clientTransport: MockVaultClientTransport.forbidden)
            try await vaultClient.login(method: .token("client_token"))

            let sut = VaultProvider(vaultClient: vaultClient)

            let context = try VaultProvider.makeContext(
                .database,
                mount: "database",
                url: "/database/creds/role"
            )

            await #expect(throws: VaultServerError.self) {
                try await sut.fetchValue(
                    forKey: .init(["database", "postgres", "credentials"], context: context),
                    type: .string
                )
            }
        }

        @Test
        func hierarchy_compatibility() async throws {
            let kvMount = "secret"
            let secretKeyPath = "local_test"
            let expectedSecrets = ["api_key": "secret_api_key"]
            let transport = MockVaultClientTransport.dev(
                keyValueMount: kvMount,
                secretKeyPath: secretKeyPath,
                expectedSecrets: expectedSecrets
            )
            let vaultClient = VaultClient(configuration: .defaultHttps(),
                                          clientTransport: transport)
            try await vaultClient.login(method: .token("client_token"))

            let sut = ConfigReader(providers: [
                VaultProvider(vaultClient: vaultClient),
                try await JSONProvider(filePath: .init(fixtureUrl(for: "/SwiftConfiguration/config.json").relativePath)),
            ])

            let secretsURLString = try await sut.fetchRequiredString(forKey: "third_party.service.api_key")

            let context = try VaultProvider.makeContext(
                .keyValue,
                mount: kvMount,
                url: secretsURLString
            )

            let secret = try await sut.fetchRequiredString(forKey: "third_party.service.api_key", context: context, as: ServiceSecret.self)
            #expect(secret.apiKey == "secret_api_key")
        }

        @Test(.disabled("Override of context missing in swift-configuration"))
        func compatibility() async throws {
            let vaultClient = VaultClient(configuration: .defaultHttp(),
                                          clientTransport: MockVaultClientTransport.successful)
            try await vaultClient.login(method: .token("client_token"))

            let buffer1 = try JSONEncoder().encode(DatabaseCredentials(username: "username1", password: "password1"))
            let buffer2 = try JSONEncoder().encode(DatabaseCredentials(username: "username2", password: "password2"))

            let context = VaultProvider.makeContext(.keyValue, mount: "path/to/mount", url: URL(string: "/secrets/key")!)

            let provider = VaultProvider(
                vaultClient: vaultClient,
                initialValues: [
                    .init(["string"]): .init("Hello", isSecret: false),
                    .init(["other", "string"]): .init("Other Hello", isSecret: false),
                    .init(["int"]): .init(42, isSecret: false),
                    .init(["other", "int"]): .init(24, isSecret: false),
                    .init(["double"]): .init(3.14, isSecret: false),
                    .init(["other", "double"]): .init(2.72, isSecret: false),
                    .init(["bool"]): .init(true, isSecret: false),
                    .init(["other", "bool"]): .init(false, isSecret: false),
                    .init(["bytes"]): .init(.bytes(Array(buffer1)), isSecret: false),
                    .init(["other", "bytes"]): .init(.bytes(Array(buffer2)), isSecret: false),
                    .init(["stringy", "array"]): .init(.stringArray(["Hello", "World"]), isSecret: false),
                    .init(["other", "stringy", "array"]): .init(.stringArray(["Hello", "Swift"]), isSecret: false),
                    .init(["inty", "array"]): .init(.intArray([42, 24]), isSecret: false),
                    .init(["other", "inty", "array"]): .init(.intArray([16, 32]), isSecret: false),
                    .init(["doubly", "array"]): .init(.doubleArray([3.14, 2.72]), isSecret: false),
                    .init(["other", "doubly", "array"]): .init(.doubleArray([0.9, 1.8]), isSecret: false),
                    .init(["booly", "array"]): .init(.boolArray([true, false]), isSecret: false),
                    .init(["other", "booly", "array"]): .init(.boolArray([false, true, true]), isSecret: false),
                    .init(["byteChunky", "array"]): .init(.byteChunkArray([Array(buffer1), Array(buffer2)]), isSecret: false),
                    .init(["other", "byteChunky", "array"]): .init(.byteChunkArray([Array(buffer2), Array(buffer1)]), isSecret: false),
                    .init(["string"], context: context): .init("Hello", isSecret: true)
            ])

            

            let test = ProviderCompatTest(
                provider: provider,
                configuration: .init(overrides: [
                    "bytes": .bytes(Array(buffer1)),
                    "other.bytes": .bytes(Array(buffer2)),
                    "byteChunky.array": .byteChunkArray([Array(buffer1), Array(buffer2)]),
                    "other.byteChunky.array": .byteChunkArray([Array(buffer2), Array(buffer1)])
                ])
            )
            try await test.run()
        }

    }
}

#if DatabaseEngineSupport
extension VaultClientTests.VaultConfigProvider {
    @Test
    func fetch_database_static_credentials() async throws {
        let databaseMount = "database_mount_path"
        let staticRole = "test_static_role"
        let expectedPassword = "test_database_password"
        let transport = MockVaultClientTransport.dev(
            databaseMount: databaseMount,
            staticRole: staticRole,
            staticRoleDatabaseUsername: "test_database_username",
            staticRoleDatabasePassword: expectedPassword,
            expectedSecrets: [String:String]()
        )
        let vaultClient = VaultClient(configuration: .defaultHttp(),
                                      clientTransport: transport)
        try await vaultClient.login(method: .token("client_token"))

        let sut = VaultProvider(vaultClient: vaultClient)

        let relativeURL = "/\(databaseMount)/static-creds/\(staticRole)"
        let context = VaultProvider.makeContext(
            .database,
            mount: databaseMount,
            url: URL(configString: relativeURL)!
        )

        let value = try #require(
            try await sut.fetchValue(
                forKey: .init(["database", "postgres", "credentials"], context: context),
                type: .string
            ).value
        )

        if case let .string(jsonString) = value.content {
            let credentials = try JSONDecoder().decode(DatabaseCredentials.self, from: jsonString.data(using: .utf8)!)
            #expect(credentials.password == expectedPassword)
        } else {
            Issue.record("Decoding failed for value '\(value.description)' in \(#function)")
        }
    }

    @Test
    func fetch_database_dynamic_credentials() async throws {
        let databaseMount = "database_mount_path"
        let dynamicRole = "test_dynamic_role"
        let expectedUsername = "test_database_username"
        let expectedPassword = "test_dynamic_database_password"
        let transport = MockVaultClientTransport.dev(
            databaseMount: databaseMount,
            dynamicRole: dynamicRole,
            dynamicRoleDatabaseUsername: expectedUsername,
            dynamicRoleDatabasePassword: expectedPassword,
            expectedSecrets: [String:String]()
        )
        let vaultClient = VaultClient(configuration: .defaultHttp(),
                                      clientTransport: transport)
        try await vaultClient.login(method: .token("client_token"))

        let sut = VaultProvider(vaultClient: vaultClient)

        let relativeURL = "/\(databaseMount)/creds/\(dynamicRole)"

        let context = try VaultProvider.makeContext(
            .database,
            mount: databaseMount,
            url: relativeURL
        )

        let value = try #require(
            try await sut.fetchValue(
                forKey: .init(["database", "postgres", "credentials"], context: context),
                type: .string
            ).value
        )

        if case let .string(jsonString) = value.content {
            let credentials = try JSONDecoder().decode(DatabaseCredentials.self, from: jsonString.data(using: .utf8)!)
            #expect(credentials.password == expectedPassword)
        } else {
            Issue.record("Decoding failed for value '\(value.description)' in \(#function)")
        }
    }

    @Test
    func database_engine_config_reader_and_expressible_by_config_string() async throws {
        let databaseMount = "database_mount_path"
        let staticRole = "test_static_role"
        let expectedUsername = "test_database_username"
        let expectedPassword = "test_database_password"
        let transport = MockVaultClientTransport.dev(
            databaseMount: databaseMount,
            staticRole: staticRole,
            staticRoleDatabaseUsername: expectedUsername,
            staticRoleDatabasePassword: expectedPassword,
            expectedSecrets: [String:String]()
        )
        let vaultClient = VaultClient(configuration: .defaultHttp(),
                                      clientTransport: transport)
        try await vaultClient.login(method: .token("client_token"))

        let provider = VaultProvider(vaultClient: vaultClient)

        let relativeURL = "/\(databaseMount)/static-creds/\(staticRole)"
        let context = VaultProvider.makeContext(
            .database,
            mount: databaseMount,
            url: URL(configString: relativeURL)!
        )

        let sut = ConfigReader(provider: provider)
        let credentials = try await sut.fetchRequiredString(forKey: "database.postgres.credentials", context: context, as: DatabaseCredentials.self)
        #expect(credentials.username == expectedUsername)
        #expect(credentials.password == expectedPassword)
    }
}
#endif

// MARK: Alternative Implementation
extension VaultClientTests.VaultConfigProvider {
    @Test
    func hierarchy_compatibility_with_json_provider() async throws {
        let kvMount = "secret"
        let secretKeyPath = "local_test"
        let expectedSecrets = ["api_key": "secret_api_key"]
        let databaseMount = "database_mount_path"
        let staticRole = "test_static_role"
        let staticUsername = "test_database_username"
        let dynamicRole = "test_dynamic_role"
        let dynamicRolePassword = "test_dynamic_role_password"
        let expectedPassword = "test_database_password"
        let transport = MockVaultClientTransport.dev(
            databaseMount: databaseMount,
            staticRole: staticRole,
            staticRoleDatabaseUsername: staticUsername,
            staticRoleDatabasePassword: expectedPassword,
            dynamicRole: dynamicRole,
            dynamicRoleDatabasePassword: dynamicRolePassword,
            keyValueMount: kvMount,
            secretKeyPath: secretKeyPath,
            expectedSecrets: expectedSecrets
        )
        let vaultClient = VaultClient(configuration: .defaultHttps(),
                                      clientTransport: transport)
        try await vaultClient.login(method: .token("client_token"))

        let absoluteKey1 = AbsoluteConfigKey(["third_party", "service", "api_key"])
        let absoluteKey2 = AbsoluteConfigKey(["third_party", "service", "api_key"], context: ["version": 2])
        let absoluteKey3 = AbsoluteConfigKey(["server", "database", "credentials"])

        let secretProvider = VaultSecretProvider(
            vaultClient: vaultClient,
            evaluationMap: [
                absoluteKey1: try await VaultSecretProvider.keyValueSecret(mount: kvMount, key: secretKeyPath),
                absoluteKey2: try await VaultSecretProvider.keyValueSecret(mount: kvMount, key: secretKeyPath, version: 2),
                absoluteKey3: try await VaultSecretProvider.databaseCredentials(mount: databaseMount, role: .static(name: staticRole))
            ]
        )

        let sut = ConfigReader(providers: [
            secretProvider,
            try await JSONProvider(filePath: .init(fixtureUrl(for: "/SwiftConfiguration/config2.json").relativePath)),
        ])

        let secret = try await sut.fetchRequiredString(forKey: "third_party.service.api_key", context: ["version": 2], as: ServiceSecret.self)
        #expect(secret.apiKey == "secret_api_key")

        let staticCredentials = try await sut.fetchRequiredString(forKey: "server.database.credentials", as: DatabaseCredentials.self)
        #expect(staticCredentials.username == staticUsername)
        #expect(staticCredentials.password == expectedPassword)

        // This ConfigKey has not been registered in VaultSecretProvider
        let absoluteKey4 = AbsoluteConfigKey(["job", "database", "credentials"])
        let databaseKey: String = absoluteKey4.components.joined(separator: ".")
        var credentials = try await sut.fetchRequiredString(forKey: databaseKey, as: DatabaseCredentials.self)
        #expect(credentials.username == "username_dev_local")
        #expect(credentials.password == "password_local_dev")

        secretProvider.updateEvaluation(absoluteKey4, with: try await VaultSecretProvider.databaseCredentials(mount: databaseMount, role: .dynamic(name: dynamicRole)))

        // Register ConfigKey
        credentials = try await sut.fetchRequiredString(forKey: databaseKey, as: DatabaseCredentials.self)
        #expect(credentials.username != "username_dev_local")
        #expect(credentials.password == dynamicRolePassword)
    }

    @Test
    func compatibility_vault_secret_provider() async throws {
        let vaultClient = VaultClient(configuration: .defaultHttp(),
                                      clientTransport: MockVaultClientTransport.successful)
        try await vaultClient.login(method: .token("client_token"))

        let provider = VaultSecretProvider(
            vaultClient: vaultClient,
            evaluationMap: [
                .init(["string"]): { _ in Array("Hello".utf8) },
                .init(["other", "string"]): { _ in Array("Other Hello".utf8) },
                .init(["int"]): { _ in try Array(JSONEncoder().encode(42)) },
                .init(["other", "int"]): { _ in try Array(JSONEncoder().encode(24)) },
                .init(["double"]): { _ in try Array(JSONEncoder().encode(3.14)) },
                .init(["other", "double"]): { _ in try Array(JSONEncoder().encode(2.72)) },
                .init(["bool"]): { _ in try Array(JSONEncoder().encode(true)) },
                .init(["other", "bool"]): { _ in try Array(JSONEncoder().encode(false)) },
                .init(["bytes"]): { _ in .magic },
                .init(["other", "bytes"]): { _ in .magic2 },
                .init(["stringy", "array"]): { _ in try Array(JSONEncoder().encode(["Hello", "World"])) },
                .init(["other", "stringy", "array"]): { _ in try Array(JSONEncoder().encode(["Hello", "Swift"])) },
                .init(["inty", "array"]): { _ in try Array(JSONEncoder().encode([42, 24])) },
                .init(["other", "inty", "array"]): { _ in try Array(JSONEncoder().encode([16, 32])) },
                .init(["doubly", "array"]): { _ in try Array(JSONEncoder().encode([3.14, 2.72])) },
                .init(["other", "doubly", "array"]): { _ in try Array(JSONEncoder().encode([0.9, 1.8])) },
                .init(["booly", "array"]): { _ in try Array(JSONEncoder().encode([true, false])) },
                .init(["other", "booly", "array"]): { _ in try Array(JSONEncoder().encode([false, true, true])) },
                .init(["byteChunky", "array"]): { _ in try Array(JSONEncoder().encode([[UInt8].magic, [UInt8].magic2])) },
                .init(["other", "byteChunky", "array"]): { _ in try Array(JSONEncoder().encode([[UInt8].magic, [UInt8].magic2, [UInt8].magic])) }
            ],
            initialValues: [
                .init(["string"]): .init("Hello", isSecret: false),
                .init(["other", "string"]): .init("Other Hello", isSecret: false),
                .init(["int"]): .init(42, isSecret: false),
                .init(["other", "int"]): .init(24, isSecret: false),
                .init(["double"]): .init(3.14, isSecret: false),
                .init(["other", "double"]): .init(2.72, isSecret: false),
                .init(["bool"]): .init(true, isSecret: false),
                .init(["other", "bool"]): .init(false, isSecret: false),
                .init(["bytes"]): .init(.magic, isSecret: false),
                .init(["other", "bytes"]): .init(.magic2, isSecret: false),
                .init(["stringy", "array"]): .init(.stringArray(["Hello", "World"]), isSecret: false),
                .init(["other", "stringy", "array"]): .init(.stringArray(["Hello", "Swift"]), isSecret: false),
                .init(["inty", "array"]): .init(.intArray([42, 24]), isSecret: false),
                .init(["other", "inty", "array"]): .init(.intArray([16, 32]), isSecret: false),
                .init(["doubly", "array"]): .init(.doubleArray([3.14, 2.72]), isSecret: false),
                .init(["other", "doubly", "array"]): .init(.doubleArray([0.9, 1.8]), isSecret: false),
                .init(["booly", "array"]): .init(.boolArray([true, false]), isSecret: false),
                .init(["other", "booly", "array"]): .init(.boolArray([false, true, true]), isSecret: false),
                .init(["byteChunky", "array"]): .init(.byteChunkArray([.magic, .magic2]), isSecret: false),
                .init(["other", "byteChunky", "array"]): .init(.byteChunkArray([.magic, .magic2, .magic]), isSecret: false)
        ])

        let test = ProviderCompatTest(
            provider: provider,
            configuration: .init()
        )
        try await test.run()
    }
}


#endif
