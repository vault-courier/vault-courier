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

extension VaultClient {

    /// Creates a new token.
    ///
    /// - Note: Certain options are only available when called by a root token.
    /// - Parameters:
    ///   - capabilities: type with the desired token properties
    ///   - wrappTTL: Optional wrapped time to live of the token
    /// - Returns: ``VaultCourier/VaultAuthResponse``
    public func createToken(
        _ capabilities: CreateVaultToken,
        wrapTimeToLive: Duration? = nil
    ) async throws -> VaultAuthResponse {
        try await withTokenProvider { provider in
            try await provider.createToken(capabilities, wrappTTL: wrapTimeToLive)
        }
    }

    // MARK: Lookup

    /// Get token's information
    /// - Parameter token: token ID
    /// - Returns: Token properties
    public func lookup(token: String) async throws -> LookupTokenResponse {
        try await withTokenProvider { provider in
            try await provider.lookup(token: token)
        }
    }

    /// Get client's token information
    /// - Returns: Returns information about the client token.
    public func lookupCurrentToken() async throws -> LookupTokenResponse {
        try await withTokenProvider { provider in
            try await provider.lookupCurrentToken()
        }
    }

    /// Get token's information via accessor
    /// - Parameter accessor: accessor ID
    /// - Returns: Returns information about the reference token which is referenced by the accessor.
    public func lookupToken(accessor: String) async throws -> LookupTokenResponse {
        try await withTokenProvider { provider in
            try await provider.lookupToken(accessor: accessor)
        }
    }

    // MARK: Renew

    /// Renews a lease associated with a token.
    ///
    /// This is used to prevent the expiration of a token, and the automatic revocation of it. Token renewal is possible only if there is a lease associated with it.
    /// - Parameters:
    ///   - token: Token to renew
    ///   - increment: An optional requested increment duration. This increment may not be honored, for instance in the case of periodic tokens. If not supplied, Vault will use the default TTL
    /// - Returns: ``VaultCourier/VaultAuthResponse``
    public func renewToken(
        _ token: String,
        by increment: Duration? = nil
    ) async throws -> VaultAuthResponse {
        try await withTokenProvider { provider in
            try await provider.renewToken(token, by: increment)
        }
    }

    /// Renews a lease associated with the calling token.
    ///
    /// This is used to prevent the expiration of a token, and the automatic revocation of it. Token renewal is possible only if there is a lease associated with it.
    /// - Parameters:
    ///   - increment: An optional requested increment duration. This increment may not be honored, for instance in the case of periodic tokens. If not supplied, Vault will use the default TTL
    /// - Returns: ``VaultCourier/VaultAuthResponse``
    public func renewToken(
        by increment: Duration? = nil
    ) async throws -> VaultAuthResponse {
        try await withTokenProvider { provider in
            try await provider.renewToken(by: increment)
        }
    }

    /// Renews a lease associated with a token using its accessor.
    ///
    /// This is used to prevent the expiration of a token, and the automatic revocation of it. Token renewal is possible only if there is a lease associated with it.
    /// - Parameters:
    ///   - accessor: Accessor associated with the token to renew.
    ///   - increment: An optional requested lease increment can be provided. This increment may be ignored by Vault.
    /// - Returns: ``VaultCourier/VaultAuthResponse``
    public func renewToken(
        accessor: String,
        by increment: Duration? = nil
    ) async throws -> VaultAuthResponse {
        try await withTokenProvider { provider in
            try await provider.renewToken(accessor: accessor, by: increment)
        }
    }

    // MARK: Revoke

    /// Revokes a token and all child tokens.
    ///
    /// When the token is revoked, all dynamic secrets generated with it are also revoked.
    /// - Parameter token: Token to revoke.
    /// - Parameter orphan: Revokes a token but not its child tokens. When the token is revoked, all secrets generated with it are also revoked. All child tokens are orphaned, but can be revoked sub-sequently. This is a root-protected endpoint, so this flag only works with a root token.
    public func revoke(
        token: String,
        orphan: Bool = false
    ) async throws {
        try await withTokenProvider { provider in
            try await provider.revoke(token: token, orphan: orphan)
        }
    }

    /// Revokes the current client's token and all child tokens.
    ///
    /// When the token is revoked, all dynamic secrets generated with it are also revoked.
    public func revokeCurrentToken() async throws {
        try await withTokenProvider { provider in
            try await provider.revokeCurrentToken()
        }
    }

    /// Revoke the token associated with the accessor and all the child tokens.
    ///
    /// This is meant for purposes where there is no access to token ID but there is need to revoke a token and its children.
    /// - Parameter accessor: Accessor of the token
    public func revokeToken(
        accessor: String
    ) async throws {
        try await withTokenProvider { provider in
            try await provider.revokeToken(accessor: accessor)
        }
    }

    
    /// Fetches the named role configuration.
    /// - Parameter name: The name of the token role.
    /// - Returns: ``VaultTokenRole``
    public func readTokenRole(name: String) async throws -> VaultTokenRole {
        try await withTokenProvider { provider in
            try await provider.readTokenRole(name: name)
        }
    }
    
    /// Creates (or replaces) the named token role.
    /// - Parameter capabilities: new properties of the token role
    public func updateTokenRole(
        _ capabilities: VaultTokenRole
    ) async throws {
        try await withTokenProvider { provider in
            try await provider.updateTokenRole(capabilities)
        }
    }

    
    /// Deletes the named token role.
    /// - Parameter name:The name of the token role.
    public func deleteTokenRole(name: String) async throws {
        try await withTokenProvider { provider in
            try await provider.deleteTokenRole(name: name)
        }
    }
}
