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
@preconcurrency import PklSwift
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.URL
import class Foundation.JSONDecoder
import class Foundation.JSONEncoder
import struct Foundation.Data
#endif
import Logging

extension VaultClient: PklSwift.ResourceReader {
    // MARK: BaseReader
    public func listElements(uri: URL) async throws -> [PklSwift.PathElement] {
        throw PklError("listElements(uri:) not implemented")
    }

    // MARK: ResourceReader
    public func read(url: URL) async throws -> [UInt8] {
        let mountPath = url.relativePath.removeSlash()
        let kvMountPath = mounts.kv.relativePath.removeSlash()
        let databaseMountPath = mounts.database.relativePath.removeSlash()

        if mountPath.starts(with: kvMountPath) {
            return try await readKVSecret(relativePath: mountPath)
        } else if mountPath.starts(with: databaseMountPath) {
            let databasePath = mountPath.suffix(from: mounts.database.relativePath.endIndex)
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

    func readKVSecret(relativePath: String) async throws -> [UInt8] {
        let key = String(relativePath.suffix(from: mounts.kv.relativePath.endIndex).dropFirst())
        guard !key.isEmpty else {
            logger.error("missing key in url path")
            return []
        }

        do {
            let buffer = try await readKeyValueSecretData(key: key)
            return Array(buffer)
        } catch {
            logger.debug(.init(stringLiteral: String(reflecting: error)))
            return []
        }
    }

    func readStaticDatabaseCredential(relativePath: String) async throws -> [UInt8] {
        let components = relativePath.split(separator: "/static-creds/", maxSplits: 2).map({String($0)})
        guard components.count == 2,
              let enginePath = components.first,
              let roleName = components.last else {
            logger.error("Not a valid static credential path")
            return []
        }

        do {
            let response = try await databaseCredentials(staticRole: roleName, enginePath: enginePath)
            let credentials = DatabaseCredentials(username: response.username, password: response.password)
            let data = try JSONEncoder().encode(credentials)

            return Array(data)
        } catch {
            logger.debug(.init(stringLiteral: String(reflecting: error)))
            return []
        }
    }

    func readDatabaseCredential(relativePath: String) async throws -> [UInt8] {
        let components = relativePath.split(separator: "/creds/", maxSplits: 2).map({String($0)})
        guard components.count == 2,
              let enginePath = components.first,
              let roleName = components.last else {
            logger.error("Not a valid static credential path")
            return []
        }

        do {
            let response = try await databaseCredentials(dynamicRole: roleName, enginePath: enginePath)
            let credentials = DatabaseCredentials(username: response.username, password: response.password)
            let data = try JSONEncoder().encode(credentials)

            return Array(data)
        } catch {
            logger.debug(.init(stringLiteral: String(reflecting: error)))
            return []
        }
    }
}

#endif

extension String {
    func removeSlash() -> String {
        if self.hasPrefix("/") {
            return String(self.suffix(from: self.index(after: self.startIndex)))
        }
        return self
    }
}

