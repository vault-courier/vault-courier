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

/// General Vault API response
public struct VaultResponse<
    VaultData: Decodable & Sendable,
    Auth: Decodable & Sendable
>: Sendable {
    public let requestID: String

    public let data: VaultData?

    public let auth: Auth?

    package init(requestID: String, data: VaultData?, auth: Auth?) {
        self.requestID = requestID
        self.data = data
        self.auth = auth
    }
}

extension VaultResponse where Auth == Never {
    package init(requestID: String, data: VaultData) {
        self.init(requestID: requestID,
                  data: data,
                  auth: nil)
    }
}

extension VaultResponse where VaultData == Never {
    package init(requestID: String, auth: Auth) {
        self.init(requestID: requestID,
                  data: nil,
                  auth: auth)
    }
}
