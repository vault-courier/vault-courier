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
import Foundation
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
#endif
