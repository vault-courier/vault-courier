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
    public let leaseId: String?

    public let tokenPolicies: [String]

    public let tokenTTL: Int?

    public let tokenMaxTTL: Int?

    public let secretIdTTL: Int?

    public let leaseDuration: Int?

    public let renewable: Bool?

    public let secretIdNumberOfUses: Int?

    public let bindSecretId: Bool?

    public let secretIdBoundCidrs: [String]?

    public let tokenType: String?
}

extension ReadAppRoleResponse {
    init(component: Components.Schemas.ReadAppRoleResponse) {
        self.leaseId = component.leaseId
        self.tokenPolicies = component.data.tokenPolicies
        self.tokenTTL = component.data.tokenTtl
        self.tokenMaxTTL = component.data.tokenMaxTtl
        self.secretIdTTL = component.data.secretIdTtl
        self.leaseDuration = component.leaseDuration
        self.renewable = component.renewable
        self.secretIdNumberOfUses = component.data.secretIdNumUses
        self.bindSecretId = component.data.bindSecretId
        self.secretIdBoundCidrs = component.data.secretIdBoundCidrs
        self.tokenType = component.data.tokenType
    }
}
