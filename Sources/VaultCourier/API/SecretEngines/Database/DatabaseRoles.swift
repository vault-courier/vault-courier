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

#if PostgresPluginSupport || ValkeyPluginSupport
extension VaultClient {
    /// Creates a vault role for accessing database secrets
    /// - Parameters:
    ///   - staticRole: static role configuration
    ///   - mountPath: mount path of secret engine
    public func create(
        staticRole: DatabaseStaticRoleConfig,
        mountPath: String
    ) async throws {
        try await withDatabaseClient(mountPath: mountPath) { client in
            try await client.create(staticRole: staticRole)
        }
    }

    /// Creates a postgres dynamic database role
    /// - Parameter dynamicRole: dynamic role configuration
    /// - Parameter mountPath: mount path of database secret engine, e.g. `database`
    public func create(
        dynamicRole: DatabaseDynamicRoleConfig,
        mountPath: String
    ) async throws {
        try await withDatabaseClient(mountPath: mountPath) { client in
            try await client.create(dynamicRole: dynamicRole)
        }
    }
}
#endif

#if DatabaseEngineSupport
extension VaultClient {
    /// Deletes a vault database static role
    /// - Parameters:
    ///   - name: name of the role
    ///   - enginePath: mount path of secret engine
    public func deleteStaticRole(
        name: String,
        mountPath: String
    ) async throws {
        try await withDatabaseClient(mountPath: mountPath) { client in
            try await client.deleteStaticRole(name: name)
        }
    }

    /// Deletes a dynamic database role
    /// - Parameters:
    ///   - name: name of dynamic database role
    ///   - enginePath: mount path of secret engine
    public func deleteRole(
        name: String,
        mountPath: String
    ) async throws {
        try await withDatabaseClient(mountPath: mountPath) { client in
            try await client.deleteRole(name: name)
        }
    }
}
#endif
