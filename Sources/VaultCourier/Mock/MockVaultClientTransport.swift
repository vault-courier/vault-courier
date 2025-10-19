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

#if MockSupport
import HTTPTypes
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.URL
import class Foundation.JSONDecoder
import class Foundation.JSONEncoder
import struct Foundation.Data
#endif
import OpenAPIRuntime
import Utils

public struct MockVaultClientTransport: ClientTransport {
    public var sendBlock: @Sendable (HTTPRequest, HTTPBody?, URL, String) async throws -> (HTTPResponse, HTTPBody?)

    public func send(_ request: HTTPRequest, body: HTTPBody?, baseURL: URL, operationID: String) async throws -> (
        HTTPResponse, HTTPBody?
    ) { try await sendBlock(request, body, baseURL, operationID) }

    public init(sendBlock: @Sendable @escaping (HTTPRequest, HTTPBody?, URL, String) async throws -> (HTTPResponse, HTTPBody?)) {
        self.sendBlock = sendBlock
    }

    /// Require authentication before processing request
    ///
    /// Example of use:
    ///  ```
    ///    return try await withRequiredAuthentication(req: req, clientToken: clientToken) { _, _ in
    ///        try await encode(response:
    ///            RoleCredentialsResponse(
    ///            requestID: "",
    ///            username: dynamicRoleDatabaseUsername,
    ///            password: dynamicRoleDatabasePassword,
    ///            timeToLive: .seconds(86400),
    ///            updatedAt: "")
    ///        )
    ///    }
    /// ```
    public static func withRequiredAuthentication(
        req: HTTPRequest,
        body: HTTPBody? = nil,
        clientToken: String,
        _ next: @escaping @Sendable (HTTPRequest, HTTPBody?) async throws -> HTTPBody?)
    async throws -> (HTTPResponse, HTTPBody?) {
        guard req.headerFields[VaultHeaderName.vaultToken] == clientToken else {
            return (.init(status: .unauthorized), nil)
        }
        let responseBody = try await next(req, body)
        return (.init(status: .ok), responseBody)
    }

    public static var successful: Self { MockVaultClientTransport { _, _, _, _ in (HTTPResponse(status: .ok), HTTPBody("bye")) } }

    public static var forbidden: Self { MockVaultClientTransport { _, _, _, _ in (HTTPResponse(status: .forbidden), HTTPBody("error")) } }

    /// KeyValue response body
    ///
    /// Encodes the input `data` inside a response body of the form
    ///
    ///     {
    ///       "request_id": "request_id",
    ///        "data": {
    ///          "data": input
    ///        }
    ///     }
    ///
    public static func encodeKeyValue(data: some Codable) async throws -> HTTPBody {
        guard let encoded = try? JSONEncoder().encode(data)
        else { return .init() }

        let json = String(data: encoded, encoding: .utf8) ?? "null"
        return HTTPBody("""
        {
          "request_id": "request_id",
          "data": {
            "data": \(json)
          }
        }
        """)
    }

    /// Response body which encodes any encodable input as it is
    public static func encode(response: some Encodable) async throws -> HTTPBody {
        return .vaultData(response)
    }
}

extension MockVaultClientTransport {
    struct TokenBody: Decodable {
        let token: String
    }

