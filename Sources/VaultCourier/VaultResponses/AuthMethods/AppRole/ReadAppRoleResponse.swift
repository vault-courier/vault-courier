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


public struct ReadAppRoleResponse: Sendable {
    public let requestId: String?

    public let tokenPolicies: [String]

    public let tokenTimeToLive: Int?

    public let tokenMaxTimeToLive: Int?

    public let secretIdTimeToLive: Int?

    public let leaseDuration: Int?

    public let renewable: Bool?

    public let secretIdNumberOfUses: Int?

    public let bindSecretId: Bool?

    public let secretIdBoundCidrs: [String]?

    public let tokenType: TokenType
}

extension Components.Schemas.ReadAppRoleResponse {
    var appRoleResponse: ReadAppRoleResponse {
        get throws {
            guard let tokenType = TokenType(rawValue: data.tokenType?.rawValue ?? "") else {
                throw VaultClientError.receivedUnexpectedResponse("Unexpected token type: \(String(describing: data.tokenType))")
            }

            return .init(
                requestId: requestId,
                tokenPolicies: data.tokenPolicies ?? [],
                tokenTimeToLive: data.tokenTtl,
                tokenMaxTimeToLive: data.tokenMaxTtl,
                secretIdTimeToLive: data.secretIdTtl,
                leaseDuration: leaseDuration,
                renewable: renewable,
                secretIdNumberOfUses: data.secretIdNumUses,
                bindSecretId: data.bindSecretId,
                secretIdBoundCidrs: data.secretIdBoundCidrs,
                tokenType: tokenType
            )
        }
    }
}
