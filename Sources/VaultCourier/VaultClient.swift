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

import Synchronization
import OpenAPIRuntime
import Logging
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.URL
#endif
#if AppRoleSupport
import AppRoleAuth
#endif
import TokenAuth
import SystemWrapping

/// REST Client for Hashicorp Vault and OpenBao.
///
/// This is the main client to interact with the Vault server. Either you call one-shot operations or use the scoped functions like
/// e.g. ``withKeyValueClient(mountPath:execute:)`` for multiple calls to the same group of endpoints.
///
/// Before a client can interact with Vault, it must authenticate against an ``AuthMethod``. For example, authenticate with AppRole credentials
///
/// ```swift
/// let vaultClient = VaultClient(
///     configuration: .defaultHttps(),
///     clientTransport: AsyncHTTPClientTransport()
/// )
/// try await vaultClient.login(
///     method: .appRole(
///         path: "path/to/approle/mount",
///         credentials: .init(
///             roleID: "app_role_id",
///             secretID: "s3cret_id"
///         )
///     )
/// )
/// ```
public final class VaultClient: Sendable {
    /// Vault client configuration
    public struct Configuration: Sendable {
        /// Vault's base URL, e.g. `https://127.0.0.1:8200/v1`
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

        /// Default Configuration with base URL `http://127.0.0.1:8200/v1`
        public static func defaultHttp(backgroundActivityLogger: Logging.Logger? = nil) -> Self {
            .init(apiURL: VaultClient.Server.defaultHttpURL,
                  backgroundActivityLogger: backgroundActivityLogger)
        }

        /// Default Configuration with base URL `https://127.0.0.1:8200/v1`
        public static func defaultHttps(backgroundActivityLogger: Logging.Logger? = nil) -> Self {
            .init(apiURL: VaultClient.Server.defaultHttpsURL,
                  backgroundActivityLogger: backgroundActivityLogger)
        }
    }

    /// Vault's base URL, e.g. `https://127.0.0.1:8200/v1`
    public let apiURL: URL

    /// Client transport, e.g. `AsyncHTTPClientTransport`, `URLSessionTransport` or any mock client transport
    let clientTransport: any ClientTransport

    let logger: Logging.Logger

    /// Middlewares to be invoked before the transport.
    let middlewares: [any ClientMiddleware]

    private let _token: Mutex<String?>

    /// Session token
    private var token: String? {
        get {
            _token.withLock { $0 }
        }
        set {
            _token.withLock {
                $0 = newValue
            }
        }
    }

    public init(configuration: Configuration,
                clientTransport: any ClientTransport,
                middlewares: [any ClientMiddleware] = []) {
        self.apiURL = configuration.apiURL
        self.clientTransport = clientTransport
        self.middlewares = middlewares
        self.logger = configuration.backgroundActivityLogger
        self._token = .init(nil)
    }

    
    /// Session token
    /// - Returns: current client session token
    /// - Throws: ``VaultClientError`` when client is not logged in
    public func sessionToken() throws -> String {
        guard let token else {
            throw VaultClientError.clientIsNotLoggedIn()
        }
        return token
    }

    /// Remove current session token
    public func resetSession() {
        self.token = nil
    }
}

extension VaultClient {
    public func login(method: AuthMethod) async throws {
        let authenticator = makeAuthenticator(method, apiURL: apiURL, clientTransport: clientTransport)
        self.token = try await authenticator.authenticate()
        logger.info("login authorized")
    }

}

extension VaultClient {
    /// Handler to interact with the system backend endpoints
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
    /// Handler to interact with the key/value secret endpoints
    ///
    /// A key/value client is created with the current session token and middlewares
    ///
    /// - Parameters:
    ///   - mountPath: mount path of key/value secrets
    ///   - execute: action closure to execute with the key/value client
    /// - Returns: return type of the `execute` closure
    public func withKeyValueClient<ReturnType: Sendable>(
        mountPath: String,
        execute: (KeyValueEngineClient) async throws -> ReturnType
    ) async throws -> ReturnType {
        let sessionToken = try? sessionToken()
        let client = KeyValueEngineClient(
            apiURL: apiURL,
            clientTransport: clientTransport,
            mountPath: mountPath,
            middlewares: middlewares,
            token: sessionToken
        )
        return try await execute(client)
    }

    #if DatabaseEngineSupport
    
    /// Handler to interact with the database secret endpoints
    ///
    /// A database client is created with the current session token and middlewares
    ///
    /// ## Package traits
    ///
    /// This handler is guarded by the `DatabaseEngineSupport` package trait.
    ///
    /// - Parameters:
    ///   - mountPath: mount path of database secrets
    ///   - execute: action closure to execute with the database client
    /// - Returns: return type of the `execute` closure
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
    /// Handler to interact with the token authentication endpoints
    ///
    /// A token-auth client is created with the current session token and middlewares
    ///
    /// - Parameter execute: action closure to execute with the token-auth client
    /// - Returns: return type of the `execute` closure
    public func withTokenAuthClient<ReturnType: Sendable>(
        execute: (TokenAuthClient) async throws -> ReturnType
    ) async throws -> ReturnType {
        let sessionToken = try? sessionToken()
        let client = TokenAuthClient(
            apiURL: apiURL,
            clientTransport: clientTransport,
            middlewares: middlewares,
            token: sessionToken
        )
        return try await execute(client)
    }

#if AppRoleSupport
    /// Handler to interact with the AppRole authentication endpoints
    /// 
    /// An Approle-auth client is created with the current session token and middlewares
    ///
    /// ## Package traits
    ///
    /// This handler is guarded by the `AppRoleSupport` package trait.
    ///
    /// - Parameter execute: action closure to execute with the token-auth client
    /// - Parameter mountPath: path to approle authentication mount
    /// - Returns: return type of the `execute` closure
    public func withAppRoleClient<ReturnType: Sendable>(
        mountPath: String,
        execute: (AppRoleAuthClient) async throws -> ReturnType
    ) async throws -> ReturnType {
        let sessionToken = try? sessionToken()
        let client = AppRoleAuthClient(
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
