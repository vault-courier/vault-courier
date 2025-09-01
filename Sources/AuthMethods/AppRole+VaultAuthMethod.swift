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

import AppRoleAuth
import VaultUtilities

extension AppRoleAuth: VaultAuthMethod {
    /// Authenticate with Vault
    /// - Returns: session token
    public func authenticate() async throws -> String {
        let appRolePath = basePath.relativePath.removeSlash()

        guard let credentials else {
            throw AppRoleError.missingCredentials()
        }

        let response = try await client.authApproleLogin(
            path: .init(enginePath: appRolePath),
            body: .json(.init(roleId: credentials.roleID, secretId: credentials.secretID))
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                return json.auth.clientToken
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                throw AppRoleError.badRequest(errors)
            case .undocumented(statusCode: let statusCode, _):
                throw AppRoleError.operationFailed(statusCode)
        }
    }
}

extension AppRoleMock: VaultAuthMethod {
    public func authenticate() async throws -> String {
        let response = try await authApproleLogin(
            path: .init(enginePath: appRolePath),
            body: .json(.init(roleId: credentials.roleID, secretId: credentials.secretID))
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                return json.auth.clientToken
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                throw AppRoleError.badRequest(errors)
            case .undocumented(statusCode: let statusCode, _):
                throw AppRoleError.operationFailed(statusCode)
        }
    }
}
