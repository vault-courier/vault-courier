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

#if TransitEngineSupport

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.Date
#endif

public struct EncryptionKeyResponse: Sendable {
    public let requestID: String

    public let isDerived: Bool

    public let isExportable: Bool

    public let isPlaintextBackupAllowed: Bool

    public let keyType: EncryptionKey.KeyType

    public let autoRotatePeriod: Duration?

    // End of core

    public let isDeletionAllowed: Bool

    public let isImported: Bool

    public let kdf: String?

    public let keys: [AsymmetricKeyData]

    public let latestVersion: Int

    public let minAvailableVersion: Int

    public let minDecryptionVersion: Int

    public let minEncryptionVersion: Int

    public let name: String

    public let isSoftDeleted: Bool

    public let supportsDecryption: Bool

    public let supportsEncryption: Bool

    public let supportsSigning: Bool

    public let supportsDerivation: Bool
}

public struct AsymmetricKeyData: Sendable {
    public let certificateChain: String?

    public let createdAt: Date

    public let name: String?

    public let publicKey: String?
}

#endif
