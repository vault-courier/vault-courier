#if PklSupport
// Code generated from Pkl module `VaultAppRole`. DO NOT EDIT.
import PklSwift

public enum VaultAppRole {}

extension VaultAppRole {
    public enum TokenType: String, CaseIterable, CodingKeyRepresentable, Decodable, Hashable, Sendable {
        case batch = "batch"
        case service = "service"
        case `default` = "default"
    }

    /// Configuration for creating a Vault AppRole
    /// https://developer.hashicorp.com/vault/api-docs/auth/approle#create-update-approle
    public struct Module: PklRegisteredType, Decodable, Hashable, Sendable {
        public static let registeredIdentifier: String = "VaultAppRole"

        /// Custom approle auth path. This value was given in AuthMethodConfig
        public var approle_path: String?

        ///  Name of the AppRole. Must be less than 4096 bytes, accepted characters include a-Z, 0-9, space, hyphen, underscore and periods.
        public var role_name: String

        /// Require `secret_id` to be presented when logging in using this AppRole.
        public var bind_secret_id: Bool?

        /// Comma-separated string or list of CIDR blocks; if set, specifies blocks of IP addresses which can perform the login operation.
        public var secret_id_bound_cidrs: [String]?

        /// Number of times any particular SecretID can be used to fetch a token from this AppRole, after which the SecretID by default will expire. A value of zero will allow unlimited uses. However, this option may be overridden by the request's `num_uses` field when generating a SecretID.
        public var secret_id_num_uses: Int?

        /// Duration in either an integer number of seconds (3600) or an integer time unit (60m) after which by default any SecretID expires. A value of zero will allow the SecretID to not expire. However, this option may be overridden by the request's `ttl` field when generating a SecretID.
        public var secret_id_ttl: Duration?

        /// If set, the secret IDs generated using this role will be cluster local. This can only be set during role creation and once set, it can't be reset later.
        public var local_secret_ids: Bool?

        /// The incremental lifetime for generated tokens. This current value of this will be referenced at renewal time.
        public var token_ttl: Duration?

        /// The maximum lifetime for generated tokens. This current value of this will be referenced at renewal time.
        public var token_max_ttl: Duration?

        /// List of token policies to encode onto generated tokens. Depending on the auth method, this list may be supplemented by user/group/other values.
        public var token_policies: [String]

        /// List of CIDR blocks; if set, specifies blocks of IP addresses which can authenticate successfully, and ties the resulting token to these blocks as well.
        public var token_bound_cidrs: [String]?

        /// If set, will encode an explicit max TTL onto the token. This is a hard cap even if `token_ttl` and `token_max_ttl` would otherwise allow a renewal.
        public var token_explicit_max_ttl: String?

        /// If set, the default policy will not be set on generated tokens; otherwise it will be added to the policies set in `token_policies`.
        public var token_no_default_policy: Bool?

        /// The maximum number of times a generated token may be used (within its lifetime); 0 means unlimited. If you require the token to have the ability to create child tokens, you will need to set this value to 0.
        public var token_num_uses: Int?

        /// The maximum allowed period value when a periodic token is requested from this role.
        public var token_period: Duration?

        /// The type of token that should be generated. Can be service, batch, or default to use the mount's tuned default (which unless changed will be service tokens). For token store roles, there are two additional possibilities: `default-service` and `default-batch` which specify the type to return unless the client requests a different type at generation time. For machine based authentication cases, you should use batch type tokens.
        public var token_type: TokenType

        public init(
            approle_path: String?,
            role_name: String,
            bind_secret_id: Bool?,
            secret_id_bound_cidrs: [String]?,
            secret_id_num_uses: Int?,
            secret_id_ttl: Duration?,
            local_secret_ids: Bool?,
            token_ttl: Duration?,
            token_max_ttl: Duration?,
            token_policies: [String],
            token_bound_cidrs: [String]?,
            token_explicit_max_ttl: String?,
            token_no_default_policy: Bool?,
            token_num_uses: Int?,
            token_period: Duration?,
            token_type: TokenType
        ) {
            self.approle_path = approle_path
            self.role_name = role_name
            self.bind_secret_id = bind_secret_id
            self.secret_id_bound_cidrs = secret_id_bound_cidrs
            self.secret_id_num_uses = secret_id_num_uses
            self.secret_id_ttl = secret_id_ttl
            self.local_secret_ids = local_secret_ids
            self.token_ttl = token_ttl
            self.token_max_ttl = token_max_ttl
            self.token_policies = token_policies
            self.token_bound_cidrs = token_bound_cidrs
            self.token_explicit_max_ttl = token_explicit_max_ttl
            self.token_no_default_policy = token_no_default_policy
            self.token_num_uses = token_num_uses
            self.token_period = token_period
            self.token_type = token_type
        }
    }

    /// Load the Pkl module at the given source and evaluate it into `VaultAppRole.Module`.
    ///
    /// - Parameter source: The source of the Pkl module.
    public static func loadFrom(source: ModuleSource) async throws -> VaultAppRole.Module {
        try await PklSwift.withEvaluator { evaluator in
            try await loadFrom(evaluator: evaluator, source: source)
        }
    }

    /// Load the Pkl module at the given source and evaluate it with the given evaluator into
    /// `VaultAppRole.Module`.
    ///
    /// - Parameter evaluator: The evaluator to use for evaluation.
    /// - Parameter source: The module to evaluate.
    public static func loadFrom(
        evaluator: PklSwift.Evaluator,
        source: PklSwift.ModuleSource
    ) async throws -> VaultAppRole.Module {
        try await evaluator.evaluateModule(source: source, as: Module.self)
    }
}
#endif
