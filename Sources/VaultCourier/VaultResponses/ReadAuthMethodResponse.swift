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

public struct ReadAuthMethodResponse: Sendable {
    public let requestId: String?

    /// Type of authentication method
    public let authMethod: String

    public let isLocal: Bool?

    public let sealWrap: Bool?

    public let config: AuthMethodConfig?

    public let description: String?

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