    /// Client transport with approle login, unwrap and database and kv secrets mocked endpoints
    public static func dev(
        clientToken: String = "client_token",
        apppRoleMountPath: String = "approle",
        appRoleName: String = "test_role_name",
        wrappedToken: String = "secret_wrap_id",
        expectedSecretID: String = "secret_id",
        databaseMount: String = "database_mount_path",
        staticRole: String = "test_static_role",
        staticRoleDatabaseUsername: String = "test_database_username",
        staticRoleDatabasePassword: String = "test_database_password",
        dynamicRole: String = "test_dynamic_role",
        dynamicRoleDatabaseUsername: String = "test_database_username",
        dynamicRoleDatabasePassword: String = "test_dynamic_database_password",
        keyValueMount: String = "key_value_mount_path",
        secretKeyPath: String = "secret_key_path",
        expectedSecrets: some Codable & Sendable
    ) -> Self {
        MockVaultClientTransport { req, body, _, _ in
            switch req.normalizedPath {
                case "/auth/\(apppRoleMountPath)/login":
                    return (.init(status: .ok),
                            try await Self.encode(response:
                                                    VaultAuthResponse(
                                                        requestID: "bb10149f-39dd-8261-a427-d52e64922355",
                                                        clientToken: clientToken,
                                                        accessor: "accessor_token",
                                                        tokenPolicies: ["default"],
                                                        metadata: ["tag1": "development"],
                                                        leaseDuration: .seconds(3600*24),
                                                        isRenewable: true,
                                                        entityID: "913160eb-837f-ee8c-e6aa-9ded162b5b75",
                                                        tokenType: .batch,
                                                        isOrphan: true,
                                                        numberOfUses: 0
                                                    )
                                                 )
                    )
                case "/auth/\(apppRoleMountPath)/role/\(appRoleName)/secret-id":
                    // This endpoint is actually called from an operations job
                    if req.headerFields.contains(VaultHeaderName.wrapTTL) {
                        return (.init(status: .ok),
                                try await Self.encode(response:
                                                        WrappedTokenResponse(
                                                            requestID: "bb10149f-39dd-8261-a427-d52e64922356",
                                                            token: wrappedToken,
                                                            accessor: "accessor_token",
                                                            timeToLive: 120,
                                                            createdAt: .now,
                                                            creationPath: "auth/\(apppRoleMountPath)/role/\(appRoleName)/secret-id",
                                                            wrappedAccessor: "54d4834d-aa0e-8f19-3286-7a172370ae7b")
                                                     )
                        )
                    } else {
                        return (.init(status: .ok),
                                try await Self.encode(response:
                                                        GenerateAppSecretIdResponse(
                                                            requestID: "81ac0ea6-610d-61df-4039-9aab7cc5bf05",
                                                            secretID: expectedSecretID,
                                                            secretIDAccessor: "e69a33c6-af8e-0ca1-fbc7-63a35ca50d33",
                                                            secretIDTimeToLive: .seconds(86400),
                                                            secretIDNumberOfUses: 2
                                                        )
                                                     )
                        )
                    }
                case "/sys/wrapping/unwrap":
                    let clientToken = req.headerFields[VaultHeaderName.vaultToken]
                    let tokenBody: String? = if let body {
                        try await JSONDecoder().decode(TokenBody.self, from: Data(collecting: body, upTo: 1024*1024)).token
                    } else {
                        nil
                    }

                    guard tokenBody != clientToken else {
                        return (.init(status: .badRequest), nil)
                    }

                    if let tokenBody {
                        guard tokenBody == wrappedToken else {
                            return (.init(status: .unauthorized),nil)
                        }
                    } else {
                        guard clientToken == wrappedToken else {
                            return (.init(status: .unauthorized),nil)
                        }
                    }
                    return (.init(status: .ok),
                            try await encode(response:
                                                GenerateAppSecretIdResponse(
                                                    requestID: "81ac0ea6-610d-61df-4039-9aab7cc5bf05",
                                                    secretID: expectedSecretID,
                                                    secretIDAccessor: "e69a33c6-af8e-0ca1-fbc7-63a35ca50d33",
                                                    secretIDTimeToLive: .seconds(86400),
                                                    secretIDNumberOfUses: 2
                                                )
                                            )
                    )
                case "/\(databaseMount)/static-creds/\(staticRole)":
                    guard req.headerFields[VaultHeaderName.vaultToken] == clientToken else {
                        return (.init(status: .unauthorized), nil)
                    }
                    return (
                        .init(status: .ok),
                        try await MockVaultClientTransport.encode(response:
                                                                    StaticRoleCredentialsResponse(
                                                                        requestID: "aa10149f-39dd-8261-a427-d52e64922357",
                                                                        username: staticRoleDatabaseUsername,
                                                                        password: staticRoleDatabasePassword,
                                                                        timeToLive: .seconds(86400),
                                                                        updatedAt: .now,
                                                                        rotation: .period(.seconds(86400)))
                                                                 )
                    )
                case "/\(databaseMount)/creds/\(dynamicRole)":
                    guard req.headerFields[VaultHeaderName.vaultToken] == clientToken else {
                        return (.init(status: .unauthorized), nil)
                    }
                    return (
                        .init(status: .ok),
                        try await Self.encode(response:
                                                RoleCredentialsResponse(
                                                    requestID: "cc10149f-39dd-8261-a427-d52e64922355",
                                                    username: dynamicRoleDatabaseUsername,
                                                    password: dynamicRoleDatabasePassword,
                                                    timeToLive: .seconds(86400))
                                             )
                    )
                case "/\(keyValueMount)/data/\(secretKeyPath)",
                    "/\(keyValueMount)/data/\(secretKeyPath)?version=2":
                    guard req.headerFields[VaultHeaderName.vaultToken] == clientToken else {
                        return (.init(status: .unauthorized), nil)
                    }
                    return (
                        .init(status: .ok),
                        try await Self.encodeKeyValue(data: (expectedSecrets))
                    )
                default:
                    throw MockClientTransportError()
            }
        }
    }
}

extension HTTPBody {
    static func vaultData(_ response: some Encodable) -> Self {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            let dateAsString = try VaultDateTranscoder().encode(date)
            var container = encoder.singleValueContainer()
            try container.encode(dateAsString)
        }
        guard let encoded = try? encoder.encode(response) else {
            return .init()
        }
        return .init(encoded)
    }
}

public struct MockClientTransportError: Error, Equatable {}

extension HTTPRequest {
    var normalizedPath: String? {
        self.path?.replacingOccurrences(of: "%2F", with: "/")
    }
}
#endif
