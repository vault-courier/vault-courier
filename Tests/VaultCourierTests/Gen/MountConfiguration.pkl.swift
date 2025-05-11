// Code generated from Pkl module `MountConfiguration`. DO NOT EDIT.
import PklSwift

public enum MountConfiguration {}

extension MountConfiguration {
    public enum SecretEngine: String, CaseIterable, CodingKeyRepresentable, Decodable, Hashable {
        case kv = "kv"
        case database = "database"
    }

    public enum ConfigKey: String, CaseIterable, CodingKeyRepresentable, Decodable, Hashable {
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

    /// Vault System Mount. Enables a new secrets engine at the given path
    public struct Module: PklRegisteredType, Decodable, Hashable {
        public static let registeredIdentifier: String = "MountConfiguration"

        /// Specifies the type of the backend, such as "kv", "database", "aws", etc...
        public var type: SecretEngine

        /// Specifies the path where the secrets engine will be mounted. This is specified as part of the URL.
        public var path: String

        /// Specifies the human-friendly description of the mount.
        public var description: String?

        /// Specifies configuration options for this mount; if set on a specific mount, values will override any global defaults (e.g. the system TTL/Max TTL)
        public var config: [ConfigKey: String]?

        ///  Specifies mount type specific options that are passed to the backend.
        public var options: [String: String]?

        public var local: Bool?

        public var seal_wrap: Bool?

        public var external_entropy_access: Bool?

        public init(
            type: SecretEngine,
            path: String,
            description: String?,
            config: [ConfigKey: String]?,
            options: [String: String]?,
            local: Bool?,
            seal_wrap: Bool?,
            external_entropy_access: Bool?
        ) {
            self.type = type
            self.path = path
            self.description = description
            self.config = config
            self.options = options
            self.local = local
            self.seal_wrap = seal_wrap
            self.external_entropy_access = external_entropy_access
        }
    }

    /// Load the Pkl module at the given source and evaluate it into `MountConfiguration.Module`.
    ///
    /// - Parameter source: The source of the Pkl module.
    public static func loadFrom(source: ModuleSource) async throws -> MountConfiguration.Module {
        try await PklSwift.withEvaluator { evaluator in
            try await loadFrom(evaluator: evaluator, source: source)
        }
    }

    /// Load the Pkl module at the given source and evaluate it with the given evaluator into
    /// `MountConfiguration.Module`.
    ///
    /// - Parameter evaluator: The evaluator to use for evaluation.
    /// - Parameter source: The module to evaluate.
    public static func loadFrom(
        evaluator: PklSwift.Evaluator,
        source: PklSwift.ModuleSource
    ) async throws -> MountConfiguration.Module {
        try await evaluator.evaluateModule(source: source, as: Module.self)
    }
}