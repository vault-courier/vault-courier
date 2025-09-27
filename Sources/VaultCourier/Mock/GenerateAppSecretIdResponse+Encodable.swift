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

#if AppRoleSupport && MockSupport
extension GenerateAppSecretIdResponse: Encodable {
    enum CodingKeys: String, CodingKey {
        case requestID = "request_id"
        case data
    }

    enum SecretKeys: String, CodingKey {
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
        let secretInfo = AppRoleSecretID(secretID: secretID,
                                         secretIDAccessor: secretIDAccessor,
                                         secretIDTimeToLive: Int(secretIDTimeToLive.components.seconds),
                                         secretIDNumberOfUses: secretIDNumberOfUses)
        try container.encode(secretInfo, forKey: .data)
    }
}

extension GenerateAppSecretIdResponse {
    public init(requestID: String,
                secretID: String,
                secretIDAccessor: String,
                secretIDTimeToLive: Duration,
                secretIDNumberOfUses: Int) {
        self.requestID = requestID
        self.secretID = secretID
        self.secretIDAccessor = secretIDAccessor
        self.secretIDTimeToLive = secretIDTimeToLive
        self.secretIDNumberOfUses = secretIDNumberOfUses
    }
}
#endif
