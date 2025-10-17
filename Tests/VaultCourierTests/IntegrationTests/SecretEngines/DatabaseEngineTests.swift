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
    static var enginePath: String {
        let suffix = "abcdefghijklmnopqrstuvwxyz".randomSample(count: 10).map { String($0) }.joined()
        let path = "my_databases_\(suffix)"
        return path
    }

    @Suite(.setupPostgresConnection(name: connectionName, enginePath: enginePath))
    struct Roles {
        @Test
        func create_static_role_and_read_credentials() async throws {
            let vaultClient = VaultClient.current
            let (mountConfig, connectionConfig) = VaultClient.postgresConnectionConfig
            let mountPath = mountConfig.path
            let staticRoleName = "test_static_role"
            let databaseRoleName = env("STATIC_DB_ROLE") ?? "test_static_role_username"
            let staticRole = DatabaseStaticRoleConfig.postgres(.init(vaultRoleName: staticRoleName,
                                                                            databaseUsername: databaseRoleName,
                                                                            databaseConnectionName: connectionConfig.connection,
                                                                            rotation: .period(.seconds(28 * 24 * 60 * 60))))

            // MUT
            try await vaultClient.create(staticRole: staticRole, mountPath: mountPath)

            // MUT
            let response = try await vaultClient.databaseCredentials(staticRole: staticRoleName, mountPath: mountPath)
            guard case .period(let period) =  response.rotation else {
                Issue.record("Response does not correspond to given request")
                return
            }
            #expect(response.username == databaseRoleName)
            #expect(period == .seconds(2419200))

            // MUT
            try await vaultClient.deleteStaticRole(name: staticRoleName, mountPath: mountPath)
        }

        @Test
        func create_dynamic_role_and_read_credentials() async throws {
            let vaultClient = VaultClient.current
            let (mountConfig, connectionConfig) = VaultClient.postgresConnectionConfig
            let mountPath = mountConfig.path
            let dynamicRoleName = "test_dynamic_role"
            let dynamicRole = DatabaseDynamicRoleConfig.postgres(.init(vaultRoleName: dynamicRoleName,
                                                                       databaseConnectionName: connectionConfig.connection,
                                                                       creationStatements: [
                                                                        "CREATE ROLE \"{{name}}\" LOGIN PASSWORD '{{password}}';",
                                                                       ]))
            // MUT
            try await vaultClient.create(dynamicRole: dynamicRole, mountPath: mountPath)

            let _ = try await vaultClient.databaseCredentials(dynamicRole: dynamicRoleName, mountPath: mountPath)

            // MUT
            try await vaultClient.deleteRole(name: dynamicRoleName, mountPath: mountPath)
        }
    }
}
#endif

// MARK: Valkey
#if ValkeyPluginSupport
extension IntegrationTests.SecretEngine.Database.Valkey {
    static var connectionName: String { "valkey_db" }
    static var enginePath: String {
        let suffix = "abcdefghijklmnopqrstuvwxyz".randomSample(count: 10).map { String($0) }.joined()
        let path = "caches_\(suffix)"
        return path
    }

    @Suite(.setupValkeyConnection(name: connectionName, enginePath: enginePath))
    struct Roles {
        @Test
        func create_static_role_and_read_credentials() async throws {
            let vaultClient = VaultClient.current
            let (mountConfig, connectionConfig) = VaultClient.valkeyConnectionConfig
            let mountPath = mountConfig.path
            let staticRoleName = "test_static_role"
            let databaseRoleName = env("STATIC_DB_ROLE") ?? "test_static_role_username"
            let staticRole = DatabaseStaticRoleConfig.valkey(.init(vaultRoleName: staticRoleName,
                                                                   databaseUsername: databaseRoleName,
                                                                   databaseConnectionName: connectionConfig.connection,
                                                                   rotation: .period(.seconds(28 * 24 * 60 * 60))))

            // MUT
            try await vaultClient.create(staticRole: staticRole, mountPath: mountPath)

            // MUT
            let response = try await vaultClient.databaseCredentials(staticRole: staticRoleName, mountPath: mountPath)
            guard case .period(let period) =  response.rotation else {
                Issue.record("Response does not correspond to given request")
                return
            }
            #expect(response.username == databaseRoleName)
            #expect(period == .seconds(2419200))

            // MUT
            try await vaultClient.deleteStaticRole(name: staticRoleName, mountPath: mountPath)
        }

        @Test
        func create_dynamic_role_and_read_credentials() async throws {
            let vaultClient = VaultClient.current
            let (mountConfig, connectionConfig) = VaultClient.valkeyConnectionConfig
            let mountPath = mountConfig.path
            let dynamicRoleName = "test_dynamic_role"
            let dynamicRole = DatabaseDynamicRoleConfig.valkey(.init(vaultRoleName: dynamicRoleName,
                                                                     databaseConnectionName: connectionConfig.connection,
                                                                     creationStatements: [
                                                                        "+@admin",
                                                                     ]))
            // MUT
            try await vaultClient.create(dynamicRole: dynamicRole, mountPath: mountPath)

            // MUT
            let _ = try await vaultClient.databaseCredentials(dynamicRole: dynamicRoleName, mountPath: mountPath)

            // MUT
            try await vaultClient.deleteRole(name: dynamicRoleName, mountPath: mountPath)
        }
    }
}
#endif
#endif
