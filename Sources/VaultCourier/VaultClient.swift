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
import Tracing
import Utils
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
/// e.g. ``withKeyValueClient(namespace:mountPath:execute:)`` for multiple calls to the same group of endpoints.
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

        /// Vault's namespace
        ///
        /// Namespaces support secure multi-tenancy (SMT) within a single Vault instance as isolated environments known as tenants.
        /// Within that namespace, users can independently manage their sensitive data, including: secret engines, authentication methods, policies and tokens.
        public let namespace: String

        /// Vault client's logger
        public let backgroundActivityLogger: Logging.Logger

        static var loggingDisabled: Logger { .init(label: "vault-client-do-not-log", factory: { _ in SwiftLogNoOpLogHandler() }) }

        /// Configuration initializer
        /// - Parameters:
        ///   - apiURL: Vault's base URL, e.g. `http://127.0.0.1:8200/v1`
        ///   - namespace: VaultClient's namespace. If not set, it will default to the `root` namespace.
        ///   - backgroundActivityLogger: Vault client logger
        public init(apiURL: URL,
                    namespace: String? = nil,
                    backgroundActivityLogger: Logging.Logger? = nil) {
            self.apiURL = apiURL
            self.namespace = namespace ?? "root"
            self.backgroundActivityLogger = backgroundActivityLogger ?? Self.loggingDisabled
        }

        /// Default Configuration with base URL `http://127.0.0.1:8200/v1`
        ///
        /// - warning:
        /// This configuration is just for local development.
        /// Never use this configuration in production. Always use TLS for production deployments
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

    /// VaultClient's namespace
    public struct Namespace: Sendable {
        public let name: String

        func middleware(_ childNamespace: String? = nil) throws -> [VaultNamespaceMiddleware] {
            if let childNamespace {
                guard childNamespace.isValidNamespaceName else {
                    throw VaultClientError.invalidVault(namespace: childNamespace)
                }

                let namespace = name != "root" ? "\(name)/\(childNamespace)" : childNamespace
                return [VaultNamespaceMiddleware.init(name: namespace)]
            } else {
                return name != "root" ? [VaultNamespaceMiddleware(name: name)] : []
            }
        }
    }

    /// Vault's base URL, e.g. `https://127.0.0.1:8200/v1`
    public let apiURL: URL

    /// Global namespace for this client instance. If `nil` the namespace is the `root` namespace
    public let namespace: Namespace

    /// Client transport, e.g. `AsyncHTTPClientTransport`, `URLSessionTransport` or any mock client transport
    let clientTransport: any ClientTransport

    let logger: Logging.Logger

    /// Middlewares to be invoked before the transport. It does not include the namespace middleware, which is handled separately
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
        self.namespace = Namespace.init(name: configuration.namespace)
        self.clientTransport = clientTransport
        self.logger = configuration.backgroundActivityLogger
        self.middlewares = middlewares
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
        self.logger.debug("Session token deleted")
    }
}

extension VaultClient {
    public func login(method: AuthMethod) async throws {
        try await withSpan("login", ofKind: .client) { span in
            let authenticator = try makeAuthenticator(method, apiURL: apiURL, namespace: namespace, clientTransport: clientTransport, middlewares: middlewares)
            let startEvent = "Starting login"
            let metadata: [String: Logger.MetadataValue] = [
                "auth-method": .stringConvertible(method),
                "vault-namespace": .string(namespace.name)
              ]
            self.logger.trace(.init(stringLiteral: startEvent),metadata: metadata)

            self.token = try await authenticator.authenticate()

            let endEvent = "login authorized"
            self.logger.trace(.init(stringLiteral: endEvent), metadata: metadata)
            span.addEvent(.init(name: endEvent, attributes: [
                TracingSupport.AttributeKeys.vaultNamespace: .string(namespace.name),
                TracingSupport.AttributeKeys.vaultAuthMethod: .stringConvertible(method)
            ]))
        }
    }

}

