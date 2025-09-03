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
import protocol Foundation.LocalizedError
#else
import struct Foundation.URL
import class Foundation.JSONDecoder
import class Foundation.JSONEncoder
import struct Foundation.Data
import protocol Foundation.LocalizedError
#endif
import VaultUtilities

extension VaultClient {
    /// Creates a database conection between Vault and a Postgres Database
    public func databaseConnection(
        configuration: PostgresConnectionConfiguration,
        enginePath: String
    ) async throws {
        let sessionToken = try sessionToken()

        let response = try await client.configureDatabase(
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
                              passwordAuthentication: configuration.passwordAuthentication.rawValue,
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

    /// Reads vault-database conection
//    public func databaseConnection(
//        name: String,
//        enginePath: String
//    ) async throws -> DatabaseConnectionResponse {
//        let sessionToken = try sessionToken()
//
//        let response = try await client.readDatabaseConfiguration(
//            path: .init(enginePath: enginePath, connectionName: name),
//            headers: .init(xVaultToken: sessionToken)
//        )
//
//        switch response {
//            case .ok(let content):
//                let json = try content.body.json
//                return .init(component: json)
//            case .badRequest(let content):
//                let errors = (try? content.body.json.errors) ?? []
//                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
//                throw VaultClientError.badRequest(errors)
//            case .internalServerError(let content):
//                let errors = (try? content.body.json.errors) ?? []
//                logger.debug("Internal server error: \(errors.joined(separator: ", ")).")
//                throw VaultClientError.internalServerError(errors)
//            case .undocumented(let statusCode, _):
//                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
//                throw VaultClientError.operationFailed(statusCode)
//        }
//    }

    /// Deletes a database conection between Vault and a Postgres Database
    /// - Note: The roles in the database are not deleted
    public func deleteDatabaseConnection(
        _ connectionName: String,
        enginePath: String
    ) async throws {
        let sessionToken = try sessionToken()

        let response = try await client.deleteDatabaseConnection(
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

    /// Closes a connection and it's underlying plugin and restarts it with the configuration stored in the barrier.
    /// 
    /// - Note: This method resets the connection, but vault's database password is still the same
    public func resetDatabaseConnection(
        _ connectionName: String,
        enginePath: String? = nil
    ) async throws {
        let enginePath = enginePath ?? self.mounts.database.relativePath.removeSlash()
        let sessionToken = try sessionToken()

        let response = try await client.databaseReset(
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
