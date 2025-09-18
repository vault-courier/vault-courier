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
extension VaultClient {

    /// Creates a vault role for accessing database secrets
    /// - Parameters:
    ///   - staticRole: static role properties
    ///   - enginePath: mount path of secret engine
    public func create(
        staticRole: CreateDatabaseStaticRole,
        enginePath: String
    ) async throws {
        try await withDatabaseClient(mountPath: enginePath) { client in
            try await client.create(staticRole: staticRole)
        }
    }
    
    /// Deletes a vault database static role
    /// - Parameters:
    ///   - name: name of the role
    ///   - enginePath: mount path of secret engine
    public func deleteStaticRole(
        name: String,
        enginePath: String
    ) async throws {
        try await withDatabaseClient(mountPath: enginePath) { client in
            try await client.deleteStaticRole(name: name)
        }
    }

    #if PostgresPluginSupport
    /// Creates a dynamic database role
    /// - Parameter dynamicRole: properties of dynamic role
    /// - Parameter enginePath: mount path of secret engine
    public func createPostgres(
        dynamicRole: CreatePostgresRole,
        enginePath: String
    ) async throws {
        try await withDatabaseClient(mountPath: enginePath) { client in
            try await client.createPostgres(dynamicRole: dynamicRole)
        }
    }
    #endif

    #if ValkeyPluginSupport
    /// Creates a dynamic database role
    /// - Parameter dynamicRole: properties of dynamic role
    /// - Parameter enginePath: mount path of secret engine
    public func createValkey(
        dynamicRole: CreateValkeyRole,
        enginePath: String
    ) async throws {
        try await withDatabaseClient(mountPath: enginePath) { client in
            try await client.createValkey(dynamicRole: dynamicRole)
        }
    }
    #endif

    /// Deletes a dynamic database role
    /// - Parameters:
    ///   - name: name of dynamic database role
    ///   - enginePath: mount path of secret engine
    public func deleteRole(
        name: String,
        enginePath: String
    ) async throws {
        try await withDatabaseClient(mountPath: enginePath) { client in
            try await client.deleteRole(name: name)
        }
    }
}
#endif
