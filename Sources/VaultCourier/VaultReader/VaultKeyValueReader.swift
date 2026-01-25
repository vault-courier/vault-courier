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
import Tracing
import Utils

/// A Pkl resource reader for a KeyValue Vault secret
///
/// You can generate this class from an already existing ``VaultClient`` with ``VaultClient/makeKeyValueSecretReader(mountPath:prefix:)``
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

    public let mountPath: String

    init(client: VaultClient,
         scheme: String,
         mountPath: String,
         backgroundActivityLogger: Logging.Logger? = nil) {
        self.client = client
        self.scheme = scheme
        var logger = backgroundActivityLogger ?? Logger(label: "vault-kv-reader-do-not-log", factory: { _ in SwiftLogNoOpLogHandler() })
        logger[metadataKey: "pkl-resouce-reader"] = "kv"
        logger[metadataKey: "scheme"] = .string(scheme)
        self.logger = logger
        self.mountPath = mountPath
    }

    /// Builds scheme for the ``VaultKeyValueReader``
    ///
    /// Encodes the mount path to a valid scheme by replacing `_` with `-`,
    /// `/` with `.`, and appends it to `vault.`
    ///
    /// Example:
    /// The database mount is `path/to/secrets` is transformed into `path.to.secrets`.
    /// Then a credential can be read with the scheme
    /// `vault.path.to.secrets`
    ///
    /// - Parameters:
    ///   - mountPath: mount path of database secret engine
    ///   - prefix: optional prefix to add in the scheme. It must be a RFC1738 conformant scheme string.
    /// - Returns: encoded scheme
    public static func buildSchemeFor(
        mountPath: String,
        prefix: String? = nil
    ) throws -> String {
        guard mountPath.isValidVaultMountPath else {
            throw VaultClientError.invalidVault(mountPath: mountPath)
        }

        let mount = mountPath.replacingOccurrences(of: "_", with: "-")
                             .replacingOccurrences(of: "/", with: ".")
        return "\(prefix?.appending(".") ?? "")vault.kv.\(mount)"
    }
}

// MARK: ResourceReader

extension VaultKeyValueReader: ResourceReader {
    public func read(url: URL) async throws -> [UInt8] {
        try await withSpan("read-external-resource") { span in
            do {
                let relativePath = url.relativePath.removeSlash()
                let version: Int?
                let key: String
                
                let components = relativePath.split(separator: "?version=", maxSplits: 2).map({String($0)})
                if components.count == 2 {
                    key = components[0]
                    version = Int(components[1])
                } else {
                    key = components[0]
                    version = nil
                }
                
                guard !key.isEmpty else {
                    let error = VaultReaderError.invalidKeyValueURL(relativePath)
                    TracingSupport.handleResponse(error: error, span)
                    throw error
                }
                
                let buffer = try await client.readKeyValueSecretData(
                    mountPath: mountPath.removeSlash(),
                    key: key,
                    version: version
                )
                logger.trace("read kv secret",
                             metadata: [
                                "key": .string(key),
                                "version": .stringConvertible(version ?? "last"),
                                "path": .string(mountPath)
                             ])
                return Array(buffer)
            } catch let error as VaultServerError {
                logger.debug(.init(stringLiteral: String(reflecting: error)))
                TracingSupport.handleResponse(error: error, span)
                throw error
            } catch {
                logger.trace(.init(stringLiteral: String(reflecting: error)))
                let error = VaultReaderError.readingConfigurationFailed()
                TracingSupport.handleResponse(error: error, span)
                throw error
            }
        }
    }

    public func listElements(uri: URL) async throws -> [PklSwift.PathElement] {
        throw PklError("listElements(uri:) not implemented")
    }
}

extension VaultClient {
    /// Creates a KeyValue resource reader for Pkl configuration files using this `VaultClient` instance and its Logger.
    ///
    /// See ``VaultCourier/VaultKeyValueReader/buildSchemeFor(mountPath:prefix:)`` for how the scheme is built.
    ///
    /// - Parameters:
    ///   - mountPath: mount path to key/value secret engine
    ///   - prefix: optional prefix to add to the scheme. Lower case letters "a"..."z", digits, and the characters plus ("+"), period ("."), and hyphen ("-") are allowed.
    /// - Returns: A `ResourceReader` capable of retrieving secrets from Vault using this client.
    public func makeKeyValueSecretReader(
        mountPath: String,
        prefix: String? = nil
    ) throws -> VaultKeyValueReader {
        let schemeString = try VaultKeyValueReader.buildSchemeFor(mountPath: mountPath, prefix: prefix)
        guard let uri = URL(string: "\(schemeString):") else {
            throw VaultClientError.invalidVault(mountPath: mountPath)
        }

        guard let scheme = uri.scheme else {
            throw VaultReaderError.invalidURI(scheme: uri.description)
        }

        return .init(
            client: self,
            scheme: scheme,
            mountPath: mountPath,
            backgroundActivityLogger: logger
        )
    }
}

extension ResourceReader where Self == VaultKeyValueReader {
    /// Reader for KeyValue secrets in a Vault
    public static func vaultKeyValue(
        client: VaultClient,
        mountPath: String,
        prefix: String? = nil,
        backgroundActivityLogger: Logging.Logger? = nil
    ) -> VaultKeyValueReader? {
        guard let schemeString = try? VaultKeyValueReader.buildSchemeFor(mountPath: mountPath, prefix: prefix),
              let uri = URL(string: "\(schemeString):"),
              let scheme = uri.scheme else {
            return nil
        }

        return .init(
            client: client,
            scheme: scheme,
            mountPath: mountPath,
            backgroundActivityLogger: backgroundActivityLogger
        )
    }
}

#endif
