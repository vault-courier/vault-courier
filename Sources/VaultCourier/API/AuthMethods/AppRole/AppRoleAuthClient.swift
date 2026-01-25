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
import FoundationInternationalization
#else
import struct Foundation.URL
#endif
import Synchronization
import Tracing
import Logging
import AppRoleAuth
import Utils

/// Client for AppRole Authentication
///
/// - Note: You don't usually create this type directly, but instead use ``VaultClient/withAppRoleClient(mountPath:execute:)`` to interact with this type
public final class AppRoleAuthClient: Sendable {
    static var loggingDisabled: Logger { .init(label: "app-role-provider-do-not-log", factory: { _ in SwiftLogNoOpLogHandler() }) }

    init(apiURL: URL,
         clientTransport: any ClientTransport,
         mountPath: String,
         middlewares: [any ClientMiddleware] = [],
         token: String? = nil,
         logger: Logger? = nil) {
        self.auth = AppRoleAuth(
            configuration: .init(apiURL: apiURL, mountPath: mountPath),
            clientTransport: clientTransport,
            middlewares: middlewares,
            token: token)
        self.apiURL = apiURL
        self.mountPath = mountPath.removeSlash()
        self._token = .init(token)
        var logger = logger ?? Self.loggingDisabled
        logger[metadataKey: "auth"] = "approle"
        self.logger = logger
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

    typealias TracingAttributes = TracingSupport.AttributeKeys
}

extension AppRoleAuthClient {
    /// Creates a new AppRole
    public func createAppRole(
        _ appRole: AppRoleCreationConfig
    ) async throws {
        return try await withSpan(Operations.AuthCreateApprole.id, ofKind: .client) { span in
            guard let sessionToken = token else {
                 let clientError = VaultClientError.clientIsNotLoggedIn()
                TracingSupport.handleResponse(error: clientError, span)
                throw clientError
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
                    let eventName = "approle created."
                    span.attributes[TracingAttributes.responseStatusCode] = 204
                    span.addEvent(.init(name: eventName))
                    logger.trace(.init(stringLiteral: eventName))
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }

    /// Read AppRole
    /// - Parameter name: role name
    public func readAppRole(name: String) async throws -> ReadAppRoleResponse {
        return try await withSpan(Operations.AuthReadApprole.id, ofKind: .client) { span in
            guard let sessionToken = token else {
                let clientError = VaultClientError.clientIsNotLoggedIn()
               TracingSupport.handleResponse(error: clientError, span)
               throw clientError
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

                    let vaultRequestID = json.requestId
                    TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)
                    logger.trace(
                        .init(stringLiteral: "read approle"),
                        metadata: [
                        TracingAttributes.vaultRequestID: .string(vaultRequestID)
                    ])

                    return .init(
                        requestID: vaultRequestID,
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
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }

    /// Delete existing AppRole
    /// - Parameter name: role name
    public func deleteAppRole(name: String) async throws {
        return try await withSpan(Operations.AuthDeleteApprole.id, ofKind: .client) { span in
            guard let sessionToken = token else {
                let clientError = VaultClientError.clientIsNotLoggedIn()
               TracingSupport.handleResponse(error: clientError, span)
               throw clientError
            }
            let mountPath = self.mountPath

            let response = try await auth.client.authDeleteApprole(
                path: .init(enginePath: mountPath, roleName: name),
                headers: .init(xVaultToken: sessionToken)
            )

            switch response {
                case .noContent:
                    let eventName = "approle deleted"
                    span.attributes[TracingAttributes.responseStatusCode] = 204
                    span.addEvent(.init(name: eventName))
                    logger.trace(.init(stringLiteral: eventName))
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }

    /// Get AppRole ID
    /// - Parameter name: role name
    public func appRoleID(name: String) async throws -> AppRoleIDResponse {
        return try await withSpan(Operations.AuthReadRoleId.id, ofKind: .client) { span in
            guard let sessionToken = token else {
                let clientError = VaultClientError.clientIsNotLoggedIn()
               TracingSupport.handleResponse(error: clientError, span)
               throw clientError
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
                                let vaultRequestID = component.requestId
                                TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)
                                logger.trace(
                                    .init(stringLiteral: "read appRoleID"),
                                    metadata: [
                                    TracingAttributes.vaultRequestID: .string(vaultRequestID)
                                ])
                                return .init(requestID: component.requestId, roleID: component.data.roleId)
                            case .VaultWrappedResponse:
                                let clientError = VaultClientError.receivedUnexpectedResponse()
                                TracingSupport.handleResponse(error: clientError, span)
                                throw clientError
                        }
                    } else if let json = json.value2 {
                        logger.debug(.init(stringLiteral: "\(#function) Unknown body response: \(json.value.description)"))
                        let clientError = VaultClientError.receivedUnexpectedResponse()
                        TracingSupport.handleResponse(error: clientError, span)
                        throw clientError
                    } else {
                        preconditionFailure("Unreachable path \(#function)")
                    }
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }

    /// Get a wrapped AppRole ID
    /// - Parameter name: role name
    /// - Parameter wrapTimeToLive: duration of wrapping token
    public func wrapAppRoleID(
        name: String,
        wrapTimeToLive: Duration
    ) async throws -> WrappedTokenResponse {
        return try await withSpan("wrap-approle-id", ofKind: .client) { span in
            guard let sessionToken = token else {
                let clientError = VaultClientError.clientIsNotLoggedIn()
               TracingSupport.handleResponse(error: clientError, span)
               throw clientError
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
                                let clientError = VaultClientError.receivedUnexpectedResponse()
                                TracingSupport.handleResponse(error: clientError, span)
                                throw clientError
                            case .VaultWrappedResponse(let component):
                                let vaultRequestID = component.requestId
                                TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)
                                logger.trace(
                                    .init(stringLiteral: "wrapped appRoleID generated"),
                                    metadata: [
                                    TracingAttributes.vaultRequestID: .string(vaultRequestID)
                                ])
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
                        let clientError = VaultClientError.decodingFailed()
                        TracingSupport.handleResponse(error: clientError, span)
                        throw clientError
                    } else {
                        preconditionFailure("Unreachable path \(#function)")
                    }
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }

    /// Generate AppRole secretID
    /// - Parameter capabilities: the properties this generated secretID must have
    /// - Returns: Either a wrapped response token or the secretID
    public func generateAppSecretId(
        capabilities: AppRoleTokenGenerationConfig
    ) async throws -> AppRoleSecretIdResponse {
        return try await withSpan(Operations.AuthApproleSecretId.id, ofKind: .client) { span in
            guard let sessionToken = token else {
                let clientError = VaultClientError.clientIsNotLoggedIn()
               TracingSupport.handleResponse(error: clientError, span)
               throw clientError
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
                                let vaultRequestID = component.requestId
                                TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)
                                let eventName = "appRole secret ID generated"
                                span.addEvent(.init(name: eventName, attributes: .init(dictionaryLiteral: ("wrapped", "false"))))
                                logger.trace(
                                    .init(stringLiteral: eventName),
                                    metadata: [
                                    TracingAttributes.vaultRequestID: .string(vaultRequestID),
                                    "wrapped": .stringConvertible(false)
                                ])
                                return .secretId(.init(
                                    requestID: vaultRequestID,
                                    secretID: component.data.secretId,
                                    secretIDAccessor: component.data.secretIdAccessor,
                                    secretIDTimeToLive: .seconds(component.data.secretIdTtl),
                                    secretIDNumberOfUses: component.data.secretIdNumUses))
                            case .VaultWrappedResponse(let component):
                                let vaultRequestID = component.requestId
                                TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)
                                let eventName = "appRole secret ID generated"
                                span.addEvent(.init(name: eventName, attributes: .init(dictionaryLiteral: ("wrapped", "true"))))
                                logger.trace(
                                    .init(stringLiteral: eventName),
                                    metadata: [
                                    TracingAttributes.vaultRequestID: .string(vaultRequestID),
                                    "wrapped": .stringConvertible(true)
                                ])
                                return .wrapped(
                                    .init(
                                        requestID: vaultRequestID,
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
                        let clientError = VaultClientError.receivedUnexpectedResponse()
                        TracingSupport.handleResponse(error: clientError, span)
                        throw clientError
                    } else {
                        preconditionFailure("Unreachable path \(#function)")
                    }
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }

    /// Fetches the login session token and its information.
    ///
    /// if ``VaultCourier/AppRoleCreationConfig/bindSecretID`` is enabled (the default) on the AppRole, `secretID` is required too. Any other bound authentication values on the AppRole (such as client IP CIDR) are also evaluated.
    ///
    /// - Note: this method does not set the token session of the vault client. See the ``VaultCourier/VaultClient/login(method:)`` which initiates login from the given authentication
    /// method and sets the session token of the client.
    /// - Parameters:
    ///   - roleID: RoleID of the AppRole
    ///   - secretID: SecretID belonging to AppRole
    /// - Returns: ``VaultAuthResponse``
    public func loginToken(
        roleID: String,
        secretID: String
    ) async throws -> VaultAuthResponse {
        return try await withSpan(Operations.AuthApproleLogin.id, ofKind: .client) { span in
            let mountPath = self.mountPath

            let response = try await auth.client.authApproleLogin(
                path: .init(enginePath: mountPath),
                body: .json(.init(roleId: roleID, secretId: secretID))
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json
                    guard let tokenType = TokenType(rawValue: json.auth.tokenType.rawValue) else {
                        let clientError = VaultClientError.receivedUnexpectedResponse("unexpected token type: \(String(describing: json.auth.tokenType))")
                        TracingSupport.handleResponse(error: clientError, span)
                        throw clientError
                    }

                    let vaultRequestID = json.requestId
                    TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)
                    let eventName = "login"
                    span.addEvent(.init(name: eventName, attributes: [TracingSupport.AttributeKeys.vaultAuthMethod: .string("approle")] ))
                    logger.trace(.init(stringLiteral: eventName), metadata: [TracingSupport.AttributeKeys.vaultAuthMethod: .string("approle")])

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
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }

    public func lookupSecretID(
        role: String,
        accessorSecretID: String
    ) async throws -> LookupAppRoleSecretIDResponse {
        return try await withSpan(Operations.AuthReadApproleSecretIdWithAccessor.id, ofKind: .client) { span in
            guard let sessionToken = token else {
                let clientError = VaultClientError.clientIsNotLoggedIn()
               TracingSupport.handleResponse(error: clientError, span)
               throw clientError
            }
            let mountPath = self.mountPath

            let response = try await auth.client.authReadApproleSecretIdWithAccessor(
                path: .init(enginePath: mountPath, roleName: role),
                headers: .init(xVaultToken: .init(sessionToken)),
                body: .json(.init(secretIdAccessor: accessorSecretID))
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json

                    let vaultRequestID = json.requestId
                    TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)
                    logger.trace(.init(stringLiteral: "lookup secretID"))

                    return .init(requestID: json.requestId,
                                 cidrList: json.data.cidrList ?? [],
                                 createdAt: json.data.creationTime,
                                 expiresAt: json.data.expirationTime,
                                 updatedAt: json.data.lastUpdatedTime,
                                 metadata: json.data.metadata?.additionalProperties ?? [:],
                                 secretIdAccessor: json.data.secretIdAccessor,
                                 secretIdTimeToLive: .seconds(json.data.secretIdTtl),
                                 secretIdNumberOfUses: json.data.secretIdNumUses,
                                 tokenBoundCIDRS: json.data.tokenBoundCidrs ?? [])

                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }

    public func destroySecretID(
        role: String,
        accessorSecretID: String
    ) async throws {
        return try await withSpan(Operations.AuthDestroyApproleSecretIdWithAccessor.id, ofKind: .client) { span in
            guard let sessionToken = token else {
                let clientError = VaultClientError.clientIsNotLoggedIn()
               TracingSupport.handleResponse(error: clientError, span)
               throw clientError
            }
            let mountPath = self.mountPath

            let response = try await auth.client.authDestroyApproleSecretIdWithAccessor(
                path: .init(enginePath: mountPath, roleName: role),
                headers: .init(xVaultToken: .init(sessionToken)),
                body: .json(.init(secretIdAccessor: accessorSecretID))
            )

            switch response {
                case .noContent:
                    let eventName = "approle secretID destroyed"
                    span.attributes[TracingAttributes.responseStatusCode] = 204
                    span.addEvent(.init(name: eventName))
                    logger.trace(.init(stringLiteral: eventName))
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }
}
#endif
