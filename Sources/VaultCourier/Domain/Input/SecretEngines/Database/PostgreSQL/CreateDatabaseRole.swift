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

/// Database dynamic role creation configuration
public struct CreateDatabaseRole: Sendable {
    /// The vault role name which maps to a dynamically generated database username
    public var vaultRoleName: String

    /// The name of the database connection to use for this role.
    public var databaseConnectionName: String

    /// Specifies the time to live (TTL) for the leases associated with this role. Defaults to system/engine default TTL time.
    public var defaultTimeToLive: Duration?

    /// Specifies the maximum TTL for the leases associated with this role. Defaults to sys/mounts's default TTL time;
    /// this value is allowed to be less than the mount max TTL (or, if not set, the system max TTL), but it is not allowed to be longer. See also The TTL General Case.
    public var maxTimeToLive: Duration?

    ///  Specifies the database statements executed to create and configure a user.
    ///
    ///  If the statement is SQL, then it must be a semicolon-separated string, a base64-encoded semicolon-separated string,
    ///  a serialized JSON string array, or a base64-encoded serialized JSON string array. The `{{name}}`, `{{password}}` and `{{expiration}}` values will be substituted. The generated password will be a random alphanumeric 20 character string.
    ///
    ///  This parameter is supported in PostgreSQL and Valkey database plugins
    public var creationStatements: [String]

    /// Specifies the database statements to be executed to revoke a user.
    ///
    /// If the statement is SQL, then it must be a semicolon-separated string, a base64-encoded semicolon-separated string, a serialized JSON string array, or a base64-encoded serialized JSON string array.
    /// The `{{name}}` value will be substituted. If not provided defaults to a generic drop user statement.
    ///
    /// - Note: This parameter is ignore in the Valkey database plugin
    public var revocationStatements: [String]?

    /// Specifies the database statements to be executed rollback a create operation in the event of an error. Not every plugin type will support this functionality.
    ///
    /// If the statement is SQL, then it must be a semicolon-separated string, a base64-encoded semicolon-separated string,
    /// a serialized JSON string array, or a base64-encoded serialized JSON string array. The `{{name}}` value will be substituted.
    ///
    /// - Note: This parameter is ignore in the Valkey database plugin
    public var rollbackStatements: [String]?

    /// Specifies the database statements to be executed to renew a user. Not every plugin type will support this functionality.
    ///
    /// If the statement is SQL, then it must be a semicolon-separated string, a base64-encoded semicolon-separated string, a serialized JSON string array,
    /// or a base64-encoded serialized JSON string array. The `{{name}}` and `{{expiration}}` values will be substituted.
    ///
    /// - Note: This parameter is ignore in the Valkey database plugin
    public var renewStatements: [String]?

    /// Specifies the database statements to be executed to rotate the password for a given username.
    ///
    /// If the statement is SQL, then it must be a semicolon-separated string, a base64-encoded semicolon-separated string, a serialized JSON string array,
    /// or a base64-encoded serialized JSON string array. The `{{name}}` and `{{password}}` values will be substituted. The generated password will be a random alphanumeric 20 character string.
    public var rotationStatements: [String]?

    /// Specifies the type of credential that will be generated for the role. Options include: `password`, `rsa_private_key`, `client_certificate`. See the plugin's API page for credential types supported by individual databases.
    ///
    /// - Note: This property is ignored in Valkey's database plugin
    public var credentialType: DatabaseCredentialMethod?

    /// Specifies the configuration for the given `credential_type`. See documentation for details
    public var credentialConfig: [String: String]?

    public init(vaultRoleName: String,
                databaseConnectionName: String,
                defaultTimeToLive: Duration? = nil,
                maxTimeToLive: Duration? = nil,
                creationStatements: [String],
                revocationStatements: [String]? = nil,
                rollbackStatements: [String]? = nil,
                renewStatements: [String]? = nil,
                rotation_statements: [String]? = nil,
                credentialType: DatabaseCredentialMethod? = nil,
                credentialConfig: [String : String]? = nil) {
        self.vaultRoleName = vaultRoleName
        self.databaseConnectionName = databaseConnectionName
        self.defaultTimeToLive = defaultTimeToLive
        self.maxTimeToLive = maxTimeToLive
        self.creationStatements = creationStatements
        self.revocationStatements = revocationStatements
        self.rollbackStatements = rollbackStatements
        self.renewStatements = renewStatements
        self.rotationStatements = rotation_statements
        self.credentialType = credentialType
        self.credentialConfig = credentialConfig
    }
}

public enum DatabaseCredentialMethod: String, Sendable {
    case password
    case rsaPrivateKey = "rsa_private_key"
    case clientCertificate = "client_certificate"
}
