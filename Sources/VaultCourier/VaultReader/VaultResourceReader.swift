//===----------------------------------------------------------------------===//
//  Copyright (c) 2025 Javier Cuesta
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//===----------------------------------------------------------------------===//

#if Pkl
import PklSwift
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.URL
import class Foundation.JSONDecoder
import class Foundation.JSONEncoder
import struct Foundation.Data
#endif
import Logging

extension ModuleSource: @unchecked Sendable { }

public final class VaultResourceReader: Sendable {
    let client: VaultClient

    /// Each URI begins with a scheme name that refers to a specification for
    /// assigning identifiers within that scheme.
    public let scheme: String

    public let isGlobbable: Bool = false

    public let hasHierarchicalUris: Bool = true

    let logger: Logging.Logger

    static let loggingDisabled = Logger(label: "vault-resource-reader-do-not-log", factory: { _ in SwiftLogNoOpLogHandler() })

    init(client: VaultClient,
         scheme: String,
         backgroundActivityLogger: Logging.Logger? = nil) {
        self.client = client
        self.scheme = scheme
        self.logger = backgroundActivityLogger ?? VaultResourceReader.loggingDisabled
    }
}

extension VaultResourceReader: ResourceReader {
    public func read(url: URL) async throws -> [UInt8] {
        let mountPath = url.relativePath.removeSlash()
        let kvMountPath = client.mounts.kv.relativePath.removeSlash()
        let databaseMountPath = client.mounts.database.relativePath.removeSlash()

        if mountPath.starts(with: kvMountPath) {
            return try await readKVSecret(relativePath: mountPath)
        } else if mountPath.starts(with: databaseMountPath) {
            let databasePath = mountPath.suffix(from: client.mounts.database.relativePath.endIndex)
            if databasePath.hasPrefix("/static-creds/") {
                return try await readStaticDatabaseCredential(relativePath: mountPath)
            } else if databasePath.hasPrefix("/creds/") {
                return try await readDatabaseCredential(relativePath: mountPath)
            } else {
                throw VaultClientError.readingUnsupportedDatabaseEndpoint(url.relativePath)
            }
        } else {
            throw VaultClientError.readingUnsupportedEngine(url.relativePath)
        }
    }
    
    public func listElements(uri: URL) async throws -> [PklSwift.PathElement] {
        throw PklError("listElements(uri:) not implemented")
    }

    func readKVSecret(relativePath: String) async throws -> [UInt8] {
        let key = String(relativePath.suffix(from: client.mounts.kv.relativePath.endIndex).dropFirst())
        guard !key.isEmpty else {
            logger.error("missing key in url path")
            throw VaultReaderError.invalidKeyValueURL(relativePath)
        }

        do {
            let buffer = try await client.readKeyValueSecretData(key: key)
            return Array(buffer)
        } catch {
            logger.debug(.init(stringLiteral: String(reflecting: error)))
            throw VaultClientError.readingConfigurationFailed()
        }
    }

    func readStaticDatabaseCredential(relativePath: String) async throws -> [UInt8] {
        let components = relativePath.split(separator: "/static-creds/", maxSplits: 2).map({String($0)})
        guard components.count == 2,
              let enginePath = components.first,
              let roleName = components.last else {
            throw VaultReaderError.invalidDatabaseCredential(path: relativePath)
        }

        do {
            let response = try await client.databaseCredentials(staticRole: roleName, enginePath: enginePath)
            let credentials = DatabaseCredentials(username: response.username, password: response.password)
            let data = try JSONEncoder().encode(credentials)

            return Array(data)
        } catch {
            logger.debug(.init(stringLiteral: String(reflecting: error)))
            throw VaultClientError.readingConfigurationFailed()
        }
    }

    func readDatabaseCredential(relativePath: String) async throws -> [UInt8] {
        let components = relativePath.split(separator: "/creds/", maxSplits: 2).map({String($0)})
        guard components.count == 2,
              let enginePath = components.first,
              let roleName = components.last else {
            throw VaultReaderError.invalidDatabaseCredential(path: relativePath)
        }

        do {
            let response = try await client.databaseCredentials(dynamicRole: roleName, enginePath: enginePath)
            let credentials = DatabaseCredentials(username: response.username, password: response.password)
            let data = try JSONEncoder().encode(credentials)

            return Array(data)
        } catch {
            logger.debug(.init(stringLiteral: String(reflecting: error)))
            throw VaultClientError.readingConfigurationFailed()
        }
    }
}

