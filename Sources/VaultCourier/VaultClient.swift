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
    public struct Configuration: Sendable {
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

    /// Vault's base URL, e.g. `http://127.0.0.1:8200/v1`
    public let apiURL: URL

    let clientTransport: any ClientTransport

    let logger: Logging.Logger

    /// Middlewares to be invoked before the transport.
    let middlewares: [any ClientMiddleware]

    /// Session token
    private var token: String?

    public init(configuration: Configuration,
                clientTransport: any ClientTransport,
                middlewares: [any ClientMiddleware] = []) {
        self.apiURL = configuration.apiURL
        self.clientTransport = clientTransport
        self.middlewares = middlewares
        self.logger = configuration.backgroundActivityLogger
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

