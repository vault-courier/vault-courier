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

import OpenAPIRuntime
#if canImport(FoundationEssentials)
import FoundationEssentials
import protocol Foundation.LocalizedError
#else
import struct Foundation.URL
import protocol Foundation.LocalizedError
#endif

extension VaultClient {
    /// Creates a new AppRole
    public func createAppRole(
        _ appRole: CreateAppRole
    ) async throws {
        let sessionToken = try sessionToken()
        let mountPath = self.mounts.appRole.relativePath.removeSlash()

        let response = try await client.authCreateApprole(
            path: .init(enginePath: mountPath, roleName: appRole.name),
            headers: .init(xVaultToken: sessionToken),
            body: .json(.init(
                tokenBoundCidrs: appRole.tokenBoundCIDRS,
                tokenExplicitMaxTtl: nil,
                tokenNoDefaultPolicy: appRole.tokenNoDefaultPolicy,
                tokenNumUses: appRole.tokenNumberOfUses,
                tokenPeriod: appRole.tokenPeriod?.formatted(.vaultSeconds),
                tokenType: .init(rawValue: appRole.tokenType.rawValue),
                tokenTtl: appRole.tokenTTL?.formatted(.vaultSeconds),
                tokenMaxTtl: appRole.tokenMaxTTL?.formatted(.vaultSeconds),
                tokenPolicies: appRole.tokenPolicies,
                bindSecretId: appRole.bindSecretId,
                secretIdBoundCidrs: appRole.secretIdBoundCIDRS,
                secretIdNumUses: appRole.secretIdNumberOfUses,
                secretIdTtl: appRole.secretIdTTL?.formatted(.vaultSeconds),
                localSecretIds: appRole.localSecretIds))
        )


        switch response {
            case .noContent:
                logger.info("approle \(appRole.name) created.")
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .undocumented(let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }

    /// Read AppRole
    /// - Parameter name: role name
    public func readAppRole(name: String) async throws -> ReadAppRoleResponse {
        let sessionToken = try sessionToken()
        let mountPath = self.mounts.appRole.relativePath.removeSlash()

        let response = try await client.authReadApprole(
            path: .init(enginePath: mountPath, roleName: name),
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                return try json.appRoleResponse
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .undocumented(let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }

    
    /// Delete existing AppRole
    /// - Parameter name: role name
    public func deleteAppRole(name: String) async throws {
        let sessionToken = try sessionToken()
        let mountPath = self.mounts.appRole.relativePath.removeSlash()

        let response = try await client.authDeleteApprole(
            path: .init(enginePath: mountPath, roleName: name),
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .noContent:
                logger.info("App role deleted successfully.")
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .undocumented(let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }

    
    /// Get AppRole ID
    /// - Parameter name: role name
    public func appRoleID(name: String) async throws -> AppRoleIDResponse {
        let sessionToken = try sessionToken()
        let mountPath = self.mounts.appRole.relativePath.removeSlash()

        let response = try await client.authReadRoleId(
            path: .init(enginePath: mountPath, roleName: name),
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                return AppRoleIDResponse(component: json)
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .undocumented(let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }

    
    /// Generate AppRole secretID
    /// - Parameter capabilities: the properties this generated secretID must have
    /// - Returns: Either a wrapped response token or the secretID
    public func generateAppSecretId(
        capabilities: GenerateAppRoleToken
    ) async throws -> AppRoleSecretIdResponse {
        let sessionToken = try sessionToken()
        let appRolePath = self.mounts.appRole.relativePath.removeSlash()

        let headers: Operations.AuthApproleSecretId.Input.Headers = if let wrapTTL = capabilities.wrapTTL {
            .init(xVaultToken: sessionToken, xVaultWrapTTL: wrapTTL.formatted(.vaultSeconds))
        } else {
            .init(xVaultToken: sessionToken)
        }

        let response = try await client.authApproleSecretId(
            path: .init(enginePath: appRolePath, roleName: capabilities.roleName),
            headers: headers,
            body: .json(.init(
                tokenBoundCidrs: capabilities.tokenBoundCIDRS,
                cidrList: capabilities.cidrList,
                metadata: capabilities.metadata,
                numUses: capabilities.tokenNumberOfUses,
                ttl: capabilities.tokenTTL?.formatted(.vaultSeconds)))
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                if let json = json.value1 {
                    switch json {
                        case .GenerateAppRoleSecretIdResponse(let component):
                            return .secretId(.init(component: component))
                        case .VaultWrappedResponse(let component):
                            return .wrapped(.init(component: component))
                    }
                } else if let json = json.value2 {
                    logger.debug(.init(stringLiteral: "\(#function) Unknown body response: \(json.value.description)"))
                    throw VaultClientError.decodingFailed()
                } else {
                    preconditionFailure("Unreachable path \(#function)")
                }
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .undocumented(let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }

    
    /// Fetches the login session token and its information.
    ///
    /// if ``bindSecretID`` is enabled (the default) on the AppRole, ``secretID`` is required too. Any other bound authentication values on the AppRole (such as client IP CIDR) are also evaluated.
    ///
    /// - Note: this method does not set the token session of the vault client. See the ``login()`` which initiates login from the given authentication
    /// method and sets the session token of the client.
    /// - Parameters:
    ///   - roleID: RoleID of the AppRole
    ///   - secretID: SecretID belonging to AppRole
    /// - Returns: ``VaultAuthResponse``
    public func loginToken(
        roleID: String,
        secretID: String
    ) async throws -> VaultAuthResponse {
        let appRolePath = mounts.appRole.relativePath.removeSlash()

        let response = try await client.authApproleLogin(
            path: .init(enginePath: appRolePath),
            body: .json(.init(roleId: roleID, secretId: secretID))
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                return try json.authResponse
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.permissionDenied()
            case .undocumented(statusCode: let statusCode, _):
                logger.debug(.init(stringLiteral: "login failed with \(statusCode): "))
                throw VaultClientError.permissionDenied()
        }
    }
}
