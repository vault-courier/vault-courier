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
}
