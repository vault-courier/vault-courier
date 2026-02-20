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
    static var enginePath: String { "custom" }

    @Test
    func create_encryption_key_encrypt_and_decrypt() async throws {
        let vaultClient = VaultClient.current

        let plaintext = "dGhlIHF1aWNrIGJyb3duIGZveAo="
        let key = EncryptionKey(name: "test_key", type: .`aes256-gcm96`, version: 1)
        let response = try await vaultClient.withTransitClient(mountPath: Self.enginePath) { client in
            _ = try await client.writeEncryptionKey(name: key.name, type: key.type)

            let encryption = try await client.encrypt(plaintext: plaintext, key: key)

            return try await client.decrypt(ciphertext: encryption.ciphertext, key: key)
        }

        #expect(response.plaintext == plaintext)
    }

    @Test
    func ed25519_cannot_encrypt() async throws {
        let vaultClient = VaultClient.current

        let key = EncryptionKey(name: "test_key", type: .ed25519, version: 1)
        await #expect(throws: VaultClientError.self) {
            try await vaultClient.withTransitClient(mountPath: Self.enginePath) { client in
                _ = try await client.writeEncryptionKey(name: key.name, type: key.type)
                return try await client.encrypt(plaintext: "dGhlIHF1aWNrIGJyb3duIGZveAo=", key: key)
            }
        }
    }

    @Test
    func generate_key_with_invalid_bits_fails() async throws {
        let vaultClient = VaultClient.current

        let key = EncryptionKey(name: "test_key", type: .`aes256-gcm96`, version: 1)
        let response = try await vaultClient.withTransitClient(mountPath: Self.enginePath) { client in
            _ = try await client.writeEncryptionKey(name: key.name, type: key.type)
            return try await client.generateDataKey(outputType: .plaintext, keyName: key.name, bits: .bit512)
        }

        _ = try #require(response.plaintext)
    }

    @Test
    func sign_and_verify_data() async throws {
        let vaultClient = VaultClient.current

        let key = EncryptionKey(name: "test_key", type: .ed25519, version: 1)
        let input = "adba32=="
        let hashAlgorithm = HashAlgorithm.SHA2_224
        let isValid = try await vaultClient.withTransitClient(mountPath: Self.enginePath) { client in
            _ = try await client.writeEncryptionKey(name: key.name, type: key.type)
            let signature = try await client.sign(input: input, hashAlgorithm: hashAlgorithm, keyName: key.name)
            return try await client.verifySignedInput(input, verificationKey: .signature(signature), hashAlgorithm: hashAlgorithm, keyName: key.name)
        }

        #expect(isValid)
    }

    @Test
    func sign_csr() async throws {
        let vaultClient = VaultClient.current

        let key = EncryptionKey(name: "test_key", type: .ed25519, version: 1)

        try await vaultClient.withTransitClient(mountPath: Self.enginePath) { client in
            _ = try await client.writeEncryptionKey(name: key.name, type: key.type)
            _ = try await client.signCSR(nil, keyName: key.name)
        }
    }
}

#endif
