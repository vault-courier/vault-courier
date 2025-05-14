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


public struct PostgresConnectionConfiguration: Sendable, Decodable {
    /// The name of the connection
    public var connection: String

    /// The name of the database plugin
    public let pluginName: String

    /// Specifies if the connection is verified during initial configuration.
    public var verifyConnection: Bool

    /// List of the _vault_ roles allowed to use this connection. If contains a `*` any role can use this connection.
    /// Currently, roles and connections are bounded if this parameter is different than `*`. This means credentials cannot be generated and accessed by a role which is not on the list.
    public var allowedRoles: [String]

    /// Specifies the PostgreSQL DSN
    public var connectionUrl: String

    /// Specifies the maximum number of open connections to the database. Defaults to 4 when set to `nil`.
    public var maxOpenConnections: Int?

    /// Specifies the maximum number of idle connections to the database.
    /// A zero uses the value of `max_open_connections` and a negative value
    /// disables idle connections. If larger than `max_open_connections` it will be reduced to be equal. Defaults to zero
    public var maxIdleConnections: Int?

    /// Specifies the maximum amount of time a connection may be reused. If set to `nil`, connections are reused forever.
    public var maxConnectionLifetime: String?

    /// Vault database ("Root") user.
    public var username: String?

    /// This password is usually overriden after first set. See `rotateRoot`
    public var password: String?

    /// The x509 CA file for validating the certificate presented by the PostgreSQL server. Must be PEM encoded.
    public var tlsCa: String?

    /// The x509 client certificate for connecting to the database. Must be PEM encoded.
    public var tlsCertificate: String?

    /// The secret key used for the x509 client certificate. Must be PEM encoded.
    public var privateKey: String?

    ///  Template describing how dynamic usernames are generated. See [templating documentation](https://developer.hashicorp.com/vault/docs/concepts/username-templating)
    public var usernameTemplate: String?

    /// Turns off the escaping of special characters inside of the username and password fields. See the databases secrets engine docs for more information. Defaults to false.
    public var disableEscaping: Bool

    /// Postgres Authentication Method
    ///
    /// When set to "scram-sha-256", passwords will be hashed by Vault and stored as-is by PostgreSQL.
    /// Using "scram-sha-256" requires a minimum version of PostgreSQL 10. Available options are
    /// "scram-sha-256" and "password". The default is "password". When set to "password", passwords
    /// will be sent to PostgreSQL in plaintext format and may appear in PostgreSQL logs as-is.
    /// For more information, please refer to the PostgreSQL documentation.
    public var passwordAuthentication: PostgresAuthMethod

    /// Specifies the database statements to be executed to rotate the root user's credentials. See the plugin's API page for more information on support and formatting for this parameter.
    public var rootRotationStatements: [String]?

    public init(connection: String,
                verifyConnection: Bool = true,
                allowedRoles: [String] = [],
                connectionUrl: String,
                maxOpenConnections: Int? = nil,
                maxIdleConnections: Int? = nil,
                maxConnectionLifetime: String? = nil,
                username: String? = nil,
                password: String? = nil,
                tlsCa: String? = nil,
                tlsCertificate: String? = nil,
                privateKey: String? = nil,
                usernameTemplate: String? = nil,
                disableEscaping: Bool = false,
                passwordAuthentication: PostgresAuthMethod = .password,
                rootRotationStatements: [String] = []) {
        self.connection = connection
        self.pluginName = "postgresql-database-plugin"
        self.verifyConnection = verifyConnection
        self.allowedRoles = allowedRoles
        self.connectionUrl = connectionUrl
        self.maxOpenConnections = maxOpenConnections
        self.maxIdleConnections = maxIdleConnections
        self.maxConnectionLifetime = maxConnectionLifetime
        self.username = username
        self.password = password
        self.tlsCa = tlsCa
        self.tlsCertificate = tlsCertificate
        self.privateKey = privateKey
        self.usernameTemplate = usernameTemplate
        self.disableEscaping = disableEscaping
        self.passwordAuthentication = passwordAuthentication
        self.rootRotationStatements = rootRotationStatements
    }

    enum CodingKeys: String, CodingKey {
        case connection
        case pluginName = "plugin_name"
        case verifyConnection = "verify_connection"
        case allowedRoles = "allowed_roles"
        case connectionUrl = "connection_url"
        case maxOpenConnections = "max_open_connections"
        case maxIdleConnections = "max_idle_connections"
        case maxConnectionLifetime = "max_connection_lifetime"
        case username
        case password
        case tlsCa = "tls_ca"
        case tlsCertificate = "tls_certificate"
        case privateKey = "private_key"
        case usernameTemplate = "username_template"
        case disableEscaping = "disable_escaping"
        case passwordAuthentication = "password_authentication"
        case rootRotationStatements = "root_rotation_statements"
    }
}

public enum PostgresAuthMethod: String, Decodable, Sendable, CustomDebugStringConvertible {
    case password
    case scramSHA256 = "scram-sha-256"

    public var debugDescription: String { rawValue }
}
