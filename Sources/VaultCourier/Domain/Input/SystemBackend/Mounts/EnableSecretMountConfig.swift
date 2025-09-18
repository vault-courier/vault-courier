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

/// Request type for enabling a new secret mount
public struct EnableSecretMountConfig: Sendable {
    /// Type of mount, e.g. `kv` or `database`
    public var mountType: String

    /// The path where the secret mount should be enabled
    public var path: String

    /// User-friendly description for this mount.
    public var description: String?

    /// Configuration for this mount, such as `default_lease_ttl` and `max_lease_ttl`.
    public var config: [String: String]?

    /// The options to pass into the backend. See specific backend documentation.
    public var options: [String: String]?

    /// Mark the mount as a local mount, which is not replicated and is unaffected by replication.
    public var isLocal: Bool?

    /// Whether to turn on seal wrapping for the mount.
    public var sealWrap: Bool?

    /// Whether to give the mount access to Vault's external entropy.
    public var externalEntropyAccess: Bool?

    public init(mountType: String,
                path: String,
                description: String? = nil,
                config: [String : String]? = nil,
                options: [String : String]? = nil,
                isLocal: Bool? = nil, sealWrap: Bool? = nil,
                externalEntropyAccess: Bool? = nil) {
        self.mountType = mountType
        self.path = path
        self.description = description
        self.config = config
        self.options = options
        self.isLocal = isLocal
        self.sealWrap = sealWrap
        self.externalEntropyAccess = externalEntropyAccess
    }
}
