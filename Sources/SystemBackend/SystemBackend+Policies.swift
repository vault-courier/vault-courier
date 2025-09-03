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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import class Foundation.JSONDecoder
import class Foundation.JSONEncoder
import struct Foundation.Data
#endif
import OpenAPIRuntime
import VaultUtilities

extension SystemBackend {
    /// Add a new or update an existing ACL policy.
    ///
    /// - Parameters:
    ///   - name: name of the policy
    ///   - hclPolicy: policy in hcl format
    public func createPolicy(
        name: String,
        hclPolicy: String
    ) async throws {
        let sessionToken = policies.token

        let response = try await policies.client.policiesWriteAclPolicy(.init(
            path: .init(name: name),
            headers: .init(xVaultToken: sessionToken),
            body: .json(.init(policy: hclPolicy)))
        )

        switch response {
            case .noContent:
                logger.info("Policy '\(name)' written successfully!")
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                throw VaultClientError.badRequest(errors)
            case .undocumented(let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode)."))
                throw VaultClientError.operationFailed(statusCode)
        }
    }
}
