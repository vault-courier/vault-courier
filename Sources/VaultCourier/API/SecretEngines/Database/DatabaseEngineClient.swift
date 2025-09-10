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
import Synchronization
import Logging
import DatabaseEngine
import VaultUtilities

/// Client for Database secret engine
public final class DatabaseEngineClient: Sendable {
    static var loggingDisabled: Logger { .init(label: "database-engine-client-do-not-log", factory: { _ in SwiftLogNoOpLogHandler() }) }

    init(apiURL: URL,
         clientTransport: any ClientTransport,
         mountPath: String,
         middlewares: [any ClientMiddleware] = [],
         token: String? = nil,
         logger: Logger? = nil) {
        self.engine = DatabaseEngine(
            configuration: .init(apiURL: apiURL, mountPath: mountPath),
            clientTransport: clientTransport,
            middlewares: middlewares,
            token: token)
        self.apiURL = apiURL
        self.mountPath = mountPath.removeSlash()
        self._token = .init(token)
        self.logger = logger ?? Self.loggingDisabled
    }

    /// Vault's base URL
    let apiURL: URL

    let mountPath: String

    /// Engine client
    let engine: DatabaseEngine

    let _token: Mutex<String?>

    /// Client token
    var token: String? {
        get {
            _token.withLock { $0 }
        }
        set {
            _token.withLock {
                $0 = newValue
            }
        }
    }

    let logger: Logging.Logger
}

extension DatabaseEngineClient {

