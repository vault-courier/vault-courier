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
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.URL
#endif

public protocol DatabaseResourceReaderStrategy: ResourceReaderStrategy, Sendable {
    /// Parses URL into the parameters the vault client needs to fetch a database secret.
    /// - Parameter url: URL to parse
    /// - Returns: Returns `nil` if its not a URL for a database resource. Otherwise, it returns the parameters needed to call a database secret endpoint.
    func parse(_ url: URL) throws -> (mount: String, role: DatabaseRole)?
}

extension DatabaseResourceReaderStrategy where Self == DatabaseReaderParser {
    /// Strategy to parse Database resource which expects a URL prefixed with the given `mount`
    public static func mount(_ mount: String) -> DatabaseReaderParser {
        .init(mount: mount)
    }
}

public struct DatabaseReaderParser: DatabaseResourceReaderStrategy {
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
#endif
