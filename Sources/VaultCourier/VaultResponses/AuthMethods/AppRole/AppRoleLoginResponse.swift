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

public struct AppRoleLoginResponse: Sendable {
    let isRenewable: Bool

    let leaseDuration: Int

    let tokenPolicies: [String]

    let accessor: String

    let clientToken: String

    let leaseId: String?
}

extension AppRoleLoginResponse {
    init(payload: Components.Schemas.VaultAuthResponse) {
        self.isRenewable = payload.auth.renewable
        self.leaseDuration = payload.auth.leaseDuration
        self.tokenPolicies = payload.auth.tokenPolicies
        self.accessor = payload.auth.accessor
        self.clientToken = payload.auth.clientToken
        self.leaseId = payload.leaseId
    }
}
