// Code generated from Pkl module `TodoConfig`. DO NOT EDIT.
@preconcurrency import PklSwift

public enum TodoConfig {}

extension TodoConfig {
    public struct Module: PklRegisteredType, Decodable, Hashable, Sendable {
        public static let registeredIdentifier: String = "TodoConfig"

        public var postgresConfig: PostgresConfig

        public init(postgresConfig: PostgresConfig) {
            self.postgresConfig = postgresConfig
        }
    }

    public struct PostgresConfig: PklRegisteredType, Decodable, Hashable, Sendable {
        public static let registeredIdentifier: String = "TodoConfig#PostgresConfig"

        /// The host url of Server
        public var hostname: String

        /// The port to listen
        public var port: Int

        /// Database name
        public var database: String

        /// Database credentials
        public var credentials: String

        public init(hostname: String, port: Int, database: String, credentials: String) {
            self.hostname = hostname
            self.port = port
            self.database = database
            self.credentials = credentials
        }
    }

    /// Load the Pkl module at the given source and evaluate it into `TodoConfig.Module`.
    ///
    /// - Parameter source: The source of the Pkl module.
    public static func loadFrom(source: ModuleSource) async throws -> TodoConfig.Module {
        try await PklSwift.withEvaluator { evaluator in
            try await loadFrom(evaluator: evaluator, source: source)
        }
    }

    /// Load the Pkl module at the given source and evaluate it with the given evaluator into
    /// `TodoConfig.Module`.
    ///
    /// - Parameter evaluator: The evaluator to use for evaluation.
    /// - Parameter source: The module to evaluate.
    public static func loadFrom(
        evaluator: PklSwift.Evaluator,
        source: PklSwift.ModuleSource
    ) async throws -> TodoConfig.Module {
        try await evaluator.evaluateModule(source: source, as: Module.self)
    }
}
