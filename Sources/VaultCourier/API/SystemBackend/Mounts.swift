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

import struct OpenAPIRuntime.OpenAPIObjectContainer

extension VaultClient {
    public func enableSecretEngine(
        mountConfig: EnableSecretMountConfig
    ) async throws {
        let sessionToken = try sessionToken()

        let configuration = try mountConfig.config.flatMap(OpenAPIObjectContainer.init(unvalidatedValue:))
        let options = try mountConfig.options.flatMap(OpenAPIObjectContainer.init(unvalidatedValue:))
        
        let response = try await client.mountsEnableSecretsEngine(
            path: .init(path: mountConfig.path),
            headers: .init(xVaultToken: sessionToken),
            body: .json(.init(
                config: configuration,
                externalEntropyAccess: mountConfig.externalEntropyAccess,
                local: mountConfig.local,
                options: options,
                sealWrap: mountConfig.sealWrap,
                _type: mountConfig.mountType)
            )
        )
        
        switch response {
            case .noContent:
                logger.info("\(mountConfig.mountType) engine enabled.")
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
