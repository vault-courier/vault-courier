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
    /// Vault client containing the base URL and secret engine mount paths used for requests.
    let client: VaultClient

    /// Each URI begins with a scheme name that refers to a specification for
    /// assigning identifiers within that scheme.
    public let scheme: String

    public let isGlobbable: Bool = false

    public let hasHierarchicalUris: Bool = true

    let logger: Logging.Logger

    static let loggingDisabled = Logger(label: "vault-resource-reader-do-not-log", factory: { _ in SwiftLogNoOpLogHandler() })

    let keyValueReaderParser: any KeyValueResourceReaderStrategy

    let databaseReaderParser: any DatabaseResourceReader

    init<T, U>(client: VaultClient,
            scheme: String,
            keyValueReaderParser: T,
            databaseReaderParser: U,
            backgroundActivityLogger: Logging.Logger? = nil)
    where T: KeyValueResourceReaderStrategy, U: DatabaseResourceReader {
        self.client = client
        self.scheme = scheme
        self.logger = backgroundActivityLogger ?? VaultResourceReader.loggingDisabled
        self.keyValueReaderParser = keyValueReaderParser
        self.databaseReaderParser = databaseReaderParser
    }
}

extension VaultResourceReader: ResourceReader {
    public func read(url: URL) async throws -> [UInt8] {
        do {
            if let (mount,key, version) = try keyValueReaderParser.parse(url) {
                let buffer = try await client.readKeyValueSecretData(
                    enginePath: mount.removeSlash(),
                    key: key,
                    version: version
                )
                return Array(buffer)
            } else if let (mount, role) = try databaseReaderParser.parse(url) {
                return try await readDatabaseCredential(mount: mount.removeSlash(), role: role)
            } else {
                throw VaultReaderError.readingUnsupportedEngine(url.relativePath)
            }
        } catch {
            logger.debug(.init(stringLiteral: String(reflecting: error)))
            throw VaultReaderError.readingConfigurationFailed()
        }
    }
    
    public func listElements(uri: URL) async throws -> [PklSwift.PathElement] {
        throw PklError("listElements(uri:) not implemented")
    }

    func readDatabaseCredential(mount: String, role: DatabaseRole) async throws -> [UInt8] {
        let credentials: DatabaseCredentials
        switch role {
            case .static(let name):
                let response = try await client.databaseCredentials(staticRole: name, enginePath: mount)
                credentials = DatabaseCredentials(username: response.username, password: response.password)

            case .dynamic(let name):
                let response = try await client.databaseCredentials(dynamicRole: name, enginePath: mount)
                credentials = DatabaseCredentials(username: response.username, password: response.password)
        }
        let data = try JSONEncoder().encode(credentials)
        return Array(data)
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
            throw VaultReaderError.readingConfigurationFailed()
        }
    }

    /// The file path to the pkl ModuleSource
    public func readConfiguration(
        filepath: String
    ) async throws -> String {
        try await readConfiguration(
            source: .path(filepath),
            expression: "output.text",
            as: String.self
        )
    }

    public func readConfiguration(
        text: String
    ) async throws -> String {
        try await readConfiguration(
            source: .text(text),
            expression: "output.text",
            as: String.self
        )
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
            throw VaultReaderError.readingConfigurationFailed()
        }
    }
}

extension VaultClient {
    /// Creates a custom resource reader for Pkl configuration files using this VaultClient instance.
    /// It uses the client's token and defined secret mounts to fetch the resources on those paths.
    ///
    /// Example of a declaration of a Pkl resource
    /// ```
    /// appKeys = read("vault:/path/to/secrets/key?version=2").text
    /// ```
    ///
    /// - Parameter scheme: The scheme that they are responsible for reading. It defaults to `vault`.
    /// - Returns: Vault resource reader
    public func makeResourceReader(
        scheme: String = "vault"
    ) -> VaultResourceReader {
        .init(client: self,
              scheme: scheme,
              keyValueReaderParser: KeyValueReaderParser(mount: mounts.kv.relativePath.removeSlash()),
              databaseReaderParser: DatabaseReaderParser(mount: mounts.database.relativePath.removeSlash()))
    }
}

public protocol ResourceReaderStrategy: Sendable {
    /// The type of the data type.
    associatedtype ParseOutput

    func parse(_ url: URL) throws -> ParseOutput
}

public protocol KeyValueResourceReaderStrategy: ResourceReaderStrategy {
    /// Parses URL into the parameters the vault client needs to fetch a key/value secret.
    /// - Parameter url: URL to parse
    /// - Returns: Returns `nil` if its not a URL for a KeyValue resource. Otherwise, it returns the parameters needed to call a key/value secret endpoint.
    func parse(_ url: URL) throws -> (mount: String, key: String, version: Int?)?
}

public protocol DatabaseResourceReader: ResourceReaderStrategy {
    /// Parses URL into the parameters the vault client needs to fetch a database secret.
    /// - Parameter url: URL to parse
    /// - Returns: Returns `nil` if its not a URL for a database resource. Otherwise, it returns the parameters needed to call a database secret endpoint.
    func parse(_ url: URL) throws -> (mount: String, role: DatabaseRole)?
}

public struct KeyValueReaderParser: KeyValueResourceReaderStrategy {
    /// Mount path of Key/Value secret
    let mount: String

    public init(mount: String) {
        self.mount = mount.removeSlash()
    }

    public func parse(_ url: URL) throws -> (mount: String, key: String, version: Int?)? {
        let relativePath = url.relativePath.removeSlash()

        if relativePath.starts(with: mount) {
            let query = url.query()
            let key = String(relativePath.suffix(from: mount.endIndex).dropFirst())
            guard !key.isEmpty else {
                throw VaultReaderError.invalidKeyValueURL(relativePath)
            }

            let version: Int? = if let query {
                Int(query.dropFirst("version=".count))
            } else {
                nil
            }

            return (mount: mount, key: key, version: version)
        } else {
            return nil
        }
    }
}

/// Strategy to parse KeyValue resource which splits paths by "/data/"
struct KeyValueDataParser: KeyValueResourceReaderStrategy {
    func parse(_ url: URL) throws -> (mount: String, key: String, version: Int?)? {
        fatalError("Not implemented")
    }
}

public struct DatabaseReaderParser: DatabaseResourceReader {
    /// Mount path to Database secrets
    let mount: String

    public init(mount: String) {
        self.mount = mount.removeSlash()
    }

    public func parse(_ url: URL) throws -> (mount: String, role: DatabaseRole)? {
        let relativePath = url.relativePath.removeSlash()
        if relativePath.starts(with: mount) {
            let databasePath = relativePath.suffix(from: mount.endIndex)
            if databasePath.hasPrefix("/static-creds/") {
                let roleName = try split(url: url, separator: "/static-creds/")
                return (mount, .static(name: roleName))
            } else if databasePath.hasPrefix("/creds/") {
                let roleName = try split(url: url, separator: "/creds/")
                return (mount, .dynamic(name: roleName))
            } else {
                throw VaultReaderError.readingUnsupportedDatabaseEndpoint(url.relativePath)
            }
        } else {
            return nil
        }
    }

    /// Returns role name
    func split(url: URL, separator: String) throws -> String {
        let relativePath = url.relativePath.removeSlash()
        let components = relativePath.split(separator: separator, maxSplits: 2).map({String($0)})
        guard components.count == 2,
              let roleName = components.last else {
            throw VaultReaderError.invalidDatabaseCredential(path: url.relativePath)
        }
        return roleName
    }
}

public enum DatabaseRole: Sendable {
    case `static`(name: String)
    case `dynamic`(name: String)
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
