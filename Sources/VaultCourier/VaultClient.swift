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
import Logging
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

public actor VaultClient {
    public struct Configuration {
        /// Vault's base URL, e.g. `http://127.0.0.1:8200/v1`
        public let apiURL: URL

        /// Custom AppRole engine path in Vault. Defaults to `approle` when set to `nil`.
        public let appRolePath: String

        /// Custom mount path for the KeyValue v2 engine in Vault. Defaults to `secret` when set to `nil`.
        public let kvMountPath: String

        /// Custom mount path for the Database engine in Vault. Defaults to `database` when set to `nil`.
        public let databaseMountPath: String

        public let backgroundActivityLogger: Logging.Logger

        static let loggingDisabled = Logger(label: "vault-client-do-not-log", factory: { _ in SwiftLogNoOpLogHandler() })

        public init(apiURL: URL,
                    appRolePath: String? = nil,
                    kvMountPath: String? = nil,
                    databaseMountPath: String? = nil,
                    backgroundActivityLogger: Logging.Logger? = nil) {
            self.apiURL = apiURL
            self.appRolePath = appRolePath ?? "approle"
            self.kvMountPath = kvMountPath ?? "secret"
            self.databaseMountPath = databaseMountPath ?? "database"
            self.backgroundActivityLogger = backgroundActivityLogger ?? Self.loggingDisabled
        }
    }

    /// Mount engine paths
    struct Mounts {
        public let kv: URL

        public let database: URL

        public let appRole: URL
    }

    let client: any APIProtocol

    let logger: Logging.Logger

    let mounts: Mounts

    /// Authentication state
    private var authState: AuthenticationState

    private var authMethod: AuthMethod

    public init(configuration: Configuration,
                clientTransport: any ClientTransport,
                authentication: Authentication,
                middlewares: [any ClientMiddleware] = []) {
        switch authentication {
            case let .appRole(credentials, isWrapped):
                self.authState = isWrapped ? .wrapped(credentials) : .unwrapped(credentials)
                self.authMethod = .appRole
            case .token(let token):
                self.authMethod = .token
                self.authState = .authorized(token: token)
        }

        self.client = Client(
            serverURL: configuration.apiURL,
            transport: clientTransport,
            middlewares: middlewares
        )
        self.logger = configuration.backgroundActivityLogger
        self.mounts = .init(kv: .init(string: configuration.kvMountPath, relativeTo: configuration.apiURL) ?? URL(string: "/secret", relativeTo: configuration.apiURL)!,
                            database: .init(string: configuration.databaseMountPath, relativeTo: configuration.apiURL) ?? URL(string: "/database", relativeTo: configuration.apiURL)!,
                            appRole: .init(string: configuration.appRolePath, relativeTo: configuration.apiURL.appending(path: "auth")) ??  URL(string: "/approle", relativeTo: configuration.apiURL.appending(path: "auth"))!)
    }

    public init(configuration: Configuration,
                client: any APIProtocol,
                authentication: Authentication) {
        switch authentication {
            case let .appRole(credentials, isWrapped):
                self.authState = isWrapped ? .wrapped(credentials) : .unwrapped(credentials)
                self.authMethod = .appRole
            case .token(let token):
                self.authMethod = .token
                self.authState = .authorized(token: token)
        }

        self.client = client
        self.logger = configuration.backgroundActivityLogger
        self.mounts = .init(kv: .init(string: configuration.kvMountPath, relativeTo: configuration.apiURL) ?? URL(string: "secret", relativeTo: configuration.apiURL)!,
                            database: .init(string: configuration.databaseMountPath, relativeTo: configuration.apiURL) ?? URL(string: "/database", relativeTo: configuration.apiURL)!,
                            appRole: .init(string: configuration.appRolePath, relativeTo: configuration.apiURL.appending(path: "auth")) ??  URL(string: "/approle", relativeTo: configuration.apiURL.appending(path: "auth"))!)
    }

    enum AuthenticationState: CustomStringConvertible {
        case wrapped(AppRoleCredentials)
        case unwrapped(AppRoleCredentials)
        case authorized(token: String)

        var description: String {
            switch self {
                case .wrapped: "wrapped"
                case .unwrapped: "unwrapped"
                case .authorized: "authorized"
            }
        }
    }

    public enum Authentication {
        case appRole(credentials: AppRoleCredentials, isWrapped: Bool)
        case token(String)
    }

    enum AuthMethod {
        case appRole
        case token
    }

    public struct AppRoleCredentials: Sendable {
        public let roleID: String
        public let secretID: String

        public init(roleID: String,
                    secretID: String) {
            self.roleID = roleID
            self.secretID = secretID
        }
    }

    ///  Before a client can interact with Vault, it must authenticate against an auth method.
    ///  Upon authentication, a token is generated. This token is conceptually similar to
    ///  a session ID on a website. Here we update the internal token
    @discardableResult
    public func authenticate() async throws -> Bool{
        switch authMethod {
            case .appRole:
                return await appRoleLogin()
            case .token:
                logger.debug("Already authorized with a token. No further authentication required.")
                return true
        }
    }

    private func appRoleLogin() async -> Bool {
        switch authState {
            case .wrapped:
                do {
                    try await unwrapToken()
                    return try await authenticate()
                } catch {
                    logger.debug(.init(stringLiteral: "authentication failed: " + String(reflecting: error)))
                    logger.info("Unauthorized")
                    return false
                }
            case .unwrapped:
                do {
                    try await login()
                    return true
                } catch {
                    logger.debug(.init(stringLiteral: "authentication failed: " + String(reflecting: error)))
                    logger.info("Unauthorized")
                    return false
                }
            case .authorized:
                logger.debug("Already authorized with a token. No further authentication required.")
                return true
        }
    }

    public func unwrapToken() async throws {
        guard case let .wrapped(credentials) = authState else {
            throw VaultClientError.invalidState(authState.description)
        }

        let response = try await client.unwrap(
            .init(headers: .init(xVaultToken: credentials.secretID),
                  body: .json(.init()))
        )
        switch response {
            case .ok(let content):
                let json = try content.body.json
                guard let secretId = json.data?.secretId,
                      !secretId.isEmpty else {
                    logger.debug("Missing or empty secretID in response")
                    throw VaultClientError.decodingFailed()
                }

                logger.info("Unwrap Successful!")
                let roleID = credentials.roleID
                self.authState = .unwrapped(.init(roleID: roleID, secretID: secretId))
                return
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.permissionDenied()
            case .undocumented(let statusCode, _):
                logger.debug(.init(stringLiteral: "unwrapToken failed with \(statusCode): "))
                throw VaultClientError.permissionDenied()
        }
    }

    public func login() async throws {
        switch authState {
        case .wrapped:
            throw VaultClientError.invalidState(authState.description)
        case .unwrapped(let appRoleCredentials):
            try await appRoleLogin(credentials: appRoleCredentials)
        case .authorized:
            return
        }
    }

    func sessionToken() throws -> String {
        guard case let .authorized(sessionToken) = authState else {
            throw VaultClientError.clientIsNotLoggedIn()
        }
        return sessionToken
    }

    func appRoleLogin(credentials: AppRoleCredentials) async throws {
        let appRolePath = mounts.appRole.relativePath.removeSlash()

        let response = try await client.authApproleLogin(
            path: .init(enginePath: appRolePath),
            body: .json(.init(roleId: credentials.roleID, secretId: credentials.secretID))
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                self.authState = .authorized(token: json.auth.clientToken)
                logger.info("login authorized")
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.permissionDenied()
            case .undocumented(statusCode: let statusCode, _):
                logger.debug(.init(stringLiteral: "login failed with \(statusCode): "))
                throw VaultClientError.permissionDenied()
        }
    }
}
