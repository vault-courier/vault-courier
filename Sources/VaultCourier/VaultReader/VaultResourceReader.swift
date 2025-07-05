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

/// A Pkl resource reader for Vault
///
/// You can generate this class from an already existing ``VaultClient`` with ``VaultClient.makeResourceReader``
public final class VaultResourceReader<
    KeyValueStrategy: KeyValueResourceReaderStrategy,
    DatabaseStrategy: DatabaseResourceReaderStrategy
> : Sendable {
    /// Vault client containing the base URL and secret engine mount paths used for requests.
    let client: VaultClient

    /// Each URI begins with a scheme name that refers to a specification for
    /// assigning identifiers within that scheme.
    public let scheme: String

    public let isGlobbable: Bool = false

    public let hasHierarchicalUris: Bool = true

    let logger: Logging.Logger

    /// Strategy for reading the component of key/value resources
    let keyValueReaderParser: KeyValueStrategy

    /// Strategy for reading the component of database resources
    let databaseReaderParser: DatabaseStrategy

    init(client: VaultClient,
         scheme: String,
         keyValueReaderParser: KeyValueStrategy,
         databaseReaderParser: DatabaseStrategy,
         backgroundActivityLogger: Logging.Logger? = nil) {
        self.client = client
        self.scheme = scheme
        self.logger = backgroundActivityLogger ?? Logger(label: "vault-resource-reader-do-not-log", factory: { _ in SwiftLogNoOpLogHandler() })
        self.keyValueReaderParser = keyValueReaderParser
        self.databaseReaderParser = databaseReaderParser
    }
}

// MARK: ResourceReader

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
    
    /// Reads a Pkl module and decodes it into the specified type.
    ///
    /// This function loads and evaluates the provided Pkl module, then decodes the result into an instance of the given type.
    ///
    /// - Parameters:
    ///   - source: The Pkl module to read and evaluate.
    ///   - type: The expected output type to decode the module into.
    /// - Returns: An instance of the specified type decoded from the module output.
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

    /// Reads a Pkl module and decodes it into a String
    /// - Parameter filepath: The filepath to the Pkl module
    /// - Returns: The module source decoded into a string
    public func readConfiguration(
        filepath: String
    ) async throws -> String {
        try await readConfiguration(
            source: .path(filepath),
            expression: "output.text",
            as: String.self
        )
    }

    /// Reads a Pkl module and decodes it into a String
    /// - Parameter text: A text representation of the Pkl module
    /// - Returns: The module source decoded into a string
    public func readConfiguration(
        text: String
    ) async throws -> String {
        try await readConfiguration(
            source: .text(text),
            expression: "output.text",
            as: String.self
        )
    }

    
    /// Reads a Pkl module, applies an expression to it, and decodes the result into the specified type.
    ///
    /// This method loads the provided Pkl module, evaluates the given Pkl expression within the context of the module,
    /// and decodes the resulting value into an instance of the specified type.
    ///
    /// - Parameters:
    ///   - source: The Pkl module to load and evaluate.
    ///   - expression: A Pkl expression to apply to the loaded module (e.g., accessing a specific property).
    ///   - type: The type to decode the evaluated result into.
    /// - Returns: A value of the specified type decoded from the result of the evaluated expression.
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
    /// Creates a custom resource reader for Pkl configuration files using this `VaultClient` instance.
    /// The reader uses the client's token and configured secret engine mounts to fetch resources from Vault.
    ///
    /// For example, if a `VaultClient` is initialized with a Key-Value mount at `/path/to/secrets`,
    /// you can access version 2 of the secret at the path `key` from a Pkl file like this:
    ///
    /// ```
    /// appKeys = read("vault:/path/to/secrets/key?version=2").text
    /// ```
    ///
    /// - Parameter scheme: The URL scheme this reader handles. Defaults to `vault`.
    /// - Returns: A `ResourceReader` capable of retrieving secrets from Vault using this client.
    public func makeResourceReader(
        scheme: String = "vault"
    ) -> VaultResourceReader<KeyValueReaderParser, DatabaseReaderParser> {
        .init(
            client: self,
            scheme: scheme,
            keyValueReaderParser: useClientKeyValueMount(),
            databaseReaderParser: useClientDatabaseMount()
        )
    }

    
    /// Creates a custom resource reader for Pkl configuration files using this `VaultClient` instance.
    ///
    /// The reader uses the client's session token, and the respective ``ResourceReaderStrategy`` to parse the secret mounts. These parsed mounts are used in the requests.
    ///
    /// - Parameters:
    ///   - scheme: The URL scheme this reader handles. Defaults to `vault`.
    ///   - keyValueReaderParser: The strategy for parsing a Key-Value mount URL.
    ///   - databaseReaderParser: The strategy for parsing a database mount URL
    /// - Returns: A `ResourceReader` capable of retrieving secrets from Vault using this client.
    public func makeResourceReader<
        KeyValueStrategy: KeyValueResourceReaderStrategy,
        DatabaseStrategy: DatabaseResourceReaderStrategy
    >(
        scheme: String = "vault",
        keyValueReaderParser: KeyValueStrategy,
        databaseReaderParser: DatabaseStrategy
    ) -> VaultResourceReader<KeyValueStrategy, DatabaseStrategy> {
        .init(
            client: self,
            scheme: scheme,
            keyValueReaderParser: keyValueReaderParser,
            databaseReaderParser: databaseReaderParser
        )
    }

    public func useClientKeyValueMount() -> KeyValueReaderParser {
        .mount(mounts.kv.relativePath.removeSlash())
    }

    public func useClientDatabaseMount() -> DatabaseReaderParser {
        .mount(mounts.database.relativePath.removeSlash())
    }
}
#endif
