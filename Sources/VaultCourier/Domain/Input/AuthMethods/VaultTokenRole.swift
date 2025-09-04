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

/// Token role configuration
public struct VaultTokenRole: Sendable {
    /// The name of the token role.
    public var roleName: String

    /// If set, tokens can be created with any subset of the policies in this list, rather than the normal semantics of tokens being a subset of the calling token's
    /// policies. The parameter is a comma-delimited string of policy names. If at creation time ``noDefaultPolicy`` is not set and \"default\" is not
    /// contained in ``disallowedPolicies`` or glob matched in ``allowedPoliciesGlob``, the \"default\" policy will be added to the created
    /// token automatically.
    public var allowedPolicies: [String]?

    /// If set, successful token creation via this role will require that no policies in the given list are requested. The parameter is a comma-delimited string of
    /// policy names. Adding \"default\" to this list will prevent \"default\" from being added automatically to created tokens."
    public var disallowedPolicies: [String]?

    /// If set, tokens can be created with any subset of glob matched policies in this list, rather than the normal semantics of tokens being a subset of the
    /// calling token's policies. The parameter is a comma-delimited string of policy name globs. If at creation time ``noDefaultPolicy`` is not set and
    /// \"default\" is not contained in ``disallowedPolicies`` or glob matched in ``disallowedPoliciesGlob``, the \"default\" policy will be
    /// added to the created token automatically. If combined with ``allowedPolicies`` policies need to only match one of the two lists to be permitted.
    /// Note that unlike ``allowedPolicies`` the policies listed in ``allowedPoliciesGlob`` will not be added to the token when no policies are
    /// specified in the call to ``VaultCourier/VaultClient/createToken(_:wrappTTL:)``.
    public var allowedPoliciesGlob: [String]?

    /// If set, successful token creation via this role will require that no requested policies glob match any of policies in this list. The parameter is a
    /// comma-delimited string of policy name globs. Adding any glob that matches \"default\" to this list will prevent \"default\" from being added
    /// automatically to created tokens. If combined with ``disallowedPolicies`` policies need to only match one of the two lists to be blocked."
    public var disallowedPoliciesGlob: [String]?

    /// If true, tokens created against this policy will be orphan tokens (they will have no parent). As such, they will not be automatically revoked by the
    /// revocation of any other token.
    public var orphan: Bool

    /// If `true`, the default policy will not be set on generated tokens; otherwise it will be added to the policies set in ``CreateVaultToken/policies``
    public var noDefaultPolicy: Bool

    /// Set to false to disable the ability of the token to be renewed past its initial TTL. Setting the value to true will allow the token to be renewable up to
    /// the system/mount maximum TTL.
    public var isRenewable: Bool?

    /// JSON list of allowed entity aliases. If set, specifies the entity aliases which are allowed to be used during token generation. This field supports globbing.
    /// 
    /// - Note: ``allowedEntityAliases`` is not case sensitive.
    public var allowedEntityAliases: [String]?

    /// List of CIDR blocks; if set, specifies blocks of IP addresses which can authenticate successfully, and ties the resulting token to these blocks as well.
    public var tokenBoundCidrs: [String]?

    /// Token type
    public var tokenType: TokenType?

    /// If set, will encode an explicit max TTL onto the token. This is a hard cap even if `tokenTTL` and `tokenMaxTTL` would otherwise allow a renewal.
    public var tokenExplicitMaxTTL: Duration?

    /// The maximum uses for the given token. This can be used to create a one-time-token or limited use token. The value of `nil` has no limit to the number of uses.
    public var tokenNumberOfUses: Int?

    /// If specified, the token will be periodic; it will have no maximum TTL (unless an `tokenMaxTTL` is also set) but every renewal will use the given period. Requires a root token or one with the sudo capability.
    public var tokenPeriod: Duration?

    /// If set, tokens created against this role will have the given suffix as part of their path in addition to the role name. This can be useful in certain scenarios,
    /// such as keeping the same role name in the future but revoking all tokens created against it before some point in time. The suffix can be changed,
    /// allowing new callers to have the new suffix as part of their path, and then tokens with the old suffix can be revoked via
    /// `/sys/leases/revoke-prefix`.
    public var pathSufix: String?

    public init(roleName: String,
                allowedPolicies: [String]? = nil,
                disallowedPolicies: [String]? = nil,
                allowedPoliciesGlob: [String]? = nil,
                disallowedPoliciesGlob: [String]? = nil,
                orphan: Bool = false,
                noDefaultPolicy: Bool = false,
                isRenewable: Bool? = nil,
                allowedEntityAliases: [String]? = nil,
                tokenBoundCidrs: [String]? = nil
                , tokenType: TokenType? = nil,
                tokenExplicitMaxTTL: Duration? = nil,
                tokenNumberOfUses: Int? = nil,
                tokenPeriod: Duration? = nil,
                pathSufix: String? = nil) {
        self.roleName = roleName
        self.allowedPolicies = allowedPolicies
        self.disallowedPolicies = disallowedPolicies
        self.allowedPoliciesGlob = allowedPoliciesGlob
        self.disallowedPoliciesGlob = disallowedPoliciesGlob
        self.orphan = orphan
        self.noDefaultPolicy = noDefaultPolicy
        self.isRenewable = isRenewable
        self.allowedEntityAliases = allowedEntityAliases
        self.tokenBoundCidrs = tokenBoundCidrs
        self.tokenType = tokenType
        self.tokenExplicitMaxTTL = tokenExplicitMaxTTL
        self.tokenNumberOfUses = tokenNumberOfUses
        self.tokenPeriod = tokenPeriod
        self.pathSufix = pathSufix
    }
}
