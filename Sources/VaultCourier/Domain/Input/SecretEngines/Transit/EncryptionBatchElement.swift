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

/// Input for batch encryption
public struct EncryptionBatchElement: Sendable {
    public let plaintext: String

    public let associatedData: String?

    public let reference: String?

    public let derivedKeyContext: DerivedKeyContext?

    public init(
        plaintext: String,
        associatedData: String?,
        reference: String?,
        derivedKeyContext: DerivedKeyContext?
    ) {
        self.plaintext = plaintext
        self.associatedData = associatedData
        self.reference = reference
        self.derivedKeyContext = derivedKeyContext
    }
}

/// If key derivation was used, all encrypt/decrypt requests for that key must provide a context which is used for key derivation.
public struct DerivedKeyContext: Sendable {
    /// base64 encoded context for key derivation
    public let context: String

    /// base64 encoded nonce value.
    /// The value must be exactly 96 bits (12 bytes) long and the user must ensure that for any given context (and thus, any given encryption key) this nonce value is never reused.
    public let nonce: String?

    /// This parameter will only be used when a key is expected to be created. Whether to support convergent encryption.
    /// This is only supported when using a key with key derivation enabled and will require all requests to carry both a context and 96-bit (12-byte) for AES and ChaCha20 or 192-bit (24-byte) for XChaCha20 nonce.
    /// The given nonce will be used in place of a randomly generated nonce. As a result, when the same context and nonce are supplied, the same ciphertext is generated.
    /// - important: when using this mode that you ensure that all nonces are unique for a given context. Failing to do so will severely impact the ciphertext's security.
    public let convergentEncryption: String?

    public init(
        context: String,
        nonce: String?,
        convergentEncryption: String? = nil
    ) {
        self.context = context
        self.nonce = nonce
        self.convergentEncryption = convergentEncryption
    }
}

#endif
