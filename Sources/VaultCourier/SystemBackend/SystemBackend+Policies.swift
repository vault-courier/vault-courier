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
import struct Foundation.URL
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
        _ policy: ACLPolicyHCL
    ) async throws {
        let sessionToken = policies.token

        let response = try await policies.client.policiesWriteAclPolicy(.init(
            path: .init(name: policy.name),
            headers: .init(xVaultToken: sessionToken),
            body: .json(.init(policy: policy.policy)))
        )

        switch response {
            case .noContent:
                logger.info("Policy '\(policy.name)' written successfully!")
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                throw VaultClientError.badRequest(errors)
            case .undocumented(let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode)."))
                throw VaultClientError.operationFailed(statusCode)
        }
    }

    /// Add a new or update an existing ACL policy.
    ///
    /// - Parameters:
    ///   - name: name of the policy
    ///   - contentOf: URL to a ACL policy in HCL format
    public func createPolicy(
        name: String,
        contentOf: URL
    ) async throws {
        let policy = try String(contentsOf: contentOf, encoding: .utf8)
        try await createPolicy(.init(name: name, policy: policy))
    }

    public func readPolicy(name: String) async throws -> ACLPolicyHCL {
        let sessionToken = policies.token

        let response = try await policies.client.policiesReadAclPolicy(.init(
            path: .init(name: name),
            headers: .init(xVaultToken: sessionToken))
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                return .init(name: json.data.name, policy: json.data.policy)
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                throw VaultClientError.badRequest(errors)
            case .undocumented(let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode)."))
                throw VaultClientError.operationFailed(statusCode)
        }
    }
    
    /// Deletes an ACL policy
    /// - Parameter name: name of ACL policy
    public func deletePolicy(name: String) async throws {
        let sessionToken = policies.token

        let response = try await policies.client.policiesDeleteAclPolicy(.init(
            path: .init(name: name),
            headers: .init(xVaultToken: sessionToken))
        )

        switch response {
            case .noContent:
                logger.info("Policy '\(name)' deleted")
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                throw VaultClientError.badRequest(errors)
            case .undocumented(let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode)."))
                throw VaultClientError.operationFailed(statusCode)
        }
    }
}
