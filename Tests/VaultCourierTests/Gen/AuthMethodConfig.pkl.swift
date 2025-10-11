#if PklSupport
// Code generated from Pkl module `AuthMethodConfig`. DO NOT EDIT.
import PklSwift

public enum AuthMethodConfig {}

extension AuthMethodConfig {
    public enum AuthMethod: String, CaseIterable, CodingKeyRepresentable, Decodable, Hashable, Sendable {
        case approle = "approle"
        case token = "token"
    }

    public enum ConfigKey: String, CaseIterable, CodingKeyRepresentable, Decodable, Hashable, Sendable {
        case default_lease_ttl = "default_lease_ttl"
        case max_lease_ttl = "max_lease_ttl"
        case force_no_cache = "force_no_cache"
        case audit_non_hmac_request_keys = "audit_non_hmac_request_keys"
        case audit_non_hmac_response_keys = "audit_non_hmac_response_keys"
        case listing_visibility = "listing_visibility"
        case passthrough_request_headers = "passthrough_request_headers"
        case allowed_response_headers = "allowed_response_headers"
        case plugin_version = "plugin_version"
        case identity_token = "identity_token"
    }

    /// Payload for enabling auth methods
    public struct Module: PklRegisteredType, Decodable, Hashable, Sendable {
        public static let registeredIdentifier: String = "AuthMethodConfig"

        /// Specifies the path in which to enable the auth method. This is part of the request URL.
        public var path: String

        /// Specifies the name of the authentication method type, such as "approle", github" or "token".
        public var type: AuthMethod

        /// Specifies a human-friendly description of the auth method.
        public var description: String?

        /// Specifies configuration options for this mount; if set on a specific mount, values will override any global defaults (e.g. the system TTL/Max TTL)
        public var config: [ConfigKey: String]?

        ///  Specifies mount type specific options that are passed to the backend.
        public var options: [String: String]?

        /// Specifies if the auth method is local only. Local auth methods are not replicated nor (if a secondary) removed by replication.
        /// Local auth mounts also generate entities for tokens issued. The entity will be replicated across clusters and the aliases generated
        /// on the local auth mount will be local to the cluster. If the goal of marking an auth method as `local` was to comply with GDPR guidelines,
        /// then care must be taken to not set the data pertaining to local auth mount or local auth mount aliases in the metadata of the associated
        /// entity. Metadata related to local auth mount aliases can be stored as custom_metadata on the alias itself which will also be retained locally to the cluster.
        /// These options are allowed in Vault open-source, but relevant functionality is only supported in Vault Enterprise.
        public var local: Bool?

        /// Enable seal wrapping for the mount, causing values stored by the mount to be wrapped by the seal's encryption capability.
        /// These options are allowed in Vault open-source, but relevant functionality is only supported in Vault Enterprise.
        public var seal_wrap: Bool?

        public init(
            path: String,
            type: AuthMethod,
            description: String?,
            config: [ConfigKey: String]?,
            options: [String: String]?,
            local: Bool?,
            seal_wrap: Bool?
        ) {
            self.path = path
            self.type = type
            self.description = description
            self.config = config
            self.options = options
            self.local = local
            self.seal_wrap = seal_wrap
        }
    }

    /// Load the Pkl module at the given source and evaluate it into `AuthMethodConfig.Module`.
    ///
    /// - Parameter source: The source of the Pkl module.
    public static func loadFrom(source: ModuleSource) async throws -> AuthMethodConfig.Module {
        try await PklSwift.withEvaluator { evaluator in
            try await loadFrom(evaluator: evaluator, source: source)
        }
    }

    /// Load the Pkl module at the given source and evaluate it with the given evaluator into
    /// `AuthMethodConfig.Module`.
    ///
    /// - Parameter evaluator: The evaluator to use for evaluation.
    /// - Parameter source: The module to evaluate.
    public static func loadFrom(
        evaluator: PklSwift.Evaluator,
        source: PklSwift.ModuleSource
    ) async throws -> AuthMethodConfig.Module {
        try await evaluator.evaluateModule(source: source, as: Module.self)
    }
}
#endif
