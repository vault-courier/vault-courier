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

import Testing
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.URL
#endif
import OpenAPIRuntime
import OpenAPIAsyncHTTPClient
import VaultCourier
import Logging

extension VaultClient {
    @TaskLocal static var current = VaultClient(
        configuration: .init(apiURL: try! URL(validatingOpenAPIServerURL: "http://127.0.0.1:8200/v1")),
        client: Client(
            serverURL: try! URL(validatingOpenAPIServerURL: "http://127.0.0.1:8200/v1"),
            transport: AsyncHTTPClientTransport()
        ),
        authentication: .token("integration_token")
    )
}

struct VaultClientTrait: SuiteTrait, TestTrait, TestScoping {
    let apiURL: URL
    let token: String

    func setupClient() async throws -> VaultClient {
        let vaultClient = VaultClient(configuration: .init(apiURL: apiURL),
                                      client: Client(
                                        serverURL: apiURL,
                                        transport: AsyncHTTPClientTransport()
                                      ),
                                      authentication: .token(token))
        try await vaultClient.authenticate()
        return vaultClient
    }

    func provideScope(for test: Test, testCase: Test.Case?, performing function: @Sendable () async throws -> Void) async throws {
        let vaultClient = try await setupClient()
        try await VaultClient.$current.withValue(vaultClient) {
            try await function()
        }
    }
}

extension SuiteTrait where Self == VaultClientTrait {
    static func setupVaultClient(apiURL: URL = try! URL(validatingOpenAPIServerURL: "http://127.0.0.1:8200/v1"),
                                 token: String = "integration_token") -> Self {
        return Self(apiURL: apiURL, token: token)
    }
}

// MARK: Mock

struct MockVaultClient: SuiteTrait, TestTrait, TestScoping {
    let apiURL: URL
    let token: String
    let readerSchema: String?
    let appRolePath: String?
    let kvMountPath: String?
    let databaseMountPath: String?
    let logger: Logger?
    let middlewares: [any ClientMiddleware]

    func setupClient() async throws -> VaultClient {
        let vaultClient = VaultClient(configuration: .init(apiURL: apiURL,
                                                           readerSchema: readerSchema,
                                                           appRolePath: appRolePath,
                                                           kvMountPath: kvMountPath,
                                                           databaseMountPath: databaseMountPath,
                                                           backgroundActivityLogger: logger,
                                                           middlewares: middlewares),
                                      client: MockClient(),
                                      authentication: .token(token))
        return vaultClient
    }

    func provideScope(for test: Test, testCase: Test.Case?, performing function: @Sendable () async throws -> Void) async throws {
        let vaultClient = try await setupClient()
        try await VaultClient.$current.withValue(vaultClient) {
            try await function()
        }
    }
}

extension TestTrait where Self == MockVaultClient {
    static func setupMockVaultClient(apiURL: URL = try! URL(validatingOpenAPIServerURL: "http://127.0.0.1:8200/v1"),
                                     token: String = "test_token",
                                     readerSchema: String? = nil,
                                     appRolePath: String? = nil,
                                     kvMountPath: String? = nil,
                                     databaseMountPath: String? = nil,
                                     logger: Logger? = nil,
                                     middlewares: [any ClientMiddleware] = []) -> Self {
        return Self(apiURL: apiURL,
                    token: token,
                    readerSchema: readerSchema,
                    appRolePath: appRolePath,
                    kvMountPath: kvMountPath,
                    databaseMountPath: databaseMountPath,
                    logger: logger,
                    middlewares: middlewares)
    }
}
