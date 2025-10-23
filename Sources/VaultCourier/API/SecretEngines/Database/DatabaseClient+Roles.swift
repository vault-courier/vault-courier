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
import FoundationInternationalization
#else
import struct Foundation.URL
import class Foundation.JSONDecoder
import class Foundation.JSONEncoder
import struct Foundation.Data
#endif
import Logging
import DatabaseEngine
import Utils

#if PostgresPluginSupport || ValkeyPluginSupport
// MARK: Create Database Roles
extension DatabaseEngineClient {

    /// Creates a vault role for accessing database secrets
    ///
    /// ## Package traits
    ///
    /// This method is guarded by any of the database-plugin package traits.
    ///
    /// - Parameters:
    ///   - staticRole: configuration for static role creation
    public func create(
        staticRole: DatabaseStaticRoleConfig,
    ) async throws {
        let sessionToken = self.engine.token
        let enginePath = self.engine.mountPath

        let rotationPeriod: String?
        let rotationSchedule: String?
        let rotationWindow: String?
        let response:  Operations.DatabaseCreateStaticRole.Output

        switch staticRole {
            case .postgres(let postgresStaticRole):
                switch postgresStaticRole.rotation {
                    case .period(let period):
                        rotationPeriod = period.formatted(.vaultSeconds)
                        rotationSchedule = nil
                        rotationWindow = nil
                    case .scheduled(let scheduled):
                        rotationPeriod = nil
                        rotationSchedule = scheduled.schedule
                        rotationWindow = scheduled.window?.formatted(.vaultSeconds)
                }

                response = try await engine.client.databaseCreateStaticRole(
                    .init(
                        path: .init(enginePath: enginePath, roleName: postgresStaticRole.vaultRoleName),
                        headers: .init(xVaultToken: sessionToken),
                        body: .json(.init(username: postgresStaticRole.databaseUsername,
                                          dbName: postgresStaticRole.databaseConnectionName,
                                          rotationPeriod: rotationPeriod,
                                          rotationSchedule: rotationSchedule,
                                          rotationWindow: rotationWindow,
                                          rotationStatements: postgresStaticRole.rotationStatements,
                                          credentialType: postgresStaticRole.credentialType?.rawValue,
                                          credentialConfig: .init(unvalidatedValue: postgresStaticRole.credentialConfig ?? [:]))))
                )
            case .valkey(let valkeyStaticRole):
                switch valkeyStaticRole.rotation {
                    case .period(let period):
                        rotationPeriod = period.formatted(.vaultSeconds)
                        rotationSchedule = nil
                        rotationWindow = nil
                    case .scheduled(let scheduled):
                        rotationPeriod = nil
                        rotationSchedule = scheduled.schedule
                        rotationWindow = scheduled.window?.formatted(.vaultSeconds)
                }

                response = try await engine.client.databaseCreateStaticRole(
                    .init(
                        path: .init(enginePath: enginePath, roleName: valkeyStaticRole.vaultRoleName),
                        headers: .init(xVaultToken: sessionToken),
                        body: .json(.init(username: valkeyStaticRole.databaseUsername,
                                          dbName: valkeyStaticRole.databaseConnectionName,
                                          rotationPeriod: rotationPeriod,
                                          rotationSchedule: rotationSchedule,
                                          rotationWindow: rotationWindow,
                                          rotationStatements: valkeyStaticRole.rotationStatements,
                                          credentialConfig: .init(unvalidatedValue: [:]))))
                )
        }

        switch response {
            case .ok , .noContent:
                logger.info("Database static role written")
                return
            case let .undocumented(statusCode, payload):
                let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                throw vaultError
        }
    }

    /// Creates a dynamic database role
    /// - Parameter dynamicRole: configuration of dynamic role creation
    public func create(
        dynamicRole: DatabaseDynamicRoleConfig
    ) async throws {
        let sessionToken = self.engine.token
        let enginePath = self.engine.mountPath

        let response:  Operations.DatabaseCreateRole.Output
        let data: Data
        switch dynamicRole {
            case .postgres(let config):
                data = try JSONEncoder().encode(config.creationStatements)
                guard let statements = String(data: data, encoding: .utf8) else {
                    throw VaultClientError.invalidRole(statements: config.creationStatements)
                }

                response = try await engine.client.databaseCreateRole(
                    .init(
                        path: .init(enginePath: enginePath, roleName: config.vaultRoleName),
                        headers: .init(xVaultToken: sessionToken),
                        body: .json(.WritePostgresRoleRequest(.init(
                            dbName: config.databaseConnectionName,
                            defaultTtl: config.defaultTimeToLive?.formatted(.vaultSeconds),
                            maxTtl: config.maxTimeToLive?.formatted(.vaultSeconds),
                            creationStatements: [statements],
                            revocationStatements: config.revocationStatements,
                            rollbackStatements: config.rollbackStatements,
                            renewStatements: config.renewStatements,
                            rotationStatements: config.rotationStatements,
                            credentialType: config.credentialType?.rawValue,
                            credentialConfig: .init(unvalidatedValue: config.credentialConfig ?? [:]))))
                    )
                )
            case .valkey(let config):
                data = try JSONEncoder().encode(config.creationStatements)
                guard let statements = String(data: data, encoding: .utf8) else {
                    throw VaultClientError.invalidRole(statements: config.creationStatements)
                }

                response = try await engine.client.databaseCreateRole(
                    .init(
                        path: .init(enginePath: enginePath, roleName: config.vaultRoleName),
                        headers: .init(xVaultToken: sessionToken),
                        body: .json(.WriteValkeyRoleRequest(.init(
                            dbName: config.databaseConnectionName,
                            defaultTtl: config.defaultTimeToLive?.formatted(.vaultSeconds),
                            maxTtl: config.maxTimeToLive?.formatted(.vaultSeconds),
                            creationStatements: [statements]) // Filed a bug for this which can simplify the api: https://github.com/openbao/openbao/issues/1813
                        ))
                    )
                )
        }

        switch response {
            case .noContent:
                logger.info("Database dynamic role written")
                return
            case let .undocumented(statusCode, payload):
                let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                throw vaultError
        }
    }
}
#endif

extension DatabaseEngineClient {
    /// Deletes a vault database static role
    ///
    /// ## Package traits
    ///
    /// This method is guarded by the `DatabaseEngineSupport` package trait.
    ///
    /// - Parameters:
    ///   - name: name of the role
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
            case let .undocumented(statusCode, payload):
                let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                throw vaultError
        }
    }

    /// Deletes a dynamic database role
    ///
    /// ## Package traits
    ///
    /// This method is guarded by the `DatabaseEngineSupport` package trait.
    ///
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
            case let .undocumented(statusCode, payload):
                let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                throw vaultError
        }
    }
}

// MARK: Role Credentials
extension DatabaseEngineClient {
    /// Reads database credentials for a static role
    ///
    /// ## Package traits
    ///
    /// This method is guarded by the `DatabaseEngineSupport` package trait.
    ///
    /// - Parameters:
    ///   - staticRole: static role name
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
            case let .undocumented(statusCode, payload):
                let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                throw vaultError
        }
    }

    /// Read current credentials for a dynamic role
    ///
    /// ## Package traits
    ///
    /// This method is guarded by the `DatabaseEngineSupport` package trait.
    ///
    /// - Parameters:
    ///   - dynamicRole: dynamic role name
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
                    timeToLive: json.data.ttl.flatMap({ .seconds($0)}))
            case let .undocumented(statusCode, payload):
                let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                throw vaultError
        }
    }
}
#endif
