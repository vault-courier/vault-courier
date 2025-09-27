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
#else
import struct Foundation.URL
import class Foundation.JSONDecoder
import class Foundation.JSONEncoder
import struct Foundation.Data
import struct Foundation.Date
#endif
import Synchronization
import Logging
import KeyValue

/// Client for Key/Value secret engine
///
/// - Note: You don't usually create this type directly, but instead use ``VaultClient/withKeyValueClient(mountPath:execute:)`` to interact with this type
public final class KeyValueEngineClient: Sendable {
    static var loggingDisabled: Logger { .init(label: "key-value-provider-do-not-log", factory: { _ in SwiftLogNoOpLogHandler() }) }

    init(apiURL: URL,
         clientTransport: any ClientTransport,
         mountPath: String,
         middlewares: [any ClientMiddleware] = [],
         token: String? = nil,
         logger: Logger? = nil) {
        self.engine = KeyValueEngine(
            configuration: .init(apiURL: apiURL, mountPath: mountPath),
            clientTransport: clientTransport,
            middlewares: middlewares,
            token: token)
        self.apiURL = apiURL
        self.mountPath = mountPath.removeSlash()
        self._token = .init(token)
        self.logger = logger ?? Self.loggingDisabled
    }

    /// Vault's base URL
    let apiURL: URL

    /// Mount path of KeyValue secret engine
    let mountPath: String

    /// Engine client
    let engine: KeyValueEngine

    let _token: Mutex<String?>

    /// Client token
    var token: String? {
        get {
            _token.withLock { $0 }
        }
        set {
            _token.withLock {
                $0 = newValue
            }
        }
    }

    let logger: Logging.Logger
}

extension KeyValueEngineClient {
    /// Creates a new version of a secret at the specified location. If the value does not yet exist, the calling token must have an ACL policy granting the create capability.
    /// If the value already exists, the calling token must have an ACL policy granting the update capability.
    ///
    /// - Parameters:
    ///   - secret: value of the secret. It must be a codable object or a dictionary.
    ///   - key: It's the path of the secret to update
    /// - Returns: Metadata about the secret, like its current version and creation time
    @discardableResult
    public func writeKeyValue(
        secret: some Codable,
        key: String
    ) async throws -> KeyValueMetadata {
        let sessionToken = self.engine.token
        let enginePath = self.engine.mountPath

        let data = try JSONEncoder().encode(secret)
        let json: OpenAPIObjectContainer
        do {
            json = try JSONDecoder().decode(OpenAPIObjectContainer.self, from: data)
        } catch {
            throw VaultClientError.invalidSecretType()
        }

        let response = try await engine.client.writeKvSecrets(
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
                let deletedAt: Date? = if case let .case1(date) = json.data.deletionTime {
                    date
                } else {
                    nil
                }
                return .init(
                    requestID: json.requestId,
                    createdAt: json.data.createdTime,
                    custom: json.data.customMetadata?.additionalProperties,
                    deletedAt: deletedAt,
                    isDestroyed: json.data.destroyed,
                    version: json.data.version
                )
            case let .undocumented(statusCode, payload):
                let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                throw vaultError
        }
    }

    /// Retrieves the secret at the specified path location.
    ///
    /// - Parameters:
    ///   - key: It's the path to the secret relative to the secret mount `enginePath`
    ///   - version: Specifies the version to return. If not set the latest version is returned.
    /// - Returns: value of the secret
    public func readKeyValueSecret<T: Decodable & Sendable>(
        key: String,
        version: Int? = nil
    ) async throws -> T {
        let sessionToken = self.engine.token
        let enginePath = self.engine.mountPath

        let response = try await engine.client.readKvSecrets(
            path: .init(kvPath: enginePath, secretKey: key),
            query: .init(version: version),
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                let data = try JSONEncoder().encode(json.data.data)
                return try JSONDecoder().decode(T.self, from: data)
            case let .undocumented(statusCode, payload):
                let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                throw vaultError
        }
    }

    /// Retrieves the secret at the specified path location.
    ///
    /// - Parameters:
    ///   - key: It's the path to the secret relative to the kv secret mount.
    ///   - version: Specifies the version to return. If not set the latest version is returned.
    /// - Returns: value of the secret with its requestID
    public func readKeyValue<T: Decodable & Sendable>(
        key: String,
        version: Int? = nil
    ) async throws -> KeyValueResponse<T> {
        let sessionToken = self.engine.token
        let enginePath = self.engine.mountPath

        let response = try await engine.client.readKvSecrets(
            path: .init(kvPath: enginePath, secretKey: key),
            query: .init(version: version),
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                let data = try JSONEncoder().encode(json.data.data)
                let secret = try JSONDecoder().decode(T.self, from: data)
                return .init(
                    requestID: json.requestId,
                    data: secret
                )
            case let .undocumented(statusCode, payload):
                let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                throw vaultError
        }
    }

