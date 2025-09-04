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

import OpenAPIRuntime
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.URL
import struct Foundation.Date
import typealias Foundation.TimeInterval
#endif
import Synchronization
import Logging
import TokenAuth
import VaultUtilities

public final class TokenProvider: Sendable {
    static var loggingDisabled: Logger { .init(label: "token-provider-do-not-log", factory: { _ in SwiftLogNoOpLogHandler() }) }

    init(apiURL: URL,
         clientTransport: any ClientTransport,
         middlewares: [any ClientMiddleware] = [],
         token: String? = nil,
         logger: Logger? = nil) {
        self.auth = TokenAuth(
            apiURL: apiURL,
            clientTransport: clientTransport,
            middlewares: middlewares,
            token: token)
        self.apiURL = apiURL
        self._token = .init(token)
        self.logger = logger ?? Self.loggingDisabled
    }

    /// Vault's URL
    let apiURL: URL

    /// Authentication client
    let auth: TokenAuth

    let _token: Mutex<String?>

    /// Client token
    var token: String? {
        get {
            _token.withLock { $0 }
        }
        set {
            _token.withLock {
                $0 = newValue
            }
        }
    }

    let logger: Logging.Logger
}

extension TokenProvider {
    /// Creates a new token.
    ///
    /// - Note: Certain options are only available when called by a root token.
    /// - Parameters:
    ///   - capabilities: type with the desired token properties
    ///   - wrappTTL: Optional wrapped time to live of the token
    /// - Returns: ``VaultCourier/VaultAuthResponse``
    public func createToken(
        _ capabilities: CreateVaultToken,
        wrappTTL: Duration? = nil
    ) async throws -> VaultAuthResponse {
        let sessionToken = auth.token

        let response = try await auth.client.tokenCreate(
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
                guard let tokenType = TokenType(rawValue: json.auth.tokenType.rawValue) else {
                    throw VaultClientError.receivedUnexpectedResponse("unexpected token type: \(String(describing: json.auth.tokenType))")
                }

                return .init(
                    requestID: json.requestId,
                    clientToken: json.auth.clientToken,
                    accessor: json.auth.accessor,
                    tokenPolicies: json.auth.tokenPolicies,
                    metadata: json.auth.metadata?.additionalProperties ?? [:],
                    leaseDuration: .seconds(json.auth.leaseDuration),
                    isRenewable: json.auth.renewable,
                    entityID: json.auth.entityId,
                    tokenType: tokenType,
                    isOrphan: json.auth.orphan,
                    numberOfUses: json.auth.numUses
                )
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .undocumented(let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }

    // MARK: Lookup
    
    /// Get token's information
    /// - Parameter token: token ID
    /// - Returns: Token properties
    public func lookup(token: String) async throws -> LookupTokenResponse {
        let sessionToken = auth.token

        let response = try await auth.client.lookupToken(
            headers: .init(xVaultToken: sessionToken),
            body: .json(.init(token: token))
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                guard let tokenType = TokenType(rawValue: json.data._type.rawValue) else {
                    throw VaultClientError.receivedUnexpectedResponse("unexpected token type: \(String(describing: json.data._type))")
                }

                return .init(
                    requestId: json.requestId,
                    clientToken: json.data.id,
                    accessor: json.data.accessor,
                    createdAt: Date(timeIntervalSince1970: TimeInterval(json.data.creationTime)),
                    creationTimeToLive: .seconds(json.data.creationTtl),
                    expiresAt: json.data.expireTime,
                    explicitMaxTimeToLive: .seconds(json.data.explicitMaxTtl ?? 0),
                    timeToLive: .seconds(json.data.ttl),
                    policies: json.data.policies,
                    metadata: json.data.meta?.additionalProperties ?? [:],
                    isRenewable: json.data.renewable,
                    tokenType: tokenType,
                    isOrphan: json.data.orphan,
                    numberOfUses: json.data.numUses
                )
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .undocumented(let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }
    
    /// Get client's token information
    /// - Returns: Returns information about the client token.
    public func lookupCurrentToken() async throws -> LookupTokenResponse {
        let sessionToken = auth.token

        let response = try await auth.client.lookupTokenSelf(
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                guard let tokenType = TokenType(rawValue: json.data._type.rawValue) else {
                    throw VaultClientError.receivedUnexpectedResponse("unexpected token type: \(String(describing: json.data._type))")
                }

                return .init(
                    requestId: json.requestId,
                    clientToken: json.data.id,
                    accessor: json.data.accessor,
                    createdAt: Date(timeIntervalSince1970: TimeInterval(json.data.creationTime)),
                    creationTimeToLive: .seconds(json.data.creationTtl),
                    expiresAt: json.data.expireTime,
                    explicitMaxTimeToLive: .seconds(json.data.explicitMaxTtl ?? 0),
                    timeToLive: .seconds(json.data.ttl),
                    policies: json.data.policies,
                    metadata: json.data.meta?.additionalProperties ?? [:],
                    isRenewable: json.data.renewable,
                    tokenType: tokenType,
                    isOrphan: json.data.orphan,
                    numberOfUses: json.data.numUses
                )
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .undocumented(let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }
    
    /// Get token's information via accessor
    /// - Parameter accessor: accessor ID
    /// - Returns: Returns information about the reference token which is referenced by the accessor.
    public func lookupToken(accessor: String) async throws -> LookupTokenResponse {
        let sessionToken = auth.token

        let response = try await auth.client.lookupTokenAccessor(
            headers: .init(xVaultToken: sessionToken),
            body: .json(.init(accessor: accessor))
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                guard let tokenType = TokenType(rawValue: json.data._type.rawValue) else {
                    throw VaultClientError.receivedUnexpectedResponse("unexpected token type: \(String(describing: json.data._type))")
                }

                return .init(
                    requestId: json.requestId,
                    clientToken: json.data.id,
                    accessor: json.data.accessor,
                    createdAt: Date(timeIntervalSince1970: TimeInterval(json.data.creationTime)),
                    creationTimeToLive: .seconds(json.data.creationTtl),
                    expiresAt: json.data.expireTime,
                    explicitMaxTimeToLive: .seconds(json.data.explicitMaxTtl ?? 0),
                    timeToLive: .seconds(json.data.ttl),
                    policies: json.data.policies,
                    metadata: json.data.meta?.additionalProperties ?? [:],
                    isRenewable: json.data.renewable,
                    tokenType: tokenType,
                    isOrphan: json.data.orphan,
                    numberOfUses: json.data.numUses
                )
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
    /// - Returns: ``VaultCourier/VaultAuthResponse``
    public func renewToken(
        _ token: String,
        by increment: Duration? = nil
    ) async throws -> VaultAuthResponse {
        let sessionToken = auth.token

        let response = try await auth.client.tokenRenew(
            headers: .init(xVaultToken: sessionToken),
            body: .json(.init(token: token, increment: increment?.formatted(.vaultSeconds)))
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                guard let tokenType = TokenType(rawValue: json.auth.tokenType.rawValue) else {
                    throw VaultClientError.receivedUnexpectedResponse("unexpected token type: \(String(describing: json.auth.tokenType))")
                }

                return .init(
                    requestID: json.requestId,
                    clientToken: json.auth.clientToken,
                    accessor: json.auth.accessor,
                    tokenPolicies: json.auth.tokenPolicies,
                    metadata: json.auth.metadata?.additionalProperties ?? [:],
                    leaseDuration: .seconds(json.auth.leaseDuration),
                    isRenewable: json.auth.renewable,
                    entityID: json.auth.entityId,
                    tokenType: tokenType,
                    isOrphan: json.auth.orphan,
                    numberOfUses: json.auth.numUses
                )
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
    /// - Returns: ``VaultCourier/VaultAuthResponse``
    public func renewToken(
        by increment: Duration? = nil
    ) async throws -> VaultAuthResponse {
        let sessionToken = auth.token

        let response = try await auth.client.tokenRenewSelf(
            headers: .init(xVaultToken: sessionToken),
            body: .json(.init(increment: increment?.formatted(.vaultSeconds)))
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                guard let tokenType = TokenType(rawValue: json.auth.tokenType.rawValue) else {
                    throw VaultClientError.receivedUnexpectedResponse("unexpected token type: \(String(describing: json.auth.tokenType))")
                }

                return .init(
                    requestID: json.requestId,
                    clientToken: json.auth.clientToken,
                    accessor: json.auth.accessor,
                    tokenPolicies: json.auth.tokenPolicies,
                    metadata: json.auth.metadata?.additionalProperties ?? [:],
                    leaseDuration: .seconds(json.auth.leaseDuration),
                    isRenewable: json.auth.renewable,
                    entityID: json.auth.entityId,
                    tokenType: tokenType,
                    isOrphan: json.auth.orphan,
                    numberOfUses: json.auth.numUses
                )
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
    /// - Returns: ``VaultCourier/VaultAuthResponse``
    public func renewToken(
        accessor: String,
        by increment: Duration? = nil
    ) async throws -> VaultAuthResponse {
        let sessionToken = auth.token

        let response = try await auth.client.tokenRenewAccessor(
            headers: .init(xVaultToken: sessionToken),
            body: .json(.init(accessor: accessor, increment: increment?.formatted(.vaultSeconds)))
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                guard let tokenType = TokenType(rawValue: json.auth.tokenType.rawValue) else {
                    throw VaultClientError.receivedUnexpectedResponse("unexpected token type: \(String(describing: json.auth.tokenType))")
                }

                return .init(
                    requestID: json.requestId,
                    clientToken: json.auth.clientToken,
                    accessor: json.auth.accessor,
                    tokenPolicies: json.auth.tokenPolicies,
                    metadata: json.auth.metadata?.additionalProperties ?? [:],
                    leaseDuration: .seconds(json.auth.leaseDuration),
                    isRenewable: json.auth.renewable,
                    entityID: json.auth.entityId,
                    tokenType: tokenType,
                    isOrphan: json.auth.orphan,
                    numberOfUses: json.auth.numUses
                )
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
    public func revoke(
        token: String,
        orphan: Bool = false
    ) async throws {
        let sessionToken = auth.token

        if orphan {
            let response = try await auth.client.tokenRevokeOrphan(
                headers: .init(xVaultToken: sessionToken),
                body: .json(.init(token: token))
            )

            switch response {
                case .noContent:
                    logger.info("Token revoked successfully.")
                case .badRequest(let content):
                    let errors = (try? content.body.json.errors) ?? []
                    logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                    throw VaultClientError.badRequest(errors)
                case .undocumented(statusCode: let statusCode, _):
                    logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                    throw VaultClientError.operationFailed(statusCode)
            }
        } else {
            let response = try await auth.client.tokenRevoke(
                headers: .init(xVaultToken: sessionToken),
                body: .json(.init(token: token))
            )

            switch response {
                case .noContent:
                    logger.info("Token revoked successfully.")
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
    public func revokeCurrentToken() async throws {
        let sessionToken = auth.token

        let response = try await auth.client.tokenRevokeSelf(
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .noContent:
                logger.info("Token revoked successfully.")
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
    public func revokeToken(
        accessor: String
    ) async throws {
        let sessionToken = auth.token

        let response = try await auth.client.tokenRevokeAccessor(
            headers: .init(xVaultToken: sessionToken),
            body: .json(.init(accessor: accessor))
        )

        switch response {
            case .noContent:
                logger.info("Token revoked successfully.")
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .undocumented(statusCode: let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }


    /// Fetches the named role configuration.
    /// - Parameter name: The name of the token role.
    /// - Returns: ``VaultTokenRole``
    public func readTokenRole(name: String) async throws -> VaultTokenRole {
        let sessionToken = auth.token

        let response = try await auth.client.readTokenRole(
            path: .init(roleName: name),
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                return .init(
                    roleName: json.data.name,
                    allowedPolicies: json.data.allowedPolicies,
                    disallowedPolicies: json.data.disallowedPolicies,
                    allowedPoliciesGlob: json.data.allowedPoliciesGlob,
                    disallowedPoliciesGlob: json.data.disallowedPoliciesGlob,
                    orphan: json.data.orphan ?? false,
                    noDefaultPolicy: json.data.tokenNoDefaultPolicy ?? false,
                    isRenewable: json.data.renewable,
                    allowedEntityAliases: json.data.allowedEntityAliases,
                    tokenBoundCidrs: json.data.tokenBoundCidrs,
                    tokenType: .init(rawValue: json.data.tokenType?.rawValue ?? ""),
                    tokenExplicitMaxTTL: json.data.tokenExplicitMaxTtl.flatMap({.seconds($0)}),
                    tokenNumberOfUses: json.data.tokenNumUses,
                    tokenPeriod: json.data.tokenPeriod.flatMap({.seconds($0)}),
                    pathSufix: json.data.pathSuffix
                )
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .undocumented(statusCode: let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }

    /// Creates (or replaces) the named token role.
    /// - Parameter capabilities: new properties of the token role
    public func updateTokenRole(
        _ capabilities: VaultTokenRole
    ) async throws {
        let sessionToken = auth.token

        let response = try await auth.client.updateTokenRole(
            path: .init(roleName: capabilities.roleName),
            headers: .init(xVaultToken: sessionToken),
            body: .json(.init(
                    allowedPolicies: capabilities.allowedPolicies,
                    disallowedPolicies: capabilities.disallowedPolicies,
                    allowedPoliciesGlob: capabilities.allowedPoliciesGlob,
                    disallowedPoliciesGlob: capabilities.disallowedPoliciesGlob,
                    orphan: capabilities.orphan,
                    renewable: capabilities.isRenewable,
                    pathSuffix: capabilities.pathSufix,
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


    /// Deletes the named token role.
    /// - Parameter name:The name of the token role.
    public func deleteTokenRole(name: String) async throws {
        let sessionToken = auth.token

        let response = try await auth.client.deleteTokenRole(
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
