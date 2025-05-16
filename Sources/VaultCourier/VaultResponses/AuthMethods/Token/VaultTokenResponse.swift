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


public struct VaultTokenResponse: Sendable {
    public let requestId: String?

    public let mountType: String?

    /// The token value
    public let clientToken: String

    public let accessor: String

    public let tokenPolicies: [String]

    public let leaseDuration: Int

    public let renewable: Bool

    public let tokenType: String

    public let orphan: Bool

    public let numberOfUses: Int
}

extension VaultTokenResponse {
    init(component: Components.Schemas.TokenCreateResponse) {
        self.requestId = component.requestId
        self.mountType = component.mountType
        self.clientToken = component.auth.clientToken
        self.accessor = component.auth.accessor
        self.tokenPolicies = component.auth.tokenPolicies
        self.leaseDuration = component.auth.leaseDuration
        self.renewable = component.renewable
        self.tokenType = component.auth.tokenType
        self.orphan = component.auth.orphan
        self.numberOfUses = component.auth.numUses
    }
}
