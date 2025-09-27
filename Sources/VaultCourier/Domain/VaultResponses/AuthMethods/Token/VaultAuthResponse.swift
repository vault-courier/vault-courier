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

public struct VaultAuthResponse: Sendable {
    public let requestID: String?

    /// The token value
    public let clientToken: String

    public let accessor: String

    public let tokenPolicies: [String]

    /// The metadata associated to the created token
    public let metadata: [String: String]

    /// The time to live (TTL) period of the token
    public let leaseDuration: Duration

    public let isRenewable: Bool

    public let entityID: String?

    public let tokenType: TokenType

    /// Specifies if the token created has a parent
    public let isOrphan: Bool

    /// A value of zero means unlimited number of uses
    public let numberOfUses: Int
}
