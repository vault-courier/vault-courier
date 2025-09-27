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

/// Connection configuration for Vault and Valkey
public struct ValkeyConnectionConfig: Sendable, Decodable {
    /// The name of the connection
    public var connection: String

    /// The name of the database plugin
    public let pluginName: String

    /// Specifies if the connection is verified during initial configuration.
    public var verifyConnection: Bool

    /// List of the _vault_ roles allowed to use this connection. If contains a `*` any role can use this connection.
    /// Currently, roles and connections are bounded if this parameter is different than `*`. This means credentials cannot be generated and accessed by a role which is not on the list.
    public var allowedRoles: [String]

    /// Valkey's host to connect
    public var host: String

    /// Valkey's port to connect
    public var port: UInt16

    /// Vault database ("Root") user.
    public var username: String

    /// This password should be usually be overridden after first set
    public var password: String

    /// TLS certificate. To disable TLS set to `nil`
    public var tls: TLS?

    /// Specifies the database statements to be executed to rotate the root user's credentials. See the plugin's API page for more information on support and formatting for this parameter.
    public var rootRotationStatements: [String]?

    /// The name of the password policy to use when generating passwords for this database. If not specified, this will use a default policy defined as: 20 characters with at least 1 uppercase, 1 lowercase, 1 number, and 1 dash character.
    public var passwordPolicy: String?

    public init(connection: String,
                verifyConnection: Bool = true,
                allowedRoles: [String],
                host: String,
                port: UInt16,
                username: String,
                password: String,
                tls: TLS?,
                rootRotationStatements: [String] = [],
                passwordPolicy: String? = nil) {
        self.connection = connection
        self.pluginName = "valkey-database-plugin"
        self.verifyConnection = verifyConnection
        self.allowedRoles = allowedRoles
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.tls = tls
        self.rootRotationStatements = rootRotationStatements
        self.passwordPolicy = passwordPolicy
    }

    enum CodingKeys: String, CodingKey {
        case connection
        case pluginName = "plugin_name"
        case verifyConnection = "verify_connection"
        case allowedRoles = "allowed_roles"
        case host
        case port
        case username
        case password
        case tls
        case caCert = "ca_cert"
        case skipTLSVerification = "insecure_tls"
        case rootRotationStatements = "root_rotation_statements"
        case passwordPolicy = "password_policy"
    }

    public struct TLS: Sendable, Decodable {
        /// The x509 CA file for validating the certificate presented by the Valkey server. Must be PEM encoded.
        public var caCert: String

        /// Specifies whether to skip verification of the server certificate when using TLS
        public var skipTLSVerification: Bool

        public init(caCert: String,
                    skipTLSVerification: Bool) {
            self.caCert = caCert
            self.skipTLSVerification = skipTLSVerification
        }

        enum CodingKeys: String, CodingKey {
            case caCert = "ca_cert"
            case skipTLSVerification = "insecure_tls"
        }
    }

    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.connection = try values.decode(String.self, forKey: .connection)
        self.pluginName = try values.decode(String.self, forKey: .pluginName)
        self.verifyConnection = try values.decode(Bool.self, forKey: .verifyConnection)
        self.allowedRoles = try values.decodeIfPresent([String].self, forKey: .allowedRoles) ?? []
        self.host = try values.decode(String.self, forKey: .host)
        self.port = try values.decode(UInt16.self, forKey: .port)
        self.username = try values.decode(String.self, forKey: .username)
        self.password = try values.decode(String.self, forKey: .password)
        let useTLS = try values.decodeIfPresent(Bool.self, forKey: .tls) ?? false
        let caCert = try values.decodeIfPresent(String.self, forKey: .caCert)
        let skipTLSVerification = try values.decodeIfPresent(Bool.self, forKey: .skipTLSVerification)
        if useTLS, let caCert, let skipTLSVerification  {
            self.tls = .init(caCert: caCert, skipTLSVerification: skipTLSVerification)
        } else {
            self.tls = nil
        }
        self.rootRotationStatements = try values.decodeIfPresent([String].self, forKey: .rootRotationStatements)
        self.passwordPolicy = try values.decodeIfPresent(String.self, forKey: .passwordPolicy)
    }
}

#endif
