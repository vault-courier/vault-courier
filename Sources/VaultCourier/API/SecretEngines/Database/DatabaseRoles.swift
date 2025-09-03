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

import VaultUtilities

extension VaultClient {
    public func create(
        staticRole: CreateDatabaseStaticRole,
        enginePath: String
    ) async throws {
        let sessionToken = try sessionToken()

        let rotationPeriod: String?
        let rotationSchedule: String?
        let rotationWindow: String?
        switch staticRole.rotation {
            case .period(let period):
                rotationPeriod = period.formatted(.vaultSeconds)
                rotationSchedule = nil
                rotationWindow = nil
            case .scheduled(let scheduled):
                rotationPeriod = nil
                rotationSchedule = scheduled.schedule
                rotationWindow = scheduled.window?.formatted(.vaultSeconds)
        }

        let response = try await client.databaseCreateStaticRole(
            .init(
                path: .init(enginePath: enginePath, roleName: staticRole.vaultRoleName),
                headers: .init(xVaultToken: sessionToken),
                body: .json(.init(username: staticRole.databaseUsername,
                                  dbName: staticRole.databaseConnectionName,
                                  rotationPeriod: rotationPeriod,
                                  rotationSchedule: rotationSchedule,
                                  rotationWindow: rotationWindow,
                                  rotationStatements: staticRole.rotationStatements,
                                  credentialType: staticRole.credentialType.rawValue,
                                  credentialConfig: .init(unvalidatedValue: staticRole.credentialConfig ?? [:]))))
        )

        switch response {
            case .ok , .noContent:
                logger.info("Database static role written")
                return
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .internalServerError(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Internal server error: \(errors.joined(separator: ", ")).")
                throw VaultClientError.internalServerError(errors)
            case .undocumented(let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode)"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }

    public func deleteStaticRole(
        name: String,
        enginePath: String
    ) async throws {
        let sessionToken = try sessionToken()

        let response = try await client.databaseDeleteStaticRole(
            path: .init(enginePath: enginePath, roleName: name),
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .noContent:
                logger.info("Database static role \(name) deleted")
                return
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .internalServerError(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Internal server error: \(errors.joined(separator: ", ")).")
                throw VaultClientError.internalServerError(errors)
            case .undocumented(let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode)"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }

    public func create(
        dynamicRole: CreateDatabaseRole,
        enginePath: String
    ) async throws {
        let sessionToken = try sessionToken()

        let response = try await client.databaseCreateRole(
            .init(
                path: .init(enginePath: enginePath, roleName: dynamicRole.vaultRoleName),
                headers: .init(xVaultToken: sessionToken),
                body: .json(.init(
                    dbName: dynamicRole.databaseConnectionName,
                    defaultTtl: dynamicRole.defaultTTL?.formatted(.vaultSeconds),
                    maxTtl: dynamicRole.maxTTL?.formatted(.vaultSeconds),
                    creationStatements: dynamicRole.creationStatements,
                    revocationStatements: dynamicRole.revocationStatements,
                    rollbackStatements: dynamicRole.rollbackStatements,
                    renewStatements: dynamicRole.renewStatements,
                    rotationStatements: dynamicRole.rotationStatements,
                    credentialType: dynamicRole.credentialType.rawValue,
                    credentialConfig: .init(unvalidatedValue: dynamicRole.credentialConfig ?? [:]))))
        )

        switch response {
            case .noContent:
                logger.info("Database dynamic role written")
                return
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .internalServerError(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Internal server error: \(errors.joined(separator: ", ")).")
                throw VaultClientError.internalServerError(errors)
            case .undocumented(let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode)"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }

    public func deleteRole(
        name: String,
        enginePath: String
    ) async throws {
        let sessionToken = try sessionToken()

        let response = try await client.databaseDeleteRole(
            path: .init(enginePath: enginePath, roleName: name),
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .noContent:
                logger.info("Database static role \(name) deleted")
                return
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .internalServerError(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Internal server error: \(errors.joined(separator: ", ")).")
                throw VaultClientError.internalServerError(errors)
            case .undocumented(let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode)"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }
}
