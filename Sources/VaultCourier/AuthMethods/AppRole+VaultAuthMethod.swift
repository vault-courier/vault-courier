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
import AppRoleAuth
import Tracing
import Utils
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.URL
#endif

extension AppRoleAuth: VaultAuthMethod {
    /// Authenticate with Vault
    /// - Returns: session token
    public func authenticate() async throws -> String {
        return try await withSpan(Operations.AuthApproleLogin.id, ofKind: .client) { span in
            let appRolePath = basePath.relativePath.removeSlash()

            guard let credentials else {
                let clientError = VaultClientError(message: "AppRole credentials have not been set")
                TracingSupport.handleResponse(error: clientError, span)
                throw clientError
            }

            let response = try await client.authApproleLogin(
                path: .init(enginePath: appRolePath),
                body: .json(.init(roleId: credentials.roleID, secretId: credentials.secretID))
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json

                    let vaultRequestID = json.requestId
                    span.attributes[TracingSupport.AttributeKeys.vaultRequestID] = vaultRequestID
                    span.attributes[TracingSupport.AttributeKeys.responseStatusCode] = 200
                    let eventName = "login"
                    span.addEvent(.init(name: eventName, attributes: [TracingSupport.AttributeKeys.vaultAuthMethod: .string("approle")] ))

                    return json.auth.clientToken
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }
}
#endif
