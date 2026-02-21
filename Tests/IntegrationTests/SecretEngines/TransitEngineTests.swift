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
import Testing
import VaultCourier

extension IntegrationTests.SecretEngine.Transit {
    @Test(.setupSecretEngine(type: "transit"))
    func create_encryption_key_encrypt_and_decrypt() async throws {
        let vaultClient = VaultClient.current
        let mountPath = VaultClient.secretEngine.path

        let plaintext = "dGhlIHF1aWNrIGJyb3duIGZveAo="
        let key = EncryptionKey(name: "test_key", type: .aes256_gcm96, version: 1)
        let response = try await vaultClient.withTransitClient(mountPath: mountPath) { client in
            _ = try await client.writeEncryptionKey(name: key.name, type: key.type)

            let encryption = try await client.encrypt(plaintext: plaintext, key: key)

            return try await client.decrypt(ciphertext: encryption.ciphertext, key: key)
        }

        #expect(response.plaintext == plaintext)
    }

    @Test(.setupSecretEngine(type: "transit"))
    func ed25519_cannot_encrypt() async throws {
        let vaultClient = VaultClient.current
        let mountPath = VaultClient.secretEngine.path

        let key = EncryptionKey(name: "test_key", type: .ed25519, version: 1)
        await #expect(throws: VaultClientError.self) {
            try await vaultClient.withTransitClient(mountPath: mountPath) { client in
                _ = try await client.writeEncryptionKey(name: key.name, type: key.type)
                return try await client.encrypt(plaintext: "dGhlIHF1aWNrIGJyb3duIGZveAo=", key: key)
            }
        }
    }

    @Test(.setupSecretEngine(type: "transit"))
    func generate_key_with_invalid_bits_fails() async throws {
        let vaultClient = VaultClient.current
        let mountPath = VaultClient.secretEngine.path

        let key = EncryptionKey(name: "test_key", type: .aes256_gcm96, version: 1)
        let response = try await vaultClient.withTransitClient(mountPath: mountPath) { client in
            _ = try await client.writeEncryptionKey(name: key.name, type: key.type)
            return try await client.generateDataKey(outputType: .plaintext, keyName: key.name, bits: .bit512)
        }

        _ = try #require(response.plaintext)
    }

    @Test(.setupSecretEngine(type: "transit"))
    func sign_and_verify_data() async throws {
        let vaultClient = VaultClient.current
        let mountPath = VaultClient.secretEngine.path

        let key = EncryptionKey(name: "test_key", type: .ed25519, version: 1)
        let input = "adba32=="
        let hashAlgorithm = HashAlgorithm.SHA2_224
        let isValid = try await vaultClient.withTransitClient(mountPath: mountPath) { client in
            _ = try await client.writeEncryptionKey(name: key.name, type: key.type)
            let signature = try await client.sign(input: input, hashAlgorithm: hashAlgorithm, keyName: key.name)
            return try await client.verifySignedInput(input, verificationKey: .signature(signature), hashAlgorithm: hashAlgorithm, keyName: key.name)
        }

        #expect(isValid)
    }

    @Test(.setupSecretEngine(type: "transit"))
    func sign_csr() async throws {
        let vaultClient = VaultClient.current
        let mountPath = VaultClient.secretEngine.path

        let key = EncryptionKey(name: "test_key", type: .ed25519, version: 1)

        try await vaultClient.withTransitClient(mountPath: mountPath) { client in
            _ = try await client.writeEncryptionKey(name: key.name, type: key.type)
            _ = try await client.signCSR(nil, keyName: key.name)
        }
    }

    @Test(.setupSecretEngine(type: "transit"))
    func batch_encryption() async throws {
        let vaultClient = VaultClient.current
        let mountPath = VaultClient.secretEngine.path

        let plaintext = "dGhlIHF1aWNrIGJyb3duIGZveAo="
        let key = EncryptionKey(name: "test_key", type: .aes256_gcm96, version: 1)
        let response = try await vaultClient.withTransitClient(mountPath: mountPath) { client in
            _ = try await client.writeEncryptionKey(name: key.name, type: key.type)

            let encryption = try await client.encryptBatch(
                [
                .init(plaintext: plaintext, associatedData: nil, reference: "reference_1", derivedKeyContext: nil),
                .init(plaintext: plaintext, associatedData: nil, reference: "reference_2", derivedKeyContext: nil),
                .init(plaintext: plaintext, associatedData: nil, reference: "reference_3", derivedKeyContext: nil)
                ],
                key: key
            )

            return encryption
        }

        #expect(response.hasPartialFailure == false)
    }

    @Test(.setupSecretEngine(type: "transit"))
    func batch_encryption_with_partial_failure() async throws {
        let vaultClient = VaultClient.current
        let mountPath = VaultClient.secretEngine.path

        let plaintext = "dGhlIHF1aWNrIGJyb3duIGZveAo="
        let associatedData = "dGhlIHF1aWNrIGJyb3duIGZveAo="
        let key = EncryptionKey(name: "test_key", type: .aes256_gcm96, version: 1)
        let response = try await vaultClient.withTransitClient(mountPath: mountPath) { client in
            _ = try await client.writeEncryptionKey(name: key.name, type: key.type)

            let encryption = try await client.encryptBatch(
                [
                .init(plaintext: plaintext, associatedData: associatedData, reference: "reference_1", derivedKeyContext: nil),
                .init(plaintext: "not based64 encoded", associatedData: associatedData, reference: "reference_2", derivedKeyContext: nil),
                .init(plaintext: plaintext, associatedData: associatedData, reference: "reference_3", derivedKeyContext: nil)
                ],
                key: key
            )

            return encryption
        }

        #expect(response.hasPartialFailure == true)
    }

    @Test(.setupSecretEngine(type: "transit"))
    func batch_encryption_with_full_failure() async throws {
        let vaultClient = VaultClient.current
        let mountPath = VaultClient.secretEngine.path

        let plaintext = "dGhlIHF1aWNrIGJyb3duIGZveAo="
        let key = EncryptionKey(name: "test_key", type: .aes256_gcm96, version: 1)

        await #expect(throws: VaultServerError.self) {
            try await vaultClient.withTransitClient(mountPath: mountPath) { client in
                _ = try await client.writeEncryptionKey(name: key.name, type: key.type)

                // Context should be set on all or none
                return try await client.encryptBatch(
                    [
                    .init(plaintext: plaintext, associatedData: nil, reference: "reference_1", derivedKeyContext: nil),
                    .init(plaintext: plaintext, associatedData: nil, reference: "reference_2", derivedKeyContext: .init(context: plaintext, nonce: nil)),
                    .init(plaintext: plaintext, associatedData: nil, reference: "reference_3", derivedKeyContext: nil)
                    ],
                    key: key
                )
            }
        }
    }
}

#endif
