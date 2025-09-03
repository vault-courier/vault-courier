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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
//import struct Foundation.Date
import Foundation
#endif
import VaultUtilities

public struct LookupTokenResponse: Sendable {
    public let requestId: String?

    /// The token value
    public let clientToken: String

    public let accessor: String

    public let createdAt: Date

    public let creationTimeToLive: Duration

    public let expiresAt: String?

    public let explicitMaxTimeToLive: Duration

    public let timeToLive: Duration

    public let policies: [String]

    /// The metadata associated to the created token
    public let metadata: [String: String]

    public let isRenewable: Bool

    public let tokenType: TokenType

    /// Specifies if the token created has a parent
    public let isOrphan: Bool

    /// A value of zero means unlimited number of uses
    public let numberOfUses: Int
}

//extension Components.Schemas.TokenLookupResponse {
//    var tokenResponse: LookupTokenResponse {
//        get throws {
//            guard let tokenType = TokenType(rawValue: data._type.rawValue) else {
//                throw VaultClientError.receivedUnexpectedResponse("unexpected token type: \(String(describing: data._type))")
//            }
//
//            return .init(
//                requestId: requestId,
//                clientToken: data.id,
//                accessor: data.accessor,
//                createdAt: Date(timeIntervalSince1970: TimeInterval(data.creationTime)),
//                creationTimeToLive: .seconds(data.creationTtl),
//                expiresAt: data.expireTime,
//                explicitMaxTimeToLive: .seconds(data.explicitMaxTtl ?? 0),
//                timeToLive: .seconds(data.ttl),
//                policies: data.policies,
//                metadata: data.meta?.additionalProperties ?? [:],
//                isRenewable: data.renewable,
//                tokenType: tokenType,
//                isOrphan: data.orphan,
//                numberOfUses: data.numUses
//            )
//        }
//    }
//}
