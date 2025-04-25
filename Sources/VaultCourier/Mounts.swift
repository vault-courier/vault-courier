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
    public func enableSecretEngine(
        mountConfig: EnableSecretMountConfig
    ) async throws {
        let sessionToken = try sessionToken()

        let configuration: OpenAPIRuntime.OpenAPIObjectContainer? = if let config = mountConfig.config {
            try .init(unvalidatedValue: config)
        } else {
            nil
        }
        
        let options: OpenAPIRuntime.OpenAPIObjectContainer? = if let options = mountConfig.options {
            try .init(unvalidatedValue: options)
        } else {
            nil
        }
        
        let response = try await client.mountsEnableSecretsEngine(
            path: .init(path: mountConfig.path),
            headers: .init(xVaultToken: sessionToken),
            body: .json(.init(
                config: configuration,
                externalEntropyAccess: mountConfig.externalEntropyAccess,
                local: mountConfig.local,
                options: options,
                sealWrap: mountConfig.sealWrap,
                _type: mountConfig.mountType))
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

    /// Creates a database conection between Vault and a Postgres Database
    public func databaseConnection(
        configuration: PostgresConnectionConfiguration,
        enginePath: String
        ) async throws {
            let sessionToken = try sessionToken()

        let response = try await client.configureDatabase(.init(
            path: .init(enginePath: enginePath, connectionName: configuration.connection),
            headers: .init(xVaultToken: sessionToken),
            body: .json(.init(pluginName: configuration.pluginName,
                              verifyConnection: configuration.verifyConnection,
                              allowedRoles: configuration.allowedRoles,
                              connectionUrl: configuration.connectionUrl,
                              maxOpenConnections: configuration.maxOpenConnections,
                              maxIdleConnections: configuration.maxIdleConnections,
                              maxConnectionLifetime: configuration.maxConnectionLifetime,
                              username: configuration.username,
                              password: configuration.password,
                              tlsCa: configuration.tlsCa,
                              tlsCertificate: configuration.tlsCertificate,
                              privateKey: configuration.privateKey,
                              usernameTemplate: configuration.usernameTemplate,
                              disableEscaping: configuration.disableEscaping,
                              passwordAuthentication: configuration.passwordAuthentication,
                              rootRotationStatements: configuration.rootRotationStatements)))
        )

        switch response {
            case .noContent:
                logger.info("Postgres database connection configured")
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .undocumented(let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }

    /// Deletes a database conection between Vault and a Postgres Database
    /// - Note: The roles in the database are not deleted
    public func deleteDatabaseConnection(
        _ connectionName: String,
        enginePath: String
    ) async throws {
        let sessionToken = try sessionToken()

        let response = try await client.deleteDatabaseConnection(.init(
            path: .init(enginePath: enginePath, connectionName: connectionName),
            headers: .init(xVaultToken: sessionToken))
        )

        switch response {
            case .noContent:
                logger.info("Postgres database connection deleted")
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .internalServerError(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Internal server error: \(errors.joined(separator: ", ")).")
                throw VaultClientError.internalServerError(errors)
            case .undocumented(let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
        }
    }

    /// Rotates Vault database password
    /// - Note: After this action only vault knows this user's password
    public func rotateRoot(
        connection: String,
        enginePath: String
    ) async throws {
        let sessionToken = try sessionToken()

        let response = try await client.databaseRotateRoot(
            path: .init(enginePath: enginePath, connectionName: connection),
            headers: .init(xVaultToken: sessionToken))

        switch response {
            case .noContent:
                logger.info("Vault root credentials rotated")
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .undocumented(let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }

    public func create(
        staticRole: CreateDatabaseStaticRole,
        enginePath: String
    ) async throws {
        let sessionToken = try sessionToken()

        let response = try await client.databaseCreateStaticRole(
            .init(
                path: .init(enginePath: enginePath, roleName: staticRole.vaultRoleName),
                headers: .init(xVaultToken: sessionToken),
                body: .json(.init(username: staticRole.databaseUsername,
                                  dbName: staticRole.databaseConnectionName,
                                  rotationPeriod: staticRole.rotationPeriod,
                                  rotationSchedule: staticRole.rotationSchedule,
                                  rotationWindow: staticRole.rotationWindow,
                                  rotationStatements: staticRole.rotationStatements,
                                  credentialType: staticRole.credentialType,
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
                    defaultTtl: dynamicRole.defaultTTL,
                    maxTtl: dynamicRole.maxTTL,
                    creationStatements: dynamicRole.creationStatements,
                    revocationStatements: dynamicRole.revocationStatements,
                    rollbackStatements: dynamicRole.rollbackStatements,
                    renewStatements: dynamicRole.renewStatements,
                    rotationStatements: dynamicRole.rotationStatements,
                    credentialType: dynamicRole.credentialType,
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
}
