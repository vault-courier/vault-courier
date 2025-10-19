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

extension IntegrationTests.VaultConfigProvider {
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
            VaultSecretProvider[http://127.0.0.1:8200/v1]
            """#
        let vaultClient = VaultClient(configuration: .defaultHttp(),
                                      clientTransport: MockVaultClientTransport.successful)
        try await vaultClient.login(method: .token("client_token"))

        let sut = VaultSecretProvider(vaultClient: vaultClient)
        #expect(sut.description == expectedDescription)
    }

    @Test
    func printingDebugDescription() async throws {
        let expectedDescription = #"""
            VaultSecretProvider[http://127.0.0.1:8200/v1, 0 watchers, 1 values: string=[string: Hello]]
            """#
        let vaultClient = VaultClient(configuration: .defaultHttp(),
                                      clientTransport: MockVaultClientTransport.successful)
        try await vaultClient.login(method: .token("client_token"))

        let sut = VaultSecretProvider(vaultClient: vaultClient,
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

        let absoluteKey = AbsoluteConfigKey(["third_party", "service", "api_key"], context: ["version": 2])
        let sut = VaultSecretProvider(
            vaultClient: vaultClient,
            evaluationMap: [
                absoluteKey: try await VaultSecretProvider.keyValueSecret(mount: kvMount, key: secretKeyPath)
            ]
        )

        let value = try #require(
            try await sut.fetchValue(
                forKey: absoluteKey,
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

        let context: [String: ConfigContextValue] = ["version": 2]
        let absoluteKey = AbsoluteConfigKey(["third_party", "service", "api_key"], context: context)
        let provider = VaultSecretProvider(
            vaultClient: vaultClient,
            evaluationMap: [
                absoluteKey: try await VaultSecretProvider.keyValueSecret(mount: kvMount, key: secretKeyPath)
            ]
        )

        let sut = ConfigReader(provider: provider)

        let readerValue = try await sut.fetchRequiredString(forKey: "third_party.service.api_key", context: context)
        #expect(readerValue == #"{"api_key":"secret_api_key"}"#)
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

        let absoluteKey = AbsoluteConfigKey(["third_party", "service", "api_key"])
        let sut = VaultSecretProvider(
            vaultClient: vaultClient,
            evaluationMap: [
                absoluteKey: try await VaultSecretProvider.keyValueSecret(mount: kvMount, key: secretKeyPath)
            ]
        )

        #expect(try sut.value(forKey: absoluteKey, type: .string).value == nil)

        let value = try #require(
            try await sut.fetchValue(forKey: absoluteKey,type: .string).value
        )

        let expected = try #require(
            try sut.value(forKey: absoluteKey, type: .string).value
        )

        #expect(expected == value)
    }

    @Test
    func receive_unauthorized_response() async throws {
        let vaultClient = VaultClient(configuration: .defaultHttp(),
                                      clientTransport: MockVaultClientTransport.forbidden)
        try await vaultClient.login(method: .token("client_token"))

        let absKey = AbsoluteConfigKey(["database", "postgres", "credentials"])
        let sut = VaultSecretProvider(
            vaultClient: vaultClient,
            evaluationMap: [
                absKey: try await VaultSecretProvider.databaseCredentials(mount: "database", role: .dynamic(role: "qa_role"))
            ]
        )

        await #expect(throws: VaultServerError.self) {
            try await sut.fetchValue(
                forKey: absKey,
                type: .string
            )
        }
    }

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
        var absoluteKey2 = absoluteKey1
        absoluteKey2.context = ["version": 2]
        let absoluteKey3 = AbsoluteConfigKey(["server", "database", "credentials"])

        let secretProvider = VaultSecretProvider(
            vaultClient: vaultClient,
            evaluationMap: [
                absoluteKey1: try await VaultSecretProvider.keyValueSecret(mount: kvMount, key: secretKeyPath),
                absoluteKey2: try await VaultSecretProvider.keyValueSecret(mount: kvMount, key: secretKeyPath, version: 2),
                absoluteKey3: try await VaultSecretProvider.databaseCredentials(mount: databaseMount, role: .static(role: staticRole))
            ]
        )

        let sut = ConfigReader(providers: [
            secretProvider,
            try await JSONProvider(filePath: .init(fixtureUrl(for: "/SwiftConfiguration/config.json").relativePath)),
        ])

        let secret = try await sut.fetchRequiredString(
            forKey: "third_party.service.api_key",
            context: ["version": 2],
            as: ServiceSecret.self
        )
        #expect(secret.apiKey == "secret_api_key")

        let staticCredentials = try await sut.fetchRequiredString(
            forKey: "server.database.credentials",
            as: DatabaseCredentials.self
        )
        #expect(staticCredentials.username == staticUsername)
        #expect(staticCredentials.password == expectedPassword)

        // This ConfigKey has not been registered in VaultSecretProvider
        let absoluteKey4 = AbsoluteConfigKey(["job", "database", "credentials"])
        let databaseKey: String = absoluteKey4.components.joined(separator: ".")
        var credentials = try await sut.fetchRequiredString(forKey: databaseKey, as: DatabaseCredentials.self)
        #expect(credentials.username == "username_dev_local")
        #expect(credentials.password == "password_local_dev")

        secretProvider.updateEvaluation(
            absoluteKey4,
            with: try await VaultSecretProvider.databaseCredentials(
                mount: databaseMount,
                role: .dynamic(role: dynamicRole)
            )
        )

        // Register ConfigKey
        credentials = try await sut.fetchRequiredString(forKey: databaseKey, as: DatabaseCredentials.self)
        #expect(credentials.username != "username_dev_local")
        #expect(credentials.password == dynamicRolePassword)
    }
}

#if DatabaseEngineSupport
extension IntegrationTests.VaultConfigProvider {
    static let databaseMount = "database_mount_path"
    static let staticRole = "test_static_role"
    static let staticRoleDatabasePassword = "test_database_password"
    static let dynamicRole = "test_dynamic_role"
    static let dynamicRoleDatabaseUsername = "test_database_username"
    static let dynamicRoleDatabasePassword = "test_dynamic_database_password"

    static var databaseEnabledTransport: MockVaultClientTransport {
        MockVaultClientTransport.dev(
            databaseMount: databaseMount,
            staticRole: staticRole,
            staticRoleDatabaseUsername: "test_database_username",
            staticRoleDatabasePassword: staticRoleDatabasePassword,
            dynamicRole: dynamicRole,
            dynamicRoleDatabaseUsername: dynamicRoleDatabaseUsername,
            dynamicRoleDatabasePassword: dynamicRoleDatabasePassword,
            expectedSecrets: [String:String]()
        )
    }
    @Test
    func fetch_database_static_credentials() async throws {
        let vaultClient = VaultClient(configuration: .defaultHttp(),
                                      clientTransport: Self.databaseEnabledTransport)
        try await vaultClient.login(method: .token("client_token"))

        let absKey = AbsoluteConfigKey(["database", "postgres", "credentials"])
        let sut = VaultSecretProvider(
            vaultClient: vaultClient,
            evaluationMap: [
                absKey: try await VaultSecretProvider.databaseCredentials(mount: Self.databaseMount, role: .static(role: Self.staticRole))
            ]
        )

        let value = try #require(
            try await sut.fetchValue(forKey: absKey,type: .string).value
        )

        if case let .string(jsonString) = value.content {
            let credentials = try JSONDecoder().decode(DatabaseCredentials.self, from: jsonString.data(using: .utf8)!)
            #expect(credentials.password == Self.staticRoleDatabasePassword)
        } else {
            Issue.record("Decoding failed for value '\(value.description)' in \(#function)")
        }
    }

    @Test
    func fetch_database_dynamic_credentials() async throws {
        let vaultClient = VaultClient(configuration: .defaultHttp(),
                                      clientTransport: Self.databaseEnabledTransport)
        try await vaultClient.login(method: .token("client_token"))

        let absKey = AbsoluteConfigKey(["database", "postgres", "credentials"])
        let sut = VaultSecretProvider(
            vaultClient: vaultClient,
            evaluationMap: [
                absKey: try await VaultSecretProvider.databaseCredentials(mount: Self.databaseMount, role: .dynamic(role: Self.dynamicRole))
            ]
        )

        let value = try #require(
            try await sut.fetchValue(forKey: absKey,type: .string).value
        )

        if case let .string(jsonString) = value.content {
            let credentials = try JSONDecoder().decode(DatabaseCredentials.self, from: jsonString.data(using: .utf8)!)
            #expect(credentials.password == Self.dynamicRoleDatabasePassword)
        } else {
            Issue.record("Decoding failed for value '\(value.description)' in \(#function)")
        }
    }

    @Test
    func database_engine_config_reader_and_expressible_by_config_string() async throws {
        let vaultClient = VaultClient(configuration: .defaultHttp(),
                                      clientTransport: Self.databaseEnabledTransport)
        try await vaultClient.login(method: .token("client_token"))

        let absKey = AbsoluteConfigKey(["database", "postgres", "credentials"])
        let provider = VaultSecretProvider(
            vaultClient: vaultClient,
            evaluationMap: [
                absKey: try await VaultSecretProvider.databaseCredentials(mount: Self.databaseMount, role: .dynamic(role: Self.dynamicRole))
            ]
        )

        let sut = ConfigReader(provider: provider)
        let credentials = try await sut.fetchRequiredString(
            forKey: VaultSecretProvider.keyEncoder.encode(absKey),
            as: DatabaseCredentials.self
        )
        #expect(credentials.password == Self.dynamicRoleDatabasePassword)
    }
}
#endif


// MARK: Compatibility
extension IntegrationTests.VaultConfigProvider {
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
