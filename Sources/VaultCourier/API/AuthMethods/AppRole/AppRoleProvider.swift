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
import OpenAPIRuntime
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.URL
#endif
import Synchronization
import Logging
import AppRoleAuth
//import Utils

public final class AppRoleProvider: Sendable {
    static var loggingDisabled: Logger { .init(label: "app-role-provider-do-not-log", factory: { _ in SwiftLogNoOpLogHandler() }) }

    init(apiURL: URL,
         clientTransport: any ClientTransport,
         mountPath: String? = nil,
         middlewares: [any ClientMiddleware] = [],
         token: String? = nil,
         logger: Logger? = nil) {
        self.auth = AppRoleAuth(
            configuration: .init(apiURL: apiURL, mountPath: mountPath),
            clientTransport: clientTransport,
            middlewares: middlewares,
            token: token)
        self.apiURL = apiURL
        self.mountPath = mountPath?.removeSlash() ?? "approle"
        self._token = .init(token)
        self.logger = logger ?? Self.loggingDisabled
    }

    /// Vault's URL
    let apiURL: URL

    let mountPath: String

    /// Authentication client
    let auth: AppRoleAuth

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

extension AppRoleProvider {
    /// Creates a new AppRole
    public func createAppRole(
        _ appRole: CreateAppRole
    ) async throws {
        guard let sessionToken = token else {
            throw VaultClientError.clientIsNotLoggedIn()
        }
        let mountPath = self.mountPath

        let response = try await auth.client.authCreateApprole(
            path: .init(enginePath: mountPath, roleName: appRole.name),
            headers: .init(xVaultToken: sessionToken),
            body: .json(.init(
                tokenBoundCidrs: appRole.tokenBoundCIDRS,
                tokenExplicitMaxTtl: nil,
                tokenNoDefaultPolicy: appRole.tokenNoDefaultPolicy,
                tokenNumUses: appRole.tokenNumberOfUses,
                tokenPeriod: appRole.tokenPeriod?.formatted(.vaultSeconds),
                tokenType: .init(rawValue: appRole.tokenType.rawValue),
                tokenTtl: appRole.tokenTimeToLive?.formatted(.vaultSeconds),
                tokenMaxTtl: appRole.tokenMaxTimeToLive?.formatted(.vaultSeconds),
                tokenPolicies: appRole.tokenPolicies,
                bindSecretId: appRole.bindSecretID,
                secretIdBoundCidrs: appRole.secretIdBoundCIDRS,
                secretIdNumUses: appRole.secretIdNumberOfUses,
                secretIdTtl: appRole.secretIdTimeToLive?.formatted(.vaultSeconds),
                localSecretIds: appRole.localSecretIds))
        )


        switch response {
            case .noContent:
                logger.info("approle \(appRole.name) created.")
            case let .undocumented(statusCode, payload):
                let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                throw vaultError
        }
    }

    /// Read AppRole
    /// - Parameter name: role name
    public func readAppRole(name: String) async throws -> ReadAppRoleResponse {
        guard let sessionToken = token else {
            throw VaultClientError.clientIsNotLoggedIn()
        }
        let mountPath = self.mountPath

        let response = try await auth.client.authReadApprole(
            path: .init(enginePath: mountPath, roleName: name),
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                guard let tokenType = TokenType(rawValue: json.data.tokenType?.rawValue ?? "") else {
                    throw VaultClientError.receivedUnexpectedResponse("Unexpected token type: \(String(describing: json.data.tokenType))")
                }

                return .init(
                    requestID: json.requestId,
                    tokenPolicies: json.data.tokenPolicies ?? [],
                    tokenTimeToLive: json.data.tokenTtl.flatMap(Duration.seconds(_:)),
                    tokenMaxTimeToLive: json.data.tokenMaxTtl.flatMap(Duration.seconds(_:)),
                    tokenBoundCIDRS: json.data.tokenBoundCidrs,
                    tokenExplicitMaxTimeToLive: json.data.tokenExplicitMaxTtl.flatMap(Duration.seconds(_:)),
                    tokenNoDefaultPolicy: json.data.tokenNoDefaultPolicy ?? false,
                    tokenNumberOfUses: json.data.tokenNumUses ?? 0,
                    tokenPeriod: json.data.tokenPeriod,
                    secretIdTimeToLive: json.data.secretIdTtl.flatMap(Duration.seconds(_:)),
                    isRenewable: json.renewable,
                    secretIdNumberOfUses: json.data.secretIdNumUses,
                    bindSecretID: json.data.bindSecretId ?? true,
                    localSecretID: json.data.localSecretIds ?? false,
                    secretIdBoundCIDRS: json.data.secretIdBoundCidrs,
                    tokenType: tokenType
                )
            case let .undocumented(statusCode, payload):
                let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                throw vaultError
        }
    }

    /// Delete existing AppRole
    /// - Parameter name: role name
    public func deleteAppRole(name: String) async throws {
        guard let sessionToken = token else {
            throw VaultClientError.clientIsNotLoggedIn()
        }
        let mountPath = self.mountPath

        let response = try await auth.client.authDeleteApprole(
            path: .init(enginePath: mountPath, roleName: name),
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .noContent:
                logger.info("Approle \(name) deleted.")
            case let .undocumented(statusCode, payload):
                let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                throw vaultError
        }
    }

