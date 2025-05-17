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
    /// - Returns: ``VaultTokenResponse``
    public func createToken(
        _ capabilities: CreateVaultToken,
        wrappTTL: Duration? = nil
    ) async throws -> VaultTokenResponse {
        let sessionToken = try sessionToken()

        let response = try await client.tokenCreate(
            headers: .init(xVaultToken: sessionToken, xVaultWrapTTL: wrappTTL?.formatted(.vaultSeconds)),
            body: .json(.init(
                displayName: capabilities.displayName,
                entityAlias: capabilities.entityAlias,
                explicitMaxTtl: capabilities.tokenMaxTTL?.formatted(.vaultSeconds),
                id: capabilities.id,
                meta: .init(unvalidatedValue: capabilities.meta ?? [:]),
                noDefaultPolicy: !capabilities.hasDefaultPolicy,
                noParent: !capabilities.hasParent,
                numUses: capabilities.tokenNumberOfUses,
                period: capabilities.tokenPeriod?.formatted(.vaultSeconds),
                policies: capabilities.policies,
                renewable: capabilities.isRenewable,
                ttl: capabilities.ttl?.formatted(.vaultSeconds),
                _type: .init(rawValue: capabilities.type?.rawValue ?? ""))
            )
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                return try json.tokenResponse
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .undocumented(let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }

    // MARK: Renew

    /// Renews a lease associated with a token.
    /// 
    /// This is used to prevent the expiration of a token, and the automatic revocation of it. Token renewal is possible only if there is a lease associated with it.
    /// - Parameters:
    ///   - token: Token to renew
    ///   - increment: An optional requested increment duration. This increment may not be honored, for instance in the case of periodic tokens. If not supplied, Vault will use the default TTL
    /// - Returns: ``VaultTokenResponse``
    public func renewToken(
        _ token: String,
        by increment: Duration? = nil
    ) async throws -> VaultTokenResponse {
        let sessionToken = try sessionToken()

        let response = try await client.tokenRenew(
            headers: .init(xVaultToken: sessionToken),
            body: .json(.init(token: token, increment: increment?.formatted(.vaultSeconds)))
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                return try json.tokenResponse
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .undocumented(statusCode: let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }

    /// Renews a lease associated with the calling token.
    ///
    /// This is used to prevent the expiration of a token, and the automatic revocation of it. Token renewal is possible only if there is a lease associated with it.
    /// - Parameters:
    ///   - increment: An optional requested increment duration. This increment may not be honored, for instance in the case of periodic tokens. If not supplied, Vault will use the default TTL
    /// - Returns: ``VaultTokenResponse``
    public func renewToken(
        by increment: Duration? = nil
    ) async throws -> VaultTokenResponse {
        let sessionToken = try sessionToken()

        let response = try await client.tokenRenewSelf(
            headers: .init(xVaultToken: sessionToken),
            body: .json(.init(increment: increment?.formatted(.vaultSeconds)))
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                return try json.tokenResponse
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .undocumented(statusCode: let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }

    /// Renews a lease associated with a token using its accessor.
    /// 
    /// This is used to prevent the expiration of a token, and the automatic revocation of it. Token renewal is possible only if there is a lease associated with it.
    /// - Parameters:
    ///   - accessor: Accessor associated with the token to renew.
    ///   - increment: An optional requested lease increment can be provided. This increment may be ignored by Vault.
    /// - Returns: ``VaultTokenResponse``
    public func renewToken(
        accessor: String,
        by increment: Duration? = nil
    ) async throws -> VaultTokenResponse {
        let sessionToken = try sessionToken()

        let response = try await client.tokenRenewAccessor(
            headers: .init(xVaultToken: sessionToken),
            body: .json(.init(accessor: accessor, increment: increment?.formatted(.vaultSeconds)))
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                return try json.tokenResponse
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .undocumented(statusCode: let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }

    // MARK: Revoke

    /// Revokes a token and all child tokens.
    /// 
    /// When the token is revoked, all dynamic secrets generated with it are also revoked.
    /// - Parameter token: Token to revoke.
    /// - Parameter orphan: Revokes a token but not its child tokens. When the token is revoked, all secrets generated with it are also revoked. All child tokens are orphaned, but can be revoked sub-sequently. This is a root-protected endpoint, so this flag only works with a root token.
    /// - Returns: ``VaultTokenResponse``
    public func revokeToken(
        _ token: String,
        orphan: Bool = false
    ) async throws -> VaultTokenResponse {
        let sessionToken = try sessionToken()

        if orphan {
            let response = try await client.tokenRevokeOrphan(
                headers: .init(xVaultToken: sessionToken),
                body: .json(.init(token: token))
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json
                    return try json.tokenResponse
                case .badRequest(let content):
                    let errors = (try? content.body.json.errors) ?? []
                    logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                    throw VaultClientError.badRequest(errors)
                case .undocumented(statusCode: let statusCode, _):
                    logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                    throw VaultClientError.operationFailed(statusCode)
            }
        } else {
            let response = try await client.tokenRevoke(
                headers: .init(xVaultToken: sessionToken),
                body: .json(.init(token: token))
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json
                    return try json.tokenResponse
                case .badRequest(let content):
                    let errors = (try? content.body.json.errors) ?? []
                    logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                    throw VaultClientError.badRequest(errors)
                case .undocumented(statusCode: let statusCode, _):
                    logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                    throw VaultClientError.operationFailed(statusCode)
            }
        }
    }

    /// Revokes the current client's token and all child tokens.
    /// 
    /// When the token is revoked, all dynamic secrets generated with it are also revoked.
    /// - Returns: ``VaultTokenResponse``
    public func revokeCurrentToken() async throws -> VaultTokenResponse {
        let sessionToken = try sessionToken()

        let response = try await client.tokenRevokeSelf(
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                return try json.tokenResponse
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .undocumented(statusCode: let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }

    /// Revoke the token associated with the accessor and all the child tokens.
    /// 
    /// This is meant for purposes where there is no access to token ID but there is need to revoke a token and its children.
    /// - Parameter accessor: Accessor of the token
    /// - Returns: ``VaultTokenResponse``
    public func revokeToken(
        accessor: String
    ) async throws -> VaultTokenResponse {
        let sessionToken = try sessionToken()

        let response = try await client.tokenRevokeAccessor(
            headers: .init(xVaultToken: sessionToken),
            body: .json(.init(accessor: accessor))
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                return try json.tokenResponse
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .undocumented(statusCode: let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }

    #warning("TODO: Write the ReadTokenRole")

    public func updateTokenRole(
        _ capabilities: UpdateTokenRole
    ) async throws {
        let sessionToken = try sessionToken()

        let response = try await client.updateTokenRole(
            path: .init(roleName: capabilities.roleName),
            headers: .init(xVaultToken: sessionToken),
            body: .json(.init(
                    allowedPolicies: capabilities.allowedPolicies,
                    disallowedPolicies: capabilities.disallowedPolicies,
                    allowedPoliciesGlob: capabilities.allowedPoliciesGlob,
                    disallowedPoliciesGlob: capabilities.disallowedPoliciesGlob,
                    orphan: capabilities.orphan,
                    renewable: capabilities.isRenewable,
                    pathSufix: capabilities.pathSufix,
                    allowedEntityAliases: capabilities.allowedEntityAliases,
                    tokenBoundCidrs: capabilities.tokenBoundCidrs,
                    tokenExplicitMaxTtl: capabilities.tokenExplicitMaxTTL?.formatted(.vaultSeconds),
                    tokenNoDefaultPolicy: capabilities.noDefaultPolicy,
                    tokenNumUses: capabilities.tokenNumberOfUses,
                    tokenPeriod: capabilities.tokenPeriod?.formatted(.vaultSeconds),
                    tokenType: .init(rawValue: capabilities.tokenType?.rawValue ?? "")
                )
            )
        )

        switch response {
            case .noContent:
                logger.info("Token role updated successfully.")
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .undocumented(statusCode: let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }

    public func deleteTokenRole(name: String) async throws {
        let sessionToken = try sessionToken()

        let response = try await client.deleteTokenRole(
            path: .init(roleName: name),
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .noContent:
                logger.info("Token role deleted successfully.")
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .undocumented(statusCode: let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }
}
