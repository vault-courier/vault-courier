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
import OpenAPIAsyncHTTPClient
import AsyncHTTPClient
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.URL
import class Foundation.JSONDecoder
import class Foundation.JSONEncoder
import struct Foundation.Data
#endif

@testable import VaultCourier


extension IntegrationTests {
    @Suite(
        .tags(.postgres, .integration),
        .serialized
    )
    struct DatabaseEngine {
        let localApiURL = try! URL(validatingOpenAPIServerURL: "http://127.0.0.1:8200/v1")
        var configuration: VaultClient.Configuration { .init(apiURL: localApiURL) }
        var authToken: VaultClient.Authentication { .token("integration_token") }

        func setupClient() async throws -> VaultClient {
            let vaultClient = VaultClient(configuration: configuration,
                                          client: Client(
                                            serverURL: localApiURL,
                                            transport: AsyncHTTPClientTransport()
                                          ),
                                          authentication: authToken)
            try await vaultClient.authenticate()
            return vaultClient
        }

        @Test("Create, Rotate Postgres Connection")
        func setup_postgres_connection() async throws {
            let vaultClient = try await setupClient()

            let enginePath = "my-postgres-db"
            let mountConfig = EnableSecretMountConfig(mountType: "database", path: enginePath)
            await #expect(throws: Never.self){
                try await vaultClient.enableSecretEngine(mountConfig: mountConfig)
            }

            let connectionName = "postgres_db"
            let config = postgresConnectionConfiguration(connectionName)
            await #expect(throws: Never.self, "creation of database connection failed") {
                try await vaultClient.databaseConnection(configuration: config, enginePath: enginePath)
            }

            await #expect(throws: Never.self, "Rotate root failed") {
                try await vaultClient.rotateRoot(connection: connectionName, enginePath: enginePath)
            }
        }
    }
}

extension IntegrationTests.DatabaseEngine {
    @Suite("Database Roles")
    struct Roles {
        let localApiURL = try! URL(validatingOpenAPIServerURL: "http://127.0.0.1:8200/v1")
        var configuration: VaultClient.Configuration { .init(apiURL: localApiURL) }
        var authToken: VaultClient.Authentication { .token("integration_token") }

        let connectionName = "postgres_db"
        let enginePath = "my-postgres-db"

        func setupClient() async throws -> VaultClient {
            let vaultClient = VaultClient(configuration: configuration,
                                          client: Client(
                                            serverURL: localApiURL,
                                            transport: AsyncHTTPClientTransport()
                                          ),
                                          authentication: authToken)
            try await vaultClient.authenticate()
            return vaultClient
        }

        @Test
        func create_static_role() async throws {
            let vaultClient = try await setupClient()
            let staticRole = CreateDatabaseStaticRole(vaultRoleName: "test_static_role",
                                                      databaseUsername: env("STATIC_DB_ROLE") ?? "test_static_role_username",
                                                      databaseConnectionName: connectionName,
                                                      rotationPeriod: "28d")

            // MUT
            await #expect(throws: Never.self, "static role creation failed") {
                try await vaultClient.create(staticRole: staticRole, enginePath: enginePath)
            }
        }

        @Test
        func create_dynamic_role() async throws {
            let vaultClient = try await setupClient()

            let dynamicRole = CreateDatabaseRole(vaultRoleName: "test_dynamic_role",
                                                 databaseConnectionName: connectionName,
                                                 creationStatements: [
                                                    "CREATE ROLE \"{{name}}\" LOGIN PASSWORD '{{password}}';",
                                                 ])
            // MUT
            await #expect(throws: Never.self, "dynamic role creation failed") {
                try await vaultClient.create(dynamicRole: dynamicRole, enginePath: enginePath)
            }
        }
    }
}

extension IntegrationTests {
    static func postgresConnectionConfiguration(_ name: String) -> PostgresConnectionConfiguration {
        // Host name inside container
        let host = env("POSTGRES_HOSTNAME") ?? "pg-db"
        let port = env("POSTGRES_PORT").flatMap(Int.init(_:)) ?? 5432
        let databaseName = env("POSTGRES_DB") ?? "test_database"
        let sslMode = "disable"
        let connectionURL = "postgresql://{{username}}:{{password}}@\(host):\(port)/\(databaseName)?sslmode=\(sslMode)"
        let vaultUsername = env("VAULT_DB_USERNAME") ?? "vault_user"
        let vaultPassword = env("VAULT_DB_PASSWORD") ?? "init_password"
        let config = PostgresConnectionConfiguration.init(connection: name,
                                                          pluginName: "postgresql-database-plugin",
                                                          allowedRoles: ["*"],
                                                          connectionUrl: connectionURL,
                                                          username: vaultUsername,
                                                          password: vaultPassword,
                                                          passwordAuthentication: "scram-sha-256")
        return config
    }
}
