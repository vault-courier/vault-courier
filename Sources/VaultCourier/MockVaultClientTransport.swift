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

    public static func response(data: (some Codable)?) -> HTTPBody {
        let json: String
        if let data {
            let encoded = try? JSONEncoder().encode(data)
            json = if let encoded {
                String(data: encoded, encoding: .utf8) ?? "null"
            } else {
                "null"
            }
        } else {
            json = "null"
        }

        return HTTPBody("""
        {
          "request_id": "bb10149f-39dd-8261-a427-d52e64922355",
          "data": \(json),
        }
        """)
    }

    public static func vaultAuth(_ response: VaultAuthResponse) async throws -> HTTPBody {
        return .vaultAuth(response)
    }
}

extension HTTPBody {
    static func vaultAuth(_ response: VaultAuthResponse) -> Self {

        let tokenPolicies: String = if let encoded = try? JSONEncoder().encode(response.tokenPolicies) {
            String(data: encoded, encoding: .utf8) ?? "[]"
        } else {
            "[]"
        }

        let result = """
        {
          "request_id": "\(response.requestID ?? "")",
          "auth": {
            "client_token": "\(response.clientToken)",
            "accessor": "\(response.accessor)",
            "token_policies": \(tokenPolicies),
            "metadata": {
              "role_name": "my_role",
              "tag1": "production"
            },
            "lease_duration": \(response.leaseDuration.components.seconds),
            "renewable": \(response.isRenewable),
            "entity_id": "913160eb-837f-ee8c-e6aa-9ded162b5b75",
            "token_type": "\(response.tokenType.rawValue)",
            "orphan": \(response.isOrphan),
            "mfa_requirement": null,
            "num_uses": \(response.numberOfUses)
          }
        }
        """
        return .init(result)
    }
}
