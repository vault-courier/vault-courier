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
/// Request type for creating an AppRole
public struct CreateAppRole: Sendable {
    /// Name of the app role
    public var name: String

    /// Require `secretID` to be presented when logging in using this AppRole.
    public var bindSecretID: Bool

    /// list of CIDR blocks; if set, specifies blocks of IP addresses which can perform the login operation.
    public var secretIdBoundCIDRS: [String]?

    /// Number of times any particular SecretID can be used to fetch a token from this AppRole, after which the SecretID by default will expire. A value of `nil` will allow unlimited uses. However, this option may be overridden by the request's ``VaultCourier/GenerateAppRoleToken/tokenNumberOfUses`` field when generating a SecretID.
    public var secretIdNumberOfUses: Int?

    /// Duration after which by default any SecretID expires. A value of `nil` will allow the SecretID to not expire. However, this option may be overridden by the request's ``VaultCourier/GenerateAppRoleToken/tokenTimeToLive`` field when generating a SecretID.
    public var secretIdTimeToLive: Duration?

    /// If set, the secret IDs generated using this role will be cluster local. This can only be set during role creation and once set, it can't be reset later.
    public var localSecretIds: Bool?

    /// List of token policies to encode onto generated tokens. Depending on the auth method, this list may be supplemented by user/group/other values.
    public var tokenPolicies: [String]

    /// List of CIDR blocks; if set, specifies blocks of IP addresses which can authenticate successfully, and ties the resulting token to these blocks as well.
    public var tokenBoundCIDRS: [String]?

    /// The incremental lifetime for generated tokens. This current value of this will be referenced at renewal time.
    public var tokenTimeToLive: Duration?

    /// The maximum lifetime for generated tokens. This current value of this will be referenced at renewal time.
    public var tokenMaxTimeToLive: Duration?

    /// If set, the default policy will not be set on generated tokens; otherwise it will be added to the policies set in `tokenPolicies`.
    public var tokenNoDefaultPolicy: Bool

    public var tokenNumberOfUses: Int?

    /// The maximum allowed period value when a [periodic](https://developer.hashicorp.com/vault/docs/concepts/tokens#token-time-to-live-periodic-tokens-and-explicit-max-ttls) token is requested from this role.
    public var tokenPeriod: Duration?

    /// The type of token that should be generated. Can be service, batch, or default to use the mount's tuned default (which unless changed will be service tokens). For machine based authentication cases, you should use batch type tokens.
    public var tokenType: TokenType

    public init(name: String,
                bindSecretId: Bool = true,
                secretIdBoundCIDRS: [String]? = nil,
                secretIdNumberOfUses: Int? = nil,
                secretIdTimeToLive: Duration? = nil,
                localSecretIds: Bool? = nil,
                tokenPolicies: [String],
                tokenBoundCIDRS: [String]? = nil,
                tokenTimeToLive: Duration? = nil,
                tokenMaxTimeToLive: Duration? = nil,
                tokenNoDefaultPolicy: Bool = false,
                tokenNumberOfUses: Int? = nil,
                tokenPeriod: Duration? = nil,
                tokenType: TokenType) {
        self.name = name
        self.bindSecretID = bindSecretId
        self.secretIdBoundCIDRS = secretIdBoundCIDRS
        self.secretIdNumberOfUses = secretIdNumberOfUses
        self.secretIdTimeToLive = secretIdTimeToLive
        self.localSecretIds = localSecretIds
        self.tokenPolicies = tokenPolicies
        self.tokenBoundCIDRS = tokenBoundCIDRS
        self.tokenTimeToLive = tokenTimeToLive
        self.tokenMaxTimeToLive = tokenMaxTimeToLive
        self.tokenNoDefaultPolicy = tokenNoDefaultPolicy
        self.tokenNumberOfUses = tokenNumberOfUses
        self.tokenPeriod = tokenPeriod
        self.tokenType = tokenType
    }
}
#endif
