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
import struct Foundation.URL
#endif
import OpenAPIRuntime
import SystemPolicies
import Logging
import Tracing
import Utils

extension SystemBackend {
    /// Add a new or update an existing ACL policy.
    ///
    /// - Parameters:
    ///   - policy: policy in hcl format
    public func createPolicy(
        _ policy: ACLPolicyHCL
    ) async throws {
        return try await withSpan(Operations.PoliciesWriteAclPolicy.id, ofKind: .client) { span in
            let sessionToken = policies.token

            let response = try await policies.client.policiesWriteAclPolicy(.init(
                path: .init(name: policy.name),
                headers: .init(xVaultToken: sessionToken),
                body: .json(.init(policy: policy.policy)))
            )

            switch response {
                case .noContent:
                    let eventName = "policy written"
                    span.attributes[TracingSupport.AttributeKeys.responseStatusCode] = 204
                    span.addEvent(.init(name: eventName, attributes: ["name": .string(policy.name)]))
                    logger.trace(.init(stringLiteral: eventName), metadata: ["name": .string(policy.name)])
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
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
        return try await withSpan(Operations.PoliciesReadAclPolicy.id, ofKind: .client) { span in
            let sessionToken = policies.token

            let response = try await policies.client.policiesReadAclPolicy(.init(
                path: .init(name: name),
                headers: .init(xVaultToken: sessionToken))
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json
                    let vaultRequestID = json.requestId
                    TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)
                    logger.trace(
                        .init(stringLiteral: "read policy"),
                        metadata: [
                            TracingSupport.AttributeKeys.vaultRequestID: .string(vaultRequestID),
                    ])
                    return .init(name: json.data.name, policy: json.data.policy)
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }
    
    /// Deletes an ACL policy
    /// - Parameter name: name of ACL policy
    public func deletePolicy(name: String) async throws {
        return try await withSpan(Operations.PoliciesDeleteAclPolicy.id, ofKind: .client) { span in
            let sessionToken = policies.token

            let response = try await policies.client.policiesDeleteAclPolicy(.init(
                path: .init(name: name),
                headers: .init(xVaultToken: sessionToken))
            )

            switch response {
                case .noContent:
                    let eventName = "policy deleted"
                    span.attributes[TracingSupport.AttributeKeys.responseStatusCode] = 204
                    span.addEvent(.init(name: eventName, attributes: ["name": .string(name)]))
                    logger.trace(.init(stringLiteral: eventName), metadata: ["name": .string(name)])
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }
}