extension VaultClient {
    /// Handler to interact with the system backend endpoints
    /// - Parameters:
    ///   - namespace: optional child namespace to add to the parent namespace. It cannot contain `/`
    ///   - execute: action closure to execute with system client
    ///
    /// - Note: for security reasons, Vault restricts access to some of the system backend endpoints for child namespaces. See https://openbao.org/docs/concepts/namespaces/#restricted-api-paths
    ///
    /// - Returns: return type of the `execute` closure
    public func withSystemBackend<ReturnType: Sendable>(
        namespace: String? = nil,
        execute: (SystemBackend) async throws -> ReturnType
    ) async throws -> ReturnType {
        let namespaceMiddleware = try self.namespace.middleware(namespace?.removeSlash())
        let namespaceName = namespaceMiddleware.first?.name ?? "root"
        let sessionToken = try? sessionToken()
        let client = SystemBackend(
            apiURL: apiURL,
            namespace: namespaceName,
            clientTransport: clientTransport,
            middlewares: middlewares + namespaceMiddleware,
            token: sessionToken,
            logger: logger
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
    ///   - namespace: optional child namespace to add to the parent namespace
    ///   - mountPath: mount path of key/value secrets
    ///   - execute: action closure to execute with the key/value client
    /// - Returns: return type of the `execute` closure
    public func withKeyValueClient<ReturnType: Sendable>(
        namespace: String? = nil,
        mountPath: String,
        execute: (KeyValueEngineClient) async throws -> ReturnType
    ) async throws -> ReturnType {
        let namespaceMiddleware = try self.namespace.middleware(namespace?.removeSlash())
        let namespaceName = namespaceMiddleware.first?.name ?? "root"
        let sessionToken = try? sessionToken()
        let client = KeyValueEngineClient(
            apiURL: apiURL,
            clientTransport: clientTransport,
            namespace: namespaceName,
            mountPath: mountPath,
            middlewares: middlewares,
            token: sessionToken,
            logger: logger
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
    ///   - namespace: optional child namespace to add to the parent namespace
    ///   - mountPath: mount path of database secrets
    ///   - execute: action closure to execute with the database client
    /// - Returns: return type of the `execute` closure
    public func withDatabaseClient<ReturnType: Sendable>(
        namespace: String? = nil,
        mountPath: String,
        execute: (DatabaseEngineClient) async throws -> ReturnType
    ) async throws -> ReturnType {
        let namespaceMiddleware = try self.namespace.middleware(namespace?.removeSlash())
        let namespaceName = namespaceMiddleware.first?.name ?? "root"
        let sessionToken = try? sessionToken()
        let client = DatabaseEngineClient(
            apiURL: apiURL,
            clientTransport: clientTransport,
            namespace: namespaceName,
            mountPath: mountPath,
            middlewares: middlewares + namespaceMiddleware,
            token: sessionToken,
            logger: logger
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
    /// - Parameter namespace: optional child namespace to add to the parent namespace
    /// - Parameter execute: action closure to execute with the token-auth client
    /// - Returns: return type of the `execute` closure
    public func withTokenAuthClient<ReturnType: Sendable>(
        namespace: String? = nil,
        execute: (TokenAuthClient) async throws -> ReturnType
    ) async throws -> ReturnType {
        let namespaceMiddleware = try self.namespace.middleware(namespace?.removeSlash())
        let namespaceName = namespaceMiddleware.first?.name ?? "root"
        let sessionToken = try? sessionToken()
        let client = TokenAuthClient(
            apiURL: apiURL,
            namespace: namespaceName,
            clientTransport: clientTransport,
            middlewares: middlewares + namespaceMiddleware,
            token: sessionToken,
            logger: logger
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
    /// - Parameter namespace: optional child namespace to add to the parent namespace.
    /// - Parameter mountPath: path to approle authentication mount
    /// - Parameter execute: action closure to execute with the approle-auth client
    /// - Returns: return type of the `execute` closure
    public func withAppRoleClient<ReturnType: Sendable>(
        namespace: String? = nil,
        mountPath: String,
        execute: (AppRoleAuthClient) async throws -> ReturnType
    ) async throws -> ReturnType {
        let namespaceMiddleware = try self.namespace.middleware(namespace?.removeSlash())
        let namespaceName = namespaceMiddleware.first?.name ?? "root"
        let sessionToken = try? sessionToken()
        let client = AppRoleAuthClient(
            apiURL: apiURL,
            clientTransport: clientTransport,
            namespace: namespaceName,
            mountPath: mountPath,
            middlewares: middlewares + namespaceMiddleware,
            token: sessionToken,
            logger: logger
        )
        return try await execute(client)
    }
#endif

#if TransitEngineSupport
    /// Handler to interact with the Transit secret engine endpoints
    ///
    /// A Transit secret engine client is created with the current session token and middlewares
    ///
    /// ## Package traits
    ///
    /// This handler is guarded by the `TransitEngineSupport` package trait.
    ///
    /// - Parameter namespace: optional child namespace to add to the parent namespace.
    /// - Parameter mountPath: path to transit secret mount
    /// - Parameter execute: action closure to execute with the transit client
    /// - Returns: return type of the `execute` closure
    public func withTransitClient<ReturnType: Sendable>(
        namespace: String? = nil,
        mountPath: String,
        execute: (TransitEngineClient) async throws -> ReturnType
    ) async throws -> ReturnType {
        let namespaceMiddleware = try self.namespace.middleware(namespace?.removeSlash())
        let namespaceName = namespaceMiddleware.first?.name ?? "root"
        let sessionToken = try? sessionToken()
        let client = TransitEngineClient(
            apiURL: apiURL,
            clientTransport: clientTransport,
            namespace: namespaceName,
            mountPath: mountPath,
            middlewares: middlewares + namespaceMiddleware,
            token: sessionToken,
            logger: logger
        )
        return try await execute(client)
    }
#endif
}
