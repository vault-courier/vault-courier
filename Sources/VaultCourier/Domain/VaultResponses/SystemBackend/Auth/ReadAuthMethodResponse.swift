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

/// Response from reading authentication method configuration
public struct ReadAuthMethodResponse: Sendable {
    public let requestID: String

    /// Type of authentication method
    public let authMethod: String

    /// Specifies if the auth method is local only. Local auth methods are not replicated nor (if a secondary) removed by replication. Local auth mounts also generate entities for tokens issued.
    /// The entity will be replicated across clusters and the aliases generated on the local auth mount will be local to the cluster. Entities created by local auth mounts are still replicated to other clusters,
    /// however it is possible to prevent data pertaining to the local auth mount, including related aliases, from being replicated by omitting them from the entity metadata.
    public let isLocal: Bool?

    /// Whether to turn on seal wrapping for the mount.
    public let sealWrap: Bool?

    /// Authentication method configuration
    public let config: AuthMethodConfig?

    /// Specifies a human-friendly description of the auth method.
    public let description: String?

    /// The options to pass into the backend
    public let options: [String: String]?

    public let externalEntropyAccess: Bool?

    public let accessor: String?

    public let mountType: String?

    package init(requestID: String,
                 authMethod: String,
                 isLocal: Bool?,
                 sealWrap: Bool?,
                 config: AuthMethodConfig?,
                 description: String?,
                 options: [String : String]?,
                 externalEntropyAccess: Bool?,
                 accessor: String?,
                 mountType: String?) {
        self.requestID = requestID
        self.authMethod = authMethod
        self.isLocal = isLocal
        self.sealWrap = sealWrap
        self.config = config
        self.description = description
        self.options = options
        self.externalEntropyAccess = externalEntropyAccess
        self.accessor = accessor
        self.mountType = mountType
    }
}

public struct AuthMethodConfig: Sendable {
    public let tokenType: TokenType
    public let defaultLeaseTimeToLive: Int
    public let maxLeaseTimeToLive: Int

    package init(tokenType: TokenType,
                 defaultLeaseTimeToLive: Int,
                 maxLeaseTimeToLive: Int) {
        self.tokenType = tokenType
        self.defaultLeaseTimeToLive = defaultLeaseTimeToLive
        self.maxLeaseTimeToLive = maxLeaseTimeToLive
    }
}