extension VaultResourceReader {
    public func readConfiguration<T>(
        source: ModuleSource,
        as type: T.Type,
    ) async throws -> T
    where T: Decodable & Sendable {
        do {
            // `withEvaluatorManager` is executing on VaultClient
            // Closure inherits VaultClient isolation
            // We explicitly set withEvaluatorManager to be isolated to the VaultClient
            let output = try await withEvaluatorManager(isolation: client) { manager in
                let readerOptions = EvaluatorOptions.preconfigured
                    .withResourceReader(self)

                // Executing on VaultClient actor
                return try await manager.withEvaluator(options: readerOptions) { evaluator in
                    return try await evaluator.evaluateModule(source: source, as: type)
                }
            }

            return output
        } catch let error as PklSwift.PklError {
            logger.debug(.init(stringLiteral: String(describing: error.message)))
            throw VaultClientError.readingConfigurationFailed()
        }
    }

    /// The file path to the pkl ModuleSource
    public func readConfiguration(
        filepath: String
    ) async throws -> String {
        do {
            let output = try await withEvaluatorManager(isolation: client) { manager in
                let readerOptions = EvaluatorOptions.preconfigured
                    .withResourceReader(self)

                return try await manager.withEvaluator(options: readerOptions) { evaluator in
                    return try await evaluator.evaluateOutputText(source: .path(filepath))
                }
            }

            return output
        } catch let error as PklSwift.PklError {
            logger.debug(.init(stringLiteral: String(describing: error.message)))
            throw VaultClientError.readingConfigurationFailed()
        }
    }

    public func readConfiguration(
        text: String
    ) async throws -> String {
        do {
            let output = try await withEvaluatorManager(isolation: client) { manager in
                let readerOptions = EvaluatorOptions.preconfigured
                    .withResourceReader(self)

                return try await manager.withEvaluator(options: readerOptions) { evaluator in
                    return try await evaluator.evaluateOutputText(source: .text(text))
                }
            }

            return output
        } catch let error as PklSwift.PklError {
            logger.debug(.init(stringLiteral: String(describing: error.message)))
            throw VaultClientError.readingConfigurationFailed()
        }
    }

    public func readConfiguration<T>(
        source: ModuleSource,
        expression: String,
        as type: T.Type,
    ) async throws -> T
    where T: Decodable & Sendable {
        do {
            let output = try await withEvaluatorManager(isolation: client) { manager in
                let readerOptions = EvaluatorOptions.preconfigured
                    .withResourceReader(self)

                return try await manager.withEvaluator(options: readerOptions) { evaluator in
                    return try await evaluator.evaluateExpression(source: source, expression: expression, as: type)
                }
            }

            return output
        } catch let error as PklSwift.PklError {
            logger.debug(.init(stringLiteral: String(describing: error.message)))
            throw VaultClientError.readingConfigurationFailed()
        }
    }
}


final class ResourceReaderStrategy {

}

extension VaultClient {
    public func makeResourceReader(
        scheme: String = "vault"
    ) -> VaultResourceReader {
        .init(client: self,
              scheme: scheme)
    }
}

public struct VaultReaderError: Error, Sendable {
    public var message: String

    static func readingConfigurationFailed() -> VaultClientError {
        .init(message: "Reading module failed")
    }

    static func invalidKeyValueURL(_ relativePath: String) -> VaultClientError {
        .init(message: "Invalid key-value relative path: \(relativePath).")
    }

    static func invalidDatabaseCredential(path: String) -> VaultClientError {
        .init(message: "Invalid database credential path: \(path).")
    }

    static func readingUnsupportedEngine(_ relativePath: String) -> VaultClientError {
        .init(message: "Reading unsupported vault engine or path: \(relativePath).")
    }

    static func readingUnsupportedDatabaseEndpoint(_ relativePath: String) -> VaultClientError {
        .init(message: "Reading unsupported database endpoint: \(relativePath)")
    }
}


#endif
