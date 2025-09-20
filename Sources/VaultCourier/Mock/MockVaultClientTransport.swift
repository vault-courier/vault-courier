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

public struct MockVaultClientTransport: ClientTransport {
    public var sendBlock: @Sendable (HTTPRequest, HTTPBody?, URL, String) async throws -> (HTTPResponse, HTTPBody?)

    public func send(_ request: HTTPRequest, body: HTTPBody?, baseURL: URL, operationID: String) async throws -> (
        HTTPResponse, HTTPBody?
    ) { try await sendBlock(request, body, baseURL, operationID) }

    public init(sendBlock: @Sendable @escaping (HTTPRequest, HTTPBody?, URL, String) async throws -> (HTTPResponse, HTTPBody?)) {
        self.sendBlock = sendBlock
    }

    public static let requestBody: HTTPBody = HTTPBody("hello")
    public static let responseBody: HTTPBody = HTTPBody("bye")

    public static var successful: Self { MockVaultClientTransport { _, _, _, _ in (HTTPResponse(status: .ok), responseBody) } }

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
    public static func vaultData(_ response: some Encodable) async throws -> HTTPBody {
        return .vaultData(response)
    }

    /// Response body of login auth response
    public static func vaultAuth(_ response: VaultAuthResponse) async throws -> HTTPBody {
        return .vaultAuth(response)
    }

    /// Response body of wrapping endpoint
    public static func vaultWrapped(_ response: WrappedTokenResponse) async throws -> HTTPBody {
        return .vaultWrap(response)
    }

    public static func appRoleSecret(_ response: GenerateAppSecretIdResponse) -> HTTPBody {
        return .appRoleSecret(response)
    }
}

extension HTTPBody {
    static func vaultData(_ response: some Encodable) -> Self {
        guard let encoded = try? JSONEncoder().encode(response) else {
            return .init()
        }
        return .init(encoded)
    }
    static func vaultAuth(_ response: VaultAuthResponse) -> Self {
        guard let encoded = try? JSONEncoder().encode(response) else {
            return .init()
        }
        return .init(encoded)
    }

    static func vaultWrap(_ response: WrappedTokenResponse) -> Self {
        guard let encoded = try? JSONEncoder().encode(response) else {
            return .init()
        }
        return .init(encoded)
    }

    static func appRoleSecret(_ response: GenerateAppSecretIdResponse) -> Self {
        guard let encoded = try? JSONEncoder().encode(response) else {
            return .init()
        }
        return .init(encoded)
    }
}
#endif