    /// Retrieves the secret at the specified path location as Foundation `Data`.
    ///
    /// - Parameters:
    ///   - key: It's the path to the secret relative to the secret mount `enginePath`
    ///   - version: Specifies the version to return. If not set the latest version is returned.
    ///   - subkeysDepth: Specifies the deepest nesting level to provide in the output. The default value `nil` will not impose any limit.
    /// - Returns: Data of the secret
    public func readKeyValueSecretData(
        key: String,
        version: Int? = nil,
        subkeysDepth: Int? = nil
    ) async throws -> Data {
        let sessionToken = self.engine.token
        let enginePath = self.engine.mountPath

        let response = try await engine.client.readKvSecrets(
            path: .init(kvPath: enginePath, secretKey: key),
            query: .init(version: version),
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                let data = try JSONEncoder().encode(json.data.data)
                return data
            case let .undocumented(statusCode, payload):
                let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                throw vaultError
        }
    }

    /// Provides the subkeys within a secret entry that exists at the requested path. The secret entry at this path will be retrieved and stripped of all data by replacing underlying values of leaf keys (i.e. non-map keys or map keys with no underlying subkeys) with null.
    ///
    /// - Parameters:
    ///   - key: It's the path to the secret relative to the secret mount `enginePath`
    ///   - version: Specifies the version to return. If not set the latest version is returned.
    ///   - depth: Specifies the deepest nesting level to provide in the output. The default value `nil` will not impose any limit. If non-zero, keys that reside at the specified depth value will be artificially treated as leaves and will thus be null even if further underlying subkeys exist.
    /// - Returns: Data corresponding to stripped subkeys
    public func readSecretSubkeys(
        key: String,
        version: Int? = nil,
        depth: Int? = nil
    ) async throws -> Data {
        let sessionToken = self.engine.token
        let enginePath = self.engine.mountPath

        let response = try await engine.client.subkeysKvSecrets(
            path: .init(kvPath: enginePath, secretKey: key),
            query: .init(version: version, depth: depth),
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                let data = try JSONEncoder().encode(json.data.subkeys)
                return data
            case let .undocumented(statusCode, payload):
                let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                throw vaultError
        }
    }

