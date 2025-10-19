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
import Utils

/// A Pkl resource reader for database credentials managed by Vault
///
/// You can generate this class from an already existing ``VaultClient`` with ``VaultClient/makeDatabaseCredentialReader(mountPath:prefix:))``
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

    public let mountPath: String

    init(client: VaultClient,
         scheme: String,
         mountPath: String,
         backgroundActivityLogger: Logging.Logger? = nil) {
        self.client = client
        self.scheme = scheme
        self.logger = backgroundActivityLogger ?? Logger(label: "vault-resource-reader-do-not-log", factory: { _ in SwiftLogNoOpLogHandler() })
        self.mountPath = mountPath
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
    /// - Parameters:
    ///   - mountPath: mount path of database secret engine
    ///   - prefix: optional prefix to add to the scheme. Lower case letters "a"..."z", digits, and the (escaped) characters plus ("+"), period ("."), and hyphen ("-") are allowed.
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
        return "\(prefix?.appending(".") ?? "")vault.\(mount)"
    }
}

// MARK: ResourceReader

extension VaultDatabaseCredentialReader: ResourceReader {
    public func read(url: URL) async throws -> [UInt8] {
        do {
            let credentials: DatabaseCredentials
            let relativePath = url.relativePath.removeSlash()

            if relativePath.hasPrefix("static-creds/") {
                let roleName = relativePath.suffix(from: "static-creds/".endIndex)
                let response = try await client.databaseCredentials(staticRole: String(roleName), mountPath: mountPath)
                credentials = DatabaseCredentials(username: response.username, password: response.password)
            } else if relativePath.hasPrefix("creds/") {
                let roleName = relativePath.suffix(from: "creds/".endIndex)
                let response = try await client.databaseCredentials(dynamicRole: String(roleName), mountPath: mountPath)
                credentials = DatabaseCredentials(username: response.username, password: response.password)
            } else {
                throw VaultReaderError.readingUnsupportedDatabaseEndpoint(url.relativePath)
            }

            let data = try JSONEncoder().encode(credentials)
            return Array(data)
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
    /// Creates a Database credential reader for Pkl configuration files using this `VaultClient` instance and its Logger..
    /// 
    /// Example of resource URI: `vault.database:/creds/qa_role`. See ``VaultDatabaseCredentialReader.buildSchemeFor(mountPath:prefix)`` for how the scheme is built.
    ///
    /// - Parameters:
    ///   - mountPath: database mount path. This will be part of the scheme.
    ///   - prefix: optional prefix to add to the scheme. Lower case letters "a"--"z", digits, and the characters plus ("+"), period ("."), and hyphen ("-") are allowed.
    /// - Returns: A `ResourceReader` capable of retrieving secrets from Vault using this client.
    public func makeDatabaseCredentialReader(
        mountPath: String,
        prefix: String? = nil
    ) throws -> VaultDatabaseCredentialReader {
        let schemeString = try VaultDatabaseCredentialReader.buildSchemeFor(mountPath: mountPath, prefix: prefix)
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

extension ResourceReader where Self == VaultDatabaseCredentialReader {
    /// Reader for Database credentials managed by Vault
    public static func vaultDatabase(
        client: VaultClient,
        mountPath: String,
        prefix: String? = nil,
        backgroundActivityLogger: Logging.Logger? = nil
    ) -> VaultDatabaseCredentialReader? {
        guard let schemeString = try? VaultDatabaseCredentialReader.buildSchemeFor(mountPath: mountPath, prefix: prefix),
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
