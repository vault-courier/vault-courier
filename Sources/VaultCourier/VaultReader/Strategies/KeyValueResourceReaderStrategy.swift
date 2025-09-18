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

/// A type that parses an URL into a provided data type
///
/// A ``ResourceReaderStrategy`` allows you to customize how Pkl URI resources are parsed into path components used for calling an specific Vault endpoint
///
/// ``KeyValueResourceReaderStrategy`` and ``DatabaseResourceReaderStrategy`` are specializations of this protocol for the KeyValue and Database secret engines.
public protocol ResourceReaderStrategy {
    /// The type of the data type.
    associatedtype ParseOutput: Sendable

    func parse(_ url: URL) throws -> ParseOutput
}

public protocol CustomResourceReaderStrategy: Sendable {
    func parse(_ url: URL) async throws -> [UInt8]?
}

public protocol KeyValueResourceReaderStrategy: ResourceReaderStrategy, Sendable {
    /// Parses URL into the parameters the vault client needs to fetch a key/value secret.
    /// - Parameter url: URL to parse
    /// - Returns: Returns `nil` if its not a URL for a KeyValue resource. Otherwise, it returns the parameters needed to call a key/value secret endpoint.
    func parse(_ url: URL) throws -> (mount: String, key: String, version: Int?)?
}

extension KeyValueResourceReaderStrategy where Self == KeyValueReaderParser {
    /// Strategy to parse KeyValue resource which expects a URL prefixed with the given `mount`
    public static func mount(_ mount: String) -> KeyValueReaderParser {
        .init(mount: mount)
    }
}

extension KeyValueResourceReaderStrategy where Self == KeyValueDataPathParser {
    /// Strategy to parse KeyValue resource which splits paths by the path "/data/"
    public static var splitUponDataPathElement: KeyValueDataPathParser {
        .init()
    }
}

public struct KeyValueReaderParser: KeyValueResourceReaderStrategy, Sendable {
    /// Mount path of Key/Value secret
    let mount: String

    public init(mount: String) {
        self.mount = mount.removeSlash()
    }

    public func parse(_ url: URL) throws -> (mount: String, key: String, version: Int?)? {
        let relativePath = url.relativePath.removeSlash()

        if !mount.isEmpty,
           relativePath.starts(with: mount) {
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
public struct KeyValueDataPathParser: KeyValueResourceReaderStrategy {
    public init() {}

    public func parse(_ url: URL) throws -> (mount: String, key: String, version: Int?)? {
        let relativePath = url.relativePath.removeSlash()
        let components = relativePath.split(separator: "/data/", maxSplits: 2).map({String($0)})
        guard components.count == 2,
              let mount = components.first,
              let key = components.last else {
            return nil
        }

        let version: Int? = if let query = url.query() {
            Int(query.dropFirst("version=".count))
        } else {
            nil
        }

        return (mount, key, version)
    }
}
#endif
