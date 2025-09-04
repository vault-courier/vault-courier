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
import struct Foundation.URL
#endif
import OpenAPIRuntime
import VaultUtilities

extension SystemBackend {
    
    /// Enables secret engine
    /// - Parameter mountConfig: mount configuration including path of secret engine
    public func enableSecretEngine(
        mountConfig: EnableSecretMountConfig
    ) async throws {
        let sessionToken = mounts.token

        let configuration = try mountConfig.config.flatMap(OpenAPIObjectContainer.init(unvalidatedValue:))
        let options = try mountConfig.options.flatMap(OpenAPIObjectContainer.init(unvalidatedValue:))

        let response = try await mounts.client.mountsEnableSecretsEngine(.init(
            path: .init(path: mountConfig.path),
            headers: .init(xVaultToken: sessionToken),
            body: .json(.init(
                config: configuration,
                externalEntropyAccess: mountConfig.externalEntropyAccess,
                local: mountConfig.local,
                options: options,
                sealWrap: mountConfig.sealWrap,
                _type: mountConfig.mountType)
            ))
        )

        switch response {
            case .noContent:
                logger.info("'\(mountConfig.mountType)' secret engine enabled.")
                return
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .undocumented(let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }
    
    /// Get configuration for secret engine
    /// - Parameter path: mount path of secret engine
    public func readSecretEngineConfig(path: String) async throws -> SecretEngineConfigResponse {
        let sessionToken = mounts.token

        let response = try await mounts.client.mountsReadSecretsEngine(.init(
            path: .init(path: path),
            headers: .init(xVaultToken: sessionToken))
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json

                let config: MountConfig?
                if let value = json.data.config?.value1 {
                    switch value {
                        case .case1(let configBody):
                            config = .init(forceNoCache: configBody.forceNoCache,
                                           defaultLeaseTimeToLive: configBody.defaultLeaseTtl,
                                           maxLeaseTimeToLive: configBody.maxLeaseTtl)
                        case .case2(let dictionary):
                            logger.debug(.init(stringLiteral: "\(#function) Unknown body response: \(dictionary)"))
                            throw VaultClientError.decodingFailed()
                    }
                } else if let value = json.data.config?.value2 {
                    logger.debug(.init(stringLiteral: "\(#function) Unknown body response: \(value.value.description)"))
                    throw VaultClientError.decodingFailed()
                } else {
                    preconditionFailure("Unreachable path \(#function)")
                }

                let pluginVersion: String? = if let version = json.data.pluginVersion, !version.isEmpty {
                    version
                } else if let runningVersion = json.data.runningPluginVersion {
                    runningVersion
                } else {
                    nil
                }
                return .init(
                    requestID: json.requestId,
                    accessor: json.data.accessor,
                    config: config!,
                    description: json.data.description,
                    engineType: json.data._type,
                    options: json.data.options?.value.compactMapValues({ $0 as? String }),
                    pluginVersion: pluginVersion,
                    isLocal: json.data.local,
                    sealWrap: json.data.sealWrap,
                    externalEntropyAccess: json.data.externalEntropyAccess
                )
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .undocumented(let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }
    
    /// Disables secret engine
    /// - Parameter path: mount path to secret engine
    public func disableSecretEngine(path: String) async throws {
        let sessionToken = mounts.token

        let response = try await mounts.client.mountsDisableSecretsEngine(.init(
            path: .init(path: path),
            headers: .init(xVaultToken: sessionToken))
        )

        switch response {
            case .noContent:
                logger.info("secret engine at path '\(path)' disabled.")
                return
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
