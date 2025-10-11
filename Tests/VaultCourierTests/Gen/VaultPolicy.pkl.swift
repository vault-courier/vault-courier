#if PklSupport
// Code generated from Pkl module `VaultPolicy`. DO NOT EDIT.
import PklSwift

public enum VaultPolicy {}

extension VaultPolicy {
    public enum Capability: String, CaseIterable, CodingKeyRepresentable, Decodable, Hashable, Sendable {
        case create = "create"
        case read = "read"
        case update = "update"
        case delete = "delete"
        case list = "list"
        case sudo = "sudo"
    }

    public struct Module: PklRegisteredType, Decodable, Hashable, Sendable {
        public static let registeredIdentifier: String = "VaultPolicy"

        /// Policy name
        public var name: String

        public var payload: String

        public init(name: String, payload: String) {
            self.name = name
            self.payload = payload
        }
    }

    public struct PathPolicy: PklRegisteredType, Decodable, Hashable, Sendable {
        public static let registeredIdentifier: String = "VaultPolicy#PathPolicy"

        public var capabilities: [Capability]

        public init(capabilities: [Capability]) {
            self.capabilities = capabilities
        }
    }

    public typealias Policy = [String: PathPolicy]

    /// Load the Pkl module at the given source and evaluate it into `VaultPolicy.Module`.
    ///
    /// - Parameter source: The source of the Pkl module.
    public static func loadFrom(source: ModuleSource) async throws -> VaultPolicy.Module {
        try await PklSwift.withEvaluator { evaluator in
            try await loadFrom(evaluator: evaluator, source: source)
        }
    }

    /// Load the Pkl module at the given source and evaluate it with the given evaluator into
    /// `VaultPolicy.Module`.
    ///
    /// - Parameter evaluator: The evaluator to use for evaluation.
    /// - Parameter source: The module to evaluate.
    public static func loadFrom(
        evaluator: PklSwift.Evaluator,
        source: PklSwift.ModuleSource
    ) async throws -> VaultPolicy.Module {
        try await evaluator.evaluateModule(source: source, as: Module.self)
    }
}
#endif
