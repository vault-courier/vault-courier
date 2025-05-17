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

public struct GenerateAppSecretIdResponse: Sendable {
    public let requestId: String?

    public let leaseId: String?

    public let leaseDuration: Int?

    public let renewable: Bool?

    /// AppRole secret id
    public let secretId: String

    public let secretIdAccessor: String

    public let secretIdTtl: Int

    public let secretIdNumUses: Int
}

extension GenerateAppSecretIdResponse {
    init(component: Components.Schemas.GenerateAppRoleSecretIdResponse) {
        self.requestId = component.requestId
        self.leaseId = component.leaseId
        self.leaseDuration = component.leaseDuration
        self.renewable = component.renewable
        self.secretId = component.data.secretId
        self.secretIdAccessor = component.data.secretIdAccessor
        self.secretIdTtl = component.data.secretIdTtl
        self.secretIdNumUses = component.data.secretIdNumUses
    }
}
