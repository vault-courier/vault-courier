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

#if MockSupport
extension VaultAuthResponse: Encodable {
    enum CodingKeys: String, CodingKey {
        case requestID = "request_id"
        case auth
    }

    enum AuthKeys: String, CodingKey {
        case clientToken = "client_token"
        case accessor
        case tokenPolicies = "token_policies"
        case metadata
        case leaseDuration = "lease_duration"
        case isRenewable = "renewable"
        case entityID = "entity_id"
        case tokenType = "token_type"
        case isOrphan = "orphan"
        case numberOfUses = "num_uses"
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(requestID, forKey: .requestID)

        var auth = container.nestedContainer(keyedBy: AuthKeys.self, forKey: .auth)
        try auth.encode(clientToken, forKey: .clientToken)
        try auth.encode(accessor, forKey: .accessor)
        try auth.encode(tokenPolicies, forKey: .tokenPolicies)
        try auth.encode(metadata, forKey: .metadata)
        try auth.encode(leaseDuration.components.seconds, forKey: .leaseDuration)
        try auth.encode(isRenewable, forKey: .isRenewable)
        try auth.encode(entityID, forKey: .entityID)
        try auth.encode(tokenType, forKey: .tokenType)
        try auth.encode(isOrphan, forKey: .isOrphan)
        try auth.encode(numberOfUses, forKey: .numberOfUses)
    }
}

extension VaultAuthResponse {
    public init(requestID: String,
                clientToken: String,
                accessor: String,
                tokenPolicies: [String],
                metadata: [String : String],
                leaseDuration: Duration,
                isRenewable: Bool,
                entityID: String?,
                tokenType: TokenType,
                isOrphan: Bool,
                numberOfUses: Int) {
        self.requestID = requestID
        self.clientToken = clientToken
        self.accessor = accessor
        self.tokenPolicies = tokenPolicies
        self.metadata = metadata
        self.leaseDuration = leaseDuration
        self.isRenewable = isRenewable
        self.entityID = entityID
        self.tokenType = tokenType
        self.isOrphan = isOrphan
        self.numberOfUses = numberOfUses
    }
}
#endif
