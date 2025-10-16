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

#if DatabaseEngineSupport
import Testing

import VaultCourier
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.URL
import class Foundation.JSONDecoder
import class Foundation.JSONEncoder
import struct Foundation.Data
#endif

#if PklSupport
import PklSwift
#endif

// MARK: Postgres
#if PostgresPluginSupport
extension IntegrationTests.SecretEngine.Database.Postgres {
    static var connectionName: String { "postgres_db" }
    static var enginePath: String { "my_databases" }

    @Suite(.setupPostgresConnection(name: connectionName, enginePath: enginePath))
    struct Roles {
        @Test
        func create_static_role_and_read_credentials() async throws {
            let vaultClient = VaultClient.current
            let staticRoleName = "test_static_role"
            let databaseRoleName = env("STATIC_DB_ROLE") ?? "test_static_role_username"
            let staticRole = DatabaseStaticRoleConfig.postgres(.init(vaultRoleName: staticRoleName,
                                                                            databaseUsername: databaseRoleName,
                                                                            databaseConnectionName: connectionName,
                                                                            rotation: .period(.seconds(28 * 24 * 60 * 60))))

            // MUT
            try await vaultClient.create(staticRole: staticRole, mountPath: enginePath)

            // MUT
            let response = try await vaultClient.databaseCredentials(staticRole: staticRoleName, mountPath: enginePath)
            guard case .period(let period) =  response.rotation else {
                Issue.record("Response does not correspond to given request")
                return
            }
            #expect(response.username == databaseRoleName)
            #expect(period == .seconds(2419200))

            // MUT
            try await vaultClient.deleteStaticRole(name: staticRoleName, mountPath: enginePath)
        }

        @Test
        func create_dynamic_role_and_read_credentials() async throws {
            let vaultClient = VaultClient.current
            let dynamicRoleName = "test_dynamic_role"
            let dynamicRole = DatabaseDynamicRoleConfig.postgres(.init(vaultRoleName: dynamicRoleName,
                                                                              databaseConnectionName: connectionName,
                                                                              creationStatements: [
                                                                                "CREATE ROLE \"{{name}}\" LOGIN PASSWORD '{{password}}';",
                                                                              ]))
            // MUT
            try await vaultClient.create(dynamicRole: dynamicRole, mountPath: enginePath)

            let _ = try await vaultClient.databaseCredentials(dynamicRole: dynamicRoleName, mountPath: enginePath)

            // MUT
            try await vaultClient.deleteRole(name: dynamicRoleName, mountPath: enginePath)
        }

        #if PklSupport
        @Suite(.setupVaultClient(),
               .setupPkl(execPath: env("PKL_EXEC") ?? IntegrationTests.Pkl.localExecPath))
        struct Pkl {
            @Test
            func read_static_database_secret_from_module_source() async throws {
                let vaultClient = VaultClient.current
                let staticRoleName = "test_static_role"
                let databaseRoleName = env("STATIC_DB_ROLE") ?? "test_static_role_username"
                let staticRole = PostgresStaticRoleConfig(vaultRoleName: staticRoleName,
                                                          databaseUsername: databaseRoleName,
                                                          databaseConnectionName: connectionName,
                                                          rotation: .period(.seconds(28 * 24 * 60 * 60)))
                try await vaultClient.create(staticRole: .postgres(staticRole), mountPath: enginePath)

                let sut = try vaultClient.makeResourceReader(
                    scheme: "vault",
                    databaseReaderParsers: [.mount(enginePath)]
                )
                // MUT
                let output = try await withEvaluator(options: .preconfigured.withResourceReader(sut)) { evaluator in
                    try await AppConfig.loadFrom(
                        evaluator: evaluator,
                        source: .url(pklFixtureUrl(for: "Sample1/appConfig2.pkl"))
                    )
                }

                let databaseConfig = try #require(output.database)
                let outputSecret = try JSONDecoder().decode(DatabaseCredentials.self, from: Data(databaseConfig.credentials.utf8))

                #expect(outputSecret.username == databaseRoleName)

                try await vaultClient.deleteStaticRole(name: staticRole.vaultRoleName, mountPath: enginePath)
            }

