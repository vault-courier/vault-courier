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
    /// Creates a database conection between Vault and a Postgres Database
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
}
