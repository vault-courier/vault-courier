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

#if AppRoleSupport
public struct ReadAppRoleResponse: Sendable {
    public let requestID: String?

    public let tokenPolicies: [String]

    public let tokenTimeToLive: Duration?

    public let tokenMaxTimeToLive: Duration?

    public let tokenBoundCIDRS: [String]?

    public let tokenExplicitMaxTimeToLive: Duration?

    public let tokenNoDefaultPolicy: Bool

    public let tokenNumberOfUses: Int

    public let tokenPeriod: Int?

    public let secretIdTimeToLive: Duration?

    public let isRenewable: Bool?

    public let secretIdNumberOfUses: Int?

    public let bindSecretID: Bool

    public let localSecretID: Bool

    public let secretIdBoundCIDRS: [String]?

    public let tokenType: TokenType

    package init(requestID: String?,
                 tokenPolicies: [String],
                 tokenTimeToLive: Duration?,
                 tokenMaxTimeToLive: Duration?,
                 tokenBoundCIDRS: [String]?,
                 tokenExplicitMaxTimeToLive: Duration?,
                 tokenNoDefaultPolicy: Bool,
                 tokenNumberOfUses: Int,
                 tokenPeriod: Int?,
                 secretIdTimeToLive: Duration?,
                 isRenewable: Bool?,
                 secretIdNumberOfUses: Int?,
                 bindSecretID: Bool,
                 localSecretID: Bool,
                 secretIdBoundCIDRS: [String]?,
                 tokenType: TokenType) {
        self.requestID = requestID
        self.tokenPolicies = tokenPolicies
        self.tokenTimeToLive = tokenTimeToLive
        self.tokenMaxTimeToLive = tokenMaxTimeToLive
        self.tokenBoundCIDRS = tokenBoundCIDRS
        self.tokenExplicitMaxTimeToLive = tokenExplicitMaxTimeToLive
        self.tokenNoDefaultPolicy = tokenNoDefaultPolicy
        self.tokenNumberOfUses = tokenNumberOfUses
        self.tokenPeriod = tokenPeriod
        self.secretIdTimeToLive = secretIdTimeToLive
        self.isRenewable = isRenewable
        self.secretIdNumberOfUses = secretIdNumberOfUses
        self.bindSecretID = bindSecretID
        self.localSecretID = localSecretID
        self.secretIdBoundCIDRS = secretIdBoundCIDRS
        self.tokenType = tokenType
    }
}
#endif
