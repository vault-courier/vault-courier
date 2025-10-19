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

/// A Pkl resource reader for Vault
///
/// Execute custom VaultClient calls from a Pkl file
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

    public typealias VaultAction = @Sendable (VaultClient, URL) async throws -> [UInt8]
    
    let execute: VaultAction

    init(client: VaultClient,
         scheme: String,
         execute: @escaping VaultAction,
         backgroundActivityLogger: Logging.Logger? = nil) {
        self.client = client
        self.scheme = scheme
        self.logger = backgroundActivityLogger ?? Logger(label: "vault-resource-reader-do-not-log", factory: { _ in SwiftLogNoOpLogHandler() })
        self.execute =  execute
    }
}

// MARK: ResourceReader

extension VaultResourceReader: ResourceReader {
    public func read(url: URL) async throws -> [UInt8] {
        do {
            return try await execute(client, url)
        } catch {
            logger.debug(.init(stringLiteral: String(reflecting: error)))
            throw VaultReaderError.readingConfigurationFailed()
        }
    }

    public func listElements(uri: URL) async throws -> [PklSwift.PathElement] {
        throw PklError("listElements(uri:) not implemented")
    }
}


extension VaultClient {
    /// Creates a Vault resource reader for Pkl configuration files using this ``VaultClient`` instance and its Logger.
    ///
    /// 
    /// - Parameters:
    ///   - scheme: scheme which triggers this resource reader
    ///   - execute: closure which executes on this vault client instance and return array of bytes
    public func makeResourceReader(
        scheme: String,
        execute: @escaping VaultResourceReader.VaultAction,
    ) throws -> VaultResourceReader {
        guard URL(string: "\(scheme):") != nil else {
            throw VaultReaderError.invalidURI(scheme: scheme)
        }

        return .init(
            client: self,
            scheme: scheme,
            execute: execute,
            backgroundActivityLogger: self.logger
        )
    }
}
#endif
