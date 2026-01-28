//===----------------------------------------------------------------------===//
//  Copyright (c) 2026 Javier Cuesta
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

import OpenAPIRuntime
import SystemNamespaces
import Logging
import Tracing
import Utils

extension SystemBackend {
    /// Creates a new namespace under the current client's namespace
    /// - Parameters:
    ///   - name: name of the namespace
    ///   - metadata: user-provided metadata for description of the namespace
    /// - Returns: Namespace information including unique IDs
    public func createNamespace(
        _ name: String,
        metadata: [String: String] = [:]
    ) async throws -> NamespaceResponse {
        return try await withSpan(Operations.WriteNamespace.id, ofKind: .client) { span in
            let sessionToken = self.namespaces.token

            let response = try await self.namespaces.client.writeNamespace(.init(
                path: .init(path: name),
                headers: .init(xVaultToken: sessionToken),
                body: .json(.init(customMetadata: .init(additionalProperties: metadata))))
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json

                    let vaultRequestID = json.requestId
                    TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)
                    logger.trace(
                        .init(stringLiteral: "namespace created"),
                        metadata: [
                            TracingSupport.AttributeKeys.vaultRequestID: .string(vaultRequestID),
                            TracingSupport.AttributeKeys.vaultNamespace: .string(namespace),
                            "vault.namespace.path": .string(name),
                            "vault.namespace.metadata": .dictionary(metadata.mapValues(Logger.MetadataValue.string))
                    ])

                    return .init(
                        requestID: vaultRequestID,
                        id: json.data.id,
                        metadata: json.data.customMetadata?.additionalProperties ?? [:],
                        isLocked: json.data.locked,
                        isTainted: json.data.tainted,
                        path: json.data.path,
                        uuid: json.data.uuid
                    )
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }

    /// Patches existing namespace with new metadata
    /// - Parameters:
    ///   - name: name of namespace
    ///   - metadata: user-provided metadata for description of the namespace
    /// - Returns: Namespace information including unique IDs
    public func patchNamespace(
        _ name: String,
        metadata: [String: String] = [:]
    ) async throws -> NamespaceResponse {
        return try await withSpan(Operations.WriteNamespace.id, ofKind: .client) { span in
            let sessionToken = self.namespaces.token

            let response = try await self.namespaces.client.patchNamespace(.init(
                path: .init(path: name),
                headers: .init(xVaultToken: sessionToken),
                body: .applicationMergePatchJson(.init(customMetadata: .init(additionalProperties: metadata))))
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json

                    let vaultRequestID = json.requestId
                    TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)
                    logger.trace(
                        .init(stringLiteral: "namespace patched"),
                        metadata: [
                            TracingSupport.AttributeKeys.vaultRequestID: .string(vaultRequestID),
                            TracingSupport.AttributeKeys.vaultNamespace: .string(namespace),
                            "vault.namespace.path": .string(name),
                            "vault.namespace.metadata": .dictionary(metadata.mapValues(Logger.MetadataValue.string))
                    ])

                    return .init(
                        requestID: vaultRequestID,
                        id: json.data.id,
                        metadata: json.data.customMetadata?.additionalProperties ?? [:],
                        isLocked: json.data.locked,
                        isTainted: json.data.tainted,
                        path: json.data.path,
                        uuid: json.data.uuid
                    )
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }
    
    /// Namespace information
    /// - Parameter name: name of namespace
    /// - Returns: Namespace information including unique IDs
    public func readNamespace(
        _ name: String
    ) async throws -> NamespaceResponse {
        return try await withSpan(Operations.ReadNamespaceInfo.id, ofKind: .client) { span in
            let sessionToken = self.namespaces.token

            let response = try await self.namespaces.client.readNamespaceInfo(.init(
                path: .init(path: name),
                headers: .init(xVaultToken: sessionToken))
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json

                    let vaultRequestID = json.requestId
                    TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)
                    logger.trace(
                        .init(stringLiteral: "read namespace"),
                        metadata: [
                            TracingSupport.AttributeKeys.vaultRequestID: .string(vaultRequestID),
                            TracingSupport.AttributeKeys.vaultNamespace: .string(namespace),
                            "vault.namespace.path": .string(name)
                    ])

                    return .init(
                        requestID: vaultRequestID,
                        id: json.data.id,
                        metadata: json.data.customMetadata?.additionalProperties ?? [:],
                        isLocked: json.data.locked,
                        isTainted: json.data.tainted,
                        path: json.data.path,
                        uuid: json.data.uuid
                    )
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }

    
    /// Delete namespace
    /// - Parameter name: name of namespace
    /// - Returns: State of deletion: "in-progress" or "deleted"
    public func deleteNamespace(
        _ name: String
    ) async throws -> DeleteNamespaceState {
        return try await withSpan(Operations.DeleteNamespace.id, ofKind: .client) { span in
            let sessionToken = self.namespaces.token

            let response = try await self.namespaces.client.deleteNamespace(.init(
                path: .init(path: name),
                headers: .init(xVaultToken: sessionToken))
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json

                    let vaultRequestID = json.requestId
                    TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)
                    logger.trace(
                        .init(stringLiteral: "read namespace"),
                        metadata: [
                            TracingSupport.AttributeKeys.vaultRequestID: .string(vaultRequestID),
                            TracingSupport.AttributeKeys.vaultNamespace: .string(namespace),
                            "vault.namespace.path": .string(name)
                    ])

                    return .init(rawValue: json.data?.status ?? DeleteNamespaceState.deleted.rawValue) ?? .deleted
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }

}
