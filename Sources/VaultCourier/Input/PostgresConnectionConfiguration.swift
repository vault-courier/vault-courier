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
    public var connection: String
    public var pluginName: String
    public var verifyConnection: Bool?
    public var allowedRoles: [String]?
    public var connectionUrl: String
    public var maxOpenConnections: Int?
    public var maxIdleConnections: Int?
    public var maxConnectionLifetime: String?
    public var username: String?
    public var password: String?
    public var tlsCa: String?
    public var tlsCertificate: String?
    public var privateKey: String?
    public var usernameTemplate: String?
    public var disableEscaping: Bool?
    public var passwordAuthentication: String?
    public var rootRotationStatements: [String]?

    public init(connection: String,
                pluginName: String,
                verifyConnection: Bool? = nil,
                allowedRoles: [String]? = nil,
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
                disableEscaping: Bool? = nil,
                passwordAuthentication: String? = nil,
                rootRotationStatements: [String]? = nil) {
        self.connection = connection
        self.pluginName = pluginName
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

extension PostgresConnectionConfiguration {
    init?(_ config: PostgresDatabaseConnection.Module) {
        self.connection = config.connection
        self.pluginName = config.plugin_name
        self.verifyConnection = config.verify_connection
        self.allowedRoles = config.allowed_roles
        self.connectionUrl = config.connection_url
        self.maxOpenConnections = if let configValue = config.max_open_connections {
            Int(configValue)
        } else {
            nil
        }
        self.maxIdleConnections = if let configValue = config.max_idle_connections {
            Int(configValue)
        } else {
            nil
        }
        self.maxConnectionLifetime = config.max_connection_lifetime
        self.username = config.username
        self.password = config.password
        self.tlsCa =  config.tls_ca
        self.tlsCertificate = config.tls_certificate
        self.privateKey = config.private_key
        self.usernameTemplate = config.username_template
        self.disableEscaping = config.disable_escaping
        self.passwordAuthentication = config.password_authentication
        self.rootRotationStatements = config.root_rotation_statements
    }
}
