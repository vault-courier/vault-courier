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
#else
import class Foundation.JSONDecoder
import class Foundation.JSONEncoder
import struct Foundation.Data
#endif
import OpenAPIRuntime

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
        let sessionToken = wrapping.token
        guard sessionToken != token else {
            throw VaultClientError.badRequest(["Wrapping parameter token and client token cannot be the same"])
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
                return VaultResponse(requestID: json.requestId, data: vaultData, auth: auth)
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                throw VaultClientError.badRequest(errors)
            case .undocumented(let statusCode, _):
                throw VaultClientError.operationFailed(statusCode)
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
        guard let sessionToken = wrapping.token else {
            throw VaultClientError.clientIsNotLoggedIn()
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
                return .init(
                    requestID: json.requestId,
                    token: json.wrapInfo.token,
                    accessor: json.wrapInfo.accessor,
                    timeToLive: json.wrapInfo.ttl,
                    createdAt: json.wrapInfo.creationTime,
                    creationPath: json.wrapInfo.creationPath,
                    wrappedAccessor: json.wrapInfo.wrappedAccessor
                )
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .undocumented(statusCode: let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode)"))
                throw VaultClientError.operationFailed(statusCode)
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
        guard let sessionToken = wrapping.token else {
            throw VaultClientError.clientIsNotLoggedIn()
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
                return .init(
                    requestID: json.requestId,
                    token: json.wrapInfo.token,
                    accessor: json.wrapInfo.accessor,
                    timeToLive: json.wrapInfo.ttl,
                    createdAt: json.wrapInfo.creationTime,
                    creationPath: json.wrapInfo.creationPath,
                    wrappedAccessor: json.wrapInfo.wrappedAccessor
                )
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .undocumented(statusCode: let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode)"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }
}
