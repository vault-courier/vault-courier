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
    /// Enables authentication mount. Example AppRole, GitHub, Token...
    public func enableAuthMethod(configuration: EnableAuthMethodConfig) async throws {
        let sessionToken = try sessionToken()

        let requestConfig = try configuration.config.flatMap(OpenAPIObjectContainer.init(unvalidatedValue:))
        let requestOptions = try configuration.options.flatMap(OpenAPIObjectContainer.init(unvalidatedValue:))

        let response = try await client.authEnableMethod(.init(
            path: .init(path: configuration.path),
            headers: .init(xVaultToken: sessionToken),
            body: .json(.init(
                config: requestConfig,
                local: configuration.local,
                options: requestOptions,
                sealWrap: configuration.sealWrap,
                _type: configuration.type)))
        )

        switch response {
            case .noContent:
                logger.info("\(configuration.type) authentication method enabled")
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .undocumented(let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }

    public func readAuthMethodConfiguration(_ path: String) async throws -> ReadAuthMethodResponse {
        let sessionToken = try sessionToken()

        let response = try await client.authReadMethod(
            path: .init(path: path),
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                return .init(component: json)
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .undocumented(let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }

    public func disableAuthMethod(_ path: String) async throws {
        let sessionToken = try sessionToken()

        let response = try await client.authDisableMethod(
            path: .init(path: path),
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .noContent:
                logger.info("Authentication method disabled successfully.")
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .undocumented(let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }

    public func createAppRole(_ appRole: CreateAppRole) async throws {
        let sessionToken = try sessionToken()
        let mountPath = self.mounts.appRole.relativePath.removeSlash()

        let response = try await client.authCreateApprole(
            path: .init(enginePath: mountPath, roleName: appRole.name),
            headers: .init(xVaultToken: sessionToken),
            body: .json(.init(
                bindSecretId: appRole.bindSecretId,
                secretIdBoundCidrs: appRole.secretIdBoundCIDRS,
                secretIdNumUses: appRole.secretIdNumberOfUses,
                secretIdTtl: appRole.secretIdTTL?.formatted(.vaultSeconds),
                localSecretIds: appRole.localSecretIds,
                tokenTtl: appRole.tokenTTL?.formatted(.vaultSeconds),
                tokenMaxTtl: appRole.tokenMaxTTL?.formatted(.vaultSeconds),
                tokenPolicies: appRole.tokenPolicies,
                tokenBoundCidrs: appRole.tokenBoundCIDRS,
                tokenNoDefaultPolicy: appRole.tokenNoDefaultPolicy,
                tokenNumUses: appRole.tokenNumberOfUses,
                tokenPeriod: appRole.tokenPeriod?.formatted(.vaultSeconds),
                tokenType: appRole.tokenType.rawValue))
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
                let role = ReadAppRoleResponse(component: json)
                return role
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .undocumented(let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }

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

    public func appRoleId(name: String) async throws -> AppRoleIdResponse {
        let sessionToken = try sessionToken()
        let mountPath = self.mounts.appRole.relativePath.removeSlash()

        let response = try await client.authReadRoleId(
            path: .init(enginePath: mountPath, roleName: name),
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                return AppRoleIdResponse(component: json)
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .undocumented(let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }

    public func generateAppSecretId(
        capabilities: GenerateAppRoleToken
    ) async throws -> AppRoleSecretIdResponse {
        let sessionToken = try sessionToken()
        let appRolePath = self.mounts.appRole.relativePath.removeSlash()

        let headers: Operations.AuthApproleSecretId.Input.Headers = if let wrapTTL = capabilities.wrapTTL {
            .init(xVaultToken: sessionToken, xVaultWrapTTL: wrapTTL)
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
                ttl: capabilities.tokenTTL))
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                if let json = json.value1 {
                    switch json {
                        case .GenerateAppRoleSecretIdResponse(let component):
                            return .secretId(.init(component: component))
                        case .WrapAppRoleSecretIdResponse(let component):
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
}
