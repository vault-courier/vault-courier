#if PklSupport
// Code generated from Pkl module `PostgresRole`. DO NOT EDIT.
import PklSwift

public enum PostgresRole {}

extension PostgresRole {
    public enum CredentialType: String, CaseIterable, CodingKeyRepresentable, Decodable, Hashable {
        case password = "password"
        case rsa_private_key = "rsa_private_key"
        case client_certificate = "client_certificate"
    }

    /// Dynamic Postgres Database Role
    ///
    /// [Vault documentation](https://developer.hashicorp.com/vault/api-docs/secret/databases#create-role)
    public struct Module: PklRegisteredType, Decodable, Hashable {
        public static let registeredIdentifier: String = "PostgresRole"

        /// Specifies the name of the role to create. This is specified as part of the URL.
        public var name: String

        /// The name of the database connection to use for this role.
        public var db_connection_name: String

        /// Specifies the TTL for the leases associated with this role. Accepts time suffixed strings (1h) or an integer number of seconds. Defaults to system/engine default TTL time.
        public var default_ttl: Duration?

        /// Specifies the maximum TTL for the leases associated with this role. Accepts time suffixed strings (1h) or an integer number of seconds. Defaults to sys/mounts's default TTL time;
        /// this value is allowed to be less than the mount max TTL (or, if not set, the system max TTL), but it is not allowed to be longer. See also The TTL General Case.
        public var max_ttl: Duration?

        ///  Specifies the database statements executed to create and configure a user. Must be a semicolon-separated string, a base64-encoded semicolon-separated string,
        /// a serialized JSON string array, or a base64-encoded serialized JSON string array. The `{{name}}`, `{{password}}` and `{{expiration}}` values will be substituted. The generated password will be a random alphanumeric 20 character string.
        public var creation_statements: [String]

        /// Specifies the database statements to be executed to revoke a user. Must be a semicolon-separated string, a base64-encoded semicolon-separated string, a serialized JSON string array, or a base64-encoded serialized JSON string array.
        /// The `{{name}}` value will be substituted. If not provided defaults to a generic drop user statement.
        public var revocation_statements: [String]?

        /// Specifies the database statements to be executed rollback a create operation in the event of an error. Not every plugin type will support this functionality. Must be a semicolon-separated string, a base64-encoded semicolon-separated string,
        /// a serialized JSON string array, or a base64-encoded serialized JSON string array. The `{{name}}` value will be substituted.
        public var rollback_statements: [String]?

        /// Specifies the database statements to be executed to renew a user. Not every plugin type will support this functionality. Must be a semicolon-separated string, a base64-encoded semicolon-separated string, a serialized JSON string array,
        /// or a base64-encoded serialized JSON string array. The `{{name}}` and `{{expiration}}` values will be substituted.
        public var renew_statements: [String]?

        /// Specifies the database statements to be executed to rotate the password for a given username. Must be a semicolon-separated string, a base64-encoded semicolon-separated string, a serialized JSON string array,
        /// or a base64-encoded serialized JSON string array. The `{{name}}` and `{{password}}` values will be substituted. The generated password will be a random alphanumeric 20 character string.
        public var rotation_statements: [String]?

        /// Specifies the type of credential that will be generated for the role. Options include: `password`,
        /// `rsa_private_key`, `client_certificate`. See the plugin's API page for credential types supported 
        /// by individual databases.
        public var credential_type: CredentialType?

        /// Specifies the configuration for the given `credential_type`. See documentation for details
        public var credential_config: [String: String]?

        public init(
            name: String,
            db_connection_name: String,
            default_ttl: Duration?,
            max_ttl: Duration?,
            creation_statements: [String],
            revocation_statements: [String]?,
            rollback_statements: [String]?,
            renew_statements: [String]?,
            rotation_statements: [String]?,
            credential_type: CredentialType?,
            credential_config: [String: String]?
        ) {
            self.name = name
            self.db_connection_name = db_connection_name
            self.default_ttl = default_ttl
            self.max_ttl = max_ttl
            self.creation_statements = creation_statements
            self.revocation_statements = revocation_statements
            self.rollback_statements = rollback_statements
            self.renew_statements = renew_statements
            self.rotation_statements = rotation_statements
            self.credential_type = credential_type
            self.credential_config = credential_config
        }
    }

    public struct PasswordCredential: PklRegisteredType, Decodable, Hashable {
        public static let registeredIdentifier: String = "PostgresRole#PasswordCredential"

        public var passwordPolicy: String?

        public init(passwordPolicy: String?) {
            self.passwordPolicy = passwordPolicy
        }
    }

    public struct RSAPrivateKey: PklRegisteredType, Decodable, Hashable {
        public static let registeredIdentifier: String = "PostgresRole#RSAPrivateKey"

        public var key_bits: Int?

        public var format: String?

        public init(key_bits: Int?, format: String?) {
            self.key_bits = key_bits
            self.format = format
        }
    }

    public struct ClientCertificate: PklRegisteredType, Decodable, Hashable {
        public static let registeredIdentifier: String = "PostgresRole#ClientCertificate"

        /// A username template to be used for the client certificate common name.
        public var common_name_template: String?

        /// The PEM-encoded CA certificate.
        public var ca_cert: String?

        /// The PEM-encoded private key for the given ca_cert.
        public var ca_private_key: String?

        /// Specifies the desired key type. Options include: rsa, ed25519, ec.
        public var key_type: String

        /// Number of bits to use for the generated keys. Options include: 2048 (default),
        /// 3072, 4096; with `key_type=ec`, allowed values are: 224, 256 (default), 384, 521; ignored with `key_type=ed25519`.
        public var key_bits: Int?

        /// The number of bits to use in the signature algorithm. Options include: 256 (default), 384, 512.
        public var signature_bits: Int?

        public init(
            common_name_template: String?,
            ca_cert: String?,
            ca_private_key: String?,
            key_type: String,
            key_bits: Int?,
            signature_bits: Int?
        ) {
            self.common_name_template = common_name_template
            self.ca_cert = ca_cert
            self.ca_private_key = ca_private_key
            self.key_type = key_type
            self.key_bits = key_bits
            self.signature_bits = signature_bits
        }
    }

    /// Load the Pkl module at the given source and evaluate it into `PostgresRole.Module`.
    ///
    /// - Parameter source: The source of the Pkl module.
    public static func loadFrom(source: ModuleSource) async throws -> PostgresRole.Module {
        try await PklSwift.withEvaluator { evaluator in
            try await loadFrom(evaluator: evaluator, source: source)
        }
    }

    /// Load the Pkl module at the given source and evaluate it with the given evaluator into
    /// `PostgresRole.Module`.
    ///
    /// - Parameter evaluator: The evaluator to use for evaluation.
    /// - Parameter source: The module to evaluate.
    public static func loadFrom(
        evaluator: PklSwift.Evaluator,
        source: PklSwift.ModuleSource
    ) async throws -> PostgresRole.Module {
        try await evaluator.evaluateModule(source: source, as: Module.self)
    }
}
#endif
