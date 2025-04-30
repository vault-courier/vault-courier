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

@testable import VaultCourier


extension IntegrationTests.Database {
    static let connectionName = "postgres_db"
    static let enginePath = "my-postgres-db"

    @Suite(.setupDatabaseConnection(name: connectionName, enginePath: enginePath))
    struct Postgres {
        @Test
        func create_static_role_and_read_credentials() async throws {
            let vaultClient = VaultClient.current
            let staticRoleName = "test_static_role"
            let databaseRoleName = env("STATIC_DB_ROLE") ?? "test_static_role_username"
            let staticRole = CreateDatabaseStaticRole(vaultRoleName: staticRoleName,
                                                      databaseUsername: databaseRoleName,
                                                      databaseConnectionName: connectionName,
                                                      rotationPeriod: "28d")

            // MUT
            try await vaultClient.create(staticRole: staticRole, enginePath: enginePath)

            // MUT
            guard let response = try await vaultClient.databaseCredentials(staticRole: staticRoleName, enginePath: enginePath),
                  case .period(let period) =  response.rotation else {
                Issue.record("Response does not correspond to given request")
                return
            }
            #expect(response.username == databaseRoleName)
            #expect(period == 2419200)

            // MUT
            try await vaultClient.deleteStaticRole(name: staticRole.vaultRoleName, enginePath: enginePath)
        }

        @Test
        func create_dynamic_role_and_read_credentials() async throws {
            let vaultClient = VaultClient.current
            let dynamicRoleName = "test_dynamic_role"
            let dynamicRole = CreateDatabaseRole(vaultRoleName: dynamicRoleName,
                                                 databaseConnectionName: connectionName,
                                                 creationStatements: [
                                                    "CREATE ROLE \"{{name}}\" LOGIN PASSWORD '{{password}}';",
                                                 ])
            // MUT
            try await vaultClient.create(dynamicRole: dynamicRole, enginePath: enginePath)

            guard let _ = try await vaultClient.databaseCredentials(dynamicRole: dynamicRoleName, enginePath: enginePath)
            else {
                Issue.record("Read dynamic role credentials failed")
                return
            }

            // MUT
            try await vaultClient.deleteRole(name: dynamicRole.vaultRoleName, enginePath: enginePath)
        }
    }
}
