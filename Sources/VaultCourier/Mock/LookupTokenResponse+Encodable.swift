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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.Date
#endif
import OpenAPIRuntime

extension LookupTokenResponse: Encodable {
    enum CodingKeys: String, CodingKey {
        case requestID = "request_id"
        case data
    }

    enum DataKeys: String, CodingKey {
        case clientToken = "id"
        case accessor
        case createdAt = "creation_time"
        case creationTimeToLive = "creation_ttl"
        case displayName = "display_name"
        case expiresAt = "expire_time"
        case explicitMaxTimeToLive = "explicit_max_ttl"
        case timeToLive = "ttl"
        case policies
        case metadata
        case isRenewable = "renewable"
        case tokenType = "token_type"
        case isOrphan = "orphan"
        case numberOfUses = "num_uses"
        case path
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(requestID, forKey: .requestID)

        var auth = container.nestedContainer(keyedBy: DataKeys.self, forKey: .data)
        try auth.encode(clientToken, forKey: .clientToken)
        try auth.encode(accessor, forKey: .accessor)
        try auth.encode(createdAt, forKey: .createdAt)
        try auth.encode(creationTimeToLive.components.seconds, forKey: .creationTimeToLive)
        try auth.encodeIfPresent(displayName, forKey: .displayName)
        try auth.encodeIfPresent(expiresAt, forKey: .expiresAt)
        try auth.encode(timeToLive, forKey: .timeToLive)
        try auth.encode(policies, forKey: .policies)
        try auth.encode(metadata, forKey: .metadata)
        try auth.encode(isRenewable, forKey: .isRenewable)
        try auth.encode(tokenType, forKey: .tokenType)
        try auth.encode(isOrphan, forKey: .isOrphan)
        try auth.encode(numberOfUses, forKey: .numberOfUses)
        try auth.encodeIfPresent(path, forKey: .path)
    }
}

extension LookupTokenResponse {
    public init(requestID: String,
                clientToken: String,
                accessor: String,
                createdAt: Date,
                creationTimeToLive: Duration,
                displayName: String?,
                expiresAt: Date,
                explicitMaxTimeToLive: Duration,
                timeToLive: Duration,
                policies: [String],
                metadata: [String : String],
                isRenewable: Bool,
                tokenType: TokenType,
                isOrphan: Bool,
                numberOfUses: Int,
                path: String?) {
        self.requestID = requestID
        self.clientToken = clientToken
        self.accessor = accessor
        self.createdAt = createdAt
        self.creationTimeToLive = creationTimeToLive
        self.displayName = displayName
        self.expiresAt = expiresAt
        self.explicitMaxTimeToLive = explicitMaxTimeToLive
        self.timeToLive = timeToLive
        self.policies = policies
        self.metadata = metadata
        self.isRenewable = isRenewable
        self.tokenType = tokenType
        self.isOrphan = isOrphan
        self.numberOfUses = numberOfUses
        self.path = path
    }
}

#endif
