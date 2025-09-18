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

import struct OpenAPIRuntime.OpenAPIObjectContainer
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.Data
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
        enginePath: String,
        secret: some Codable,
        key: String
    ) async throws -> KeyValueMetadata {
        try await withKeyValueProvider(mountPath: enginePath) { provider in
            try await provider.writeKeyValue(secret: secret, key: key)
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
        enginePath: String,
        key: String,
        version: Int? = nil
    ) async throws -> T {
        try await withKeyValueProvider(mountPath: enginePath) { provider in
            try await provider.readKeyValueSecret(key: key, version: version)
        }
    }

    /// Retrieves the secret at the specified path location.
    /// 
    /// - Parameters:
    ///   - enginePath: path to key/value secret engine mount
    ///   - key: It's the path to the secret relative to the secret mount `enginePath`
    ///   - version: Specifies the version to return. If not set the latest version is returned.
    ///   - subkeysDepth: Specifies the deepest nesting level to provide in the output. The default value `nil` will not impose any limit.
    /// - Returns: Data of the secret
    public func readKeyValueSecretData(
        enginePath: String,
        key: String,
        version: Int? = nil,
        subkeysDepth: Int? = nil
    ) async throws -> Data {
        try await withKeyValueProvider(mountPath: enginePath) { provider in
            try await provider.readKeyValueSecretData(key: key, version: version, subkeysDepth: subkeysDepth)
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
        enginePath: String,
        key: String,
        version: Int? = nil,
        depth: Int? = nil
    ) async throws -> Data? {
        try await withKeyValueProvider(mountPath: enginePath) { provider in
            try await provider.readSecretSubkeys(key: key, version: version, depth: depth)
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
        enginePath: String,
        secret: some Codable,
        key: String
    ) async throws -> KeyValueMetadata? {
        try await withKeyValueProvider(mountPath: enginePath) { provider in
            try await provider.patchKeyValue(secret: secret, key: key)
        }
    }

    /// This endpoint issues a soft delete of the secret's latest version at the specified location.
    /// 
    /// This marks the version as deleted and will stop it from being returned from reads, but the underlying data will not be removed.
    ///
    /// A delete can be undone using the ``VaultCourier/VaultClient/undelete(key:versions:)`` operation.
    /// - Parameter enginePath: mount path of secret engine
    /// - Parameter key: It's the path to the secret relative to the secret mount `enginePath`
    /// - Parameter versions: The versions to be deleted. The versioned data will not be deleted, but it will no longer be returned in the read secret operations. Defaults to empty array, which deletes the latest version.
    public func delete(
        enginePath: String,
        key: String,
        versions: [String] = []
    ) async throws {
        try await withKeyValueProvider(mountPath: enginePath) { provider in
            try await provider.delete(key: key, versions: versions)
        }
    }

    /// Undeletes the data for the provided version and path in the key-value store. This restores the data, allowing it to be returned on get requests.
    ///
    /// This reverses the  ``VaultCourier/VaultClient/delete(key:versions:)`` operation.
    ///
    /// - Parameters:
    ///   - enginePath: mount path of secret engine
    ///   - key: It's the path to the secret relative to the secret mount.
    ///   - versions: The versions to undelete. The versions will be restored and their data will be returned on normal read secret requests.
    public func undelete(
        enginePath: String,
        key: String,
        versions: [String]
    ) async throws {
        try await withKeyValueProvider(mountPath: enginePath) { provider in
            try await provider.undelete(key: key, versions: versions)
        }
    }

    
    /// Creates or updates the metadata of a secret at the specified location. It does not create a new version of the secret.
    /// - Parameters:
    /// - Parameter enginePath: mount path of secret engine
    /// - Parameter key: It's the path to the secret relative to the secret mount.
    /// - Parameter isCasRequired: If `true`, the key will require the cas parameter to be set on all write requests. If `false`, the backend’s configuration will be used. Defaults to `false`
    /// - Parameter customMetadata: A Dictionary of user-provided metadata meant to describe the secret.
    /// - Parameter deleteVersionAfter: Specify the deletion time for all new versions written to this key.
    /// - Parameter versionLimit: The number of versions to keep per key. Once a key has more than the configured allowed versions, the oldest version will be permanently deleted.
    public func writeMetadata(
        enginePath: String,
        key: String,
        isCasRequired: Bool = false,
        customMetadata: [String: String],
        deleteVersionAfter: String? = nil,
        versionLimit: Int = 10
    ) async throws {
        try await withKeyValueProvider(mountPath: enginePath) { provider in
            try await provider.writeMetadata(
                key: key,
                isCasRequired: isCasRequired,
                customMetadata: customMetadata,
                deleteVersionAfter: deleteVersionAfter,
                versionLimit: versionLimit
            )
        }
    }
    
    /// Retrieves the metadata and versions for the secret at the specified path. Metadata is version-agnostic.
    /// - Parameter enginePath: mount path of secret engine
    /// - Parameter key: It's the path to the secret relative to the secret mount.
    /// - Returns: All the versioned secret metadata
    public func readMetadata(
        enginePath: String,
        key: String
    ) async throws -> KeyValueStoreMetadata {
        try await withKeyValueProvider(mountPath: enginePath) { provider in
            try await provider.readMetadata(key: key)
        }
    }
    
    /// Permanently deletes the key metadata _and all version data_ for the specified key.
    /// All version history will be removed.
    /// - Parameter enginePath: mount path of secret engine
    /// - Parameter key: It's the path to the secret relative to the secret mount.
    public func deleteAllMetadata(
        enginePath: String,
        key: String
    ) async throws {
        try await withKeyValueProvider(mountPath: enginePath) { provider in
            try await provider.deleteAllMetadata(key: key)
        }
    }
}
