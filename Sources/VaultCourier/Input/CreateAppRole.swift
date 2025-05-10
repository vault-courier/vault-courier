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


public struct CreateAppRole: Sendable {
    /// Name of the app role
    public var name: String
    public var bindSecretId: Bool?
    public var secretIdBoundCIDRS: [String]?
    public var secretIdNumberOfUses: Int?
    public var secretIdTTL: String?
    public var localSecretIds: Bool?
    public var tokenPolicies: [String]
    public var tokenBoundCIDRS: [String]?
    public var tokenTTL: String?
    public var tokenMaxTTL: String?
    public var tokenNoDefaultPolicy: Bool?
    public var tokenNumberOfUses: Int?
    public var tokenPeriod: String?
    public var tokenType: TokenType?

    public enum TokenType: String, CaseIterable, CodingKeyRepresentable, Decodable, Hashable, Sendable {
        case batch = "batch"
        case service = "service"
        case `default` = "default"
    }

    public init(name: String,
                bindSecretId: Bool? = nil,
                secretIdBoundCIDRS: [String]? = nil,
                secretIdNumberOfUses: Int? = nil,
                secretIdTTL: String? = nil,
                localSecretIds: Bool? = nil,
                tokenPolicies: [String],
                tokenBoundCIDRS: [String]? = nil,
                tokenTTL: String? = nil,
                tokenMaxTTL: String? = nil,
                tokenNoDefaultPolicy: Bool? = nil,
                tokenNumberOfUses: Int? = nil,
                tokenPeriod: String? = nil,
                tokenType: TokenType?) {
        self.name = name
        self.bindSecretId = bindSecretId
        self.secretIdBoundCIDRS = secretIdBoundCIDRS
        self.secretIdNumberOfUses = secretIdNumberOfUses
        self.secretIdTTL = secretIdTTL
        self.localSecretIds = localSecretIds
        self.tokenPolicies = tokenPolicies
        self.tokenBoundCIDRS = tokenBoundCIDRS
        self.tokenTTL = tokenTTL
        self.tokenMaxTTL = tokenMaxTTL
        self.tokenNoDefaultPolicy = tokenNoDefaultPolicy
        self.tokenNumberOfUses = tokenNumberOfUses
        self.tokenPeriod = tokenPeriod
        self.tokenType = tokenType
    }
}