            @Test
            func read_dynamic_database_secret_from_module_source() async throws {
                let vaultClient = VaultClient.current
                let dynamicRoleName = "test_dynamic_role"
                let dynamicRole = PostgresRoleConfig(vaultRoleName: dynamicRoleName,
                                                     databaseConnectionName: connectionName,
                                                     creationStatements: [
                                                        "CREATE ROLE \"{{name}}\" LOGIN PASSWORD '{{password}}';",
                                                     ])
                try await vaultClient.create(dynamicRole: .postgres(dynamicRole), mountPath: enginePath)

                let sut = try vaultClient.makeResourceReader(
                    scheme: "vault",
                    databaseReaderParsers: [.mount(enginePath)]
                )
                // MUT
                let output = try await withEvaluator(options: .preconfigured.withResourceReader(sut)) { evaluator in
                    try await AppConfig.loadFrom(
                        evaluator: evaluator,
                        source: .url(pklFixtureUrl(for: "Sample1/appConfig3.pkl"))
                    )
                }

                let databaseConfig = try #require(output.database)
                let outputSecret = try JSONDecoder().decode(DatabaseCredentials.self, from: Data(databaseConfig.credentials.utf8))
                #expect(outputSecret.username.isEmpty == false)
                #expect(outputSecret.password.isEmpty == false)

                try await vaultClient.deleteStaticRole(name: dynamicRoleName, mountPath: enginePath)
            }
        }
        #endif
    }
}
#endif

// MARK: Valkey
#if ValkeyPluginSupport
extension IntegrationTests.SecretEngine.Database.Valkey {
    static var connectionName: String { "valkey_db" }
    static var enginePath: String { "caches" }

    @Suite(.setupValkeyConnection(name: connectionName, enginePath: enginePath))
    struct Roles {
        @Test
        func create_static_role_and_read_credentials() async throws {
            let vaultClient = VaultClient.current
            let staticRoleName = "test_static_role"
            let databaseRoleName = env("STATIC_DB_ROLE") ?? "test_static_role_username"
            let staticRole = DatabaseStaticRoleConfig.valkey(.init(vaultRoleName: staticRoleName,
                                                                          databaseUsername: databaseRoleName,
                                                                          databaseConnectionName: connectionName,
                                                                          rotation: .period(.seconds(28 * 24 * 60 * 60))))

            // MUT
            try await vaultClient.create(staticRole: staticRole, mountPath: enginePath)

            // MUT
            let response = try await vaultClient.databaseCredentials(staticRole: staticRoleName, mountPath: enginePath)
            guard case .period(let period) =  response.rotation else {
                Issue.record("Response does not correspond to given request")
                return
            }
            #expect(response.username == databaseRoleName)
            #expect(period == .seconds(2419200))

            // MUT
            try await vaultClient.deleteStaticRole(name: staticRoleName, mountPath: enginePath)
        }

        @Test
        func create_dynamic_role_and_read_credentials() async throws {
            let vaultClient = VaultClient.current
            let dynamicRoleName = "test_dynamic_role"
            let dynamicRole = DatabaseDynamicRoleConfig.valkey(.init(vaultRoleName: dynamicRoleName,
                                                                            databaseConnectionName: connectionName,
                                                                            creationStatements: [
                                                                                "+@admin",
                                                                            ]))
            // MUT
            try await vaultClient.create(dynamicRole: dynamicRole, mountPath: enginePath)

            // MUT
            let _ = try await vaultClient.databaseCredentials(dynamicRole: dynamicRoleName, mountPath: enginePath)

            // MUT
            try await vaultClient.deleteRole(name: dynamicRoleName, mountPath: enginePath)
        }
    }
}
#endif
#endif
