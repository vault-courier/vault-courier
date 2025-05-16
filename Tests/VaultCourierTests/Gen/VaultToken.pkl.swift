// Code generated from Pkl module `VaultToken`. DO NOT EDIT.
import PklSwift

public enum VaultToken {}

extension VaultToken {
    public enum TokenType: String, CaseIterable, CodingKeyRepresentable, Decodable, Hashable {
        case batch = "batch"
        case service = "service"
    }

    public struct Module: PklRegisteredType, Decodable, Hashable {
        public static let registeredIdentifier: String = "VaultToken"

        /// The ID of the client token. Can only be specified by a root token. The ID provided may not contain a . character. Otherwise, the token ID is a randomly generated value.
        public var id: String?

        /// The name of the token role.
        public var role_name: String?

        /// A list of policies for the token. This must be a subset of the policies belonging to the token making the request, unless the calling token is root or contains sudo capabilities to auth/token/create.
        /// If not specified, defaults to all the policies of the calling token.
        public var policies: [String]?

        /// A map of string to string valued metadata. This is passed through to the audit devices.
        public var meta: [String: String]?

        /// This argument only has effect if used by a root or sudo caller. When set to true, the token created will not have a parent.
        public var no_parent: Bool?

        /// f true the default policy will not be contained in this token's policy set.
        public var no_default_policy: Bool?

        /// Set to false to disable the ability of the token to be renewed past its initial TTL. Setting the value to true will allow the token to be renewable up to the system/mount maximum TTL.
        public var renewable: Bool?

        /// The TTL period of the token, provided as "1h", where hour is the largest suffix. If not provided, the token is valid for the default lease TTL, or indefinitely if the root policy is used.
        public var ttl: Duration?

        /// The token type. Can be "batch" or "service". Defaults to the type specified by the role configuration named by `role_name`.
        public var type: TokenType

        /// If set, the token will have an explicit max TTL set upon it. This maximum token TTL cannot be changed later, and unlike with normal tokens, updates to the system/mount max TTL value will
        /// have no effect at renewal time -- the token will never be able to be renewed or used past the value set at issue time.
        public var explicit_max_ttl: Duration?

        ///  The display name of the token.
        public var display_name: String?

        /// The maximum uses for the given token. This can be used to create a one-time-token or limited use token. The value of 0 has no limit to the number of uses.
        public var num_uses: Int?

        /// If specified, the token will be periodic; it will have no maximum TTL (unless an "explicit-max-ttl" is also set) but every renewal will use the given period. Requires a root token or one with the sudo capability.
        public var period: Duration?

        /// Name of the entity alias to associate with during token creation. Only works in combination with role_name argument and used entity alias must be listed in allowed_entity_aliases.
        /// If this has been specified, the entity will not be inherited from the parent.
        public var entity_alias: String?

        public init(
            id: String?,
            role_name: String?,
            policies: [String]?,
            meta: [String: String]?,
            no_parent: Bool?,
            no_default_policy: Bool?,
            renewable: Bool?,
            ttl: Duration?,
            type: TokenType,
            explicit_max_ttl: Duration?,
            display_name: String?,
            num_uses: Int?,
            period: Duration?,
            entity_alias: String?
        ) {
            self.id = id
            self.role_name = role_name
            self.policies = policies
            self.meta = meta
            self.no_parent = no_parent
            self.no_default_policy = no_default_policy
            self.renewable = renewable
            self.ttl = ttl
            self.type = type
            self.explicit_max_ttl = explicit_max_ttl
            self.display_name = display_name
            self.num_uses = num_uses
            self.period = period
            self.entity_alias = entity_alias
        }
    }

    /// Load the Pkl module at the given source and evaluate it into `VaultToken.Module`.
    ///
    /// - Parameter source: The source of the Pkl module.
    public static func loadFrom(source: ModuleSource) async throws -> VaultToken.Module {
        try await PklSwift.withEvaluator { evaluator in
            try await loadFrom(evaluator: evaluator, source: source)
        }
    }

    /// Load the Pkl module at the given source and evaluate it with the given evaluator into
    /// `VaultToken.Module`.
    ///
    /// - Parameter evaluator: The evaluator to use for evaluation.
    /// - Parameter source: The module to evaluate.
    public static func loadFrom(
        evaluator: PklSwift.Evaluator,
        source: PklSwift.ModuleSource
    ) async throws -> VaultToken.Module {
        try await evaluator.evaluateModule(source: source, as: Module.self)
    }
}