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

#if PklSupport
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
import Utils

extension ModuleSource: @unchecked Sendable {}

/// A Pkl resource reader for Vault
///
/// You can generate this class from an already existing ``VaultClient`` with ``VaultClient/makeResourceReader(scheme:keyValueReaderParsers:databaseReaderParsers:customResourceReaderParsers:)``
///
/// ## Package traits
///
/// This Pkl resource reader is guarded by the `PklSupport` package trait.
///
public final class VaultResourceReader: Sendable {
    /// Vault client containing the base URL and secret engine mount paths used for requests.
    let client: VaultClient

    /// Each URI begins with a scheme name that refers to a specification for
    /// assigning identifiers within that scheme.
    public let scheme: String

    public let isGlobbable: Bool = false

    public let hasHierarchicalUris: Bool = true

    let logger: Logging.Logger

    /// Strategy for reading the component of key/value resources
    let keyValueReaderParsers: [any KeyValueResourceReaderStrategy]

    /// Strategy for reading the component of database resources
    let databaseReaderParsers: [any DatabaseResourceReaderStrategy]

    /// Custom parse URL strategies. These parses run before ``keyValueReaderParsers`` and ``DatabaseReaderParsers``
    let customParsers: [any CustomResourceReaderStrategy]

    init(client: VaultClient,
         scheme: String,
         keyValueReaderParsers: [any KeyValueResourceReaderStrategy] = [],
         databaseReaderParsers: [any DatabaseResourceReaderStrategy] = [],
         customParsers: [any CustomResourceReaderStrategy] = [],
         backgroundActivityLogger: Logging.Logger? = nil) {
        self.client = client
        self.scheme = scheme
        self.logger = backgroundActivityLogger ?? Logger(label: "vault-resource-reader-do-not-log", factory: { _ in SwiftLogNoOpLogHandler() })
        self.keyValueReaderParsers = keyValueReaderParsers
        self.databaseReaderParsers = databaseReaderParsers
        self.customParsers =  customParsers
    }
}

// MARK: ResourceReader

extension VaultResourceReader: ResourceReader {
    public func read(url: URL) async throws -> [UInt8] {
        do {
            for parser in self.customParsers {
                if let bytes = try await parser.parse(url) {
                    return bytes
                }
            }

            for parser in keyValueReaderParsers {
                if let (mount,key, version) = try parser.parse(url) {
                    let buffer = try await client.readKeyValueSecretData(
                        enginePath: mount.removeSlash(),
                        key: key,
                        version: version
                    )
                    return Array(buffer)
                }
            }

            #if DatabaseEngineSupport
            for parser in databaseReaderParsers {
                if let (mount, role) = try parser.parse(url) {
                    return try await readDatabaseCredential(mount: mount.removeSlash(), role: role)
                }
            }
            #endif

            throw VaultReaderError.readingUnsupportedEngine(url.relativePath)
        } catch {
            logger.debug(.init(stringLiteral: String(reflecting: error)))
            throw VaultReaderError.readingConfigurationFailed()
        }
    }

    public func listElements(uri: URL) async throws -> [PklSwift.PathElement] {
        throw PklError("listElements(uri:) not implemented")
    }

    #if DatabaseEngineSupport
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
    #endif
}

extension VaultClient {
    /// Creates a custom resource reader for Pkl configuration files using this `VaultClient` instance.
    /// 
    /// The reader uses the client's session token, and the respective ``ResourceReaderStrategy`` to parse the secret mounts. These parsed mounts are used in the requests.
    /// 
    /// - Parameters:
    ///   - scheme: The URL scheme this reader handles. Defaults to `vault`.
    ///   - keyValueReaderParsers: Strategies for parsing a Key-Value mount URL.
    ///   - databaseReaderParsers: Strategies for parsing a database mount URL
    ///   - customResourceReaderParsers: custom async strategy for parsing URL directly into bytes. This Parsers has priority over the other parsers
    /// - Returns: A `ResourceReader` capable of retrieving secrets from Vault using this client.
    public func makeResourceReader(
        scheme: String = "vault",
        keyValueReaderParsers: [any KeyValueResourceReaderStrategy] = [],
        databaseReaderParsers: [any DatabaseResourceReaderStrategy] = [],
        customResourceReaderParsers: [any CustomResourceReaderStrategy] = []
    ) throws -> VaultResourceReader {
        guard !scheme.isEmpty else {
            throw VaultClientError.invalidArgument("Scheme must not be empty")
        }
        return .init(
            client: self,
            scheme: scheme,
            keyValueReaderParsers: keyValueReaderParsers,
            databaseReaderParsers: databaseReaderParsers,
            customParsers: customResourceReaderParsers
        )
    }
}
#endif
