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

#if canImport(FoundationEssentials)
import FoundationEssentials
import protocol Foundation.LocalizedError
#else
import struct Foundation.URL
import class Foundation.JSONDecoder
import class Foundation.JSONEncoder
import struct Foundation.Data
import protocol Foundation.LocalizedError
#endif
import VaultUtilities

extension VaultClient {
    #if PostgresPluginSupport
    /// Creates a database connection between Vault and a Postgres Database
    public func databaseConnection(
        configuration: PostgresConnectionConfiguration,
        enginePath: String
    ) async throws {
        try await withDatabaseClient(mountPath: enginePath) { client in
            try await client.databaseConnection(configuration: configuration)
        }
    }
    #endif

    #if ValkeyPluginSupport
    /// Creates a database connection between Vault and a Valkey Database
    public func valkeyConnection(
        configuration: ValkeyConnection,
        enginePath: String
    ) async throws {
        try await withDatabaseClient(mountPath: enginePath) { client in
            try await client.databaseConnection(configuration: configuration)
        }
    }
    #endif

    #if PostgresPluginSupport
    /// Reads vault-database connection
    /// - Parameters:
    ///   - name: connection name
    ///   - enginePath: mount path of database secrets
    /// - Returns: Connection properties
    public func databaseConnection(
        name: String,
        enginePath: String
    ) async throws -> PostgresConnectionResponse {
        try await withDatabaseClient(mountPath: enginePath) { client in
            try await client.databaseConnection(name: name)
        }
    }
    #endif

    #if ValkeyPluginSupport
    /// Reads vault-database connection
    /// - Parameters:
    ///   - name: connection name
    ///   - enginePath: mount path of database secrets
    /// - Returns: Connection properties
    public func valkeyConnection(
        name: String,
        enginePath: String
    ) async throws -> ValkeyConnectionResponse {
        try await withDatabaseClient(mountPath: enginePath) { client in
            try await client.databaseConnection(name: name)
        }
    }
    #endif

    /// Deletes a database connection between Vault and a Postgres Database
    /// - Note: The roles in the database are not deleted
    public func deleteDatabaseConnection(
        _ connectionName: String,
        enginePath: String
    ) async throws {
        try await withDatabaseClient(mountPath: enginePath) { client in
            try await client.deleteDatabaseConnection(connectionName)
        }
    }

    /// Rotates Vault database password
    /// - Note: After this action only vault knows this user's password
    /// - Parameters:
    ///   - connection: connection name
    ///   - enginePath: mount path of database secrets
    public func rotateRoot(
        connection: String,
        enginePath: String
    ) async throws {
        try await withDatabaseClient(mountPath: enginePath) { client in
            try await client.rotateRoot(connection: connection)
        }
    }

    /// Closes a connection and it's underlying plugin and restarts it with the configuration stored in the barrier.
    ///  
    /// - Note: This method resets the connection, but vault's database password is still the same
    /// - Parameters:
    ///   - connectionName: connection name
    ///   - enginePath: mount path of database secrets
    public func resetDatabaseConnection(
        _ connectionName: String,
        enginePath: String
    ) async throws {
        try await withDatabaseClient(mountPath: enginePath) { client in
            try await client.resetDatabaseConnection(connectionName)
        }
    }
}

#endif
