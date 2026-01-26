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

import TokenAuth
import Tracing
import Utils

extension TokenAuth: VaultAuthMethod {
    /// Authenticate with Vault
    /// - Returns: session token
    public func authenticate() async throws -> String {
        try await withSpan("authenticate", ofKind: .client) { span in
            guard let token else {
                let clientError = VaultClientError(message: "Token has not been set in Token Authenticator")
                TracingSupport.handleResponse(error: clientError, span)
                throw clientError
            }

            let response = try await self.client.lookupTokenSelf(
                headers: .init(xVaultToken: token)
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json

                    TracingSupport.handleVaultResponse(requestID: json.requestId, span, 200)
                    span.addEvent(
                        .init(
                            name: "lookup login token",
                            attributes: [
                                TracingSupport.AttributeKeys.vaultAuthMethod: .string("token"),
                                "vault.token.display_name" : .string(json.data.displayName)
                            ]
                        )
                    )
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }

            return token
        }
    }
}
