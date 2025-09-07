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

import VaultCourier
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.URL
import class Foundation.JSONDecoder
import class Foundation.JSONEncoder
import struct Foundation.Data
#endif

#if Pkl
import PklSwift
#endif

extension IntegrationTests.SecretEngine.Database {
    static let connectionName = "postgres_db"
    static let enginePath = "my-postgres-db"

    @Suite(.setupDatabaseConnection(name: connectionName, enginePath: enginePath))
    struct Postgres {
//        @Test
//        func create_static_role_and_read_credentials() async throws {
//            let vaultClient = VaultClient.current
//            let staticRoleName = "test_static_role"
//            let databaseRoleName = env("STATIC_DB_ROLE") ?? "test_static_role_username"
//            let staticRole = CreateDatabaseStaticRole(vaultRoleName: staticRoleName,
//                                                      databaseUsername: databaseRoleName,
//                                                      databaseConnectionName: connectionName,
//                                                      rotation: .period(.seconds(28 * 24 * 60 * 60)))
//
//            // MUT
//            try await vaultClient.create(staticRole: staticRole, enginePath: enginePath)
//
//            // MUT
//            let response = try await vaultClient.databaseCredentials(staticRole: staticRoleName, enginePath: enginePath)
//            guard case .period(let period) =  response.rotation else {
//                Issue.record("Response does not correspond to given request")
//                return
//            }
//            #expect(response.username == databaseRoleName)
//            #expect(period == .seconds(2419200))
//
//            // MUT
//            try await vaultClient.deleteStaticRole(name: staticRole.vaultRoleName, enginePath: enginePath)
//        }

//        @Test
//        func create_dynamic_role_and_read_credentials() async throws {
//            let vaultClient = VaultClient.current
//            let dynamicRoleName = "test_dynamic_role"
//            let dynamicRole = CreateDatabaseRole(vaultRoleName: dynamicRoleName,
//                                                 databaseConnectionName: connectionName,
//                                                 creationStatements: [
//                                                    "CREATE ROLE \"{{name}}\" LOGIN PASSWORD '{{password}}';",
//                                                 ])
//            // MUT
//            try await vaultClient.create(dynamicRole: dynamicRole, enginePath: enginePath)
//
//            let _ = try await vaultClient.databaseCredentials(dynamicRole: dynamicRoleName, enginePath: enginePath)
//
//            // MUT
//            try await vaultClient.deleteRole(name: dynamicRole.vaultRoleName, enginePath: enginePath)
//        }

        #if Pkl
        @Suite(.setupVaultClient(databaseMountPath: enginePath))
        struct Pkl {
            @Test
            func read_static_database_secret_from_module_source() async throws {
                let vaultClient = VaultClient.current
                let staticRoleName = "test_static_role"
                let databaseRoleName = env("STATIC_DB_ROLE") ?? "test_static_role_username"
                let staticRole = CreateDatabaseStaticRole(vaultRoleName: staticRoleName,
                                                          databaseUsername: databaseRoleName,
                                                          databaseConnectionName: connectionName,
                                                          rotation: .period(.seconds(28 * 24 * 60 * 60)))
                try await vaultClient.create(staticRole: staticRole, enginePath: enginePath)

                let sut = await vaultClient.makeResourceReader()
                // MUT
                let output = try await sut.readConfiguration(
                    source: .url(pklFixtureUrl(for: "Sample1/appConfig2.pkl")),
                    as: AppConfig.Module.self
                )

                let databaseConfig = try #require(output.database)
                let outputSecret = try JSONDecoder().decode(DatabaseCredentials.self, from: Data(databaseConfig.credentials.utf8))

                #expect(outputSecret.username == databaseRoleName)

                try await vaultClient.deleteStaticRole(name: staticRole.vaultRoleName, enginePath: enginePath)
            }

            @Test
            func read_dynamic_database_secret_from_module_source() async throws {
                let vaultClient = VaultClient.current
                let dynamicRoleName = "test_dynamic_role"
                let dynamicRole = CreateDatabaseRole(vaultRoleName: dynamicRoleName,
                                                     databaseConnectionName: connectionName,
                                                     creationStatements: [
                                                        "CREATE ROLE \"{{name}}\" LOGIN PASSWORD '{{password}}';",
                                                     ])
                try await vaultClient.create(dynamicRole: dynamicRole, enginePath: enginePath)

                let sut = await vaultClient.makeResourceReader()
                // MUT
                let output = try await sut.readConfiguration(
                    source: .url(pklFixtureUrl(for: "Sample1/appConfig3.pkl")),
                    as: AppConfig.Module.self
                )

                let databaseConfig = try #require(output.database)
                let outputSecret = try JSONDecoder().decode(DatabaseCredentials.self, from: Data(databaseConfig.credentials.utf8))
                #expect(outputSecret.username.isEmpty == false)
                #expect(outputSecret.password.isEmpty == false)

                try await vaultClient.deleteStaticRole(name: dynamicRoleName, enginePath: enginePath)
            }
        }
        #endif
    }
}
