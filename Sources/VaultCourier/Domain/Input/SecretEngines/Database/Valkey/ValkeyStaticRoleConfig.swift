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

#if ValkeyPluginSupport

/// Valkey static role configuration
///
/// ## Package traits
///
/// This configuration is guarded by the `ValkeyPluginSupport` package trait.
///
public struct ValkeyStaticRoleConfig: Sendable {
    /// The corresponding role in the database of ``databaseUsername``
    public var vaultRoleName: String

    /// Specifies the database username that this Vault role corresponds to. See ``vaultRoleName``.
    public var databaseUsername: String

    /// The name of the database connection to use for this role.
    public var databaseConnectionName: String

    /// Strategy for credentials rotation
    public var rotation: RotationStrategy

    /// Specifies the database statements to be executed to rotate the password for the configured database user
    public var rotationStatements: [String]?

    public init(vaultRoleName: String,
                databaseUsername: String,
                databaseConnectionName: String,
                rotation: RotationStrategy,
                rotationStatements: [String]? = nil,
                credentialConfig: [String : String]? = nil) {
        self.vaultRoleName = vaultRoleName
        self.databaseUsername = databaseUsername
        self.databaseConnectionName = databaseConnectionName
        self.rotation = rotation
        self.rotationStatements = rotationStatements
    }
}

#endif