    /// Provides the ability to patch an existing secret at the specified location. The secret must neither be deleted nor destroyed. The client token must have an ACL policy granting the patch capability.
    ///
    /// A new version will be created upon successfully applying a patch with the provided data.
    /// - Parameters:
    ///   - secret: value of the secret. It must be a codable object or a dictionary.
    ///   - key: It's the path to the secret relative to the secret mount `enginePath`
    /// - Returns: Metadata associated to the secret.
    @discardableResult
    public func patchKeyValue(
        secret: some Codable,
        key: String
    ) async throws -> KeyValueMetadata {
        let sessionToken = self.engine.token
        let enginePath = self.engine.mountPath

        let data = try JSONEncoder().encode(secret)
        let json: OpenAPIObjectContainer
        do {
            json = try JSONDecoder().decode(OpenAPIObjectContainer.self, from: data)
        } catch {
            throw VaultClientError.invalidSecretType()
        }

        let response = try await engine.client.patchKvSecrets(
            path: .init(kvPath: enginePath, secretKey: key),
            headers: .init(xVaultToken: sessionToken),
            body: .applicationMergePatchJson(.init(
                options: .init(cas: nil),
                data: json))
            )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                let deletedAt: Date? = if case let .case1(date) = json.data.deletionTime {
                    date
                } else {
                    nil
                }
                return .init(
                    requestID: json.requestId,
                    createdAt: json.data.createdTime,
                    custom: json.data.customMetadata?.additionalProperties,
                    deletedAt: deletedAt,
                    isDestroyed: json.data.destroyed,
                    version: json.data.version
                )
            case let .undocumented(statusCode, payload):
                let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                throw vaultError
        }
    }

    /// This endpoint issues a soft delete of the secret's latest version at the specified location.
    ///
    /// This marks the version as deleted and will stop it from being returned from reads, but the underlying data will not be removed.
    ///
    /// A delete can be undone using the ``VaultCourier/KeyValueEngineClient/undelete(key:versions:)`` operation.
    /// - Parameter key: It's the path to the secret relative to the secret mount `enginePath`
    /// - Parameter versions: The versions to be deleted. The versioned data will not be deleted, but it will no longer be returned in the read secret operations. Defaults to empty array, which deletes the latest version.
    public func delete(
        key: String,
        versions: [String] = []
    ) async throws {
        let sessionToken = self.engine.token
        let enginePath = self.engine.mountPath

        if versions.isEmpty {
            let response = try await engine.client.deleteLatestKvSecrets(
                path: .init(kvPath: enginePath, secretKey: key),
                headers: .init(xVaultToken: sessionToken)
            )

            switch response {
                case .noContent:
                    logger.info("secret deleted successfully")
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    throw vaultError
            }
        } else {
            let response = try await engine.client.deleteKvSecrets(
                path: .init(kvPath: enginePath, secretKey: key),
                headers: .init(xVaultToken: sessionToken),
                body: .json(.init(versions: versions))
            )

            switch response {
                case .noContent:
                    logger.info("secret deleted successfully")
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    throw vaultError
            }
        }
    }

    /// Undeletes the data for the provided version and path in the key-value store. This restores the data, allowing it to be returned on get requests.
    ///
    /// This reverses the  ``VaultCourier/KeyValueEngineClient/delete(key:versions:)`` operation.
    ///
    /// - Parameters:
    ///   - key: It's the path to the secret relative to the secret mount.
    ///   - versions: The versions to undelete. The versions will be restored and their data will be returned on normal read secret requests.
    public func undelete(
        key: String,
        versions: [String]
    ) async throws {
        let sessionToken = self.engine.token
        let enginePath = self.engine.mountPath

        let response = try await engine.client.undeleteKvSecrets(
            path: .init(kvPath: enginePath, secretKey: key),
            headers: .init(xVaultToken: sessionToken),
            body: .json(.init(versions: versions))
        )

        switch response {
            case .noContent:
                logger.info("secret undeleted successfully")
                return
            case let .undocumented(statusCode, payload):
                let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                throw vaultError
        }
    }


    /// Creates or updates the metadata of a secret at the specified location. It does not create a new version of the secret.
    /// - Parameters:
    ///   - key: It's the path to the secret relative to the secret mount.
    ///   - isCasRequired: If `true`, the key will require the cas parameter to be set on all write requests. If `false`, the backend’s configuration will be used. Defaults to `false`
    ///   - customMetadata: A Dictionary of user-provided metadata meant to describe the secret.
    ///   - deleteVersionAfter: Specify the deletion time for all new versions written to this key.
    ///   - versionLimit: The number of versions to keep per key. Once a key has more than the configured allowed versions, the oldest version will be permanently deleted.
    public func writeMetadata(
        key: String,
        isCasRequired: Bool = false,
        customMetadata: [String: String],
        deleteVersionAfter: String? = nil,
        versionLimit: Int = 10
    ) async throws {
        let sessionToken = self.engine.token
        let enginePath = self.engine.mountPath

        let response = try await engine.client.updateMetadataKvSecrets(
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
            case let .undocumented(statusCode, payload):
                let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                throw vaultError
        }
    }

    /// Retrieves the metadata and versions for the secret at the specified path. Metadata is version-agnostic.
    /// - Parameter key: It's the path to the secret relative to the secret mount.
    /// - Returns: All the versioned secret metadata
    public func readMetadata(
        key: String
    ) async throws -> KeyValueStoreMetadata {
        let sessionToken = self.engine.token
        let enginePath = self.engine.mountPath

        let response = try await engine.client.readMetadataKvSecrets(
            path: .init(kvPath: enginePath, secretKey: key),
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                let versionTuples = try json.data.versions.additionalProperties.map { key, value -> (Int, KeyValueStoreMetadata.KeyValueLifetime) in
                    guard let index = Int(key) else {
                        throw VaultClientError.decodingFailed()
                    }
                    let deletedAt: Date? = if case let .case1(date) = value.deletionTime {
                        date
                    } else {
                        nil
                    }
                    return (index, KeyValueStoreMetadata.KeyValueLifetime(createdAt: value.createdTime, deletedAt: deletedAt, isDestroyed: value.destroyed))
                }
                let versions = Dictionary(uniqueKeysWithValues: versionTuples)
                return .init(
                    requestID: json.requestId,
                    isCasRequired: json.data.casRequired,
                    createdAt: json.data.createdTime,
                    currentVersion: json.data.currentVersion,
                    custom: json.data.customMetadata?.additionalProperties,
                    deletedVersionAfter: json.data.deleteVersionAfter,
                    versionsLimit: json.data.maxVersions,
                    oldestVersion: json.data.oldestVersion,
                    updatedAt: json.data.updatedTime,
                    versions: versions
                )
            case let .undocumented(statusCode, payload):
                let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                throw vaultError
        }
    }


    /// Permanently deletes the key metadata _and all version data_ for the specified key.
    /// All version history will be removed.
    /// - Parameter key: It's the path to the secret relative to the secret mount.
    public func deleteAllMetadata(
        key: String
    ) async throws {
        let sessionToken = self.engine.token
        let enginePath = self.engine.mountPath

        let response = try await engine.client.deleteMetadataKvSecrets(
            path: .init(kvPath: enginePath, secretKey: key),
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .noContent:
                logger.info("Metadata deleted successfully.")
            case let .undocumented(statusCode, payload):
                let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                throw vaultError
        }
    }
}
