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
    func create_encryption_key() async throws {
        let vaultClient = VaultClient.current

        let key = EncryptionKey(name: "test_key", type: .`aes256-gcm96`, version: 1)
        let response = try await vaultClient.withTransitClient(mountPath: Self.enginePath) { client in
            _ = try await client.writeEncryptionKey(name: key.name, type: key.type)

            return try await client.encrypt(plaintext: "dGhlIHF1aWNrIGJyb3duIGZveAo=", key: key)
        }

        print(response)
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


}

#endif
