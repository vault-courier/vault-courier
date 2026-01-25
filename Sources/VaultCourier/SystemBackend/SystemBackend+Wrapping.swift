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

#if canImport(FoundationEssentials)
import FoundationEssentials
import FoundationInternationalization
#else
import class Foundation.JSONDecoder
import class Foundation.JSONEncoder
import struct Foundation.Data
#endif
import OpenAPIRuntime
import SystemWrapping
import Logging
import Tracing
import Utils

extension SystemBackend {
    /// Unwraps a vault wrapped response
    ///
    /// - Parameter token: Wrapping token ID. This is required if the client token is not the wrapping token. Do not use the same wrapping token in this parameter and in the client token.
    /// - Returns: Returns the original response inside the given wrapping token
    public func unwrapResponse<
        VaultData: Decodable & Sendable,
        AuthResponse: Decodable & Sendable
    >(
        token: String?
    ) async throws -> VaultResponse<VaultData, AuthResponse> {
        return try await withSpan(Operations.Unwrap.id, ofKind: .client) { span in
            let sessionToken = wrapping.token
            guard sessionToken != token else {
                let clientError = VaultClientError.invalidArgument("Wrapping parameter token and client token cannot be the same")
                TracingSupport.handleResponse(error: clientError, span)
                throw clientError
            }

            let response = try await wrapping.client.unwrap(
                .init(headers: .init(xVaultToken: sessionToken),
                      body: .json(.init(token: token)))
            )
            switch response {
                case .ok(let content):
                    let json = try content.body.json
                    var vaultData: VaultData? = nil
                    var auth: AuthResponse? = nil
                    if VaultData.self != Never.self {
                        let data = try JSONEncoder().encode(json.data)
                        vaultData = try JSONDecoder().decode(VaultData.self, from: data)
                    }
                    if AuthResponse.self != Never.self {
                        let authData = try JSONEncoder().encode(json.auth)
                        auth = try JSONDecoder().decode(AuthResponse.self, from: authData)
                    }

                    let vaultRequestID = json.requestId
                    TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)
                    logger.trace(
                        .init(stringLiteral: "response unwrapped"),
                        metadata: [
                            TracingSupport.AttributeKeys.vaultRequestID: .string(vaultRequestID),
                    ])
                    return VaultResponse(requestID: vaultRequestID, data: vaultData, auth: auth)
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }

    /// Wraps the given dictionary of secrets in a response-wrapped token
    /// - Parameters:
    ///   - secrets: dictionary of secrets
    ///   - wrapTimeToLive: the duration of validity of the response-wrapped token
    /// - Returns: A response-wrapped token
    public func wrap(
        secrets: [String: String],
        wrapTimeToLive: Duration
    ) async throws -> WrappedTokenResponse {
        return try await withSpan(Operations.Wrap.id, ofKind: .client) { span in
            guard let sessionToken = wrapping.token else {
                let clientError = VaultClientError.clientIsNotLoggedIn()
                TracingSupport.handleResponse(error: clientError, span)
                throw clientError
            }

            let response = try await wrapping.client.wrap(
                .init(
                    headers: .init(
                        xVaultToken: .init(sessionToken),
                        xVaultWrapTTL: .init(wrapTimeToLive.formatted(.vaultSeconds))
                    ),
                    body: .json(.init(unvalidatedValue: secrets))
                )
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json
                    let vaultRequestID = json.requestId
                    TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)
                    logger.trace(
                        .init(stringLiteral: "secrets wrapped"),
                        metadata: [
                            TracingSupport.AttributeKeys.vaultRequestID: .string(vaultRequestID),
                    ])
                    return .init(
                        requestID: vaultRequestID,
                        token: json.wrapInfo.token,
                        accessor: json.wrapInfo.accessor,
                        timeToLive: json.wrapInfo.ttl,
                        createdAt: json.wrapInfo.creationTime,
                        creationPath: json.wrapInfo.creationPath,
                        wrappedAccessor: json.wrapInfo.wrappedAccessor
                    )
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }
    
    /// Rewraps a response-wrapped token
    ///
    ///  Rewraps an existing response-wrapped token. The newly generated token inherits the original token's creation TTL and preserves the same response data. Once rewrapped, the old token is invalidated.
    ///  This mechanism is useful for securely storing secrets in response-wrapped tokens when periodic rotation is required.
    ///
    /// - Parameter token: response-wrapped token
    /// - Returns: A response wrapped token with a new ID, but with the same time to live
    public func rewrap(
        token: String
    ) async throws -> WrappedTokenResponse {
        return try await withSpan(Operations.Rewrap.id, ofKind: .client) { span in
            guard let sessionToken = wrapping.token else {
                let clientError = VaultClientError.clientIsNotLoggedIn()
                TracingSupport.handleResponse(error: clientError, span)
                throw clientError
            }

            let response = try await wrapping.client.rewrap(
                .init(
                    headers: .init(
                        xVaultToken: .init(sessionToken)
                    ),
                    body: .json(.init(token: token))
                )
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json

                    let vaultRequestID = json.requestId
                    TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)
                    logger.trace(
                        .init(stringLiteral: "rewrap token"),
                        metadata: [
                            TracingSupport.AttributeKeys.vaultRequestID: .string(vaultRequestID),
                    ])
                    return .init(
                        requestID: vaultRequestID,
                        token: json.wrapInfo.token,
                        accessor: json.wrapInfo.accessor,
                        timeToLive: json.wrapInfo.ttl,
                        createdAt: json.wrapInfo.creationTime,
                        creationPath: json.wrapInfo.creationPath,
                        wrappedAccessor: json.wrapInfo.wrappedAccessor
                    )
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }

    
    /// Looks up wrapping token properties
    /// - Parameter token: wrapping token ID
    /// - Returns: properties of wrapping token
    public func lookupWrapping(token: String) async throws -> WrappedTokenInfo {
        return try await withSpan(Operations.Lookup.id, ofKind: .client) { span in
            guard let sessionToken = wrapping.token else {
                let clientError = VaultClientError.clientIsNotLoggedIn()
                TracingSupport.handleResponse(error: clientError, span)
                throw clientError
            }

            let response = try await wrapping.client.lookup(
                headers: .init(
                    xVaultToken: .init(sessionToken)
                ),
                body: .json(.init(token: token))
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json

                    let vaultRequestID = json.requestId
                    TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)
                    logger.trace(
                        .init(stringLiteral: "lookup wrapped token info"),
                        metadata: [
                            TracingSupport.AttributeKeys.vaultRequestID: .string(vaultRequestID),
                    ])

                    return .init(
                        requestID: vaultRequestID,
                        timeToLive: json.data.creationTtl,
                        createdAt: json.data.creationTime,
                        creationPath: json.data.creationPath
                    )
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }
}

#if AppRoleSupport
extension SystemBackend {
    public func unwrapAppRoleSecretID(
        token: String
    ) async throws -> GenerateAppSecretIdResponse {
        return try await withSpan("unwrap-approle-secret-id", ofKind: .client) { span in
            let response: VaultResponse<AppRoleSecretID, Never> = try await unwrapResponse(token: token)
            guard let data = response.data else {
                let clientError = VaultClientError.receivedUnexpectedResponse("Unwrap response did not contain any data")
                TracingSupport.handleResponse(error: clientError, span)
                throw clientError
            }
            return .init(requestID: response.requestID,
                         secretID: data.secretID,
                         secretIDAccessor: data.secretIDAccessor,
                         secretIDTimeToLive: .seconds(data.secretIDTimeToLive),
                         secretIDNumberOfUses: data.secretIDNumberOfUses)
        }
    }
}
#endif
