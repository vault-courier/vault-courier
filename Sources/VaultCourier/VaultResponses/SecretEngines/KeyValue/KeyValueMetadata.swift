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

public struct KeyValueMetadata: Sendable {
    public let requestID: String

    /// Date of secret creation
    public let createdAt: String

    /// Custom metadata associated to the secret
    public let custom: [String:String]?

    /// Date of soft deletion
    public let deletedAt: String?

    /// Flag wheter the secret data has been destroyed
    public let isDestroyed: Bool?

    /// Version of the secret
    public let version: Int
}

public struct KeyValueStoreMetadata: Sendable {
    public let requestID: String

    /// If true, the key will require the cas parameter to be set on all write requests. If false, Vault's backend’s configuration will be used.
    public let isCasRequired: Bool

    /// Date of secret creation
    public let createdAt: String

    /// Date of secret creation
    public let currentVersion: Int

    /// Custom metadata associated to the secret
    public let custom: [String:String]?

    /// Deletion time for all new versions written to this key
    public let deletedVersionAfter: String?

    /// The number of versions to keep per key
    /// Once a key has more than the configured allowed versions, the oldest version will be permanently deleted.
    public let versionsLimit: Int?

    public let oldestVersion: Int?

    /// Date of last update
    public let updatedAt: String?

    /// Array of all secret versions lifecycle: whether is destroyed, and creation/deletion time
    public let versions: [Int: KeyValueLifetime]

    public struct KeyValueLifetime: Sendable {
        /// Date of secret creation
        public let createdAt: String

        /// Date of soft deletion
        public let deletedAt: String?

        /// Flag wheter the secret data has been destroyed
        public let isDestroyed: Bool
    }
}

extension Operations.ReadMetadataKvSecrets.Output.Ok.Body.JsonPayload {
    var metadata: KeyValueStoreMetadata {
        get throws {
            let versionTuples = try data.versions.additionalProperties.map { key, value -> (Int, KeyValueStoreMetadata.KeyValueLifetime) in
                guard let index = Int(key) else {
                    throw VaultClientError.decodingFailed()
                }
                return (index, KeyValueStoreMetadata.KeyValueLifetime(createdAt: value.createdTime, deletedAt: value.deletionTime, isDestroyed: value.destroyed))
            }
            let versions = Dictionary(uniqueKeysWithValues: versionTuples)
            return .init(requestID: requestId,
                  isCasRequired: data.casRequired,
                  createdAt: data.createdTime,
                  currentVersion: data.currentVersion,
                  custom: data.customMetadata?.additionalProperties,
                  deletedVersionAfter: data.deleteVersionAfter,
                  versionsLimit: data.maxVersions,
                  oldestVersion: data.oldestVersion,
                  updatedAt: data.updatedTime,
                  versions: versions)
        }
    }
}
