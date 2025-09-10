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
import VaultUtilities

extension VaultClient {

    /// Reads database credentials for a static role
    /// - Parameters:
    ///   - staticRole: static role name
    ///   - enginePath: path to database mount
    /// - Returns: Static database credentials
    public func databaseCredentials(
        staticRole: String,
        enginePath: String
    ) async throws -> StaticRoleCredentialsResponse {
        try await withDatabaseClient(mountPath: enginePath) { client in
            try await client.databaseCredentials(staticRole: staticRole)
        }
    }

    
    /// Read current credentials for a dynamic role
    /// - Parameters:
    ///   - dynamicRole: dynamic role name
    ///   - enginePath: path to database mount
    /// - Returns: Dynamic role credentials
    public func databaseCredentials(
        dynamicRole: String,
        enginePath: String
    ) async throws -> RoleCredentialsResponse {
        try await withDatabaseClient(mountPath: enginePath) { client in
            try await client.databaseCredentials(dynamicRole: dynamicRole)
        }
    }
}
#endif
