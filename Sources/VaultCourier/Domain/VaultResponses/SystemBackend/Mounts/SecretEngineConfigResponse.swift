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

public struct SecretEngineConfigResponse: Sendable {
    public let requestID: String

    public let accessor: String?

    /// Configuration for this mount, such as `default_lease_ttl` and `max_lease_ttl`.
    public let config: MountConfig

    /// User-friendly description for this mount.
    public let description: String?

    /// Type of secret engine, e.g. `kv`.
    public let engineType: String?

    /// The options to pass into the backend. See specific backend documentation.
    public let options: [String: String]?

    public let pluginVersion: String?

    /// Mark the mount as a local mount, which is not replicated and is unaffected by replication.
    public let isLocal: Bool?

    /// Whether to turn on seal wrapping for the mount.
    public let sealWrap: Bool?

    /// Whether to give the mount access to Vault's external entropy.
    public let externalEntropyAccess: Bool?

    package init(requestID: String,
                 accessor: String?,
                 config: MountConfig,
                 description: String?,
                 engineType: String?,
                 options: [String : String]?,
                 pluginVersion: String?,
                 isLocal: Bool?,
                 sealWrap: Bool?,
                 externalEntropyAccess: Bool?) {
        self.requestID = requestID
        self.accessor = accessor
        self.config = config
        self.description = description
        self.engineType = engineType
        self.options = options
        self.pluginVersion = pluginVersion
        self.isLocal = isLocal
        self.sealWrap = sealWrap
        self.externalEntropyAccess = externalEntropyAccess
    }
}

/// Configuration for a secret engine mount, such as `default_lease_ttl` and `max_lease_ttl`.
public struct MountConfig: Sendable {
    public let forceNoCache: Bool
    public let defaultLeaseTimeToLive: Int
    public let maxLeaseTimeToLive: Int

    package init(forceNoCache: Bool,
                 defaultLeaseTimeToLive: Int,
                 maxLeaseTimeToLive: Int) {
        self.forceNoCache = forceNoCache
        self.defaultLeaseTimeToLive = defaultLeaseTimeToLive
        self.maxLeaseTimeToLive = maxLeaseTimeToLive
    }
}
