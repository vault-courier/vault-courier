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

/// A Pkl resource reader for a KeyValue Vault secret
///
/// You can generate this class from an already existing ``VaultClient`` with ``VaultClient/makeKeyValueSecretReader(scheme:mount:key:version:)``
///
/// ## Package traits
///
/// This Pkl resource reader is guarded by the `PklSupport` package trait.
///
public final class VaultKeyValueReader: Sendable {
    /// Vault client containing the base URL and secret engine mount paths used for requests.
    let client: VaultClient

    /// Each URI begins with a scheme name that refers to a specification for
    /// assigning identifiers within that scheme.
    public let scheme: String

    public let isGlobbable: Bool = false

    public let hasHierarchicalUris: Bool = true

    let logger: Logging.Logger

    let mount: String
    let key: String
    let version: Int?

    init(client: VaultClient,
         scheme: String,
         mount: String,
         key: String,
         version: Int? = nil,
         backgroundActivityLogger: Logging.Logger? = nil) {
        self.client = client
        self.scheme = scheme
        self.logger = backgroundActivityLogger ?? Logger(label: "vault-resource-reader-do-not-log", factory: { _ in SwiftLogNoOpLogHandler() })
        self.mount = mount
        self.key = key
        self.version = version
    }
}

// MARK: ResourceReader

extension VaultKeyValueReader: ResourceReader {
    public func read(url: URL) async throws -> [UInt8] {
        do {
            let buffer = try await client.readKeyValueSecretData(
                enginePath: mount.removeSlash(),
                key: key,
                version: version
            )
            return Array(buffer)
        } catch let error as VaultServerError {
            logger.debug(.init(stringLiteral: String(reflecting: error)))
            throw error
        } catch {
            logger.error(.init(stringLiteral: String(reflecting: error)))
            throw VaultReaderError.readingConfigurationFailed()
        }
    }

    public func listElements(uri: URL) async throws -> [PklSwift.PathElement] {
        throw PklError("listElements(uri:) not implemented")
    }
}

extension VaultClient {
    /// Creates a KeyValue resource reader for Pkl configuration files using this `VaultClient` instance.
    /// 
    /// 
    /// - Parameters:
    ///   - scheme: The URL scheme this reader handles. Defaults to `vault_kv`.
    ///   - mount: keyValue mount path
    ///   - key: key name of the secret
    ///   - version: version of the secret. `nil` reads the latest.
    /// - Returns: A `ResourceReader` capable of retrieving secrets from Vault using this client.
    public func makeKeyValueSecretReader(
        scheme: String = "vault_kv",
        mount: String,
        key: String,
        version: Int? = nil
    ) throws -> VaultKeyValueReader {
        guard !scheme.isEmpty else {
            throw VaultClientError.invalidArgument("Scheme must not be empty")
        }
        guard !mount.isEmpty else {
            throw VaultClientError.invalidArgument("Mount path must not be empty")
        }
        return .init(
            client: self,
            scheme: scheme,
            mount: mount,
            key: key,
            version: version
        )
    }
}

extension ResourceReader where Self == VaultKeyValueReader {
    /// Reader for KeyValue secrets in a Vault
    public static func vaultKeyValue(
        client: VaultClient,
        scheme: String,
        mount: String,
        key: String,
        version: Int? = nil,
        backgroundActivityLogger: Logging.Logger? = nil
    ) -> VaultKeyValueReader {
        .init(client: client,
              scheme: scheme,
              mount: mount,
              key: key,
              version: version,
              backgroundActivityLogger: backgroundActivityLogger
        )
    }
}

#endif
