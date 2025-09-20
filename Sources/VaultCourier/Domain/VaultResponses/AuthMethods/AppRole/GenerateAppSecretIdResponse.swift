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
public struct GenerateAppSecretIdResponse: Sendable {
    public let requestID: String

    /// AppRole secret id
    public let secretID: String

    public let secretIDAccessor: String

    /// Duration of the secretID
    public let secretIDTimeToLive: Duration


    public let secretIDNumberOfUses: Int

    init(requestID: String,
         appRoleSecretID: AppRoleSecretID) {
        self.init(requestID: requestID,
                  secretID: appRoleSecretID.secretID,
                  secretIDAccessor: appRoleSecretID.secretIDAccessor,
                  secretIDTimeToLive: .seconds(appRoleSecretID.secretIDTimeToLive),
                  secretIDNumberOfUses: appRoleSecretID.secretIDNumberOfUses)
    }
}

struct AppRoleSecretID: Codable, Sendable {
    let secretID: String
    let secretIDAccessor: String
    let secretIDTimeToLive: Int
    let secretIDNumberOfUses: Int

    enum CodingKeys: String, CodingKey {
        case secretID = "secret_id"
        case secretIDAccessor = "secret_id_accessor"
        case secretIDTimeToLive = "secret_id_ttl"
        case secretIDNumberOfUses = "secret_id_num_uses"
    }
}
#endif
