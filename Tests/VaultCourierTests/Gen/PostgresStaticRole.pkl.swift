#if Pkl
// Code generated from Pkl module `PostgresStaticRole`. DO NOT EDIT.
import PklSwift

public enum PostgresStaticRole {}

extension PostgresStaticRole {
    public enum CredentialType: String, CaseIterable, CodingKeyRepresentable, Decodable, Hashable {
        case password = "password"
        case rsa_private_key = "rsa_private_key"
        case client_certificate = "client_certificate"
    }

    /// Postgres Static Role
    ///
    /// [Vault Static Role documentation](https://developer.hashicorp.com/vault/api-docs/secret/databases#create-static-role)
    public struct Module: PklRegisteredType, Decodable, Hashable {
        public static let registeredIdentifier: String = "PostgresStaticRole"

        /// The corresponding role in the database of `db_username`
        public var vault_role_name: String

        /// Specifies the database username that this Vault role corresponds to. See `vault_role_name`
        public var db_username: String

        /// The name of the database connection to use for this role.
        public var db_connection_name: String

        /// Specifies the amount of time Vault should wait before rotating the password. The minimum is 5 seconds.
        /// Uses duration format strings. Mutually exclusive with `rotation_schedule`.
        public var rotation_period: Duration?

        /// A cron-style string that will define the schedule on which rotations should occur. This should be
        /// a "standard" cron-style string made of five fields of which each entry defines the minute, hour,
        /// day of month, month, and day of week respectively. For example, a value of '0 0 * * SAT' will set
        /// rotations to occur on Saturday at 00:00. Mutually exclusive with `rotation_period`."
        public var rotation_schedule: String?

        /// Specifies the amount of time in which the rotation is allowed to occur starting from a given `rotation_schedule`.
        /// If the credential is not rotated during this window, due to a failure or otherwise, it will not be rotated until
        /// the next scheduled rotation. The minimum is 1 hour. Uses duration format strings. Optional when `rotation_schedule`
        /// is set and disallowed when `rotation_period` is set.
        public var rotation_window: Duration?

        /// Specifies the database statements to be executed to rotate the password for the configured database user.
        /// Not every plugin type will support this functionality. See the plugin's API page for more information on
        /// support and formatting for this parameter.
        public var rotation_statements: [String]?

        /// Specifies the type of credential that will be generated for the role. Options include: `password`,
        /// `rsa_private_key`, `client_certificate`. See the plugin's API page for credential types supported 
        /// by individual databases.
        public var credential_type: CredentialType?

        /// Specifies the configuration for the given `credential_type`. See documentation for details
        public var credential_config: [String: String]?

        public init(
            vault_role_name: String,
            db_username: String,
            db_connection_name: String,
            rotation_period: Duration?,
            rotation_schedule: String?,
            rotation_window: Duration?,
            rotation_statements: [String]?,
            credential_type: CredentialType?,
            credential_config: [String: String]?
        ) {
            self.vault_role_name = vault_role_name
            self.db_username = db_username
            self.db_connection_name = db_connection_name
            self.rotation_period = rotation_period
            self.rotation_schedule = rotation_schedule
            self.rotation_window = rotation_window
            self.rotation_statements = rotation_statements
            self.credential_type = credential_type
            self.credential_config = credential_config
        }
    }

    public struct RotationPeriod: PklRegisteredType, Decodable, Hashable {
        public static let registeredIdentifier: String = "PostgresStaticRole#RotationPeriod"

        public var period: Duration

        public init(period: Duration) {
            self.period = period
        }
    }

    public struct RotationSchedule: PklRegisteredType, Decodable, Hashable {
        public static let registeredIdentifier: String = "PostgresStaticRole#RotationSchedule"

        public var schedule: String

        public var window: Duration?

        public init(schedule: String, window: Duration?) {
            self.schedule = schedule
            self.window = window
        }
    }

    public struct PasswordCredential: PklRegisteredType, Decodable, Hashable {
        public static let registeredIdentifier: String = "PostgresStaticRole#PasswordCredential"

        public var passwordPolicy: String?

        public init(passwordPolicy: String?) {
            self.passwordPolicy = passwordPolicy
        }
    }

    public struct RSAPrivateKey: PklRegisteredType, Decodable, Hashable {
        public static let registeredIdentifier: String = "PostgresStaticRole#RSAPrivateKey"

        public var key_bits: Int?

        public var format: String?

        public init(key_bits: Int?, format: String?) {
            self.key_bits = key_bits
            self.format = format
        }
    }

    public struct ClientCertificate: PklRegisteredType, Decodable, Hashable {
        public static let registeredIdentifier: String = "PostgresStaticRole#ClientCertificate"

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

    /// Load the Pkl module at the given source and evaluate it into `PostgresStaticRole.Module`.
    ///
    /// - Parameter source: The source of the Pkl module.
    public static func loadFrom(source: ModuleSource) async throws -> PostgresStaticRole.Module {
        try await PklSwift.withEvaluator { evaluator in
            try await loadFrom(evaluator: evaluator, source: source)
        }
    }

    /// Load the Pkl module at the given source and evaluate it with the given evaluator into
    /// `PostgresStaticRole.Module`.
    ///
    /// - Parameter evaluator: The evaluator to use for evaluation.
    /// - Parameter source: The module to evaluate.
    public static func loadFrom(
        evaluator: PklSwift.Evaluator,
        source: PklSwift.ModuleSource
    ) async throws -> PostgresStaticRole.Module {
        try await evaluator.evaluateModule(source: source, as: Module.self)
    }
}
#endif
