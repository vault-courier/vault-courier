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

#if PklSupport && DatabaseEngineSupport
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

/// A Pkl resource reader for database credentials managed by Vault
///
/// You can generate this class from an already existing ``VaultClient`` with ``VaultClient/makeDatabaseCredentialReader(mountPath:namespace:)``
///
/// ## Package traits
///
/// This Pkl resource reader is guarded by the `PklSupport` package trait.
///
public final class VaultDatabaseCredentialReader: Sendable {
    /// Vault client containing the base URL and secret engine mount paths used for requests.
    let client: VaultClient

    /// Each URI begins with a scheme name that refers to a specification for
    /// assigning identifiers within that scheme.
    public let scheme: String

    public let isGlobbable: Bool = false

    public let hasHierarchicalUris: Bool = true

    let logger: Logging.Logger

    /// Path to database engine mount
    public let mountPath: String

    /// Optional child namespace with respect to the client's namespace.
    public let namespace: String?

    init(client: VaultClient,
         scheme: String,
         mountPath: String,
         namespace: String? = nil,
         backgroundActivityLogger: Logging.Logger? = nil) {
        self.client = client
        self.scheme = scheme
        var logger = backgroundActivityLogger ?? Logger(label: "vault-database-credential-reader-do-not-log", factory: { _ in SwiftLogNoOpLogHandler() })
        logger[metadataKey: "pkl-resouce-reader"] = "database"
        logger[metadataKey: "scheme"] = .string(scheme)
        self.logger = logger
        self.mountPath = mountPath
        self.namespace = namespace
    }

    /// Builds scheme for the ``VaultDatabaseCredentialReader``
    /// 
    /// Encodes the mount path to a valid scheme by replacing `_` with `-`,
    /// `/` with `.`, and appends it to `vault.`
    /// 
    /// Example:
    /// The database mount is `path/to/my_database` is transformed into `path.to.my-database`.
    /// Then a credential can be read with the scheme
    /// `vault.path.to.my-database`
    ///
    ///  An optional namespace with respect to the vault client's namespace can be added. The resulting scheme for a namespace
    ///  is prepended to `vault.path.to.my-database`. E.g. for the child namespace `tenant-a/stage` the resulting scheme is
    ///  `tenant-a.stage.vault.path.to.my-database`
    ///
    ///
    /// - Parameters:
    ///   - mountPath: mount path of database secret engine
    ///   - namespace: optional child namespace. Let it `nil` for the parent namespace
    /// - Returns: encoded scheme
    public static func buildSchemeFor(
        mountPath: String,
        namespace: String? = nil
    ) throws -> String {
        guard mountPath.isValidVaultMountPath else {
            throw VaultClientError.invalidVault(mountPath: mountPath)
        }

        let childNamespace: String?
        if let namespace {
            guard namespace.isValidNamespace else {
                throw VaultClientError.invalidVault(namespace: namespace)
            }

            childNamespace = namespace.replacing("_", with: "-")
                                      .replacing("/", with: ".")
        } else {
            childNamespace = nil
        }

        let mount = mountPath.replacing("_", with: "-")
                             .replacing("/", with: ".")

        return "\(childNamespace?.appending(".") ?? "")vault.\(mount)"
    }
}

// MARK: ResourceReader

extension VaultDatabaseCredentialReader: ResourceReader {
    public func read(url: URL) async throws -> [UInt8] {
        try await withSpan("read-external-resource") { span in
            do {
                let credentials: DatabaseCredentials
                let relativePath = url.relativePath.removeSlash()
                let fullNamespace = if let namespace {
                    client.namespace.name + "/\(namespace)"
                } else {
                    client.namespace.name
                }

                if relativePath.hasPrefix("static-creds/") {
                    let roleName = relativePath.suffix(from: "static-creds/".endIndex)
                    let response = try await client.withDatabaseClient(namespace: namespace, mountPath: mountPath) { client in
                        try await client.databaseCredentials(staticRole: String(roleName))
                    }
                    credentials = DatabaseCredentials(username: response.username, password: response.password)
                    logger.trace("read static database credentials",
                                 metadata: [
                                    "role": .stringConvertible(roleName),
                                    "path": .string(mountPath),
                                    "namespace": .string(namespace ?? "root")
                                 ])
                } else if relativePath.hasPrefix("creds/") {
                    let roleName = relativePath.suffix(from: "creds/".endIndex)
                    let response = try await client.withDatabaseClient(namespace: namespace, mountPath: mountPath) { client in
                        try await client.databaseCredentials(dynamicRole: String(roleName))
                    }
                    credentials = DatabaseCredentials(username: response.username, password: response.password)
                    logger.trace("read dynamic database credentials",
                                 metadata: [
                                    "role": .stringConvertible(roleName),
                                    "path": .string(mountPath),
                                    "full_namespace": .string(fullNamespace)
                                 ])
                } else {
                    let error = VaultReaderError.readingUnsupportedDatabaseEndpoint(url.relativePath)
                    TracingSupport.handleResponse(error: error, span)
                    throw error
                }

                let data = try JSONEncoder().encode(credentials)
                return Array(data)
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
    /// Creates a Database credential reader for Pkl configuration files using this `VaultClient` instance and its Logger..
    /// 
    /// Example of resource URI: `vault.database:/creds/qa_role`.
    /// See ``VaultCourier/VaultDatabaseCredentialReader/buildSchemeFor(mountPath:namespace:)`` for how the scheme is built.
    ///
    /// - Parameters:
    ///   - mountPath: database mount path. This will be part of the scheme.
    ///   - namespace: optional child namespace. Let it `nil` for the parent namespace
    /// - Returns: A `ResourceReader` capable of retrieving secrets from Vault using this client.
    public func makeDatabaseCredentialReader(
        mountPath: String,
        namespace: String? = nil
    ) throws -> VaultDatabaseCredentialReader {
        let schemeString = try VaultDatabaseCredentialReader.buildSchemeFor(mountPath: mountPath, namespace: namespace)
        guard let uri = URL(string: "\(schemeString):") else {
            throw VaultClientError.invalidArgument("mountPath: \(mountPath), namespace: \(namespace ?? "<empty>")")
        }

        guard let scheme = uri.scheme else {
            throw VaultReaderError.invalidURI(scheme: uri.description)
        }

        return .init(
            client: self,
            scheme: scheme,
            mountPath: mountPath,
            namespace: namespace,
            backgroundActivityLogger: logger
        )
    }
}

extension ResourceReader where Self == VaultDatabaseCredentialReader {
    /// Reader for Database credentials managed by Vault
    public static func vaultDatabase(
        client: VaultClient,
        mountPath: String,
        namespace: String? = nil,
        backgroundActivityLogger: Logging.Logger? = nil
    ) -> VaultDatabaseCredentialReader? {
        guard let schemeString = try? VaultDatabaseCredentialReader.buildSchemeFor(mountPath: mountPath, namespace: namespace),
              let uri = URL(string: "\(schemeString):"),
              let scheme = uri.scheme else {
            return nil
        }

        return .init(
            client: client,
            scheme: scheme,
            mountPath: mountPath,
            namespace: namespace,
            backgroundActivityLogger: backgroundActivityLogger
        )
    }
}

#endif