    /// Get AppRole ID
    /// - Parameter name: role name
    public func appRoleID(name: String) async throws -> AppRoleIDResponse {
        guard let sessionToken = token else {
            throw VaultClientError.clientIsNotLoggedIn()
        }
        let mountPath = self.mountPath

        let response = try await auth.client.authReadRoleId(
            path: .init(enginePath: mountPath, roleName: name),
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                if let json = json.value1 {
                    switch json {
                        case .ReadAppRoleIdResponse(let component):
                            return .init(requestID: component.requestId, roleID: component.data.roleId)
                        case .VaultWrappedResponse:
                            throw VaultClientError.receivedUnexpectedResponse()
                    }
                } else if let json = json.value2 {
                    logger.debug(.init(stringLiteral: "\(#function) Unknown body response: \(json.value.description)"))
                    throw VaultClientError.receivedUnexpectedResponse()
                } else {
                    preconditionFailure("Unreachable path \(#function)")
                }
            case let .undocumented(statusCode, payload):
                let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                throw vaultError
        }
    }

    /// Get a wrapped AppRole ID
    /// - Parameter name: role name
    public func wrapAppRoleID(
        name: String,
        wrapTimeToLive: Duration
    ) async throws -> WrappedTokenResponse {
        guard let sessionToken = token else {
            throw VaultClientError.clientIsNotLoggedIn()
        }
        let mountPath = self.mountPath

        let response = try await auth.client.authReadRoleId(
            path: .init(enginePath: mountPath, roleName: name),
            headers: .init(
                xVaultToken: .init(sessionToken),
                xVaultWrapTTL: .init(wrapTimeToLive.formatted(.vaultSeconds))
            )
        )
        
        switch response {
            case .ok(let content):
                let json = try content.body.json
                if let json = json.value1 {
                    switch json {
                        case .ReadAppRoleIdResponse:
                            throw VaultClientError.receivedUnexpectedResponse()
                        case .VaultWrappedResponse(let component):
                            return .init(
                                requestID: component.requestId,
                                token: component.wrapInfo.token,
                                accessor: component.wrapInfo.accessor,
                                timeToLive: component.wrapInfo.ttl,
                                createdAt: component.wrapInfo.creationTime,
                                creationPath: component.wrapInfo.creationPath,
                                wrappedAccessor: component.wrapInfo.wrappedAccessor
                            )
                    }
                } else if let json = json.value2 {
                    logger.debug(.init(stringLiteral: "\(#function) Unknown body response: \(json.value.description)"))
                    throw VaultClientError.decodingFailed()
                } else {
                    preconditionFailure("Unreachable path \(#function)")
                }
            case let .undocumented(statusCode, payload):
                let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                throw vaultError
        }
    }

    /// Generate AppRole secretID
    /// - Parameter capabilities: the properties this generated secretID must have
    /// - Returns: Either a wrapped response token or the secretID
    public func generateAppSecretId(
        capabilities: GenerateAppRoleToken
    ) async throws -> AppRoleSecretIdResponse {
        guard let sessionToken = token else {
            throw VaultClientError.clientIsNotLoggedIn()
        }
        let mountPath = self.mountPath

        let response = try await auth.client.authApproleSecretId(
            path: .init(enginePath: mountPath, roleName: capabilities.roleName),
            headers: .init(
                xVaultToken: .init(sessionToken),
                xVaultWrapTTL: capabilities.wrapTimeToLive.flatMap({ $0.formatted(.vaultSeconds) }).flatMap(String.init(_:))
            ),
            body: .json(.init(
                tokenBoundCidrs: capabilities.tokenBoundCIDRS,
                cidrList: capabilities.cidrList,
                metadata: capabilities.metadata,
                numUses: capabilities.tokenNumberOfUses,
                ttl: capabilities.tokenTimeToLive?.formatted(.vaultSeconds)))
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                if let json = json.value1 {
                    switch json {
                        case .GenerateAppRoleSecretIdResponse(let component):
                            return .secretId(.init(
                                requestID: component.requestId,
                                secretID: component.data.secretId,
                                secretIDAccessor: component.data.secretIdAccessor,
                                secretIDTimeToLive: component.data.secretIdTtl,
                                secretIDNumberOfUses: component.data.secretIdNumUses))
                        case .VaultWrappedResponse(let component):
                            return .wrapped(
                                .init(
                                    requestID: component.requestId,
                                    token: component.wrapInfo.token,
                                    accessor: component.wrapInfo.accessor,
                                    timeToLive: component.wrapInfo.ttl,
                                    createdAt: component.wrapInfo.creationTime,
                                    creationPath: component.wrapInfo.creationPath,
                                    wrappedAccessor: component.wrapInfo.wrappedAccessor
                                )
                            )
                    }
                } else if let json = json.value2 {
                    logger.debug(.init(stringLiteral: "\(#function) Unknown body response: \(json.value.description)"))
                    throw VaultClientError.receivedUnexpectedResponse()
                } else {
                    preconditionFailure("Unreachable path \(#function)")
                }
            case let .undocumented(statusCode, payload):
                let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                throw vaultError
        }
    }

    /// Fetches the login session token and its information.
    ///
    /// if ``VaultCourier/CreateAppRole/bindSecretID`` is enabled (the default) on the AppRole, `secretID` is required too. Any other bound authentication values on the AppRole (such as client IP CIDR) are also evaluated.
    ///
    /// - Note: this method does not set the token session of the vault client. See the ``VaultCourier/VaultClient/login()`` which initiates login from the given authentication
    /// method and sets the session token of the client.
    /// - Parameters:
    ///   - roleID: RoleID of the AppRole
    ///   - secretID: SecretID belonging to AppRole
    /// - Returns: ``VaultAuthResponse``
    public func loginToken(
        roleID: String,
        secretID: String
    ) async throws -> VaultAuthResponse {
        let mountPath = self.mountPath

        let response = try await auth.client.authApproleLogin(
            path: .init(enginePath: mountPath),
            body: .json(.init(roleId: roleID, secretId: secretID))
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
            case let .undocumented(statusCode, payload):
                let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                throw vaultError
        }
    }
}
#endif
