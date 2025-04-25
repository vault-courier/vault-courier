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
import class Foundation.JSONDecoder
import class Foundation.JSONEncoder
import struct Foundation.Data
import protocol Foundation.LocalizedError
#endif

extension VaultClient {
    public func databaseCredentials(
        staticRole: String,
        enginePath: String? = nil
    ) async throws -> StaticRoleCredentialsResponse? {
        let enginePath = enginePath ?? self.mounts.database.relativePath.removeSlash()
        let sessionToken = try sessionToken()

        let response = try await client.databaseReadStaticRoleCredentials(
            path: .init(enginePath: enginePath, roleName: staticRole),
            headers: .init(xVaultToken: sessionToken))

        switch response {
            case .ok(let content):
                let json = try content.body.json
                return StaticRoleCredentialsResponse(component: json)
            case .badRequest(let content):
                guard let body = try? content.body.json, let errors = body.errors else {
                    logger.debug("Bad request.")
                    return nil
                }
                logger.debug("Bad request: \(errors).")
            case .internalServerError(let content):
                guard let body = try? content.body.json, let errors = body.errors else {
                    logger.debug("Internal Server error")
                    return nil
                }
                logger.debug("Internal server error: \(errors.joined()).")
            case .undocumented(let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode)"))
        }

        return nil
    }

    public func databaseCredentials(
        dynamicRole: String,
        enginePath: String? = nil
    ) async throws -> RoleCredentialsResponse? {
        let enginePath = enginePath ?? self.mounts.database.relativePath.removeSlash()
        let sessionToken = try sessionToken()

        let response = try await client.databaseReadRoleCredentials(
            path: .init(enginePath: enginePath, roleName: dynamicRole),
            headers: .init(xVaultToken: sessionToken))

        switch response {
            case .ok(let content):
                let json = try content.body.json
                return RoleCredentialsResponse(component: json)
            case .badRequest(let content):
                guard let body = try? content.body.json, let errors = body.errors else {
                    logger.debug("Bad request.")
                    return nil
                }
                logger.debug("Bad request: \(errors).")
            case .internalServerError(let content):
                guard let body = try? content.body.json, let errors = body.errors else {
                    logger.debug("Internal Server error")
                    return nil
                }
                logger.debug("Internal server error: \(errors.joined()).")
            case .undocumented(let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode)"))
        }

        return nil
    }
}
