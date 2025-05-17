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


public struct CreateVaultToken: Sendable {
    /// The ID of the client token. Can only be specified by a root token. The ID provided may not contain a . character. Otherwise, the token ID is a randomly generated value.
    ///
    /// - Note: The ID should not start with the s. prefix.
    public var id: String?

    /// The name of the token role.
    public var roleName: String?

    /// A list of policies for the token. This must be a subset of the policies belonging to the token making the request, unless the calling token is root or contains sudo capabilities to auth/token/create.
    /// If not specified, defaults to all the policies of the calling token.
    public var policies: [String]?

    /// key=value metadata to associate with the token. This is passed through to the audit devices.
    public var meta: [String:String]?

    /// Create the token with no parent
    /// This argument only has effect if used by a root or sudo caller. When set to false, the token created will not have a parent.
    public var hasParent: Bool

    /// If set to `false` the default policy will not be contained in this token's policy set.
    public var hasDefaultPolicy: Bool

    /// Set to false to disable the ability of the token to be renewed past its initial TTL. Setting the value to true will allow the token to be renewable up to the system/mount maximum TTL.
    public var isRenewable: Bool?

    /// Time to live for this token
    /// Every non-root token has a time-to-live (TTL) associated with it, which is a current period of validity since either the token's creation time or last renewal time, whichever is more recent.
    /// (Root tokens may have a TTL associated, but the TTL may also be 0, indicating a token that never expires). After the current TTL is up, the token will no longer function -- it, and its associated leases, are revoked.
    ///
    /// If not provided, the token is valid for the default lease TTL, or indefinitely if the root policy is used.
    public var ttl: Duration?

    /// Token type
    /// Defaults to the type specified by the role configuration named by `roleName`.
    public var type: TokenType?

    /// This value becomes a hard limit on the token's lifetime -- no matter what the values in
    /// - The system max TTL
    /// - The max TTL set on a mount using mount tuning
    /// - A value suggested by the auth method that issued the token. This might be configured on a per-role, per-group, or per-user basis.
    public var tokenMaxTTL: Duration?

    /// Name to associate with this token
    public var displayName: String?

    /// The maximum uses for the given token. This can be used to create a one-time-token or limited use token. The value of `nil` has no limit to the number of uses.
    public var tokenNumberOfUses: Int?

    /// If specified, the token will be periodic; it will have no maximum TTL (unless an `tokenMaxTTL` is also set) but every renewal will use the given period. Requires a root token or one with the sudo capability.
    public var tokenPeriod: Duration?

    /// Name of the entity alias to associate with during token creation. Only works in combination with `roleName` property. If this has been specified, the entity will not be inherited from the parent.
    public var entityAlias: String?

    public init(id: String? = nil,
                roleName: String? = nil,
                policies: [String]? = nil,
                meta: [String : String]? = nil,
                hasParent: Bool = true,
                hasDefaultPolicy: Bool = true,
                isRenewable: Bool? = nil,
                ttl: Duration? = nil,
                type: TokenType? = nil,
                tokenMaxTTL: Duration? = nil,
                displayName: String? = nil,
                tokenNumberOfUses: Int? = nil,
                tokenPeriod: Duration? = nil,
                entityAlias: String? = nil) {
        self.id = id
        self.roleName = roleName
        self.policies = policies
        self.meta = meta
        self.hasParent = hasParent
        self.hasDefaultPolicy = hasDefaultPolicy
        self.isRenewable = isRenewable
        self.ttl = ttl
        self.type = type
        self.tokenMaxTTL = tokenMaxTTL
        self.displayName = displayName
        self.tokenNumberOfUses = tokenNumberOfUses
        self.tokenPeriod = tokenPeriod
        self.entityAlias = entityAlias
    }
}