    #if PostgresPluginSupport
    /// Creates a database connection between Vault and a Postgres Database
    public func databaseConnection(
        configuration: PostgresConnectionConfiguration
    ) async throws {
        let sessionToken = self.engine.token
        let enginePath = self.engine.mountPath

        let response = try await engine.client.configureDatabase(
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
                              passwordAuthentication: .init(rawValue: configuration.passwordAuthentication.rawValue),
                              rootRotationStatements: configuration.rootRotationStatements))
        )

        switch response {
            case .noContent:
                logger.info("Postgres database connection configured")
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
    #endif

    #if ValkeyPluginSupport
    /// Creates a database connection between Vault and a Postgres Database
    public func databaseConnection(
        configuration: ValkeyConnection
    ) async throws {
        let sessionToken = self.engine.token
        let enginePath = self.engine.mountPath

        let response = try await engine.client.configureDatabase(
            path: .init(enginePath: enginePath, connectionName: configuration.connection),
            headers: .init(xVaultToken: sessionToken),
            body: .json(.init(pluginName: configuration.pluginName,
                              verifyConnection: configuration.verifyConnection,
                              allowedRoles: configuration.allowedRoles,
                              username: configuration.username,
                              password: configuration.password,
                              rootRotationStatements: configuration.rootRotationStatements,
                              host: configuration.host,
                              port: String(configuration.port)))
        )

        switch response {
            case .noContent:
                logger.info("Valkey database connection configured")
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
    #endif

    #if PostgresPluginSupport
    /// Reads vault-database connection
    /// - Parameters:
    ///   - name: Connection name
    /// - Returns: Connection properties
    public func databaseConnection(
        name: String
    ) async throws -> PostgresConnectionResponse {
        let sessionToken = self.engine.token
        let enginePath = self.engine.mountPath

        let response = try await engine.client.readDatabaseConfiguration(
            path: .init(enginePath: enginePath, connectionName: name),
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                let pluginVersion = json.data.pluginVersion
                let pluginName = json.data.pluginName

                let connectionURL: URL?
                let authMethod: PostgresAuthMethod?
                let username: String
                if let value = json.data.connectionDetails?.value1 {
                    switch value {
                        case .case1(let details):
                            connectionURL = URL(string: details.connectionUrl)
                            authMethod = .init(rawValue: details.passwordAuthentication)
                            username = details.username
                        case .case2(let dictionary):
                            logger.debug(.init(stringLiteral: "\(#function) Unknown body response: \(dictionary)"))
                            throw VaultClientError.decodingFailed()
                    }
                } else if let value = json.data.connectionDetails?.value2 {
                    logger.debug(.init(stringLiteral: "\(#function) Unknown body response: \(value.value.description)"))
                    throw VaultClientError.decodingFailed()
                } else {
                    preconditionFailure("Unreachable path \(#function)")
                }

                return .init(
                    requestID: json.requestId,
                    allowedRoles: json.data.allowedRoles,
                    connectionURL: connectionURL,
                    authMethod: authMethod,
                    username: username,
                    plugin: pluginName.flatMap { VaultPlugin(name: $0, version: pluginVersion) },
                    passwordPolicy: json.data.passwordPolicy,
                    rotateStatements: json.data.rootCredentialsRotateStatements ?? []
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
    #endif

    #if ValkeyPluginSupport
    /// Reads vault-database connection
    /// - Parameters:
    ///   - name: Connection name
    /// - Returns: Connection properties
    public func databaseConnection(
        name: String
    ) async throws -> ValkeyConnectionResponse {
        let sessionToken = self.engine.token
        let enginePath = self.engine.mountPath

        let response = try await engine.client.readDatabaseConfiguration(
            path: .init(enginePath: enginePath, connectionName: name),
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                let pluginVersion = json.data.pluginVersion
                let pluginName = json.data.pluginName

                let username: String
                let host: String
                let port: UInt16
                let useTLS: Bool
                if let value = json.data.connectionDetails?.value1 {
                    switch value {
                        case let .case1(unexpected):
                            logger.debug(.init(stringLiteral: "\(#function) Unexpected body response: \(unexpected)"))
                            throw VaultClientError.decodingFailed()
                        case .case2(let details):
                            username = details.username
                            host = details.host
                            guard let portNumber = UInt16(details.port) else {
                                logger.debug(.init(stringLiteral: "\(#function) Fail to decode port '\(details.port)'"))
                                throw VaultClientError.decodingFailed()
                            }
                            port =  portNumber
                            useTLS = details.tls ?? false
                    }
                } else if let value = json.data.connectionDetails?.value2 {
                    logger.debug(.init(stringLiteral: "\(#function) Unknown body response: \(value.value.description)"))
                    throw VaultClientError.decodingFailed()
                } else {
                    preconditionFailure("Unreachable path \(#function)")
                }

                return .init(
                        requestID: json.requestId,
                        allowedRoles: json.data.allowedRoles,
                        host: host,
                        port: port,
                        useTLS: useTLS,
                        username: username,
                        plugin: pluginName.flatMap { VaultPlugin(name: $0, version: pluginVersion) },
                        passwordPolicy: json.data.passwordPolicy,
                        rotateStatements: json.data.rootCredentialsRotateStatements ?? []
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
    #endif

    /// Deletes a database connection between Vault and a Postgres Database
    /// - Note: The roles in the database are not deleted
    /// - Parameters:
    ///   - connectionName: name of the database connection
    public func deleteDatabaseConnection(
        _ connectionName: String
    ) async throws {
        let sessionToken = self.engine.token
        let enginePath = self.engine.mountPath

        let response = try await engine.client.deleteDatabaseConnection(
            path: .init(enginePath: enginePath, connectionName: connectionName),
            headers: .init(xVaultToken: sessionToken)
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
                throw VaultClientError.operationFailed(statusCode)
        }
    }

    /// Rotates Vault database password
    /// - Note: After this action only vault knows this user's password
    /// - Parameters:
    ///   - connection: connection name
    public func rotateRoot(
        connection: String
    ) async throws {
        let sessionToken = self.engine.token
        let enginePath = self.engine.mountPath

        let response = try await engine.client.databaseRotateRoot(
            path: .init(enginePath: enginePath, connectionName: connection),
            headers: .init(xVaultToken: sessionToken)
        )

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

    /// Closes a connection and it's underlying plugin and restarts it with the configuration stored in the barrier.
    ///
    /// - Note: This method resets the connection, but vault's database password is still the same
    /// - Parameters:
    ///   - connectionName: connection name
    ///   - enginePath: mount path of database secrets
    public func resetDatabaseConnection(
        _ connectionName: String
    ) async throws {
        let sessionToken = self.engine.token
        let enginePath = self.engine.mountPath

        let response = try await engine.client.databaseReset(
            path: .init(enginePath: enginePath, connectionName: connectionName),
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .noContent:
                logger.info("Connection \(connectionName) reset successfully.")
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .internalServerError(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Internal server error: \(errors.joined(separator: ", ")).")
                throw VaultClientError.operationFailed(500)
            case .undocumented(let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }
}

#endif
