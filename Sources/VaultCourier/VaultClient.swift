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
import AppRoleAuth
import TokenAuth
import SystemWrapping
import VaultUtilities

/// REST Client for Hashicorp Vault and OpenBao.
///
/// Before a client can interact with Vault, it must authenticate against an auth method. This actor protects the state of the mutating token during this process.
/// Regardless of which authentication method was chosen during initialization, ``VaultClient`` always authenticates using the ``authenticate()`` method.
public actor VaultClient {

    @available(*, deprecated, message: "use a leaner configuration without mount paths")
    public struct Configuration {
        /// Vault's base URL, e.g. `http://127.0.0.1:8200/v1`
        public let apiURL: URL

        /// Custom AppRole engine path in Vault.
        public let appRolePath: String

        /// Custom mount path for the KeyValue v2 engine in Vault.
        public let kvMountPath: String

        /// Custom mount path for the Database engine in Vault.
        public let databaseMountPath: String

        public let backgroundActivityLogger: Logging.Logger

        static let loggingDisabled = Logger(label: "vault-client-do-not-log", factory: { _ in SwiftLogNoOpLogHandler() })
        
        /// Configuration initializer
        /// - Parameters:
        ///   - apiURL: Vault's base URL, e.g. `http://127.0.0.1:8200/v1`
        ///   - appRolePath: Custom AppRole engine path in Vault. Defaults to `approle` when set to `nil`.
        ///   - kvMountPath: Custom mount path for the KeyValue v2 engine in Vault. Defaults to `secret` when set to `nil`.
        ///   - databaseMountPath: Custom mount path for the Database engine in Vault. Defaults to `database` when set to `nil`.
        ///   - backgroundActivityLogger: Vault client logger
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


    public struct Configuration2: Sendable {
        /// Vault's base URL, e.g. `http://127.0.0.1:8200/v1`
        public let apiURL: URL

        /// Vault client's logger
        public let backgroundActivityLogger: Logging.Logger

        static var loggingDisabled: Logger { .init(label: "vault-client-do-not-log", factory: { _ in SwiftLogNoOpLogHandler() }) }

        /// Configuration initializer
        /// - Parameters:
        ///   - apiURL: Vault's base URL, e.g. `http://127.0.0.1:8200/v1`
        ///   - backgroundActivityLogger: Vault client logger
        public init(apiURL: URL,
                    backgroundActivityLogger: Logging.Logger? = nil) {
            self.apiURL = apiURL
            self.backgroundActivityLogger = backgroundActivityLogger ?? Self.loggingDisabled
        }
    }

    @available(*, deprecated, message: "AuthMethods and Secret engines will be created on demand")
    /// Mount engine paths
    struct Mounts {
        public let kv: URL

        public let database: URL

        public let appRole: URL
    }

    let apiURL: URL

    @available(*, deprecated, message: "This will be removed and we store only the transport client")
    let client: any APIProtocol

    let clientTransport: any ClientTransport

    let logger: Logging.Logger

    let mounts: Mounts

    /// The middlewares to be invoked before the transport.
    let middlewares: [any ClientMiddleware]

    /// Session token
    private var token: String?

//    private var authMethod: AuthMethod

    public init(configuration: Configuration,
                clientTransport: any ClientTransport,
//                authentication: Authentication,
                middlewares: [any ClientMiddleware] = []) {
//        switch authentication {
//            case let .appRole(credentials, isWrapped):
//                self.authState = isWrapped ? .wrapped(credentials) : .unwrapped(credentials)
//                self.authMethod = .appRole
//            case .token(let token):
//                self.authMethod = .token
//                self.authState = .authorized(token: token)
//        }

        self.apiURL = configuration.apiURL
        self.clientTransport = clientTransport

        self.client = Client(
            serverURL: configuration.apiURL,
            transport: clientTransport,
            middlewares: middlewares
        )
        self.middlewares = middlewares
        self.logger = configuration.backgroundActivityLogger
        self.mounts = .init(kv: .init(string: configuration.kvMountPath, relativeTo: configuration.apiURL) ?? URL(string: "/secret", relativeTo: configuration.apiURL)!,
                            database: .init(string: configuration.databaseMountPath, relativeTo: configuration.apiURL) ?? URL(string: "/database", relativeTo: configuration.apiURL)!,
                            appRole: .init(string: configuration.appRolePath, relativeTo: configuration.apiURL.appending(path: "auth")) ??  URL(string: "/approle", relativeTo: configuration.apiURL.appending(path: "auth"))!)
    }

    func sessionToken() throws -> String {
        guard let token else {
            throw VaultClientError.clientIsNotLoggedIn()
        }
        return token
    }
}

extension VaultClient {
    public func login(method: NewAuthMethod) async throws {
        let authenticator = makeAuthenticator(method, apiURL: apiURL, clientTransport: clientTransport)
        self.token = try await authenticator.authenticate()
        logger.info("login authorized")
    }

}

extension VaultClient {
    public func withSystemBackend<ReturnType: Sendable>(
        execute: (SystemBackend) async throws -> ReturnType
    ) async throws -> ReturnType {
        let sessionToken = try? sessionToken()
        let client = SystemBackend(
            apiURL: apiURL,
            clientTransport: clientTransport,
            middlewares: middlewares,
            token: sessionToken
        )
        return try await execute(client)
    }
}

extension VaultClient {
    public func withKeyValueProvider<ReturnType: Sendable>(
        mountPath: String,
        execute: (KeyValueSecretProvider) async throws -> ReturnType
    ) async throws -> ReturnType {
        let sessionToken = try? sessionToken()
        let client = KeyValueSecretProvider(
            apiURL: apiURL,
            clientTransport: clientTransport,
            mountPath: mountPath,
            middlewares: middlewares,
            token: sessionToken
        )
        return try await execute(client)
    }

    #if DatabaseEngineSupport
    public func withDatabaseClient<ReturnType: Sendable>(
        mountPath: String,
        execute: (DatabaseEngineClient) async throws -> ReturnType
    ) async throws -> ReturnType {
        let sessionToken = try? sessionToken()
        let client = DatabaseEngineClient(
            apiURL: apiURL,
            clientTransport: clientTransport,
            mountPath: mountPath,
            middlewares: middlewares,
            token: sessionToken
        )
        return try await execute(client)
    }
    #endif
}


extension VaultClient {
    public func withTokenProvider<ReturnType: Sendable>(
        execute: (TokenProvider) async throws -> ReturnType
    ) async throws -> ReturnType {
        let sessionToken = try? sessionToken()
        let client = TokenProvider(
            apiURL: apiURL,
            clientTransport: clientTransport,
            middlewares: middlewares,
            token: sessionToken
        )
        return try await execute(client)
    }

#if AppRoleSupport
    public func withAppRoleProvider<ReturnType: Sendable>(
        mountPath: String? = nil,
        execute: (AppRoleProvider) async throws -> ReturnType
    ) async throws -> ReturnType {
        let sessionToken = try? sessionToken()
        let client = AppRoleProvider(
            apiURL: apiURL,
            clientTransport: clientTransport,
            mountPath: mountPath,
            middlewares: middlewares,
            token: sessionToken
        )
        return try await execute(client)
    }
#endif
}

