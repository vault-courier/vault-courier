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
import SystemMounts
import Logging
import Tracing
import Utils

extension SystemBackend {
    
    /// Enables secret engine
    /// - Parameter mountConfig: mount configuration including path of secret engine
    public func enableSecretEngine(
        mountConfig: EnableSecretMountConfig
    ) async throws {
        return try await withSpan(Operations.MountsEnableSecretsEngine.id, ofKind: .client) { span in
            let sessionToken = mounts.token

            let configuration = try mountConfig.config.flatMap(OpenAPIObjectContainer.init(unvalidatedValue:))
            let options = try mountConfig.options.flatMap(OpenAPIObjectContainer.init(unvalidatedValue:))

            let response = try await mounts.client.mountsEnableSecretsEngine(.init(
                path: .init(path: mountConfig.path),
                headers: .init(xVaultToken: sessionToken),
                body: .json(.init(
                    config: configuration,
                    externalEntropyAccess: mountConfig.externalEntropyAccess,
                    local: mountConfig.isLocal,
                    options: options,
                    sealWrap: mountConfig.sealWrap,
                    _type: mountConfig.mountType)
                ))
            )

            switch response {
                case .noContent:
                    let eventName = "secret engine enabled"
                    span.attributes[TracingSupport.AttributeKeys.responseStatusCode] = 204
                    span.addEvent(.init(name: eventName, attributes: ["mountType": .string(mountConfig.mountType)]))
                    logger.trace(.init(stringLiteral: eventName), metadata: ["mountType": .string(mountConfig.mountType)])
                    return
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }
    
    /// Get configuration for secret engine
    /// - Parameter path: mount path of secret engine
    public func readSecretEngineConfig(path: String) async throws -> SecretEngineConfigResponse {
        return try await withSpan(Operations.MountsReadSecretsEngine.id, ofKind: .client) { span in
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
                                let clientError = VaultClientError.decodingFailed()
                                TracingSupport.handleResponse(error: clientError, span)
                                throw clientError
                        }
                    } else if let value = json.data.config?.value2 {
                        logger.debug(.init(stringLiteral: "\(#function) Unknown body response: \(value.value.description)"))
                        let clientError = VaultClientError.decodingFailed()
                        TracingSupport.handleResponse(error: clientError, span)
                        throw clientError
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

                    let vaultRequestID = json.requestId
                    TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)
                    logger.trace(
                        .init(stringLiteral: "read secret engine configuration"),
                        metadata: [
                            TracingSupport.AttributeKeys.vaultRequestID: .string(vaultRequestID),
                    ])

                    return .init(
                        requestID: vaultRequestID,
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
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }
    
    /// Disables secret engine
    /// - Parameter path: mount path to secret engine
    public func disableSecretEngine(path: String) async throws {
        return try await withSpan(Operations.MountsDisableSecretsEngine.id, ofKind: .client) { span in
            let sessionToken = mounts.token

            let response = try await mounts.client.mountsDisableSecretsEngine(.init(
                path: .init(path: path),
                headers: .init(xVaultToken: sessionToken))
            )

            switch response {
                case .noContent:
                    let eventName = "secret engine disabled."
                    span.attributes[TracingSupport.AttributeKeys.responseStatusCode] = 204
                    span.addEvent(.init(name: eventName, attributes: ["path": .string(path)]))
                    logger.trace(.init(stringLiteral: eventName), metadata: ["path": .string(path)])
                    return
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }
}
