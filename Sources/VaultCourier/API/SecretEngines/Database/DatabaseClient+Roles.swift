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

#if DatabaseEngineSupport
import OpenAPIRuntime
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.URL
import class Foundation.JSONDecoder
import class Foundation.JSONEncoder
import struct Foundation.Data
#endif
import Logging
import DatabaseEngine
import VaultUtilities

extension DatabaseEngineClient {
    /// Creates a vault role for accessing database secrets
    /// - Parameters:
    ///   - staticRole: Static role properties
    public func create(
        staticRole: CreateDatabaseStaticRole,
    ) async throws {
        let sessionToken = self.engine.token
        let enginePath = self.engine.mountPath

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

        let response = try await engine.client.databaseCreateStaticRole(
            .init(
                path: .init(enginePath: enginePath, roleName: staticRole.vaultRoleName),
                headers: .init(xVaultToken: sessionToken),
                body: .json(.init(username: staticRole.databaseUsername,
                                  dbName: staticRole.databaseConnectionName,
                                  rotationPeriod: rotationPeriod,
                                  rotationSchedule: rotationSchedule,
                                  rotationWindow: rotationWindow,
                                  rotationStatements: staticRole.rotationStatements,
                                  credentialType: staticRole.credentialType?.rawValue,
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

    /// Deletes a vault database static role
    /// - Parameters:
    ///   - name: name of the role
    ///   - enginePath: mount path of secret engine
    public func deleteStaticRole(
        name: String
    ) async throws {
        let sessionToken = self.engine.token
        let enginePath = self.engine.mountPath

        let response = try await engine.client.databaseDeleteStaticRole(
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

    #if PostgresPluginSupport
    /// Creates a dynamic database role
    /// - Parameter dynamicRole: properties of dynamic role
    public func createPostgres(
        dynamicRole: CreatePostgresRole
    ) async throws {
        let sessionToken = self.engine.token
        let enginePath = self.engine.mountPath

        let data = try JSONEncoder().encode(dynamicRole.creationStatements)
        guard let statements = String(data: data, encoding: .utf8) else {
            throw VaultClientError.invalidRole(statements: dynamicRole.creationStatements)
        }

        let response = try await engine.client.databaseCreateRole(
            .init(
                path: .init(enginePath: enginePath, roleName: dynamicRole.vaultRoleName),
                headers: .init(xVaultToken: sessionToken),
                body: .json(.WritePostgresRoleRequest(.init(
                    dbName: dynamicRole.databaseConnectionName,
                    defaultTtl: dynamicRole.defaultTimeToLive?.formatted(.vaultSeconds),
                    maxTtl: dynamicRole.maxTimeToLive?.formatted(.vaultSeconds),
                    creationStatements: [statements],
                    revocationStatements: dynamicRole.revocationStatements,
                    rollbackStatements: dynamicRole.rollbackStatements,
                    renewStatements: dynamicRole.renewStatements,
                    rotationStatements: dynamicRole.rotationStatements,
                    credentialType: dynamicRole.credentialType?.rawValue,
                    credentialConfig: .init(unvalidatedValue: dynamicRole.credentialConfig ?? [:]))))
            )
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
    #endif

    #if ValkeyPluginSupport
    /// Creates a Valkey dynamic database role
    /// - Parameter dynamicRole: properties of dynamic role
    public func createValkey(
        dynamicRole: CreateValkeyRole
    ) async throws {
        let sessionToken = self.engine.token
        let enginePath = self.engine.mountPath

        let data = try JSONEncoder().encode(dynamicRole.creationStatements)
        guard let statements = String(data: data, encoding: .utf8) else {
            throw VaultClientError.invalidRole(statements: dynamicRole.creationStatements)
        }

        let response = try await engine.client.databaseCreateRole(
            .init(
                path: .init(enginePath: enginePath, roleName: dynamicRole.vaultRoleName),
                headers: .init(xVaultToken: sessionToken),
                body: .json(.WriteValkeyRoleRequest(.init(
                    dbName: dynamicRole.databaseConnectionName,
                    defaultTtl: dynamicRole.defaultTimeToLive?.formatted(.vaultSeconds),
                    maxTtl: dynamicRole.maxTimeToLive?.formatted(.vaultSeconds),
                    creationStatements: [statements]) // Filed a bug for this which can simplify the api: https://github.com/openbao/openbao/issues/1813
                ))
            )
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
    #endif

    /// Deletes a dynamic database role
    /// - Parameters:
    ///   - name: name of dynamic database role
    public func deleteRole(
        name: String
    ) async throws {
        let sessionToken = self.engine.token
        let enginePath = self.engine.mountPath

        let response = try await engine.client.databaseDeleteRole(
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

// MARK: Role Credentials
extension DatabaseEngineClient {
    /// Reads database credentials for a static role
    /// - Parameters:
    ///   - staticRole: static role name
    ///   - enginePath: path to database mount
    /// - Returns: Static database credentials
    public func databaseCredentials(
        staticRole: String
    ) async throws -> StaticRoleCredentialsResponse {
        let sessionToken = self.engine.token
        let enginePath = self.engine.mountPath

        let response = try await engine.client.databaseReadStaticRoleCredentials(
            path: .init(enginePath: enginePath, roleName: staticRole),
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json

                let rotation: RotationStrategy? = if let rotationPeriod = json.data.rotationPeriod {
                    .period(.seconds(rotationPeriod))
                } else if let schedule = json.data.rotationSchedule {
                    if let window = json.data.rotationWindow {
                        .scheduled(.init(schedule: schedule,
                                         window: .seconds(window)))
                    } else {
                        .scheduled(.init(schedule: schedule, window: nil))
                    }
                } else {
                    nil
                }

                return .init(
                    requestID: json.requestId,
                    username: json.data.username,
                    password: json.data.password,
                    timeToLive: .seconds(json.data.ttl),
                    updatedAt: json.data.lastVaultRotation,
                    rotation: rotation
                )
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
                throw VaultClientError.operationFailed(statusCode)
        }
    }


    /// Read current credentials for a dynamic role
    /// - Parameters:
    ///   - dynamicRole: dynamic role name
    ///   - enginePath: path to database mount
    /// - Returns: Dynamic role credentials
    public func databaseCredentials(
        dynamicRole: String
    ) async throws -> RoleCredentialsResponse {
        let sessionToken = self.engine.token
        let enginePath = self.engine.mountPath

        let response = try await engine.client.databaseReadRoleCredentials(
            path: .init(enginePath: enginePath, roleName: dynamicRole),
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                return .init(
                    requestID: json.requestId,
                    username: json.data.username,
                    password: json.data.password,
                    timeToLive: json.data.ttl.flatMap({ .seconds($0)}),
                    updatedAt: json.data.lastVaultRotation)
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
                throw VaultClientError.operationFailed(statusCode)
        }
    }
}

#endif
