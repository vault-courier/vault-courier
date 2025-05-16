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

    /// This endpoints returns the configuration of the auth method
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

    /// Disables authentication method at given path
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
}
