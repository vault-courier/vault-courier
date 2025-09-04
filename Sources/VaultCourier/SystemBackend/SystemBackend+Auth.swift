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
import OpenAPIRuntime
import VaultUtilities

extension SystemBackend {
    /// Enables authentication mount. Example AppRole, Token...
    /// - Parameter configuration: Authentication method configuration
    public func enableAuthMethod(configuration: EnableAuthMethodConfig) async throws {
        let sessionToken = auth.token

        let requestConfig = try configuration.config.flatMap(OpenAPIObjectContainer.init(unvalidatedValue:))
        let requestOptions = try configuration.options.flatMap(OpenAPIObjectContainer.init(unvalidatedValue:))

        let response = try await auth.client.authEnableMethod(.init(
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


    /// This endpoints returns the configuration of the auth method
    /// - Parameter path: mount path of authentication method
    /// - Returns: Configuration of Authentication Method
    public func readAuthMethodConfiguration(_ path: String) async throws -> ReadAuthMethodResponse {
        let sessionToken = auth.token

        let response = try await auth.client.authReadMethod(
            path: .init(path: path),
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                let rawConfig = json.data.config.value
                let config: AuthMethodConfig?
                if let rawTokenType = rawConfig["token_type"] as? String,
                    let tokenType = TokenType(rawValue: rawTokenType) {
                    config = .init(tokenType: tokenType,
                                        defaultLeaseTimeToLive: (rawConfig["default_lease_ttl"] as? Int) ?? 0,
                                        maxLeaseTimeToLive: (rawConfig["max_lease_ttl"] as? Int) ?? 0)
                } else {
                    config = nil
                }

                return .init(
                    requestID: json.requestId ?? "",
                    authMethod: json.data._type,
                    isLocal: json.data.local,
                    sealWrap: json.data.sealWrap,
                    config: config,
                    description: json.data.description,
                    options: json.data.options.flatMap({$0.value as? [String : String]}),
                    externalEntropyAccess: json.data.externalEntropyAccess,
                    accessor: json.data.accessor,
                    mountType: json.mountType)
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .undocumented(let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }

    /// Disables authentication method at given path
    /// - Parameter path: mount path of authentication method
    public func disableAuthMethod(_ path: String) async throws {
        let sessionToken = auth.token

        let response = try await auth.client.authDisableMethod(
            path: .init(path: path),
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .noContent:
                logger.info("Authentication method disabled successfully on path: \(path).")
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
