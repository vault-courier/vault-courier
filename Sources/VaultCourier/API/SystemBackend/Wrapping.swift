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
        let sessionToken = try? sessionToken()
        return try await withSystemBackend { systemBackend in
            let response: VaultResponse<VaultData, Auth> = try await systemBackend.unwrapResponse(token: sessionToken)
            return response
        }
    }
}
