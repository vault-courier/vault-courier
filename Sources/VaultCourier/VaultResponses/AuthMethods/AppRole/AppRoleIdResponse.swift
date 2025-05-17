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


public struct AppRoleIdResponse: Sendable {
    /// This is the ID used to manage the lease of the secret, such as revoke or renew.
    public let leaseId: String?

    /// The lease duration is a Time To Live value: the time in seconds for which the lease is valid. A consumer of this secret must renew the lease within that time.
    public let leaseDuration: Int?

    public let renewable: Bool?

    public let roleId: String

    public init(leaseId: String?,
                leaseDuration: Int?,
                renewable: Bool?,
                roleId: String) {
        self.leaseId = leaseId
        self.leaseDuration = leaseDuration
        self.renewable = renewable
        self.roleId = roleId
    }
}

extension AppRoleIdResponse {
    init(component: Components.Schemas.ReadAppRoleIdResponse) {
        self.leaseId = component.leaseId
        self.leaseDuration = component.leaseDuration
        self.renewable = component.renewable
        self.roleId = component.data.roleId
    }
}
