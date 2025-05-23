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

import OpenAPIRuntime
#if canImport(FoundationEssentials)
import FoundationEssentials
import protocol Foundation.LocalizedError
#else
import struct Foundation.URL
import class Foundation.JSONDecoder
import class Foundation.JSONEncoder
import struct Foundation.Data
import protocol Foundation.LocalizedError
#endif

extension VaultClient {
    /// Creates a new version of a secret at the specified location. If the value does not yet exist, the calling token must have an ACL policy granting the create capability.
    /// If the value already exists, the calling token must have an ACL policy granting the update capability.
    ///
    /// - Parameters:
    ///   - enginePath: path to key/value secret engine mount
    ///   - secret: value of the secret. It must be a codable object or a dictionary.
    ///   - key: It's the path of the secret to update
    /// - Returns: Metadata about the secret, like its current version and creation time
    @discardableResult
    public func writeKeyValue(
        enginePath: String? = nil,
        secret: some Codable,
        key: String
    ) async throws -> KeyValueResponse<Never>? {
        let enginePath = enginePath ?? self.mounts.kv.relativePath.removeSlash()
        let sessionToken = try sessionToken()

        let data = try JSONEncoder().encode(secret)
        let json: OpenAPIObjectContainer
        do {
            json = try JSONDecoder().decode(OpenAPIObjectContainer.self, from: data)
        } catch {
            throw VaultClientError.invalidSecretType()
        }

        let response = try await client.writeKvSecrets(
            path: .init(kvPath: enginePath, secretKey: key),
            headers: .init(xVaultToken: sessionToken),
            body: .json(.init(
                options: .init(cas: nil),
                data: json)
            )
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                return .init(payload: json)
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                return nil
            case .undocumented(let statusCode, let payload):
                if let buffer = try await payload.body?.collect(upTo: 1024, using: .init()) {
                    let error = String(buffer: buffer)
                    logger.debug(.init(stringLiteral: "operation error with body: \(error)"))
                }
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode)"))
                return nil
        }
    }

    /// Retrieves the secret at the specified path location.
    ///
    /// - Parameters:
    ///   - enginePath: path to key/value secret engine mount
    ///   - key: It's the path to the secret relative to the secret mount `enginePath`
    ///   - version: Specifies the version to return. If not set the latest version is returned.
    /// - Returns: value of the secret
    public func readKeyValueSecret<T: Decodable & Sendable>(
        enginePath: String? = nil,
        key: String,
        version: Int? = nil
    ) async throws -> T? {
        let enginePath = enginePath ?? self.mounts.kv.relativePath.removeSlash()
        let sessionToken = try sessionToken()

        let response = try await client.readKvSecrets(
            path: .init(kvPath: enginePath, secretKey: key),
            query: .init(version: version),
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                let data = try JSONEncoder().encode(json.data.data)
                return try JSONDecoder().decode(T.self, from: data)
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                return nil
            case .undocumented(statusCode: let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode)."))
                return nil
        }
    }

    /// Retrieves the secret at the specified path location.
    ///
    /// - Parameters:
    ///   - enginePath: path to key/value secret engine mount
    ///   - key: It's the path to the secret relative to the secret mount `enginePath`
    ///   - version: Specifies the version to return. If not set the latest version is returned.
    /// - Returns: Data of the secret
    public func readKeyValueSecretData(
        enginePath: String? = nil,
        key: String,
        version: Int? = nil,
        subkeysDepth: Int? = nil
    ) async throws -> Data? {
        let enginePath = enginePath ?? self.mounts.kv.relativePath.removeSlash()
        let sessionToken = try sessionToken()

        let response = try await client.readKvSecrets(
            path: .init(kvPath: enginePath, secretKey: key),
            query: .init(version: version),
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                let data = try JSONEncoder().encode(json.data.data)
                return data
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                return nil
            case .undocumented(statusCode: let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                return nil
        }
    }

    /// Provides the subkeys within a secret entry that exists at the requested path. The secret entry at this path will be retrieved and stripped of all data by replacing underlying values of leaf keys (i.e. non-map keys or map keys with no underlying subkeys) with null.
    ///
    /// - Parameters:
    ///   - enginePath: path to key/value secret engine mount
    ///   - key: It's the path to the secret relative to the secret mount `enginePath`
    ///   - version: Specifies the version to return. If not set the latest version is returned.
    ///   - depth: Specifies the deepest nesting level to provide in the output. The default value `nil` will not impose any limit. If non-zero, keys that reside at the specified depth value will be artificially treated as leaves and will thus be null even if further underlying subkeys exist.
    /// - Returns: Data corresponding to stripped subkeys
    public func readSecretSubkeys(
        enginePath: String? = nil,
        key: String,
        version: Int? = nil,
        depth: Int? = nil
    ) async throws -> Data? {
        let enginePath = enginePath ?? self.mounts.kv.relativePath.removeSlash()
        let sessionToken = try sessionToken()

        let response = try await client.subkeysKvSecrets(
            path: .init(kvPath: enginePath, secretKey: key),
            query: .init(version: version, depth: depth),
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                let data = try JSONEncoder().encode(json.data.subkeys)
                return data
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                return nil
            case .undocumented(statusCode: let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                return nil
        }
    }

    /// Provides the ability to patch an existing secret at the specified location. The secret must neither be deleted nor destroyed. The client token must have an ACL policy granting the patch capability.
    ///
    /// A new version will be created upon successfully applying a patch with the provided data.
    /// - Parameters:
    ///   - enginePath: path to key/value secret engine mount
    ///   - secret: value of the secret. It must be a codable object or a dictionary.
    ///   - key: It's the path to the secret relative to the secret mount `enginePath`
    /// - Returns: Metadata associated to the secret.
    @discardableResult
    public func patchKeyValue(
        enginePath: String? = nil,
        secret: some Codable,
        key: String
    ) async throws -> KeyValueResponse<Never>? {
        let enginePath = enginePath ?? self.mounts.kv.relativePath.removeSlash()
        let sessionToken = try sessionToken()

        let data = try JSONEncoder().encode(secret)
        let json: OpenAPIObjectContainer
        do {
            json = try JSONDecoder().decode(OpenAPIObjectContainer.self, from: data)
        } catch {
            throw VaultClientError.invalidSecretType()
        }

        let response = try await client.patchKvSecrets(
            path: .init(kvPath: enginePath, secretKey: key),
            headers: .init(xVaultToken: sessionToken),
            body: .applicationMergePatchJson(.init(
                options: .init(cas: nil),
                data: json))
            )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                return .init(payload: json)
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                return nil
            case .undocumented(let statusCode, let payload):
                if let buffer = try await payload.body?.collect(upTo: 1024, using: .init()) {
                    let error = String(buffer: buffer)
                    logger.debug(.init(stringLiteral: "operation error with body: \(error)"))
                }
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode)"))
                return nil
        }
    }

    /// This endpoint issues a soft delete of the secret's latest version at the specified location.
    /// 
    /// This marks the version as deleted and will stop it from being returned from reads, but the underlying data will not be removed.
    ///
    /// A delete can be undone using the ``undelete(key:, versions:)`` operation.
    /// - Parameter key: It's the path to the secret relative to the secret mount `enginePath`
    /// - Parameter versions: The versions to be deleted. The versioned data will not be deleted, but it will no longer be returned in the read secret operations. Defaults to empty array, which deletes the latest version.
    public func delete(key: String, versions: [String] = []) async throws {
        let enginePath = self.mounts.kv.relativePath.removeSlash()
        let sessionToken = try sessionToken()

        if versions.isEmpty {
            let response = try await client.deleteLatestKvSecrets(
                path: .init(kvPath: enginePath, secretKey: key),
                headers: .init(xVaultToken: sessionToken)
            )

            switch response {
                case .noContent:
                    logger.info("secret deleted successfully")
                case .badRequest(let content):
                    let errors = (try? content.body.json.errors) ?? []
                    logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                    throw VaultClientError.badRequest(errors)
                case .undocumented(statusCode: let statusCode, _):
                    logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                    throw VaultClientError.operationFailed(statusCode)
            }
        } else {
            let response = try await client.deleteKvSecrets(
                path: .init(kvPath: enginePath, secretKey: key),
                headers: .init(xVaultToken: sessionToken),
                body: .json(.init(versions: versions))
            )

            switch response {
                case .noContent:
                    logger.info("secret deleted successfully")
                case .badRequest(let content):
                    let errors = (try? content.body.json.errors) ?? []
                    logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                    throw VaultClientError.badRequest(errors)
                case .undocumented(statusCode: let statusCode, _):
                    logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                    throw VaultClientError.operationFailed(statusCode)
            }
        }
    }

    /// Undeletes the data for the provided version and path in the key-value store. This restores the data, allowing it to be returned on get requests.
    ///
    /// This reverses the  ``delete(key:, versions:)`` operation.
    ///
    /// - Parameters:
    ///   - key: It's the path to the secret relative to the secret mount `enginePath`
    ///   - versions: The versions to undelete. The versions will be restored and their data will be returned on normal read secret requests.
    public func undelete(key: String, versions: [String]) async throws {
        let enginePath = self.mounts.kv.relativePath.removeSlash()
        let sessionToken = try sessionToken()

        let response = try await client.undeleteKvSecrets(
            path: .init(kvPath: enginePath, secretKey: key),
            headers: .init(xVaultToken: sessionToken),
            body: .json(.init(versions: versions))
        )

        switch response {
            case .noContent:
                logger.info("secret undeleted successfully")
                return
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .undocumented(statusCode: let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }

    public func writeMetadata(
        key: String,
        isCasRequired: Bool = false,
        customMetadata: [String: String],
        deleteVersionAfter: String? = nil,
        versionLimit: Int = 10
    ) async throws {
        let enginePath = self.mounts.kv.relativePath.removeSlash()
        let sessionToken = try sessionToken()

        let response = try await client.updateMetadataKvSecrets(
            path: .init(kvPath: enginePath, secretKey: key),
            headers: .init(xVaultToken: sessionToken),
            body: .json(.init(
                casRequired: isCasRequired,
                customMetadata: .init(additionalProperties: customMetadata),
                deleteVersionAfter: deleteVersionAfter ?? "",
                maxVersions: versionLimit)
            )
        )

        switch response {
            case .noContent:
                logger.info("Secret metadata updated.")
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .undocumented(statusCode: let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }

    public func readMetadata(key: String) async throws -> KeyValueStoreMetadata {
        let enginePath = self.mounts.kv.relativePath.removeSlash()
        let sessionToken = try sessionToken()
        
        let response = try await client.readMetadataKvSecrets(
            path: .init(kvPath: enginePath, secretKey: key),
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                return try json.metadata
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .undocumented(statusCode: let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }
}
