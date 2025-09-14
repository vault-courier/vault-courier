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

import VaultUtilities

extension VaultClient {
    /// Unwraps a vault wrapped response
    ///
    /// - Parameter token: Wrapping token ID. This is required if the client token is not the wrapping token. Do not use the same wrapping token in this parameter and in the client token.
    /// - Returns: Returns the original response inside the given wrapping token
    public func unwrapResponse<
        VaultData: Decodable & Sendable,
        Auth: Decodable & Sendable
    >(
        token: String?
    ) async throws -> VaultResponse<VaultData, Auth> {
        return try await withSystemBackend { systemBackend in
            let response: VaultResponse<VaultData, Auth> = try await systemBackend.unwrapResponse(token: token)
            return response
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
        try await withSystemBackend { systemBackend in
            try await systemBackend.wrap(secrets: secrets, wrapTimeToLive: wrapTimeToLive)
        }
    }

    /// Rewraps a response-wrapped token
    ///
    ///  Rewraps an existing response-wrapped token. The newly generated token inherits the original token's creation TTL and preserves the same response data. Once rewrapped, the old token is invalidated.
    ///  This mechanism is useful for securely storing secrets in response-wrapped tokens when periodic rotation is required.
    ///
    /// - Parameter token: response-wrapped token
    /// - Returns: A response-wrapped token with a new ID, but with the same time to live
    public func rewrap(
        token: String
    ) async throws -> WrappedTokenResponse {
        try await withSystemBackend { systemBackend in
            try await systemBackend.rewrap(token: token)
        }
    }

    /// Looks up wrapping token properties
    /// - Parameter token: wrapping token ID
    /// - Returns: properties of wrapping token
    public func lookupWrapping(
        token: String
    ) async throws -> WrappedTokenInfo {
        try await withSystemBackend { systemBackend in
            try await systemBackend.lookupWrapping(token: token)
        }
    }
}

#if AppRoleSupport
extension VaultClient {
    /// Unwraps an AppRole secretID response
    ///
    /// - Parameter token: Wrapping token ID
    /// - Returns: Returns the original AppRole secretID response
    public func unwrapAppRoleSecretID(
        token: String
    ) async throws -> GenerateAppSecretIdResponse {
        return try await withSystemBackend { systemBackend in
            try await systemBackend.unwrapAppRoleSecretID(token: token)
        }
    }
}
#endif
