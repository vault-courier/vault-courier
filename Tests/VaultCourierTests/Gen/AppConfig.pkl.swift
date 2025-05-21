// Code generated from Pkl module `AppConfig`. DO NOT EDIT.
import PklSwift

public enum AppConfig {}

extension AppConfig {
    public struct Module: PklRegisteredType, Decodable, Hashable, Sendable {
        public static let registeredIdentifier: String = "AppConfig"

        public var appKeys: String?

        public var database: Database?

        public init(appKeys: String?, database: Database?) {
            self.appKeys = appKeys
            self.database = database
        }
    }

    public struct Database: PklRegisteredType, Decodable, Hashable, Sendable {
        public static let registeredIdentifier: String = "AppConfig#Database"

        public var hostname: String

        public var port: Int

        public var credentials: String?

        public init(hostname: String, port: Int, credentials: String?) {
            self.hostname = hostname
            self.port = port
            self.credentials = credentials
        }
    }

    /// Load the Pkl module at the given source and evaluate it into `AppConfig.Module`.
    ///
    /// - Parameter source: The source of the Pkl module.
    public static func loadFrom(source: ModuleSource) async throws -> AppConfig.Module {
        try await PklSwift.withEvaluator { evaluator in
            try await loadFrom(evaluator: evaluator, source: source)
        }
    }

    /// Load the Pkl module at the given source and evaluate it with the given evaluator into
    /// `AppConfig.Module`.
    ///
    /// - Parameter evaluator: The evaluator to use for evaluation.
    /// - Parameter source: The module to evaluate.
    public static func loadFrom(
        evaluator: PklSwift.Evaluator,
        source: PklSwift.ModuleSource
    ) async throws -> AppConfig.Module {
        try await evaluator.evaluateModule(source: source, as: Module.self)
    }
}
