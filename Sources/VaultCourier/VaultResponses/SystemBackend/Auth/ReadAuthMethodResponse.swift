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
    public let requestId: String?

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
}

public struct AuthMethodConfig: Sendable {
    let tokenType: String
    let defaultLeaseTTL: Int
    let maxLeaseTTL: Int
}

extension ReadAuthMethodResponse {
    init(component: Components.Schemas.ReadAuthMethodResponse) {
        self.requestId = component.requestId
        self.accessor = component.data.accessor
        self.authMethod = component.data._type
        let config = component.data.config.value
        if let tokenType = config["token_type"] as? String {
            self.config = .init(tokenType: tokenType,
                                defaultLeaseTTL: (config["default_lease_ttl"] as? Int) ?? 0,
                                maxLeaseTTL: (config["max_lease_ttl"] as? Int) ?? 0)
        } else {
            self.config = nil
        }
        self.isLocal = component.data.local
        self.sealWrap = component.data.sealWrap
        self.description = component.data.description
        self.externalEntropyAccess = component.data.externalEntropyAccess
        self.options = component.data.options.flatMap({$0.value as? [String : String]})
        self.mountType = component.mountType
    }
}
