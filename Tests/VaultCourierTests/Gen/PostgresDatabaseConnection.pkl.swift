
#if PklSupport
// Code generated from Pkl module `PostgresDatabaseConnection`. DO NOT EDIT.
import PklSwift

public enum PostgresDatabaseConnection {}

extension PostgresDatabaseConnection {
    public enum PostgresSSLMode: String, CaseIterable, CodingKeyRepresentable, Decodable, Hashable {
        case disable = "disable"
        case allow = "allow"
        case prefer = "prefer"
        case require = "require"
        case verifyCa = "verify-ca"
        case verifyFull = "verify-full"
    }

    /// This is the payload for configuring Vault and Postgres connections
    /// https://developer.hashicorp.com/vault/api-docs/secret/databases/postgresql
    public struct Module: PklRegisteredType, Decodable, Hashable {
        public static let registeredIdentifier: String = "PostgresDatabaseConnection"

        /// Custom database engine path
        public var enginePath: String?

        /// The name of the connection
        public var connection: String

        public var plugin_name: String

        /// Specifies if the connection is verified during initial configuration. Defaults to true.
        public var verify_connection: Bool?

        /// List of the _vault_ roles allowed to use this connection. Defaults to empty (no roles), if contains a `*` any role can use this connection.
        /// Currently, roles and connections are bounded if this parameter is different than `*`. This means credentials cannot be generated and accessed by a role which is not on the list.
        public var allowed_roles: [String]?

        /// Vault database ("Root") user.
        public var username: String

        /// This password is usually overriden after first set
        public var password: String

        /// Specifies the maximum number of open connections to the database. Defaults to 4
        public var max_open_connections: UInt8?

        /// Specifies the maximum number of idle connections to the database.
        /// A zero uses the value of `max_open_connections` and a negative value
        /// disables idle connections. If larger than `max_open_connections` it will be reduced to be equal. Defaults to zero
        public var max_idle_connections: UInt8?

        /// Specifies the maximum amount of time a connection may be reused. If `<= 0s`, connections are reused forever.
        public var max_connection_lifetime: String?

        /// The x509 CA file for validating the certificate presented by the PostgreSQL server. Must be PEM encoded. Defaults to empty
        public var tls_ca: String?

        /// The x509 client certificate for connecting to the database. Must be PEM encoded. Defaults to empty
        public var tls_certificate: String?

        /// The secret key used for the x509 client certificate. Must be PEM encoded. Defaults to empty
        public var private_key: String?

        /// If set to `gcp_iam`, will enable IAM authentication to a Google CloudSQL instance.
        /// For more information on authenticating to CloudSQL via IAM, please refer to Google's official documentation here.
        /// Default to empty string
        public var auth_type: String?

        /// JSON encoded credentials for a GCP Service Account to use for IAM authentication. Requires `auth_type` to be `gcp_iam`.
        /// Default to empty string
        public var service_account_json: String?

        /// Enables the option to connect to CloudSQL Instances with Private IP. Requires `auth_type` to be `gcp_iam`.
        /// Defaults to `false`
        public var use_private_ip: Bool?

        /// Template describing how dynamic usernames are generated.
        ///
        /// Defaults to
        /// ```
        /// {{ printf "v-%s-%s-%s-%s" (.DisplayName | truncate 8) (.RoleName | truncate 8) (random 20) (unix_time) | truncate 63 }}
        /// ```
        public var username_template: String?

        /// Turns off the escaping of special characters inside of the username and password fields. See the databases secrets engine docs for more information. Defaults to false.
        public var disable_escaping: Bool?

        /// When set to "scram-sha-256", passwords will be hashed by Vault and stored as-is by PostgreSQL.
        /// Using "scram-sha-256" requires a minimum version of PostgreSQL 10. Available options are
        /// "scram-sha-256" and "password". The default is "password". When set to "password", passwords
        /// will be sent to PostgreSQL in plaintext format and may appear in PostgreSQL logs as-is.
        /// For more information, please refer to the PostgreSQL documentation.
        public var password_authentication: String

        /// Postgres URL connection
        public var connection_url: String

        /// Specifies the database statements to be executed to rotate the root user's credentials. See the plugin's API page for more information on support and formatting for this parameter.
        public var root_rotation_statements: [String]?

        public init(
            enginePath: String?,
            connection: String,
            plugin_name: String,
            verify_connection: Bool?,
            allowed_roles: [String]?,
            username: String,
            password: String,
            max_open_connections: UInt8?,
            max_idle_connections: UInt8?,
            max_connection_lifetime: String?,
            tls_ca: String?,
            tls_certificate: String?,
            private_key: String?,
            auth_type: String?,
            service_account_json: String?,
            use_private_ip: Bool?,
            username_template: String?,
            disable_escaping: Bool?,
            password_authentication: String,
            connection_url: String,
            root_rotation_statements: [String]?
        ) {
            self.enginePath = enginePath
            self.connection = connection
            self.plugin_name = plugin_name
            self.verify_connection = verify_connection
            self.allowed_roles = allowed_roles
            self.username = username
            self.password = password
            self.max_open_connections = max_open_connections
            self.max_idle_connections = max_idle_connections
            self.max_connection_lifetime = max_connection_lifetime
            self.tls_ca = tls_ca
            self.tls_certificate = tls_certificate
            self.private_key = private_key
            self.auth_type = auth_type
            self.service_account_json = service_account_json
            self.use_private_ip = use_private_ip
            self.username_template = username_template
            self.disable_escaping = disable_escaping
            self.password_authentication = password_authentication
            self.connection_url = connection_url
            self.root_rotation_statements = root_rotation_statements
        }
    }

    /// Load the Pkl module at the given source and evaluate it into `PostgresDatabaseConnection.Module`.
    ///
    /// - Parameter source: The source of the Pkl module.
    public static func loadFrom(source: ModuleSource) async throws -> PostgresDatabaseConnection.Module {
        try await PklSwift.withEvaluator { evaluator in
            try await loadFrom(evaluator: evaluator, source: source)
        }
    }

    /// Load the Pkl module at the given source and evaluate it with the given evaluator into
    /// `PostgresDatabaseConnection.Module`.
    ///
    /// - Parameter evaluator: The evaluator to use for evaluation.
    /// - Parameter source: The module to evaluate.
    public static func loadFrom(
        evaluator: PklSwift.Evaluator,
        source: PklSwift.ModuleSource
    ) async throws -> PostgresDatabaseConnection.Module {
        try await evaluator.evaluateModule(source: source, as: Module.self)
    }
}
#endif
